namespace Sybau_Backend.DTOs;

public class RecentActivityDto
{
    public int Id { get; set; }
    public string Type { get; set; } = string.Empty;   // "workout", "quest", "achievement"
    public string Title { get; set; } = string.Empty;
    public int Xp { get; set; }
    public DateTime Timestamp { get; set; }
}
