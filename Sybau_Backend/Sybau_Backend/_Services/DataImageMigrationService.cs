using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Data;

namespace Sybau_Backend._Services;

public sealed class DataImageMigrationService
{
    private const string DataImageLikePattern = "data:image/%";
    private const string LegacyUploadsLikePattern = "/uploads/%";
    private const string LegacyUploadsPrefix = "/uploads/";

    private readonly FitnessDbContext _context;
    private readonly MediaStorageService _mediaStorage;
    private readonly IWebHostEnvironment _environment;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<DataImageMigrationService> _logger;

    public DataImageMigrationService(
        FitnessDbContext context,
        MediaStorageService mediaStorage,
        IWebHostEnvironment environment,
        IHttpClientFactory httpClientFactory,
        ILogger<DataImageMigrationService> logger)
    {
        _context = context;
        _mediaStorage = mediaStorage;
        _environment = environment;
        _httpClientFactory = httpClientFactory;
        _logger = logger;
    }

    public async Task MigrateAsync()
    {
        var migrated = 0;

        var items = await _context.Items
            .Where(item => item.ImageUrl != null && EF.Functions.Like(item.ImageUrl, DataImageLikePattern))
            .ToListAsync();
        foreach (var item in items)
        {
            if (await TryMoveDataImageAsync(item.ImageUrl, "shop-items", $"item-{item.Id}") is { } imageUrl)
            {
                item.ImageUrl = imageUrl;
                migrated++;
            }
        }

        var chests = await _context.Chests
            .Where(chest => EF.Functions.Like(chest.ImageUrl, DataImageLikePattern))
            .ToListAsync();
        foreach (var chest in chests)
        {
            if (await TryMoveDataImageAsync(chest.ImageUrl, "chests", $"chest-{chest.Id}") is { } imageUrl)
            {
                chest.ImageUrl = imageUrl;
                migrated++;
            }
        }

        var users = await _context.Users
            .Where(user => user.ProfileImageUrl != null && EF.Functions.Like(user.ProfileImageUrl, DataImageLikePattern))
            .ToListAsync();
        foreach (var user in users)
        {
            if (await TryMoveDataImageAsync(user.ProfileImageUrl, "profile-images", $"profile-{user.Id}") is { } imageUrl)
            {
                user.ProfileImageUrl = imageUrl;
                migrated++;
            }
        }

        var legacyItems = await _context.Items
            .Where(item => item.ImageUrl != null && EF.Functions.Like(item.ImageUrl, LegacyUploadsLikePattern))
            .ToListAsync();
        foreach (var item in legacyItems)
        {
            if (await TryMoveLegacyUploadAsync(item.ImageUrl, "shop-items", $"item-{item.Id}") is { } imageUrl)
            {
                item.ImageUrl = imageUrl;
                migrated++;
            }
        }

        var legacyChests = await _context.Chests
            .Where(chest => EF.Functions.Like(chest.ImageUrl, LegacyUploadsLikePattern))
            .ToListAsync();
        foreach (var chest in legacyChests)
        {
            if (await TryMoveLegacyUploadAsync(chest.ImageUrl, "chests", $"chest-{chest.Id}") is { } imageUrl)
            {
                chest.ImageUrl = imageUrl;
                migrated++;
            }
        }

        var legacyUsers = await _context.Users
            .Where(user => user.ProfileImageUrl != null && EF.Functions.Like(user.ProfileImageUrl, LegacyUploadsLikePattern))
            .ToListAsync();
        foreach (var user in legacyUsers)
        {
            if (await TryMoveLegacyUploadAsync(user.ProfileImageUrl, "profile-images", $"profile-{user.Id}") is { } imageUrl)
            {
                user.ProfileImageUrl = imageUrl;
                migrated++;
            }
        }

        var remoteItems = await _context.Items
            .Where(item => item.ImageUrl != null && EF.Functions.Like(item.ImageUrl, "http%"))
            .ToListAsync();
        foreach (var item in remoteItems)
        {
            if (await TryMoveRemoteImageAsync(item.ImageUrl, "shop-items", $"item-{item.Id}") is { } imageUrl)
            {
                item.ImageUrl = imageUrl;
                migrated++;
            }
        }

        var remoteChests = await _context.Chests
            .Where(chest => EF.Functions.Like(chest.ImageUrl, "http%"))
            .ToListAsync();
        foreach (var chest in remoteChests)
        {
            if (await TryMoveRemoteImageAsync(chest.ImageUrl, "chests", $"chest-{chest.Id}") is { } imageUrl)
            {
                chest.ImageUrl = imageUrl;
                migrated++;
            }
        }

        var remoteUsers = await _context.Users
            .Where(user => user.ProfileImageUrl != null && EF.Functions.Like(user.ProfileImageUrl, "http%"))
            .ToListAsync();
        foreach (var user in remoteUsers)
        {
            if (await TryMoveRemoteImageAsync(user.ProfileImageUrl, "profile-images", $"profile-{user.Id}") is { } imageUrl)
            {
                user.ProfileImageUrl = imageUrl;
                migrated++;
            }
        }

        if (migrated <= 0) return;

        await _context.SaveChangesAsync();
        _logger.LogInformation("Migrated {Count} database image values to configured media storage.", migrated);
    }

    private async Task<string?> TryMoveDataImageAsync(string? dataImageUrl, string category, string namePrefix)
    {
        if (string.IsNullOrWhiteSpace(dataImageUrl)) return null;
        if (!DataImageCache.TryDecodeDataImage(dataImageUrl, out var image, out var error) || image == null)
        {
            _logger.LogWarning("Could not migrate {Category} data image {NamePrefix}: {Error}", category, namePrefix, error);
            return null;
        }

        return await _mediaStorage.SaveDataImageAsync(image, category, namePrefix);
    }

    private async Task<string?> TryMoveLegacyUploadAsync(string? legacyImageUrl, string category, string namePrefix)
    {
        if (ResolveLegacyUploadPath(legacyImageUrl) is not { } path)
        {
            _logger.LogWarning(
                "Could not migrate legacy upload {Category} {NamePrefix}: file is missing for {ImageUrl}",
                category,
                namePrefix,
                legacyImageUrl);
            return null;
        }

        var bytes = await File.ReadAllBytesAsync(path);
        var extension = Path.GetExtension(path);
        return await _mediaStorage.SaveBytesAsync(
            bytes,
            category,
            namePrefix,
            ContentTypeForExtension(extension),
            extension);
    }

    private async Task<string?> TryMoveRemoteImageAsync(string? remoteImageUrl, string category, string namePrefix)
    {
        if (!_mediaStorage.ShouldMigrateRemoteUrl(remoteImageUrl) ||
            !Uri.TryCreate(remoteImageUrl, UriKind.Absolute, out var uri))
        {
            return null;
        }

        try
        {
            var httpClient = _httpClientFactory.CreateClient();
            using var response = await httpClient.GetAsync(uri, HttpCompletionOption.ResponseHeadersRead);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning(
                    "Could not migrate remote image {Category} {NamePrefix}: {StatusCode} from {ImageUrl}",
                    category,
                    namePrefix,
                    (int)response.StatusCode,
                    remoteImageUrl);
                return null;
            }

            var contentType = response.Content.Headers.ContentType?.MediaType;
            if (string.IsNullOrWhiteSpace(contentType) ||
                !contentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogWarning(
                    "Could not migrate remote image {Category} {NamePrefix}: invalid content type {ContentType}",
                    category,
                    namePrefix,
                    contentType);
                return null;
            }

            var bytes = await response.Content.ReadAsByteArrayAsync();
            if (bytes.Length > 10 * 1024 * 1024)
            {
                _logger.LogWarning(
                    "Could not migrate remote image {Category} {NamePrefix}: image is larger than 10 MB",
                    category,
                    namePrefix);
                return null;
            }

            return await _mediaStorage.SaveBytesAsync(
                bytes,
                category,
                namePrefix,
                contentType,
                ExtensionForContentType(contentType) ?? Path.GetExtension(uri.AbsolutePath));
        }
        catch (Exception ex)
        {
            _logger.LogWarning(
                ex,
                "Could not migrate remote image {Category} {NamePrefix} from {ImageUrl}",
                category,
                namePrefix,
                remoteImageUrl);
            return null;
        }
    }

    private string? ResolveLegacyUploadPath(string? legacyImageUrl)
    {
        if (string.IsNullOrWhiteSpace(legacyImageUrl) ||
            !legacyImageUrl.StartsWith(LegacyUploadsPrefix, StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        var pathOnly = legacyImageUrl.Split(new[] { '?', '#' }, 2)[0];
        var relativePath = Uri.UnescapeDataString(pathOnly[LegacyUploadsPrefix.Length..])
            .Replace('/', Path.DirectorySeparatorChar);
        var legacyUploadsRoot = Path.GetFullPath(Path.Combine(_environment.ContentRootPath, "wwwroot", "uploads"));
        var fullPath = Path.GetFullPath(Path.Combine(legacyUploadsRoot, relativePath));

        if (!fullPath.StartsWith($"{legacyUploadsRoot}{Path.DirectorySeparatorChar}", StringComparison.OrdinalIgnoreCase) ||
            !File.Exists(fullPath))
        {
            return null;
        }

        return fullPath;
    }

    private static string ContentTypeForExtension(string? extension)
    {
        return (extension ?? string.Empty).ToLowerInvariant() switch
        {
            ".png" => "image/png",
            ".webp" => "image/webp",
            ".gif" => "image/gif",
            ".heic" => "image/heic",
            ".heif" => "image/heif",
            _ => "image/jpeg"
        };
    }

    private static string? ExtensionForContentType(string? contentType)
    {
        return (contentType ?? string.Empty).Split(';', 2)[0].Trim().ToLowerInvariant() switch
        {
            "image/png" => ".png",
            "image/webp" => ".webp",
            "image/gif" => ".gif",
            "image/heic" => ".heic",
            "image/heif" => ".heif",
            "image/jpeg" => ".jpg",
            _ => null
        };
    }
}
