using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Models;

public class Workout : BaseEntity<int>
{
#pragma warning disable CS8618
    protected Workout() { }
#pragma warning restore CS8618

    public Workout(string name, string? description, WorkoutCategory category)
    {
        if (string.IsNullOrWhiteSpace(name)) throw new ArgumentNullException(nameof(name));

        Name = name;
        Description = description;
        Category = category;
    }

    public string Name { get; set; }
    public string? Description { get; set; }
    public WorkoutCategory Category { get; set; }

    public ICollection<WorkoutExercise> WorkoutExercises { get; set; } = new List<WorkoutExercise>();
}