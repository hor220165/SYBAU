using Microsoft.AspNetCore.Http;

namespace Sybau_Backend._Services;

public sealed class MediaStorageService
{
    public const string UploadsRequestPath = "/uploads";

    private readonly IWebHostEnvironment _environment;
    private readonly IConfiguration _configuration;

    public MediaStorageService(IWebHostEnvironment environment, IConfiguration configuration)
    {
        _environment = environment;
        _configuration = configuration;
        UploadsRoot = ResolveUploadsRoot();
    }

    public string UploadsRoot { get; }

    public void EnsureDirectories()
    {
        Directory.CreateDirectory(UploadsRoot);
        Directory.CreateDirectory(CategoryPath("profile-images"));
        Directory.CreateDirectory(CategoryPath("shop-items"));
        Directory.CreateDirectory(CategoryPath("chests"));
    }

    public async Task<string> SaveFormFileAsync(IFormFile image, string category, string? extension = null)
    {
        var normalizedExtension = NormalizeExtension(extension ?? Path.GetExtension(image.FileName), image.ContentType);
        var fileName = $"{DateTime.UtcNow:yyyyMMddHHmmssfff}-{Guid.NewGuid():N}{normalizedExtension}";
        var fullPath = FullPathFor(category, fileName);

        await using var stream = File.Create(fullPath);
        await image.CopyToAsync(stream);

        return PublicUrl(category, fileName);
    }

    public async Task<string> SaveDataImageAsync(CachedDataImage image, string category, string namePrefix)
    {
        var extension = ExtensionForContentType(image.ContentType);
        var safePrefix = Slug(namePrefix);
        var fileName = $"{safePrefix}-{Guid.NewGuid():N}{extension}";
        var fullPath = FullPathFor(category, fileName);

        await File.WriteAllBytesAsync(fullPath, image.Bytes);
        return PublicUrl(category, fileName);
    }

    public void DeletePublicUrl(string? imageUrl)
    {
        if (string.IsNullOrWhiteSpace(imageUrl) ||
            !imageUrl.StartsWith($"{UploadsRequestPath}/", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        var relativePath = Uri.UnescapeDataString(imageUrl[UploadsRequestPath.Length..].TrimStart('/'))
            .Replace('/', Path.DirectorySeparatorChar);
        var fullPath = Path.GetFullPath(Path.Combine(UploadsRoot, relativePath));
        var uploadsRoot = Path.GetFullPath(UploadsRoot);

        if (!fullPath.StartsWith(uploadsRoot, StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        if (File.Exists(fullPath))
        {
            File.Delete(fullPath);
        }
    }

    private string ResolveUploadsRoot()
    {
        var configuredPath =
            Environment.GetEnvironmentVariable("MEDIA_UPLOADS_PATH") ??
            _configuration["MediaStorage:UploadsPath"];

        if (string.IsNullOrWhiteSpace(configuredPath))
        {
            return Path.GetFullPath(Path.Combine(_environment.ContentRootPath, "wwwroot", "uploads"));
        }

        return Path.GetFullPath(Path.IsPathRooted(configuredPath)
            ? configuredPath
            : Path.Combine(_environment.ContentRootPath, configuredPath));
    }

    private string CategoryPath(string category)
    {
        return Path.Combine(UploadsRoot, SafeCategory(category));
    }

    private string FullPathFor(string category, string fileName)
    {
        var directory = CategoryPath(category);
        Directory.CreateDirectory(directory);
        return Path.Combine(directory, fileName);
    }

    private static string PublicUrl(string category, string fileName)
    {
        return $"{UploadsRequestPath}/{SafeCategory(category)}/{Uri.EscapeDataString(fileName)}";
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

    private static string Slug(string value)
    {
        var chars = value
            .Select(ch => char.IsLetterOrDigit(ch) ? char.ToLowerInvariant(ch) : '-')
            .ToArray();
        var slug = new string(chars).Trim('-');
        return string.IsNullOrWhiteSpace(slug) ? "image" : slug;
    }
}
