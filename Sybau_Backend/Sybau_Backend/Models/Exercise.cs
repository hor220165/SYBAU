using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Models;

public class Exercise : BaseEntity<int>
{
#pragma warning disable CS8618
    protected Exercise() { }
#pragma warning restore CS8618

    public Exercise(string name, string? description, WorkoutCategory category, ExerciseDifficulty difficulty, double xpPerRep = 1, int dailyLimit = 200)
    {
        if (string.IsNullOrWhiteSpace(name)) throw new ArgumentNullException(nameof(name));
        if (xpPerRep < 0) throw new ArgumentOutOfRangeException(nameof(xpPerRep));
        if (dailyLimit < 1) throw new ArgumentOutOfRangeException(nameof(dailyLimit));

        Name = name;
        Description = description;
        Category = category;
        Difficulty = difficulty;
        XpPerRep = xpPerRep;
        DailyLimit = dailyLimit;
    }

    public string Name { get; set; }
    public string? Description { get; set; }
    public WorkoutCategory Category { get; set; }
    public ExerciseDifficulty Difficulty { get; set; }
    public double XpPerRep { get; set; } = 1;
    public int DailyLimit { get; set; } = 200;

    public ICollection<WorkoutExercise> WorkoutExercises { get; set; } = new List<WorkoutExercise>();
}