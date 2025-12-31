using System.ComponentModel.DataAnnotations;
using System.Reflection.Metadata;

namespace Sybau_Backend.Models;

public class Challenge : BaseEntity<int>
{
#pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    protected Challenge() { }
#pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.

    public Challenge(string name, string description, int xpReward)
    {
        if(string.IsNullOrWhiteSpace(name)) throw new ArgumentNullException(nameof(name));
        if(string.IsNullOrWhiteSpace(description)) throw new ArgumentNullException(nameof(description));
        if(xpReward < 1) throw new ArgumentOutOfRangeException(nameof(xpReward));
        Name = name;
        Description = description;
        XpReward = xpReward;
    }
    

    public string Name { get; set; }
    public string Description { get; set; }
    public int XpReward { get; set; }
    
    public ICollection<UserChallenge> UserChallenges { get; set; } = new List<UserChallenge>();
}