using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Models;

public class Achievement : BaseEntity<int>
{
    public Achievement() { }

    public Achievement(string name, string? description, string iconUrl, int xpReward, int coinReward, AchievementCriteriaType criteriaType, int criteriaValue)
    {
        Name = name;
        Description = description ?? string.Empty;
        IconUrl = iconUrl;
        XpReward = xpReward;
        CoinReward = coinReward;
        CriteriaType = criteriaType;
        CriteriaValue = criteriaValue;
        CreatedAt = DateTime.UtcNow;
    }

    public string Key { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string IconUrl { get; set; } = string.Empty;
    public AchievementType Type { get; set; }
    public AchievementCriteriaType CriteriaType { get; set; }
    public int TargetValue { get; set; }
    public int CriteriaValue { get; set; }
    public int XpReward { get; set; }
    public int CoinReward { get; set; }

    public new DateTime CreatedAt { get; set; }

    public ICollection<UserAchievement> UserAchievements { get; set; } = new List<UserAchievement>();
}

public enum AchievementCriteriaType
{
    WorkoutsCompleted,
    StreakDays,
    LevelReached,
    CoinsEarned,
    ChallengesCompleted,
    ItemsCollected
}
