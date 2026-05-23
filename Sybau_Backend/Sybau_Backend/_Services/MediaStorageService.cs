using System.Net;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Http;

namespace Sybau_Backend._Services;

public sealed class MediaStorageService
{
    private const string DefaultSupabaseBucket = "sybau-images";
    private const string CacheControl = "public, max-age=31536000, immutable";
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    private readonly HttpClient _httpClient;
    private readonly ILogger<MediaStorageService> _logger;
    private readonly StorageProvider _provider;
    private readonly string? _requestedProvider;

    private readonly string? _supabaseUrl;
    private readonly string? _supabaseServiceKey;
    private readonly string _supabaseBucket;
    private readonly string _supabasePublicBaseUrl;

    private readonly string? _cloudinaryCloudName;
    private readonly string? _cloudinaryApiKey;
    private readonly string? _cloudinaryApiSecret;

    public MediaStorageService(
        HttpClient httpClient,
        IConfiguration configuration,
        ILogger<MediaStorageService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
        _requestedProvider = FirstNonEmpty(
            configuration["MediaStorage:Provider"],
            Environment.GetEnvironmentVariable("MEDIA_STORAGE_PROVIDER"));

        _cloudinaryCloudName = FirstNonEmpty(
            configuration["MediaStorage:CloudinaryCloudName"],
            configuration["Cloudinary:CloudName"],
            Environment.GetEnvironmentVariable("CLOUDINARY_CLOUD_NAME"));
        _cloudinaryApiKey = FirstNonEmpty(
            configuration["MediaStorage:CloudinaryApiKey"],
            configuration["Cloudinary:ApiKey"],
            Environment.GetEnvironmentVariable("CLOUDINARY_API_KEY"));
        _cloudinaryApiSecret = FirstNonEmpty(
            configuration["MediaStorage:CloudinaryApiSecret"],
            configuration["Cloudinary:ApiSecret"],
            Environment.GetEnvironmentVariable("CLOUDINARY_API_SECRET"));

        _supabaseUrl = NormalizeBaseUrl(FirstNonEmpty(
            configuration["MediaStorage:SupabaseUrl"],
            configuration["Supabase:Url"],
            Environment.GetEnvironmentVariable("SUPABASE_URL")));
        _supabaseServiceKey = FirstNonEmpty(
            configuration["MediaStorage:ServiceRoleKey"],
            configuration["Supabase:ServiceRoleKey"],
            Environment.GetEnvironmentVariable("SUPABASE_SERVICE_ROLE_KEY"));
        _supabaseBucket = FirstNonEmpty(
            configuration["MediaStorage:Bucket"],
            Environment.GetEnvironmentVariable("SUPABASE_STORAGE_BUCKET")) ?? DefaultSupabaseBucket;
        _supabasePublicBaseUrl = BuildSupabasePublicBaseUrl(
            FirstNonEmpty(
                configuration["MediaStorage:PublicBaseUrl"],
                Environment.GetEnvironmentVariable("SUPABASE_STORAGE_PUBLIC_BASE_URL")),
            _supabaseUrl,
            _supabaseBucket);

        _provider = ResolveProvider();
    }

    public bool IsConfigured => _provider != StorageProvider.None;

    public async Task EnsureReadyAsync(CancellationToken cancellationToken = default)
    {
        switch (_provider)
        {
            case StorageProvider.Cloudinary:
                _logger.LogInformation("Media storage provider: Cloudinary.");
                return;
            case StorageProvider.Supabase:
                await EnsureSupabaseReadyAsync(cancellationToken);
                return;
            default:
                _logger.LogWarning(
                    "Media storage is not configured. Image uploads and image migration are disabled.");
                return;
        }
    }

    public async Task<string> SaveFormFileAsync(
        IFormFile image,
        string category,
        string? extension = null,
        CancellationToken cancellationToken = default)
    {
        RequireConfiguration();

        var normalizedExtension = NormalizeExtension(extension ?? Path.GetExtension(image.FileName), image.ContentType);
        await using var stream = image.OpenReadStream();

        return _provider switch
        {
            StorageProvider.Cloudinary => await UploadCloudinaryAsync(
                stream,
                image.Length,
                category,
                normalizedExtension,
                ContentTypeFor(image.ContentType, normalizedExtension),
                null,
                cancellationToken),
            StorageProvider.Supabase => await UploadSupabaseAsync(
                stream,
                category,
                normalizedExtension,
                ContentTypeFor(image.ContentType, normalizedExtension),
                null,
                cancellationToken),
            _ => throw MissingConfigurationException()
        };
    }

    public async Task<string> SaveDataImageAsync(
        CachedDataImage image,
        string category,
        string namePrefix,
        CancellationToken cancellationToken = default)
    {
        return await SaveBytesAsync(
            image.Bytes,
            category,
            namePrefix,
            image.ContentType,
            ExtensionForContentType(image.ContentType),
            cancellationToken);
    }

    public async Task<string> SaveBytesAsync(
        byte[] bytes,
        string category,
        string namePrefix,
        string? contentType,
        string? extension,
        CancellationToken cancellationToken = default)
    {
        RequireConfiguration();

        var normalizedExtension = NormalizeExtension(extension, contentType);
        await using var stream = new MemoryStream(bytes);

        return _provider switch
        {
            StorageProvider.Cloudinary => await UploadCloudinaryAsync(
                stream,
                bytes.Length,
                category,
                normalizedExtension,
                ContentTypeFor(contentType, normalizedExtension),
                namePrefix,
                cancellationToken),
            StorageProvider.Supabase => await UploadSupabaseAsync(
                stream,
                category,
                normalizedExtension,
                ContentTypeFor(contentType, normalizedExtension),
                namePrefix,
                cancellationToken),
            _ => throw MissingConfigurationException()
        };
    }

    public async Task DeletePublicUrlAsync(string? imageUrl, CancellationToken cancellationToken = default)
    {
        if (!IsConfigured || string.IsNullOrWhiteSpace(imageUrl))
        {
            return;
        }

        switch (_provider)
        {
            case StorageProvider.Cloudinary:
                await DeleteCloudinaryAsync(imageUrl, cancellationToken);
                break;
            case StorageProvider.Supabase:
                await DeleteSupabaseAsync(imageUrl, cancellationToken);
                break;
        }
    }

    public bool ShouldMigrateRemoteUrl(string? imageUrl)
    {
        if (string.IsNullOrWhiteSpace(imageUrl) ||
            !Uri.TryCreate(imageUrl, UriKind.Absolute, out var uri) ||
            (uri.Scheme != Uri.UriSchemeHttp && uri.Scheme != Uri.UriSchemeHttps))
        {
            return false;
        }

        return _provider switch
        {
            StorageProvider.Cloudinary => IsSupabaseStorageUrl(uri),
            _ => false
        };
    }

    private StorageProvider ResolveProvider()
    {
        var wantsCloudinary = string.Equals(_requestedProvider, "Cloudinary", StringComparison.OrdinalIgnoreCase);
        var wantsSupabase = string.Equals(_requestedProvider, "Supabase", StringComparison.OrdinalIgnoreCase);
        var cloudinaryConfigured =
            !string.IsNullOrWhiteSpace(_cloudinaryCloudName) &&
            !string.IsNullOrWhiteSpace(_cloudinaryApiKey) &&
            !string.IsNullOrWhiteSpace(_cloudinaryApiSecret);
        var supabaseConfigured =
            !string.IsNullOrWhiteSpace(_supabaseUrl) &&
            !string.IsNullOrWhiteSpace(_supabaseServiceKey);

        if (wantsCloudinary)
        {
            return cloudinaryConfigured ? StorageProvider.Cloudinary : StorageProvider.None;
        }

        if (wantsSupabase)
        {
            return supabaseConfigured ? StorageProvider.Supabase : StorageProvider.None;
        }

        if (cloudinaryConfigured) return StorageProvider.Cloudinary;
        if (supabaseConfigured) return StorageProvider.Supabase;
        return StorageProvider.None;
    }

    private async Task EnsureSupabaseReadyAsync(CancellationToken cancellationToken)
    {
        using var request = CreateSupabaseRequest(HttpMethod.Get, SupabaseStorageUri($"bucket/{Uri.EscapeDataString(_supabaseBucket)}"));
        using var response = await _httpClient.SendAsync(request, cancellationToken);

        if (response.StatusCode == HttpStatusCode.NotFound)
        {
            await CreateSupabaseBucketAsync(cancellationToken);
            return;
        }

        if (!response.IsSuccessStatusCode)
        {
            throw await StorageExceptionAsync("Supabase Storage bucket check", response);
        }

        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (BucketIsPublic(body) == false)
        {
            await MakeSupabaseBucketPublicAsync(cancellationToken);
        }
    }

    private async Task CreateSupabaseBucketAsync(CancellationToken cancellationToken)
    {
        using var request = CreateSupabaseRequest(HttpMethod.Post, SupabaseStorageUri("bucket"));
        request.Content = JsonContent(new
        {
            id = _supabaseBucket,
            name = _supabaseBucket,
            @public = true
        });

        using var response = await _httpClient.SendAsync(request, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw await StorageExceptionAsync("Supabase Storage bucket creation", response);
        }

        _logger.LogInformation("Created public Supabase Storage bucket {Bucket}.", _supabaseBucket);
    }

    private async Task MakeSupabaseBucketPublicAsync(CancellationToken cancellationToken)
    {
        using var request = CreateSupabaseRequest(HttpMethod.Put, SupabaseStorageUri($"bucket/{Uri.EscapeDataString(_supabaseBucket)}"));
        request.Content = JsonContent(new { @public = true });

        using var response = await _httpClient.SendAsync(request, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw await StorageExceptionAsync("Supabase Storage bucket public update", response);
        }

        _logger.LogInformation("Updated Supabase Storage bucket {Bucket} to public.", _supabaseBucket);
    }

    private async Task<string> UploadSupabaseAsync(
        Stream stream,
        string category,
        string extension,
        string contentType,
        string? namePrefix,
        CancellationToken cancellationToken)
    {
        var objectPath = ObjectPath(category, extension, namePrefix);
        using var request = CreateSupabaseRequest(
            HttpMethod.Post,
            SupabaseStorageUri($"object/{Uri.EscapeDataString(_supabaseBucket)}/{EscapeObjectPath(objectPath)}"));
        request.Headers.TryAddWithoutValidation("x-upsert", "false");
        request.Headers.TryAddWithoutValidation("cache-control", CacheControl);

        using var content = new StreamContent(stream);
        content.Headers.ContentType = MediaTypeHeaderValue.Parse(contentType);
        request.Content = content;

        using var response = await _httpClient.SendAsync(request, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw await StorageExceptionAsync("Supabase Storage upload", response);
        }

        return $"{_supabasePublicBaseUrl}/{EscapeObjectPath(objectPath)}";
    }

    private async Task DeleteSupabaseAsync(string imageUrl, CancellationToken cancellationToken)
    {
        if (TryGetSupabaseObjectPath(imageUrl) is not { } objectPath)
        {
            return;
        }

        using var request = CreateSupabaseRequest(HttpMethod.Delete, SupabaseStorageUri($"object/{Uri.EscapeDataString(_supabaseBucket)}"));
        request.Content = JsonContent(new { prefixes = new[] { objectPath } });

        using var response = await _httpClient.SendAsync(request, cancellationToken);
        if (response.IsSuccessStatusCode || response.StatusCode == HttpStatusCode.NotFound)
        {
            return;
        }

        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        _logger.LogWarning(
            "Could not delete Supabase Storage object {ObjectPath}: {StatusCode} {Body}",
            objectPath,
            (int)response.StatusCode,
            body);
    }

    private HttpRequestMessage CreateSupabaseRequest(HttpMethod method, Uri uri)
    {
        var request = new HttpRequestMessage(method, uri);
        request.Headers.TryAddWithoutValidation("apikey", _supabaseServiceKey);
        if (UsesLegacyJwtKey(_supabaseServiceKey))
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _supabaseServiceKey);
        }

        return request;
    }

    private Uri SupabaseStorageUri(string relativePath)
    {
        return new Uri($"{_supabaseUrl}/storage/v1/{relativePath.TrimStart('/')}");
    }

    private string? TryGetSupabaseObjectPath(string? imageUrl)
    {
        if (string.IsNullOrWhiteSpace(imageUrl) || string.IsNullOrWhiteSpace(_supabasePublicBaseUrl))
        {
            return null;
        }

        var publicPrefix = $"{_supabasePublicBaseUrl.TrimEnd('/')}/";
        if (!imageUrl.StartsWith(publicPrefix, StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        var encodedPath = StripQueryAndFragment(imageUrl[publicPrefix.Length..]);
        if (string.IsNullOrWhiteSpace(encodedPath))
        {
            return null;
        }

        return string.Join(
            '/',
            encodedPath.Split('/', StringSplitOptions.RemoveEmptyEntries).Select(Uri.UnescapeDataString));
    }

    private async Task<string> UploadCloudinaryAsync(
        Stream stream,
        long length,
        string category,
        string extension,
        string contentType,
        string? namePrefix,
        CancellationToken cancellationToken)
    {
        var timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString();
        var folder = CloudinaryFolder(category);
        var publicId = CloudinaryPublicId(namePrefix);
        var signature = CloudinarySignature(new SortedDictionary<string, string>
        {
            ["folder"] = folder,
            ["public_id"] = publicId,
            ["timestamp"] = timestamp
        });

        using var multipart = new MultipartFormDataContent();
        using var fileContent = new StreamContent(stream);
        fileContent.Headers.ContentType = MediaTypeHeaderValue.Parse(contentType);
        if (length > 0)
        {
            fileContent.Headers.ContentLength = length;
        }

        multipart.Add(fileContent, "file", $"{publicId}{extension}");
        multipart.Add(new StringContent(_cloudinaryApiKey!), "api_key");
        multipart.Add(new StringContent(timestamp), "timestamp");
        multipart.Add(new StringContent(folder), "folder");
        multipart.Add(new StringContent(publicId), "public_id");
        multipart.Add(new StringContent(signature), "signature");

        using var response = await _httpClient.PostAsync(CloudinaryUploadUri(), multipart, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw await StorageExceptionAsync("Cloudinary upload", response);
        }

        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        using var document = JsonDocument.Parse(body);
        if (document.RootElement.TryGetProperty("secure_url", out var secureUrl) &&
            secureUrl.GetString() is { Length: > 0 } value)
        {
            return value;
        }

        throw new InvalidOperationException("Cloudinary upload succeeded, but no secure_url was returned.");
    }

    private async Task DeleteCloudinaryAsync(string imageUrl, CancellationToken cancellationToken)
    {
        if (TryGetCloudinaryPublicId(imageUrl) is not { } publicId)
        {
            return;
        }

        var timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString();
        var signature = CloudinarySignature(new SortedDictionary<string, string>
        {
            ["public_id"] = publicId,
            ["timestamp"] = timestamp
        });

        using var form = new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["api_key"] = _cloudinaryApiKey!,
            ["timestamp"] = timestamp,
            ["public_id"] = publicId,
            ["signature"] = signature
        });

        using var response = await _httpClient.PostAsync(CloudinaryDestroyUri(), form, cancellationToken);
        if (response.IsSuccessStatusCode || response.StatusCode == HttpStatusCode.NotFound)
        {
            return;
        }

        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        _logger.LogWarning(
            "Could not delete Cloudinary image {PublicId}: {StatusCode} {Body}",
            publicId,
            (int)response.StatusCode,
            body);
    }

    private Uri CloudinaryUploadUri()
    {
        return new Uri($"https://api.cloudinary.com/v1_1/{Uri.EscapeDataString(_cloudinaryCloudName!)}/image/upload");
    }

    private Uri CloudinaryDestroyUri()
    {
        return new Uri($"https://api.cloudinary.com/v1_1/{Uri.EscapeDataString(_cloudinaryCloudName!)}/image/destroy");
    }

    private string CloudinarySignature(SortedDictionary<string, string> parameters)
    {
        var payload = string.Join('&', parameters.Select(parameter => $"{parameter.Key}={parameter.Value}"));
        var bytes = SHA1.HashData(Encoding.UTF8.GetBytes($"{payload}{_cloudinaryApiSecret}"));
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }

    private static string CloudinaryFolder(string category)
    {
        var timestamp = DateTime.UtcNow;
        return $"sybau/{SafeCategory(category)}/{timestamp:yyyy/MM}";
    }

    private static string CloudinaryPublicId(string? namePrefix)
    {
        var prefix = string.IsNullOrWhiteSpace(namePrefix) ? null : $"{Slug(namePrefix)}-";
        return $"{prefix}{DateTime.UtcNow:yyyyMMddHHmmssfff}-{Guid.NewGuid():N}";
    }

    private string? TryGetCloudinaryPublicId(string? imageUrl)
    {
        if (string.IsNullOrWhiteSpace(imageUrl) ||
            string.IsNullOrWhiteSpace(_cloudinaryCloudName) ||
            !Uri.TryCreate(imageUrl, UriKind.Absolute, out var uri) ||
            !uri.Host.Equals("res.cloudinary.com", StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        var marker = $"/{_cloudinaryCloudName}/image/upload/";
        if (!uri.AbsolutePath.StartsWith(marker, StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        var path = StripQueryAndFragment(uri.AbsolutePath[marker.Length..]);
        var segments = path.Split('/', StringSplitOptions.RemoveEmptyEntries).ToList();
        if (segments.Count == 0)
        {
            return null;
        }

        if (segments[0].Length > 1 &&
            segments[0][0] == 'v' &&
            segments[0][1..].All(char.IsDigit))
        {
            segments.RemoveAt(0);
        }

        if (segments.Count == 0)
        {
            return null;
        }

        var lastSegment = Uri.UnescapeDataString(segments[^1]);
        var extension = Path.GetExtension(lastSegment);
        if (!string.IsNullOrWhiteSpace(extension))
        {
            lastSegment = lastSegment[..^extension.Length];
        }

        segments[^1] = lastSegment;
        return string.Join('/', segments.Select(Uri.UnescapeDataString));
    }

    private void RequireConfiguration()
    {
        if (IsConfigured) return;
        throw MissingConfigurationException();
    }

    private InvalidOperationException MissingConfigurationException()
    {
        return new InvalidOperationException(_requestedProvider?.Equals("Cloudinary", StringComparison.OrdinalIgnoreCase) == true
            ? "MediaStorage Cloudinary ist nicht konfiguriert. Setze MediaStorage__CloudinaryCloudName, MediaStorage__CloudinaryApiKey und MediaStorage__CloudinaryApiSecret."
            : "MediaStorage ist nicht konfiguriert. Setze Cloudinary- oder Supabase-Environment-Variables.");
    }

    private static async Task<InvalidOperationException> StorageExceptionAsync(
        string action,
        HttpResponseMessage response)
    {
        var body = await response.Content.ReadAsStringAsync();
        return new InvalidOperationException(
            $"{action} failed with {(int)response.StatusCode} {response.ReasonPhrase}: {body}");
    }

    private static StringContent JsonContent<T>(T value)
    {
        return new StringContent(JsonSerializer.Serialize(value, JsonOptions), Encoding.UTF8, "application/json");
    }

    private static bool? BucketIsPublic(string json)
    {
        try
        {
            using var document = JsonDocument.Parse(json);
            if (document.RootElement.TryGetProperty("public", out var property) &&
                (property.ValueKind == JsonValueKind.True || property.ValueKind == JsonValueKind.False))
            {
                return property.GetBoolean();
            }
        }
        catch (JsonException)
        {
            return null;
        }

        return null;
    }

    private static string ObjectPath(string category, string extension, string? namePrefix = null)
    {
        var timestamp = DateTime.UtcNow;
        var prefix = string.IsNullOrWhiteSpace(namePrefix) ? null : $"{Slug(namePrefix)}-";
        var fileName = $"{prefix}{timestamp:yyyyMMddHHmmssfff}-{Guid.NewGuid():N}{extension}";
        return $"{SafeCategory(category)}/{timestamp:yyyy/MM}/{fileName}";
    }

    private static string SafeCategory(string category)
    {
        return category switch
        {
            "profile-images" => category,
            "shop-items" => category,
            "chests" => category,
            _ => throw new ArgumentException("Ungueltige Upload-Kategorie.", nameof(category))
        };
    }

    private static string NormalizeExtension(string? extension, string? contentType)
    {
        if (string.IsNullOrWhiteSpace(extension))
        {
            extension = ExtensionForContentType(contentType);
        }

        extension = extension.StartsWith('.') ? extension.ToLowerInvariant() : $".{extension.ToLowerInvariant()}";
        var allowedExtensions = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            ".png",
            ".jpg",
            ".jpeg",
            ".webp",
            ".gif",
            ".heic",
            ".heif"
        };

        if (!allowedExtensions.Contains(extension))
        {
            throw new ArgumentException("Nur Bilddateien sind erlaubt.");
        }

        return extension;
    }

    private static string ExtensionForContentType(string? contentType)
    {
        return (contentType ?? string.Empty).Split(';', 2)[0].Trim().ToLowerInvariant() switch
        {
            "image/png" => ".png",
            "image/webp" => ".webp",
            "image/gif" => ".gif",
            "image/heic" => ".heic",
            "image/heif" => ".heif",
            _ => ".jpg"
        };
    }

    private static string ContentTypeFor(string? contentType, string extension)
    {
        var normalizedContentType = (contentType ?? string.Empty).Split(';', 2)[0].Trim();
        if (normalizedContentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase))
        {
            return normalizedContentType;
        }

        return extension.ToLowerInvariant() switch
        {
            ".png" => "image/png",
            ".webp" => "image/webp",
            ".gif" => "image/gif",
            ".heic" => "image/heic",
            ".heif" => "image/heif",
            _ => "image/jpeg"
        };
    }

    private static string EscapeObjectPath(string objectPath)
    {
        return string.Join('/', objectPath.Split('/').Select(Uri.EscapeDataString));
    }

    private static string BuildSupabasePublicBaseUrl(string? configuredPublicBaseUrl, string? supabaseUrl, string bucket)
    {
        if (!string.IsNullOrWhiteSpace(configuredPublicBaseUrl))
        {
            return configuredPublicBaseUrl.TrimEnd('/');
        }

        return string.IsNullOrWhiteSpace(supabaseUrl)
            ? string.Empty
            : $"{supabaseUrl.TrimEnd('/')}/storage/v1/object/public/{Uri.EscapeDataString(bucket)}";
    }

    private static bool IsSupabaseStorageUrl(Uri uri)
    {
        return uri.Host.EndsWith(".supabase.co", StringComparison.OrdinalIgnoreCase) &&
               uri.AbsolutePath.Contains("/storage/v1/object/public/", StringComparison.OrdinalIgnoreCase);
    }

    private static string StripQueryAndFragment(string value)
    {
        var queryIndex = value.IndexOfAny(new[] { '?', '#' });
        return queryIndex >= 0 ? value[..queryIndex] : value;
    }

    private static string? NormalizeBaseUrl(string? value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim().TrimEnd('/');
    }

    private static string? FirstNonEmpty(params string?[] values)
    {
        return values.FirstOrDefault(value => !string.IsNullOrWhiteSpace(value))?.Trim();
    }

    private static bool UsesLegacyJwtKey(string? apiKey)
    {
        return !string.IsNullOrWhiteSpace(apiKey) &&
               !apiKey.StartsWith("sb_secret_", StringComparison.OrdinalIgnoreCase) &&
               !apiKey.StartsWith("sb_publishable_", StringComparison.OrdinalIgnoreCase);
    }

    private static string Slug(string value)
    {
        var chars = value
            .Select(ch => char.IsLetterOrDigit(ch) ? char.ToLowerInvariant(ch) : '-')
            .ToArray();
        var slug = new string(chars).Trim('-');
        return string.IsNullOrWhiteSpace(slug) ? "image" : slug;
    }

    private enum StorageProvider
    {
        None,
        Supabase,
        Cloudinary
    }
}
