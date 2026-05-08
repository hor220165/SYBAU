using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.DTOs;

public class WorkoutExerciseDto
{
    public int ExerciseId { get; set; }
    public string ExerciseName { get; set; } = string.Empty;
    public WorkoutCategory ExerciseCategory { get; set; }
    public ExerciseDifficulty Difficulty { get; set; }
    public string Unit { get; set; } = "Reps";
    public int DailyLimit { get; set; }
}
