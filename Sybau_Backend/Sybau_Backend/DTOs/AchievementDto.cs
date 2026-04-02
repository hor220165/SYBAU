namespace Sybau_Backend.DTOs;

public class AchievementDto
{
    public int Id { get; set; }
    public string Key { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int XpReward { get; set; }
    public bool Unlocked { get; set; }
    public DateTime? UnlockedAt { get; set; }
}

public class ProfileStatsDto
{
    public int TotalWorkouts { get; set; }
    public double TrainingHours { get; set; }
    public int CaloriesBurned { get; set; }
    public int LongestStreak { get; set; }
    public int CurrentStreak { get; set; }
}
