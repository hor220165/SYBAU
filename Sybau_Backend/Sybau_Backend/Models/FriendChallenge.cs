namespace Sybau_Backend.Models;

public enum FriendChallengeStatus
{
    Pending,
    Accepted,
    Completed,
    Declined,
    Expired
}

public class FriendChallenge : BaseEntity<int>
{
    protected FriendChallenge() { }

    public FriendChallenge(User challenger, User opponent, string title, string? description,
        int xpReward, int coinReward, int goalAmount, DateTime expiresAt)
    {
        Challenger = challenger ?? throw new ArgumentNullException(nameof(challenger));
        Opponent = opponent ?? throw new ArgumentNullException(nameof(opponent));

        if (string.IsNullOrWhiteSpace(title)) throw new ArgumentNullException(nameof(title));
        if (xpReward < 0) throw new ArgumentOutOfRangeException(nameof(xpReward));
        if (coinReward < 0) throw new ArgumentOutOfRangeException(nameof(coinReward));
        if (goalAmount < 1) throw new ArgumentOutOfRangeException(nameof(goalAmount));

        Title = title;
        Description = description;
        XpReward = xpReward;
        CoinReward = coinReward;
        GoalAmount = goalAmount;
        ExpiresAt = expiresAt;
        Status = FriendChallengeStatus.Pending;
    }

    public int ChallengerId { get; set; }
    public User Challenger { get; set; } = null!;

    public int OpponentId { get; set; }
    public User Opponent { get; set; } = null!;

    public string Title { get; set; } = null!;
    public string? Description { get; set; }
    public int XpReward { get; set; }
    public int CoinReward { get; set; }
    public FriendChallengeStatus Status { get; set; }
    public DateTime ExpiresAt { get; set; }

    // Konkretes Ziel (z.B. 100 Reps)
    public int GoalAmount { get; set; }

    // Wer hat gewonnen?
    public int? WinnerId { get; set; }
    public User? Winner { get; set; }

    // Fortschritt beider Spieler
    public int ChallengerProgress { get; set; }
    public int OpponentProgress { get; set; }

    public DateTime? CompletedAt { get; set; }
}
