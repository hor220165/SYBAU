using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Data;
using Sybau_Backend.DTOs;
using Sybau_Backend.Models;
using Sybau_Backend.Models.Enums;

namespace Sybau_Backend._Services;

public class UserService
{
    private readonly FitnessDbContext _context;
    private readonly ChallengeService _challengeService;
    private readonly AvatarService _avatarService;

    public UserService(FitnessDbContext context,ChallengeService challengService, AvatarService avatarService)
    {
        _context = context;
        _challengeService = challengService;
        _avatarService = avatarService;
    }

    // Alle User der Datenbank ausgeben
    public async Task<IEnumerable<User>> GetUsersExcept(int id)
    {
        return await _context.Users
            .Include(u=>u.Avatar)
            .Where(u => u.Id != id)
            .ToListAsync();
    }
    
    //Leaderboard Top10
    public async Task<IEnumerable<LeaderBoardDto>> GetLeaderboard()
    {
        // Schritt 1: Daten aus der DB holen
        var users = await _context.Users
            .Include(u => u.Avatar)
            .Where(u => u.IsAdmin == false)
            .OrderByDescending(u => u.Avatar.Level)
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
        await _avatarService.AddXpAsync(user.Avatar, xp);

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
    
    //Für AdminUse
    public async Task<User> UpdateUserAsync(User user, UpdateUserDto dto)
    {
        // User inkl. Avatar laden, falls Avatar-Level geupdatet werden soll
        var dbUser = await _context.Users
            .Include(u => u.Avatar)
            .FirstOrDefaultAsync(u => u.Id == user.Id);

        if (dbUser == null)
            throw new Exception("User nicht gefunden");

        // User-Felder updaten
        if (!string.IsNullOrEmpty(dto.Username))
            dbUser.UserName = dto.Username;
        if (!string.IsNullOrEmpty(dto.Email))
            dbUser.Email = dto.Email;
        if (dto.Coins.HasValue)
            dbUser.Coins = dto.Coins.Value;

        // Avatar-Level updaten
        if (dto.Avatar?.Level.HasValue == true)
        { 
            dbUser.Avatar.Level = dto.Avatar.Level.Value;
        }
        
        await _context.SaveChangesAsync();
        return dbUser;
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

    // Gekaufte Booster-Items eines Users abrufen (mit Quantity, aggregiert)
    public async Task<List<ItemDto>> GetUserBoostersAsync(int userId)
    {
        var userItems = await _context.UserItems
            .Include(ui => ui.Item)
            .Where(ui => ui.User.Id == userId && ui.Item.Type == ItemType.Booster)
            .ToListAsync();

        return userItems
            .GroupBy(ui => ui.Item.Id)
            .Select(g => new ItemDto
            {
                Id = g.First().Item.Id,
                Name = g.First().Item.Name,
                Description = g.First().Item.Description,
                Type = g.First().Item.Type,
                Price = g.First().Item.Price,
                XpBoostPercentage = g.First().Item.XpBoostPercent,
                Quantity = g.Sum(ui => ui.Quantity)
            })
            .ToList();
    }

    // Booster in Slots equippen
    public async Task<bool> UpdateBoostSlotsAsync(int userId, List<int?> slots)
    {
        if (slots == null || slots.Count != 4)
            return false;

        var user = await _context.Users
            .Include(u => u.Avatar)
            .Include(u => u.UserItems)
            .ThenInclude(ui => ui.Item)
            .FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null) return false;

        // Prüfe ob der User die angegebenen Booster-Items besitzt UND genug Quantity hat
        var ownedBoosters = user.UserItems
            .Where(ui => ui.Item.Type == ItemType.Booster)
            .GroupBy(ui => ui.Item.Id)
            .ToDictionary(g => g.Key, g => g.Sum(ui => ui.Quantity));

        // Zähle wie oft jede Item-ID in den Slots vorkommt
        var slotCounts = slots
            .Where(s => s.HasValue)
            .GroupBy(s => s!.Value)
            .ToDictionary(g => g.Key, g => g.Count());

        foreach (var (itemId, requiredCount) in slotCounts)
        {
            if (!ownedBoosters.TryGetValue(itemId, out var ownedQty) || ownedQty < requiredCount)
                return false; // User besitzt nicht genug Exemplare
        }

        // Item-Namen für die Slots auflösen
        var itemIds = slots.Where(s => s.HasValue).Select(s => s!.Value).Distinct().ToList();
        var items = await _context.Items
            .Where(i => itemIds.Contains(i.Id) && i.Type == ItemType.Booster)
            .ToDictionaryAsync(i => i.Id);

        // Sicherstellen, dass alle IDs gültige Booster-Items sind
        foreach (var slotItemId in slots)
        {
            if (slotItemId.HasValue && !items.ContainsKey(slotItemId.Value))
                return false;
        }

        // Slots setzen (Name des Items als String)
        user.Avatar.Boost1 = slots[0].HasValue ? items[slots[0].Value].Name : null;
        user.Avatar.Boost2 = slots[1].HasValue ? items[slots[1].Value].Name : null;
        user.Avatar.Boost3 = slots[2].HasValue ? items[slots[2].Value].Name : null;
        user.Avatar.Boost4 = slots[3].HasValue ? items[slots[3].Value].Name : null;

        await _context.SaveChangesAsync();
        return true;
    }

}