namespace Sybau_Backend.Models;

public class UserChallenge: BaseEntity<int>
{
    #pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    protected UserChallenge() { }
    #pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.

    public UserChallenge(User user, Challenge challenge)
    {
        User = user;
        Challenge = challenge;
        UserId = user.Id;
        ChallengeId = challenge.Id;
        Progress = 0;
    }
    
    public int UserId { get; set; }
    public User User { get; set; }
    
    public int ChallengeId { get; set; }
    public Challenge Challenge { get; set; }
    public int Progress { get; set; }
    public bool Completed
    {
        get => Progress >= 100;
    }


    public DateTime? CompletedAt { get; set; }
    public DateTime? ClaimedAt { get; set; }
    
    public void Complete()
    {
        if (Completed) return; // schon abgeschlossen

        Progress = 100;
        CompletedAt = DateTime.UtcNow;
    }
}