using System.Text.Json;
using System.Text.Json.Serialization;
using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.DTOs;

public class CreateExerciseDto
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public WorkoutCategory Category { get; set; }
    public ExerciseDifficulty Difficulty { get; set; }
    public string Unit { get; set; } = "Reps";
    public double XpPerRep { get; set; } = 1;
    public int DailyLimit { get; set; } = 200;

    [JsonExtensionData]
    public Dictionary<string, JsonElement>? ExtraJson { get; set; }

    public string ResolveUnit()
    {
        if (ExtraJson != null)
        {
            foreach (var (key, value) in ExtraJson)
            {
                if (string.Equals(key, "unit", StringComparison.OrdinalIgnoreCase))
                {
                    return JsonValueToString(value);
                }
            }
        }

        return Unit;
    }

    private static string JsonValueToString(JsonElement value)
    {
        return value.ValueKind switch
        {
            JsonValueKind.String => value.GetString() ?? "Reps",
            JsonValueKind.Number => value.GetRawText(),
            _ => "Reps"
        };
    }
}
