namespace Sybau_Backend.Models;

public class UserQuest : BaseEntity<int>
{
#pragma warning disable CS8618
    protected UserQuest() { }
#pragma warning restore CS8618

    public UserQuest(int userId, int questId, DateTime periodStart)
    {
        UserId = userId;
        QuestId = questId;
        Progress = 0;
        IsCompleted = false;
        IsRewardClaimed = false;
        PeriodStart = periodStart;
    }

    public int UserId { get; set; }
    public User User { get; set; }

    public int QuestId { get; set; }
    public Quest Quest { get; set; }

    public int Progress { get; set; }
    public bool IsCompleted { get; set; }
    public bool IsRewardClaimed { get; set; }
    public DateTime PeriodStart { get; set; }
    public DateTime? CompletedAt { get; set; }
}
