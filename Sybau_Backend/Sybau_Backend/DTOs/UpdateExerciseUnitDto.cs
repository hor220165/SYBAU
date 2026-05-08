namespace Sybau_Backend.DTOs;

public class UpdateExerciseUnitDto
{
    public string? Unit { get; set; }

    [System.Text.Json.Serialization.JsonExtensionData]
    public Dictionary<string, System.Text.Json.JsonElement>? ExtraJson { get; set; }

    public string? ResolveUnit()
    {
        if (ExtraJson != null)
        {
            foreach (var (key, value) in ExtraJson)
            {
                if (string.Equals(key, "unit", StringComparison.OrdinalIgnoreCase))
                {
                    return value.ValueKind switch
                    {
                        System.Text.Json.JsonValueKind.String => value.GetString(),
                        System.Text.Json.JsonValueKind.Number => value.GetRawText(),
                        _ => Unit
                    };
                }
            }
        }

        return Unit;
    }
}
