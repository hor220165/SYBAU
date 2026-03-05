using System.ComponentModel.DataAnnotations;
using System.Reflection.Metadata;

namespace Sybau_Backend.Models;

public class Challenge : BaseEntity<int>
{
#pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    protected Challenge() { }
#pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.

    public Challenge(string name, string description, int xpReward, int coinReward ,int requiredLevel)
    {
        if(string.IsNullOrWhiteSpace(name)) throw new ArgumentNullException(nameof(name));
        if(xpReward < 1) throw new ArgumentOutOfRangeException(nameof(xpReward));
        if(requiredLevel < 1) throw new ArgumentOutOfRangeException(nameof(requiredLevel));
        if(coinReward < 1) throw new ArgumentOutOfRangeException(nameof(coinReward));
        Name = name;
        Description = description;
        XpReward = xpReward;
        RequiredLevel = requiredLevel;
        CoinReward = coinReward;
    }
    

    public string Name { get; set; }
    public string? Description { get; set; }
    public int XpReward { get; set; }
    public int CoinReward { get; set; }
    public int RequiredLevel { get; set; }
    
    public ICollection<UserChallenge> UserChallenges { get; set; } = new List<UserChallenge>();
}