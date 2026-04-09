using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Models;

public class UserAchievement : BaseEntity<int>
{
    public UserAchievement() { }

    public UserAchievement(int userId, int achievementId)
    {
        UserId = userId;
        AchievementId = achievementId;
        UnlockedAt = DateTime.UtcNow;
    }

    public UserAchievement(User user, Achievement achievement)
    {
        User = user;
        UserId = user.Id;
        Achievement = achievement;
        AchievementId = achievement.Id;
        UnlockedAt = DateTime.UtcNow;
    }

    public int UserId { get; set; }
    public User User { get; set; } = null!;
    
    public int AchievementId { get; set; }
    public Achievement Achievement { get; set; } = null!;
    
    public DateTime UnlockedAt { get; set; }
}
