namespace Sybau_Backend.Models;

public class UserExerciseLog : BaseEntity<int>
{
#pragma warning disable CS8618
    protected UserExerciseLog() { }
#pragma warning restore CS8618

    public UserExerciseLog(User user, Exercise exercise, int reps, int? elapsedSeconds = null)
    {
        if (reps < 1) throw new ArgumentOutOfRangeException(nameof(reps));
        User = user ?? throw new ArgumentNullException(nameof(user));
        Exercise = exercise ?? throw new ArgumentNullException(nameof(exercise));
        Reps = reps;
        ElapsedSeconds = elapsedSeconds;
        Date = DateOnly.FromDateTime(DateTime.UtcNow);
    }

    public int UserId { get; set; }
    public User User { get; set; }
    public int ExerciseId { get; set; }
    public Exercise Exercise { get; set; }
    public int Reps { get; set; }
    public int? ElapsedSeconds { get; set; }
    public DateOnly Date { get; set; }
}
