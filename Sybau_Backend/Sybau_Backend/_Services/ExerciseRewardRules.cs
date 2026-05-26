using Sybau_Backend.Models.Enums;

namespace Sybau_Backend._Services;

public static class ExerciseRewardRules
{
    public static double XpPerUnit(ExerciseDifficulty difficulty) => difficulty switch
    {
        ExerciseDifficulty.Easy => 1,
        ExerciseDifficulty.Medium => 2,
        ExerciseDifficulty.Hard => 5,
        _ => 1
    };

    public static int CoinRewardAmount(ExerciseDifficulty difficulty) => difficulty switch
    {
        ExerciseDifficulty.Easy => 1,
        ExerciseDifficulty.Medium => 2,
        ExerciseDifficulty.Hard => 5,
        _ => 1
    };

    public static int CoinInterval(ExerciseDifficulty difficulty, string? rawUnit) => 1;

    public static int CoinsEarned(ExerciseDifficulty difficulty, string? rawUnit, int previousTotal, int loggedAmount)
    {
        if (loggedAmount <= 0) return 0;

        var interval = CoinInterval(difficulty, rawUnit);
        var previousCoins = Math.Max(0, previousTotal) / interval;
        var newCoins = (Math.Max(0, previousTotal) + loggedAmount) / interval;
        return Math.Max(0, newCoins - previousCoins) * CoinRewardAmount(difficulty);
    }

    public static string CoinUnitLabel(string? rawUnit)
    {
        return NormalizeUnit(rawUnit) switch
        {
            "Time" => "Sek",
            "Distance" => "m",
            _ => "Reps"
        };
    }

    public static string NormalizeUnit(string? rawUnit)
    {
        var value = (rawUnit ?? string.Empty).Trim().ToLowerInvariant();
        return value switch
        {
            "1" or "time" => "Time",
            "2" or "distance" => "Distance",
            _ => "Reps"
        };
    }
}
