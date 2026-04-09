using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Models;

public class SyncLog: BaseEntity<int>
{
    #pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    protected SyncLog() { }
    #pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.

    public SyncLog(User user, FitnessProviderType providerType, SyncType syncType)
    {
        User = user;
        UserId = user.Id;
        ProviderType = providerType;
        SyncType = syncType;
        Status = SyncStatus.Pending;
        StartedAt = DateTime.UtcNow;
    }

    public int UserId { get; set; }
    public User User { get; set; }
    
    public FitnessProviderType ProviderType { get; set; }
    public SyncType SyncType { get; set; }
    public int RecordsSynced { get; set; }
    public SyncStatus Status { get; set; }
    public string? ErrorMessage { get; set; }
    public DateTime StartedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public new DateTime UpdatedAt { get; set; }
}

public enum SyncType
{
    Workouts,
    Steps,
    HeartRate,
    Weight,
    All
}

public enum SyncStatus
{
    Pending,
    InProgress,
    Completed,
    Failed
}