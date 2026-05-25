using System.Security.Cryptography;
using System.Text;

namespace Sybau_Backend._Services;

public static class MediaUrlVersion
{
    public static string Append(string url, string? versionSource)
    {
        if (string.IsNullOrWhiteSpace(versionSource)) return url;

        var separator = url.Contains('?', StringComparison.Ordinal) ? '&' : '?';
        return $"{url}{separator}v={ShortHash(versionSource.Trim())}";
    }

    private static string ShortHash(string value)
    {
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(value));
        return Convert.ToHexString(hash)[..12].ToLowerInvariant();
    }
}
