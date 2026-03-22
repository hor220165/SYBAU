using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Models;

public class Exercise : BaseEntity<int>
{
#pragma warning disable CS8618
    protected Exercise() { }
#pragma warning restore CS8618

    public Exercise(string name, string? description, WorkoutCategory category, ExerciseDifficulty difficulty)
    {
        if (string.IsNullOrWhiteSpace(name)) throw new ArgumentNullException(nameof(name));

        Name = name;
        Description = description;
        Category = category;
        Difficulty = difficulty;
    }

    public string Name { get; set; }
    public string? Description { get; set; }
    public WorkoutCategory Category { get; set; }
    public ExerciseDifficulty Difficulty { get; set; }

    public ICollection<WorkoutExercise> WorkoutExercises { get; set; } = new List<WorkoutExercise>();
}