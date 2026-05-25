namespace Sybau_Backend._Services;

public static class ShopMediaUrl
{
    public static string? ForItem(int itemId, string? storedUrl) =>
        ToPublicUrl(storedUrl, $"/shop/items/{itemId}/image");

    public static string? ForChest(int chestId, string? storedUrl) =>
        ToPublicUrl(storedUrl, $"/shop/chests/{chestId}/image");

    private static string? ToPublicUrl(string? storedUrl, string imageEndpoint)
    {
        if (string.IsNullOrWhiteSpace(storedUrl)) return storedUrl;
        return storedUrl.StartsWith("data:image/", StringComparison.OrdinalIgnoreCase)
            ? MediaUrlVersion.Append(imageEndpoint, storedUrl)
            : storedUrl;
    }
}
