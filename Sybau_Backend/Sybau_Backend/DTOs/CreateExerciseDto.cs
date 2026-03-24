using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.DTOs;

public class CreateExerciseDto
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public WorkoutCategory Category { get; set; }
    public ExerciseDifficulty Difficulty { get; set; }
    public double XpPerRep { get; set; } = 1;
    public int DailyLimit { get; set; } = 200;
}