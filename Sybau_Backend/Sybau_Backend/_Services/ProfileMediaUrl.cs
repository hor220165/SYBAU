namespace Sybau_Backend._Services;

public static class ProfileMediaUrl
{
    public static string? ForUser(int userId, string? storedProfileImageUrl) =>
        HasUsableStoredImage(storedProfileImageUrl) ? $"/users/{userId}/profile/image" : null;

    public static string? ForUser(int userId, bool hasProfileImage) =>
        hasProfileImage ? $"/users/{userId}/profile/image" : null;

    public static bool HasUsableStoredImage(string? storedProfileImageUrl)
    {
        if (string.IsNullOrWhiteSpace(storedProfileImageUrl)) return false;

        var value = storedProfileImageUrl.Trim();
        if (value.StartsWith("data:", StringComparison.OrdinalIgnoreCase)) return true;
        if (IsLegacyUploadPath(value)) return false;

        return Uri.TryCreate(value, UriKind.Absolute, out var uri) &&
               (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps) &&
               !IsLegacyUploadPath(uri.AbsolutePath);
    }

    private static bool IsLegacyUploadPath(string value) =>
        value.StartsWith("/uploads/", StringComparison.OrdinalIgnoreCase) ||
        value.StartsWith("uploads/", StringComparison.OrdinalIgnoreCase);
}
