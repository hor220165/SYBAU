namespace Sybau_Backend.Models;

public class UserAchievement : BaseEntity<int>
{
    public int UserId { get; set; }
    public User User { get; set; } = null!;
    public int AchievementId { get; set; }
    public Achievement Achievement { get; set; } = null!;
    public DateTime UnlockedAt { get; set; }

    public UserAchievement() { }

    public UserAchievement(int userId, int achievementId)
    {
        UserId = userId;
        AchievementId = achievementId;
        UnlockedAt = DateTime.UtcNow;
    }
}
