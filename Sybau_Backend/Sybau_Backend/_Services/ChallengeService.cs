using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Data;
using Sybau_Backend.DTOs;
using Sybau_Backend.Models;

namespace Sybau_Backend._Services;

public class ChallengeService
{
    private readonly FitnessDbContext _context;

    public ChallengeService(FitnessDbContext context)
    {
        _context = context;
    }
    //Challenge erstellen
    public async Task<Challenge> CreateChallenge(ChallengeDto dto)
    {
        if(dto == null) throw new ArgumentNullException(nameof(dto));

        // DTO in ein Challenge-Objekt umwandeln
        var challenge = new Challenge(dto.Name, dto.Description, dto.XpReward,dto.RequiredLevel);

        _context.Challenges.Add(challenge);
        await _context.SaveChangesAsync();

        return challenge;
    }

    // Optional: Alle Challenges eines Users abrufen
    public async Task<List<UserChallenge>> GetUserChallengesAsync(int userId)
    {
        return await _context.UserChallenges
            .Include(uc => uc.Challenge)
            .Where(uc => uc.User.Id == userId)
            .ToListAsync();
    }
    
    public async Task AssignChallengesForLevelUpAsync(User user, int oldLevel)
    {
        var newLevel = user.Avatar.Level;

        // Alle Challenges, die jetzt freigeschaltet werden
        var newChallenges = await _context.Challenges
            .Where(c => c.RequiredLevel > oldLevel && c.RequiredLevel <= newLevel)
            .ToListAsync();

        foreach (var challenge in newChallenges)
        {
            if (!user.UserChallenges.Any(uc => uc.Challenge.Id == challenge.Id))
            {
                _context.UserChallenges.Add(new UserChallenge(user, challenge));
            }
        }

        await _context.SaveChangesAsync();
    }
}
