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


    // Challenge für User abschließen
    public async Task CompleteChallengeAsync(int userId, int challengeId)
    {
        var userChallenge = await _context.UserChallenges
            .Include(uc => uc.Challenge)
            .Include(uc => uc.User)
            .ThenInclude(u => u.Avatar)
            .FirstOrDefaultAsync(uc => uc.User.Id == userId && uc.Challenge.Id == challengeId);

        if (userChallenge == null)
            throw new Exception("Challenge not found for this user");

        if (userChallenge.Completed)
            throw new Exception("Challenge already completed");

        // Challenge abschließen
        userChallenge.Complete();

        // XP vergeben
        userChallenge.User.Avatar.AddExperience(userChallenge.Challenge.XpReward);

        await _context.SaveChangesAsync();
    }

    // Optional: Alle Challenges eines Users abrufen
    public async Task<List<UserChallenge>> GetUserChallengesAsync(int userId)
    {
        return await _context.UserChallenges
            .Include(uc => uc.Challenge)
            .Where(uc => uc.User.Id == userId)
            .ToListAsync();
    }
}
