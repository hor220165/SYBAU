using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Models;

public class Achievement : BaseEntity<int>
{
    public string Key { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public AchievementType Type { get; set; }
    public int TargetValue { get; set; }
    public int XpReward { get; set; }

    public ICollection<UserAchievement> UserAchievements { get; set; } = new List<UserAchievement>();
}
