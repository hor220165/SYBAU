namespace Sybau_Backend._Services;

public static class ProfileMediaUrl
{
    public static string? ForUser(int userId, bool hasProfileImage) =>
        hasProfileImage ? $"/users/{userId}/profile/image" : null;
}
