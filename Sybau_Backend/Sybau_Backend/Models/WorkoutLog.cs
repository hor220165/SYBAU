using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Models;

public class WorkoutLog: BaseEntity<int>
{
    #pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    protected WorkoutLog() { }
    #pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.

    public WorkoutLog(User user, Workout workout)
    {
        User = user;
        UserId = user.Id;
        Workout = workout;
        WorkoutId = workout.Id;
        CompletedAt = DateTime.UtcNow;
    }

    public int UserId { get; set; }
    public User User { get; set; }
    
    public int WorkoutId { get; set; }
    public Workout Workout { get; set; }
    
    public DateTime CompletedAt { get; set; }
    
    public int XpEarned { get; set; }
    public int CoinsEarned { get; set; }
    public int PerformanceScore { get; set; } // 0-100 based on form, completion time, etc.
}