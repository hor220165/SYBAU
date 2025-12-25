using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Models;

public class Reward:BaseEntity<int>
{
#pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    protected Reward(){}
#pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.

    public Reward(RewardType type, int amount, User user)
    {
        if(amount <= 0) throw new ArgumentOutOfRangeException(nameof(amount));
        Type = type;
        Amount = amount;
        User = user;
    }
    
    public RewardType Type { get; set; }
    public int Amount { get; set; }
    public User User { get; set; }
}