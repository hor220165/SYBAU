using Sybau_Backend.Data;
using Sybau_Backend.Models;

namespace Sybau_Backend._Services;

public class AvatarService
{
    private readonly FitnessDbContext _context;

    public AvatarService(FitnessDbContext context)
    {
        _context = context;
    }
    
    // Berechnung XP für nächstes Level (anpassbar)
    public int XpForNextLevel(int lvl) =>  100 + (int)(lvl * lvl * 20);
    
    
    public async Task AddXpAsync(Avatar avatar, int xp)
    {
        if (xp <= 0) return;
        
        avatar.Experience += xp;
        
        while (avatar.Experience >= XpForNextLevel(avatar.Level))
        {
            avatar.Experience -= XpForNextLevel(avatar.Level);
            avatar.Level++;
        }
        
        _context.Avatars.Update(avatar);
        await _context.SaveChangesAsync();
    }
    
}