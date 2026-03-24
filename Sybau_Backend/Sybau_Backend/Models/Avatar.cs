using System.ComponentModel.DataAnnotations;
using System.Runtime.CompilerServices;
using Sybau_Backend._Services;
using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Models;

public class Avatar : BaseEntity<int>
{
#pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    protected Avatar()
    {
    }
#pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.

    public static Avatar CreateDefault()
    {
        return new Avatar
        {
            Level = 1,
            Experience = 0,
            Boost1 = null,
            Boost2 = null,
            Boost3 = null,
            Boost4 = null
        };
    }

    public int UserId { get; set; }
    public User User { get; set; }

    //Basis-Attribute
    public int Level { get; set; }

    public int Experience { get; set; }
    

    //Booster
    public string? Boost1 { get; set; }
    public string? Boost2 { get; set; }
    public string? Boost3 { get; set; }
    public string? Boost4 { get; set; }
}
