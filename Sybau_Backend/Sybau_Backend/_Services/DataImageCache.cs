using Microsoft.Extensions.Caching.Memory;

namespace Sybau_Backend._Services;

public sealed class DataImageCache
{
    private const string DataPrefix = "data:";
    private const string Base64Marker = ";base64,";
    private readonly IMemoryCache _cache;

    public DataImageCache(IMemoryCache cache)
    {
        _cache = cache;
    }

    public static string ShopItemKey(int itemId) => $"shop:item:{itemId}";
    public static string ChestKey(int chestId) => $"shop:chest:{chestId}";
    public static string ProfileKey(int userId) => $"profile:{userId}";

    public bool TryGet(string key, out CachedDataImage image)
    {
        return _cache.TryGetValue(key, out image!);
    }

    public void Set(string key, CachedDataImage image)
    {
        _cache.Set(
            key,
            image,
            new MemoryCacheEntryOptions
            {
                Size = Math.Max(1, image.Bytes.Length),
                SlidingExpiration = TimeSpan.FromHours(6),
                AbsoluteExpirationRelativeToNow = TimeSpan.FromDays(1),
                Priority = CacheItemPriority.High
            });
    }

    public void Remove(string key)
    {
        _cache.Remove(key);
    }

    public static bool TryDecodeDataImage(string imageUrl, out CachedDataImage? image, out string? error)
    {
        image = null;
        error = null;

        var markerIndex = imageUrl.IndexOf(Base64Marker, StringComparison.OrdinalIgnoreCase);
        if (markerIndex <= DataPrefix.Length)
        {
            error = "Ungueltiges Bildformat.";
            return false;
        }

        var contentType = imageUrl[DataPrefix.Length..markerIndex];
        if (!contentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase))
        {
            error = "Ungueltiger Bildtyp.";
            return false;
        }

        var encodedData = imageUrl[(markerIndex + Base64Marker.Length)..];
        try
        {
            image = new CachedDataImage(Convert.FromBase64String(encodedData), contentType);
            return true;
        }
        catch (FormatException)
        {
            error = "Ungueltige Bilddaten.";
            return false;
        }
    }
}

public sealed record CachedDataImage(byte[] Bytes, string ContentType);
