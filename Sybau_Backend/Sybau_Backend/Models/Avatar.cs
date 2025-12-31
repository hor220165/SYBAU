using System.ComponentModel.DataAnnotations;
using System.Runtime.CompilerServices;

namespace Sybau_Backend.Models;

public class Avatar:BaseEntity<int>
{
#pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    protected Avatar() { }
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
    public string? Boost1 { get; private set; }
    public string? Boost2 { get; private set; }
    public string? Boost3 { get; private set; }
    public string? Boost4 { get; private set; }
    
    public void AddExperience(int xp)
    {
        if (xp <= 0) return;

        Experience += xp;

        // Einfaches Level-Up: XP für nächstes Level steigt linear
        while (Experience >= XpForNextLevel())
        {
            Experience -= XpForNextLevel();
            Level++;
        }

        UpdatedAt = DateTime.UtcNow;
    }

// Berechnung XP für nächstes Level (anpassbar)
    private int XpForNextLevel()
    {
        return 100 + (Level - 1) * 50;
    }

}