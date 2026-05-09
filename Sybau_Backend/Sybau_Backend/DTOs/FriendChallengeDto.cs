namespace Sybau_Backend.DTOs;

public class FriendChallengeDto
{
    public int Id { get; set; }
    public string Title { get; set; } = null!;
    public string? Description { get; set; }
    public int XpReward { get; set; }
    public int CoinReward { get; set; }
    public string Status { get; set; } = null!;
    public int GoalAmount { get; set; }
    public string GoalUnit { get; set; } = "reps";
    public DateTime ExpiresAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? CompletedAt { get; set; }

    // Challenger-Info
    public int ChallengerId { get; set; }
    public string ChallengerUserName { get; set; } = null!;
    public int ChallengerProgress { get; set; }

    // Opponent-Info
    public int OpponentId { get; set; }
    public string OpponentUserName { get; set; } = null!;
    public int OpponentProgress { get; set; }

    // Gewinner
    public int? WinnerId { get; set; }
    public string? WinnerUserName { get; set; }
}

public class CreateFriendChallengeDto
{
    public int OpponentId { get; set; }
    public string Title { get; set; } = null!;
    public string? Description { get; set; }
    public int GoalAmount { get; set; } = 100;
    public string GoalUnit { get; set; } = "reps";
    public string? DistanceUnit { get; set; }
    public int DurationHours { get; set; } = 24;
}

public class UpdateFriendChallengeProgressDto
{
    public int Amount { get; set; }
}
