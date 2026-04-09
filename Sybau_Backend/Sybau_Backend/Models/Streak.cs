using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Models;

public class Streak: BaseEntity<int>
{
    #pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    protected Streak() { }
    #pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.

    public Streak(User user, StreakType type)
    {
        User = user;
        UserId = user.Id;
        Type = type;
        CurrentStreak = 0;
        LongestStreak = 0;
        LastActivityDate = DateTime.UtcNow;
    }

    public int UserId { get; set; }
    public User User { get; set; }
    
    public StreakType Type { get; set; }
    public int CurrentStreak { get; set; }
    public int LongestStreak { get; set; }
    public DateTime LastActivityDate { get; set; }
    public new DateTime UpdatedAt { get; set; }

    public void Increment()
    {
        CurrentStreak++;
        if (CurrentStreak > LongestStreak)
        {
            LongestStreak = CurrentStreak;
        }
        LastActivityDate = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
    }

    public void Reset()
    {
        CurrentStreak = 0;
        LastActivityDate = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
    }
}

public enum StreakType
{
    Workout,
    Challenge,
    Login
}