using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Models;

public class ActivityLog : BaseEntity<int>
{
#pragma warning disable CS8618
    protected ActivityLog() { }
#pragma warning restore CS8618

    public ActivityLog(int userId, ActivityType type, double value)
    {
        if (value <= 0) throw new ArgumentOutOfRangeException(nameof(value));
        UserId = userId;
        Type = type;
        Value = value;
        Date = DateOnly.FromDateTime(DateTime.UtcNow);
    }

    public int UserId { get; set; }
    public User User { get; set; }
    public ActivityType Type { get; set; }
    public double Value { get; set; }
    public DateOnly Date { get; set; }
}
