using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.DTOs;

public class CreateWorkoutDto
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public WorkoutCategory Category { get; set; }
    public List<WorkoutExerciseCreateDto> Exercises { get; set; } = new();
}