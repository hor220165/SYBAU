using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Models;

public class Notification: BaseEntity<int>
{
    #pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    protected Notification() { }
    #pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.

    public Notification(User user, string title, string message, NotificationType type)
    {
        if (string.IsNullOrWhiteSpace(title)) throw new ArgumentNullException(nameof(title));
        if (string.IsNullOrWhiteSpace(message)) throw new ArgumentNullException(nameof(message));

        User = user;
        UserId = user.Id;
        Title = title;
        Message = message;
        Type = type;
        IsRead = false;
        CreatedAt = DateTime.UtcNow;
    }

    public int UserId { get; set; }
    public User User { get; set; }
    
    public string Title { get; set; }
    public string Message { get; set; }
    public NotificationType Type { get; set; }
    public bool IsRead { get; set; }
    public new DateTime CreatedAt { get; set; }
}

public enum NotificationType
{
    AchievementEarned,
    ChallengeCompleted,
    StreakMilestone,
    NewWorkoutAvailable,
    ShopPurchase,
    SystemUpdate,
    FriendRequest,
    LeaderboardUpdate
}