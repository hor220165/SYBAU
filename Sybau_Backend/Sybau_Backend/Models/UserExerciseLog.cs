namespace Sybau_Backend.Models;

public class UserExerciseLog : BaseEntity<int>
{
#pragma warning disable CS8618
    protected UserExerciseLog() { }
#pragma warning restore CS8618

    public UserExerciseLog(User user, Exercise exercise, int reps)
    {
        if (reps < 1) throw new ArgumentOutOfRangeException(nameof(reps));
        User = user ?? throw new ArgumentNullException(nameof(user));
        Exercise = exercise ?? throw new ArgumentNullException(nameof(exercise));
        Reps = reps;
        var cetZone = TimeZoneInfo.FindSystemTimeZoneById("Central European Standard Time");
        Date = DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, cetZone));
    }

    public int UserId { get; set; }
    public User User { get; set; }
    public int ExerciseId { get; set; }
    public Exercise Exercise { get; set; }
    public int Reps { get; set; }
    public DateOnly Date { get; set; }
}
