namespace Sybau_Backend.Models;

public class WorkoutExercise : BaseEntity<int>
{
#pragma warning disable CS8618
    protected WorkoutExercise() { }
#pragma warning restore CS8618

    public WorkoutExercise(Workout workout, Exercise exercise, int dailyLimit)
    {
        if (dailyLimit < 1) throw new ArgumentOutOfRangeException(nameof(dailyLimit));

        Workout = workout ?? throw new ArgumentNullException(nameof(workout));
        Exercise = exercise ?? throw new ArgumentNullException(nameof(exercise));
        DailyLimit = dailyLimit;
    }

    public int WorkoutId { get; set; }
    public Workout Workout { get; set; }

    public int ExerciseId { get; set; }
    public Exercise Exercise { get; set; }

    public int DailyLimit { get; set; }
}