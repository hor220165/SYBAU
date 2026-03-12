using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.DTOs;

public class ExerciseDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public WorkoutCategory Category { get; set; }
}