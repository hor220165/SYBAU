using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Data;
using Sybau_Backend.DTOs;
using Sybau_Backend.Models;

namespace Sybau_Backend._Services;

public class UserService
{
    private readonly FitnessDbContext _context;
    private readonly ChallengeService _challengeService;

    public UserService(FitnessDbContext context,ChallengeService challengService)
    {
        _context = context;
        _challengeService = challengService;
    }

    // Alle User der Datenbank ausgeben
    public async Task<IEnumerable<User>> GetUsers()
    {
        return await _context.Users.ToListAsync();
    }
    
    //Leaderboard Top10
    public async Task<IEnumerable<LeaderBoardDto>> GetLeaderboard()
    {
        // Schritt 1: Daten aus der DB holen
        var users = await _context.Users
            .Include(u => u.Avatar)
            .Where(u => u.Avatar != null)
            .OrderByDescending(u => u.Avatar.Experience)
            .Take(10)
            .ToListAsync(); // Daten kommen jetzt in den Speicher

        // Schritt 2: Clientseitig den Rank berechnen
        var leaderboard = users
            .Select((u, index) => new LeaderBoardDto
            {
                Id = u.Id,
                Rank = index + 1,
                UserName = u.UserName,
                Experience = u.Avatar.Experience,
                Level = u.Avatar.Level
            })
            .ToList();

        return leaderboard;
    }

    
    //Einen genauen User ausgeben
    public async Task<User?> GetUserById(int id)
    {
        return await _context.Users
            .Include(u => u.Avatar)
            .SingleOrDefaultAsync(u => u.Id == id);
    }
    
    // Methode zum Hinzufügen von XP und automatischer Challenge-Zuweisung
    public async Task AddXpAndHandleLevelUp(User user, int xp)
    {
        int oldLevel = user.Avatar.Level;
        user.Avatar.AddExperience(xp);

        if (user.Avatar.Level > oldLevel)
        {
            await _challengeService.AssignChallengesForLevelUpAsync(user, oldLevel);
        }

        await _context.SaveChangesAsync();
    }
    
    //Challenges von Lvl 1 zum User hinzufügen
    public async Task AssignStartingChallengesAsync(User user)
    {
        if (user == null) throw new ArgumentNullException(nameof(user));

        // Alle Challenges, die für das aktuelle Level freigeschaltet sind
        var challenges = await _context.Challenges
            .Where(c => c.RequiredLevel <= user.Avatar.Level)
            .ToListAsync();

        foreach (var challenge in challenges)
        {
            if (!user.UserChallenges.Any(uc => uc.Challenge.Id == challenge.Id))
            {
                var userChallenge = new UserChallenge(user, challenge);
                _context.UserChallenges.Add(userChallenge);
            }
        }

        await _context.SaveChangesAsync();
    }
    
    //Coins speichern Methode
    public async Task AddCoinsAsync(User user, int amount, string reason)
    {
        if (user == null) throw new ArgumentNullException(nameof(user));
        if (amount == 0) throw new ArgumentException("Amount cannot be zero");

        // Historie speichern
        var userCoin = new UserCoin(user, amount, reason);
        _context.UserCoins.Add(userCoin);

        // Kontostand aktualisieren
        user.Coins += amount;

        await _context.SaveChangesAsync();
    }


    // Challenge für User abschließen und prüfen auf levelup
    public async Task<AvatarDto?> CompleteChallengeAsync(int userId, int challengeId)
    {
        var user = await _context.Users
            .Include(u => u.Avatar)
            .Include(u => u.UserChallenges)
            .ThenInclude(uc => uc.Challenge)
            .FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null) return null;

        var userChallenge = user.UserChallenges.FirstOrDefault(uc => uc.Challenge.Id == challengeId);
        if (userChallenge == null) return null;

        if (!userChallenge.Completed)
        {
            userChallenge.Progress = 100;
            userChallenge.CompletedAt = DateTime.UtcNow;

            // XP hinzufügen + Level-Up
            await AddXpAndHandleLevelUp(user, userChallenge.Challenge.XpReward);

            // Coins gutschreiben
            if (userChallenge.Challenge.CoinReward > 0)
            {
                await AddCoinsAsync(user, userChallenge.Challenge.CoinReward, "Challenge completed");
            }
        }

        return new AvatarDto
        {
            Id = user.Avatar.Id,
            Level = user.Avatar.Level,
            Experience = user.Avatar.Experience,
            Boost1 = user.Avatar.Boost1,
            Boost2 = user.Avatar.Boost2,
            Boost3 = user.Avatar.Boost3,
            Boost4 = user.Avatar.Boost4
        };
    }
    
    
    public async Task UpdateUserAsync(User user)
    {
        _context.Users.Update(user);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteUserAsync(int userId)
    {
        var user = await _context.Users
            .Include(u => u.Avatar)
            .Include(u => u.UserChallenges)
            .FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null) return;

        // Optional: Alles löschen, was zum User gehört
        if (user.Avatar != null)
            _context.Avatars.Remove(user.Avatar);

        if (user.UserChallenges != null)
            _context.UserChallenges.RemoveRange(user.UserChallenges);

        _context.Users.Remove(user);
        await _context.SaveChangesAsync();
    }

}