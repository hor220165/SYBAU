using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Http;

namespace Sybau_Backend._Services;

public sealed class MediaStorageService
{
    private const string DefaultBucket = "sybau-images";
    private const string CacheControl = "public, max-age=31536000, immutable";
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    private readonly HttpClient _httpClient;
    private readonly ILogger<MediaStorageService> _logger;
    private readonly string? _supabaseUrl;
    private readonly string? _serviceRoleKey;
    private readonly string _bucket;
    private readonly string _publicBaseUrl;

    public MediaStorageService(
        HttpClient httpClient,
        IConfiguration configuration,
        ILogger<MediaStorageService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
        _supabaseUrl = NormalizeBaseUrl(FirstNonEmpty(
            configuration["MediaStorage:SupabaseUrl"],
            configuration["Supabase:Url"],
            Environment.GetEnvironmentVariable("SUPABASE_URL")));
        _serviceRoleKey = FirstNonEmpty(
            configuration["MediaStorage:ServiceRoleKey"],
            configuration["Supabase:ServiceRoleKey"],
            Environment.GetEnvironmentVariable("SUPABASE_SERVICE_ROLE_KEY"));
        _bucket = FirstNonEmpty(
            configuration["MediaStorage:Bucket"],
            Environment.GetEnvironmentVariable("SUPABASE_STORAGE_BUCKET")) ?? DefaultBucket;
        _publicBaseUrl = BuildPublicBaseUrl(
            FirstNonEmpty(
                configuration["MediaStorage:PublicBaseUrl"],
                Environment.GetEnvironmentVariable("SUPABASE_STORAGE_PUBLIC_BASE_URL")),
            _supabaseUrl,
            _bucket);
    }

    public bool IsConfigured =>
        !string.IsNullOrWhiteSpace(_supabaseUrl) &&
        !string.IsNullOrWhiteSpace(_serviceRoleKey);

    public async Task EnsureReadyAsync(CancellationToken cancellationToken = default)
    {
        if (!IsConfigured)
        {
            _logger.LogWarning(
                "Supabase Storage is not configured. Image uploads and data-image migration are disabled.");
            return;
        }

        using var request = CreateRequest(HttpMethod.Get, StorageUri($"bucket/{Uri.EscapeDataString(_bucket)}"));
        using var response = await _httpClient.SendAsync(request, cancellationToken);

        if (response.StatusCode == HttpStatusCode.NotFound)
        {
            await CreateBucketAsync(cancellationToken);
            return;
        }

        if (!response.IsSuccessStatusCode)
        {
            throw await StorageExceptionAsync("Supabase Storage bucket check", response);
        }

        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (BucketIsPublic(body) == false)
        {
            await MakeBucketPublicAsync(cancellationToken);
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
        var objectPath = ObjectPath(category, normalizedExtension);
        await using var stream = image.OpenReadStream();
        using var content = new StreamContent(stream);

        await UploadAsync(objectPath, content, ContentTypeFor(image.ContentType, normalizedExtension), cancellationToken);
        return PublicUrl(objectPath);
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
        var objectPath = ObjectPath(category, normalizedExtension, namePrefix);
        using var content = new ByteArrayContent(bytes);

        await UploadAsync(
            objectPath,
            content,
            ContentTypeFor(contentType, normalizedExtension),
            cancellationToken);
        return PublicUrl(objectPath);
    }

    public async Task DeletePublicUrlAsync(string? imageUrl, CancellationToken cancellationToken = default)
    {
        if (!IsConfigured || TryGetObjectPath(imageUrl) is not { } objectPath)
        {
            return;
        }

        using var request = CreateRequest(HttpMethod.Delete, StorageUri($"object/{Uri.EscapeDataString(_bucket)}"));
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

    private async Task CreateBucketAsync(CancellationToken cancellationToken)
    {
        using var request = CreateRequest(HttpMethod.Post, StorageUri("bucket"));
        request.Content = JsonContent(new
        {
            id = _bucket,
            name = _bucket,
            @public = true
        });

        using var response = await _httpClient.SendAsync(request, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw await StorageExceptionAsync("Supabase Storage bucket creation", response);
        }

        _logger.LogInformation("Created public Supabase Storage bucket {Bucket}.", _bucket);
    }

    private async Task MakeBucketPublicAsync(CancellationToken cancellationToken)
    {
        using var request = CreateRequest(HttpMethod.Put, StorageUri($"bucket/{Uri.EscapeDataString(_bucket)}"));
        request.Content = JsonContent(new { @public = true });

        using var response = await _httpClient.SendAsync(request, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw await StorageExceptionAsync("Supabase Storage bucket public update", response);
        }

        _logger.LogInformation("Updated Supabase Storage bucket {Bucket} to public.", _bucket);
    }

    private async Task UploadAsync(
        string objectPath,
        HttpContent content,
        string contentType,
        CancellationToken cancellationToken)
    {
        using var request = CreateRequest(
            HttpMethod.Post,
            StorageUri($"object/{Uri.EscapeDataString(_bucket)}/{EscapeObjectPath(objectPath)}"));
        request.Headers.TryAddWithoutValidation("x-upsert", "false");
        request.Headers.TryAddWithoutValidation("cache-control", CacheControl);
        content.Headers.ContentType = MediaTypeHeaderValue.Parse(contentType);
        request.Content = content;

        using var response = await _httpClient.SendAsync(request, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw await StorageExceptionAsync("Supabase Storage upload", response);
        }
    }

    private HttpRequestMessage CreateRequest(HttpMethod method, Uri uri)
    {
        RequireConfiguration();

        var request = new HttpRequestMessage(method, uri);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _serviceRoleKey);
        request.Headers.TryAddWithoutValidation("apikey", _serviceRoleKey);
        return request;
    }

    private Uri StorageUri(string relativePath)
    {
        return new Uri($"{_supabaseUrl}/storage/v1/{relativePath.TrimStart('/')}");
    }

    private string PublicUrl(string objectPath)
    {
        return $"{_publicBaseUrl}/{EscapeObjectPath(objectPath)}";
    }

    private string? TryGetObjectPath(string? imageUrl)
    {
        if (string.IsNullOrWhiteSpace(imageUrl) || string.IsNullOrWhiteSpace(_publicBaseUrl))
        {
            return null;
        }

        var publicPrefix = $"{_publicBaseUrl.TrimEnd('/')}/";
        if (!imageUrl.StartsWith(publicPrefix, StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        var pathAndQuery = imageUrl[publicPrefix.Length..];
        var queryIndex = pathAndQuery.IndexOfAny(new[] { '?', '#' });
        var encodedPath = queryIndex >= 0 ? pathAndQuery[..queryIndex] : pathAndQuery;
        if (string.IsNullOrWhiteSpace(encodedPath))
        {
            return null;
        }

        return string.Join(
            '/',
            encodedPath.Split('/', StringSplitOptions.RemoveEmptyEntries).Select(Uri.UnescapeDataString));
    }

    private void RequireConfiguration()
    {
        if (IsConfigured) return;

        throw new InvalidOperationException(
            "MediaStorage ist nicht konfiguriert. Setze MediaStorage__SupabaseUrl und MediaStorage__ServiceRoleKey.");
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

    private static string BuildPublicBaseUrl(string? configuredPublicBaseUrl, string? supabaseUrl, string bucket)
    {
        if (!string.IsNullOrWhiteSpace(configuredPublicBaseUrl))
        {
            return configuredPublicBaseUrl.TrimEnd('/');
        }

        return string.IsNullOrWhiteSpace(supabaseUrl)
            ? string.Empty
            : $"{supabaseUrl.TrimEnd('/')}/storage/v1/object/public/{Uri.EscapeDataString(bucket)}";
    }

    private static string? NormalizeBaseUrl(string? value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim().TrimEnd('/');
    }

    private static string? FirstNonEmpty(params string?[] values)
    {
        return values.FirstOrDefault(value => !string.IsNullOrWhiteSpace(value))?.Trim();
    }

    private static string Slug(string value)
    {
        var chars = value
            .Select(ch => char.IsLetterOrDigit(ch) ? char.ToLowerInvariant(ch) : '-')
            .ToArray();
        var slug = new string(chars).Trim('-');
        return string.IsNullOrWhiteSpace(slug) ? "image" : slug;
    }
}
