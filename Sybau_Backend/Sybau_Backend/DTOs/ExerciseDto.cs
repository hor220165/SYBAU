using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.DTOs;

public class ExerciseDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public WorkoutCategory Category { get; set; }
    public ExerciseDifficulty Difficulty { get; set; }
    public double XpPerRep { get; set; }
    public int DailyLimit { get; set; }
    public int TodayCount { get; set; }

    // Nur bei Log-Response befüllt
    public int? XpEarned { get; set; }
    public int? BonusXp { get; set; }
    public int? BoostPercent { get; set; }
    public int? CoinsEarned { get; set; }
    public int? BonusCoins { get; set; }
    public int? CoinBoostPercent { get; set; }
}