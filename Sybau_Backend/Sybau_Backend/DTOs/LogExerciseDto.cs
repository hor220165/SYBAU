namespace Sybau_Backend.DTOs;

public class LogExerciseDto
{
    public int ExerciseId { get; set; }
    public int Reps { get; set; }
    public int? ElapsedSeconds { get; set; }
    public DateOnly? Date { get; set; }
}
