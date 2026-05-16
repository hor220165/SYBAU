namespace Sybau_Backend.DTOs;

public class UserDto
{
    public int Id { get; set; }
    public string UserName { get; set; }
    public string Email { get; set; }
    public string? ProfileImageUrl { get; set; }
    public int Coins { get; set; }
    public int TotalXp { get; set; }
    public AvatarDto Avatar { get; set; }
    public bool IsAdmin { get; set; }
    public bool IsProfilePrivate { get; set; }
}

public class PublicUserProfileDto
{
    public int Id { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
    public bool IsPrivate { get; set; }
    public AvatarDto Avatar { get; set; } = new();
    public int TotalXp { get; set; }
    public ProfileStatsDto Stats { get; set; } = new();
    public List<AchievementDto> Achievements { get; set; } = new();
    public List<WeeklyActivityDto> WeeklyActivity { get; set; } = new();
    public List<int> ActivityYears { get; set; } = new();
    public List<RecentActivityDto> RecentActivities { get; set; } = new();
}
