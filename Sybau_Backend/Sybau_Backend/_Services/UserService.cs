using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Data;
using Sybau_Backend.DTOs;
using Sybau_Backend.Models;
using Sybau_Backend.Models.Enums;

namespace Sybau_Backend._Services;

public class UserService
{
    private const string DataImageLikePattern = "data:image/%";
    private readonly FitnessDbContext _context;
    private readonly ChallengeService _challengeService;
    private readonly AvatarService _avatarService;

    public UserService(FitnessDbContext context,ChallengeService challengService, AvatarService avatarService)
    {
        _context = context;
        _challengeService = challengService;
        _avatarService = avatarService;
    }

    public sealed class UserProfileSummary
    {
        public int Id { get; init; }
        public string UserName { get; init; } = string.Empty;
        public string Email { get; init; } = string.Empty;
        public bool HasProfileImage { get; init; }
        public int Coins { get; init; }
        public bool IsAdmin { get; init; }
        public bool IsProfilePrivate { get; init; }
        public int AvatarId { get; init; }
        public int AvatarLevel { get; init; }
        public int AvatarExperience { get; init; }
        public string? Boost1 { get; init; }
        public string? Boost2 { get; init; }
        public string? Boost3 { get; init; }
        public string? Boost4 { get; init; }
    }

    public async Task<UserProfileSummary?> GetUserProfileSummaryAsync(int id)
    {
        return await _context.Users
            .AsNoTracking()
            .Where(u => u.Id == id)
            .Select(u => new UserProfileSummary
            {
                Id = u.Id,
                UserName = u.UserName,
                Email = u.Email,
                HasProfileImage = u.ProfileImageUrl != null && u.ProfileImageUrl != string.Empty,
                Coins = u.Coins,
                IsAdmin = u.IsAdmin,
                IsProfilePrivate = u.IsProfilePrivate,
                AvatarId = u.Avatar.Id,
                AvatarLevel = u.Avatar.Level,
                AvatarExperience = u.Avatar.Experience,
                Boost1 = u.Avatar.Boost1,
                Boost2 = u.Avatar.Boost2,
                Boost3 = u.Avatar.Boost3,
                Boost4 = u.Avatar.Boost4
            })
            .SingleOrDefaultAsync();
    }

    public async Task<string?> GetProfileImageUrlAsync(int userId)
    {
        return await _context.Users
            .AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => u.ProfileImageUrl)
            .SingleOrDefaultAsync();
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
        var users = await _context.Users
            .AsNoTracking()
            .Where(u => u.IsAdmin == false)
            .Select(u => new
            {
                u.Id,
                u.UserName,
                HasProfileImage = u.ProfileImageUrl != null && u.ProfileImageUrl != string.Empty,
                u.Avatar.Experience,
                u.Avatar.Level
            })
            .ToListAsync();

        var leaderboard = users
            .Select(u => new
            {
                User = u,
                TotalXp = CalculateTotalXp(u.Level, u.Experience)
            })
            .OrderByDescending(entry => entry.TotalXp)
            .ThenByDescending(entry => entry.User.Level)
            .Take(10)
            .Select((u, index) => new LeaderBoardDto
            {
                Id = u.User.Id,
                Rank = index + 1,
                UserName = u.User.UserName,
                ProfileImageUrl = ProfileMediaUrl.ForUser(u.User.Id, u.User.HasProfileImage),
                Experience = u.User.Experience,
                TotalXp = u.TotalXp,
                Level = u.User.Level
            })
            .ToList();

        return leaderboard;
    }

    private static int CalculateTotalXp(int level, int experience)
    {
        var total = 0;
        for (var lvl = 1; lvl < level; lvl++)
        {
            total += 100 + lvl * lvl * 20;
        }

        return total + experience;
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

            // Level-Up loggen (1 Coin symbolisch, für Recent Activities)
            var levelUpCoin = new UserCoin(user, 1, $"Level {user.Avatar.Level} erreicht");
            _context.UserCoins.Add(levelUpCoin);
            user.Coins += 1;
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
    
    public async Task<(int longestStreak, int currentStreak)> GetStreaksAsync(int userId)
    {
        var dates = await _context.UserExerciseLogs
            .Where(l => l.UserId == userId)
            .Select(l => l.Date)
            .Distinct()
            .OrderBy(d => d)
            .ToListAsync();

        if (dates.Count == 0) return (0, 0);

        int longest = 1, current = 1, streak = 1;
        var today = DateOnly.FromDateTime(DateTime.UtcNow);

        for (int i = 1; i < dates.Count; i++)
        {
            if (dates[i].DayNumber - dates[i - 1].DayNumber == 1)
                streak++;
            else
                streak = 1;

            if (streak > longest) longest = streak;
        }

        // Current streak: prüfe ob die letzte Aktivität heute oder gestern war
        var lastDate = dates[^1];
        if (lastDate != today && lastDate.DayNumber != today.DayNumber - 1)
        {
            current = 0;
        }
        else
        {
            current = 1;
            for (int i = dates.Count - 2; i >= 0; i--)
            {
                if (dates[i + 1].DayNumber - dates[i].DayNumber == 1)
                    current++;
                else
                    break;
            }
        }

        return (longest, current);
    }

    public async Task<List<DateOnly>> GetActivityDatesAsync(int userId, DateOnly from, DateOnly to)
    {
        return await _context.UserExerciseLogs
            .Where(l => l.UserId == userId && l.Date >= from && l.Date <= to)
            .Select(l => l.Date)
            .Distinct()
            .ToListAsync();
    }

    public async Task<List<WeeklyActivityDto>> GetWeeklyActivityAsync(int userId, DateOnly from, DateOnly to)
    {
        var workoutDays = await _context.UserExerciseLogs
            .Where(l => l.UserId == userId && l.Date >= from && l.Date <= to)
            .GroupBy(l => l.Date)
            .Select(g => new WeeklyActivityDto
            {
                Date = g.Key.ToString("yyyy-MM-dd"),
                Reps = g.Sum(l => l.Reps)
            })
            .ToListAsync();

        var stepsByDate = await _context.ActivityLogs
            .Where(l => l.UserId == userId && l.Type == ActivityType.Steps && l.Date >= from && l.Date <= to)
            .GroupBy(l => l.Date)
            .Select(g => new
            {
                Date = g.Key.ToString("yyyy-MM-dd"),
                Steps = (int)g.Sum(l => l.Value)
            })
            .ToListAsync();

        var byDate = workoutDays.ToDictionary(day => day.Date);
        foreach (var stepsDay in stepsByDate)
        {
            if (byDate.TryGetValue(stepsDay.Date, out var day))
            {
                day.Steps = stepsDay.Steps;
                continue;
            }

            byDate[stepsDay.Date] = new WeeklyActivityDto
            {
                Date = stepsDay.Date,
                Steps = stepsDay.Steps
            };
        }

        return byDate.Values.OrderBy(day => day.Date).ToList();
    }

    public async Task<List<int>> GetActivityYearsAsync(int userId)
    {
        var userCreatedAt = await _context.Users
            .Where(u => u.Id == userId)
            .Select(u => u.CreatedAt)
            .FirstOrDefaultAsync();

        var exerciseDates = await _context.UserExerciseLogs
            .Where(l => l.UserId == userId)
            .Select(l => l.Date)
            .ToListAsync();

        var activityDates = await _context.ActivityLogs
            .Where(l => l.UserId == userId)
            .Select(l => l.Date)
            .ToListAsync();

        var activityYears = exerciseDates
            .Concat(activityDates)
            .Select(date => date.Year)
            .ToList();

        var currentYear = DateTime.UtcNow.Year;
        var startYear = userCreatedAt == default ? currentYear : userCreatedAt.Year;
        if (activityYears.Count > 0)
        {
            startYear = Math.Min(startYear, activityYears.Min());
        }

        return Enumerable.Range(startYear, currentYear - startYear + 1)
            .OrderByDescending(year => year)
            .ToList();
    }

    public async Task<List<RecentActivityDto>> GetRecentActivitiesAsync(int userId, int limit = 10)
    {
        var activities = new List<RecentActivityDto>();

        // 1) Workout-Sessions: Jeder Exercise-Log einzeln
        var workoutActivities = await _context.UserExerciseLogs
            .Where(l => l.UserId == userId)
            .Include(l => l.Exercise)
            .OrderByDescending(l => l.CreatedAt)
            .Select(l => new RecentActivityDto
            {
                Type = "workout",
                Title = l.Exercise.Name + " – " + l.Reps + " Reps",
                Xp = (int)Math.Round(l.Reps * l.Exercise.XpPerRep),
                Timestamp = l.CreatedAt
            })
            .ToListAsync();
        activities.AddRange(workoutActivities);

        // 2) Abgeschlossene Quests
        var questActivities = await _context.UserQuests
            .Where(q => q.UserId == userId && q.IsCompleted && q.CompletedAt != null)
            .Include(q => q.Quest)
            .Select(q => new RecentActivityDto
            {
                Type = "quest",
                Title = "Quest '" + q.Quest.Name + "' abgeschlossen",
                Xp = q.Quest.XpReward,
                Timestamp = q.CompletedAt!.Value
            })
            .ToListAsync();
        activities.AddRange(questActivities);

        // 3) Freigeschaltete Achievements
        var achievementActivities = await _context.UserAchievements
            .Where(a => a.UserId == userId)
            .Include(a => a.Achievement)
            .Select(a => new RecentActivityDto
            {
                Type = "achievement",
                Title = "Achievement '" + a.Achievement.Title + "' freigeschaltet",
                Xp = a.Achievement.XpReward,
                Timestamp = a.UnlockedAt
            })
            .ToListAsync();
        activities.AddRange(achievementActivities);

        // 4) Level-Ups (aus UserCoin-Einträgen mit "Level X erreicht")
        var levelActivities = await _context.UserCoins
            .Where(c => c.UserId == userId && c.Reason.StartsWith("Level ") && c.Reason.EndsWith(" erreicht"))
            .Select(c => new RecentActivityDto
            {
                Type = "level",
                Title = c.Reason + "!",
                Xp = 0,
                Timestamp = c.CreatedAt
            })
            .ToListAsync();
        activities.AddRange(levelActivities);

        // Nach Datum sortieren und limitieren
        var result = activities
            .OrderByDescending(a => a.Timestamp)
            .Take(limit)
            .ToList();

        // IDs zuweisen
        for (int i = 0; i < result.Count; i++)
            result[i].Id = i + 1;

        return result;
    }
    
    public async Task UpdateUserAsync(User user)
    {
        _context.Users.Update(user);
        await _context.SaveChangesAsync();
    }

    public async Task SetProfileImageUrlAsync(int userId, string? profileImageUrl)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null)
            throw new Exception("User nicht gefunden");

        user.ProfileImageUrl = profileImageUrl;
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
        if (dto.IsProfilePrivate.HasValue)
            dbUser.IsProfilePrivate = dto.IsProfilePrivate.Value;

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
        await using var transaction = await _context.Database.BeginTransactionAsync();

        var user = await _context.Users
            .Include(u => u.Avatar)
            .FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null) return;

        var friendships = await _context.Friendships
            .Where(f => f.RequesterId == userId || f.AddresseeId == userId)
            .ToListAsync();
        var friendChallenges = await _context.FriendChallenges
            .Where(fc =>
                fc.ChallengerId == userId ||
                fc.OpponentId == userId ||
                fc.WinnerId == userId)
            .ToListAsync();
        var activityLogs = await _context.ActivityLogs
            .Where(a => a.UserId == userId)
            .ToListAsync();
        var exerciseLogs = await _context.UserExerciseLogs
            .Where(l => l.UserId == userId)
            .ToListAsync();
        var userItems = await _context.UserItems
            .Where(ui => EF.Property<int>(ui, "UserId") == userId)
            .ToListAsync();
        var userCoins = await _context.UserCoins
            .Where(uc => uc.UserId == userId)
            .ToListAsync();
        var userChallenges = await _context.UserChallenges
            .Where(uc => EF.Property<int>(uc, "UserId") == userId)
            .ToListAsync();
        var userQuests = await _context.UserQuests
            .Where(uq => uq.UserId == userId)
            .ToListAsync();
        var userAchievements = await _context.UserAchievements
            .Where(ua => ua.UserId == userId)
            .ToListAsync();

        _context.FriendChallenges.RemoveRange(friendChallenges);
        _context.Friendships.RemoveRange(friendships);
        _context.ActivityLogs.RemoveRange(activityLogs);
        _context.UserExerciseLogs.RemoveRange(exerciseLogs);
        _context.UserItems.RemoveRange(userItems);
        _context.UserCoins.RemoveRange(userCoins);
        _context.UserChallenges.RemoveRange(userChallenges);
        _context.UserQuests.RemoveRange(userQuests);
        _context.UserAchievements.RemoveRange(userAchievements);

        if (user.Avatar != null)
        {
            _context.Avatars.Remove(user.Avatar);
        }

        _context.Users.Remove(user);
        await _context.SaveChangesAsync();
        await transaction.CommitAsync();
    }

    // Gekaufte Booster-Items eines Users abrufen (mit Quantity, aggregiert)
    public async Task<List<ItemDto>> GetUserBoostersAsync(int userId)
    {
        var userItems = await _context.UserItems
            .Where(ui => ui.User.Id == userId && ui.Item.Type == ItemType.Booster)
            .Select(ui => new
            {
                ItemId = ui.Item.Id,
                ui.Item.Name,
                ui.Item.Description,
                ui.Item.Type,
                ui.Item.Price,
                ui.Item.XpBoostPercent,
                ui.Item.CoinBoostPercent,
                ui.Item.Rarity,
                ui.Item.MaxQuantity,
                ui.Quantity,
                HasImage = ui.Item.ImageUrl != null && ui.Item.ImageUrl != string.Empty,
                IsDataImage = ui.Item.ImageUrl != null && EF.Functions.Like(ui.Item.ImageUrl, DataImageLikePattern),
                ExternalImageUrl = ui.Item.ImageUrl != null && ui.Item.ImageUrl != string.Empty && !EF.Functions.Like(ui.Item.ImageUrl, DataImageLikePattern)
                    ? ui.Item.ImageUrl
                    : null
            })
            .ToListAsync();

        return userItems
            .GroupBy(ui => ui.ItemId)
            .Select(g => new ItemDto
            {
                Id = g.First().ItemId,
                Name = g.First().Name,
                Description = g.First().Description,
                Type = g.First().Type,
                Price = g.First().Price,
                XpBoostPercentage = g.First().XpBoostPercent,
                CoinBoostPercentage = g.First().CoinBoostPercent,
                Rarity = g.First().Rarity,
                Quantity = g.Sum(ui => ui.Quantity),
                MaxQuantity = g.First().MaxQuantity,
                ImageUrl = ItemImageUrl(g.First().ItemId, g.First().HasImage, g.First().IsDataImage, g.First().ExternalImageUrl)
            })
            .ToList();
    }

    private static string? ItemImageUrl(int itemId, bool hasImage, bool isDataImage, string? externalImageUrl)
    {
        if (!hasImage) return null;
        return isDataImage ? $"/shop/items/{itemId}/image" : externalImageUrl;
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
