using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Models;

public class LeaderboardSnapshot: BaseEntity<int>
{
    #pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    protected LeaderboardSnapshot() { }
    #pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.

    public LeaderboardSnapshot(User user, int xp, int rank, LeaderboardType type)
    {
        User = user;
        UserId = user.Id;
        Xp = xp;
        Rank = rank;
        Type = type;
        SnapshotDate = DateTime.UtcNow;
    }

    public int UserId { get; set; }
    public User User { get; set; }
    
    public int Xp { get; set; }
    public int Rank { get; set; }
    public LeaderboardType Type { get; set; }
    public DateTime SnapshotDate { get; set; }
}

public enum LeaderboardType
{
    Daily,
    Weekly,
    Monthly,
    Overall
}