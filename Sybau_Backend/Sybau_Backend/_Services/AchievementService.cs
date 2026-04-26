using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Data;
using Sybau_Backend.DTOs;
using Sybau_Backend.Models;
using Sybau_Backend.Models.Enums;

namespace Sybau_Backend._Services;

public class AchievementService
{
    private readonly FitnessDbContext _context;
    private readonly UserService _userService;

    public AchievementService(FitnessDbContext context, UserService userService)
    {
        _context = context;
        _userService = userService;
    }

    /// <summary>
    /// Alle Achievements mit Unlock-Status für den User zurückgeben.
    /// </summary>
    public async Task<List<AchievementDto>> GetUserAchievementsAsync(int userId)
    {
        // Erst prüfen ob neue Achievements freigeschaltet werden
        await CheckAndUnlockAsync(userId);

        var achievements = await _context.Achievements
            .OrderBy(a => a.Id)
            .ToListAsync();

        var unlocked = await _context.UserAchievements
            .Where(ua => ua.UserId == userId)
            .ToDictionaryAsync(ua => ua.AchievementId, ua => ua.UnlockedAt);

        return achievements.Select(a => new AchievementDto
        {
            Id = a.Id,
            Key = a.Key,
            Title = a.Title,
            Description = a.Description,
            XpReward = a.XpReward,
            Unlocked = unlocked.ContainsKey(a.Id),
            UnlockedAt = unlocked.GetValueOrDefault(a.Id)
        }).ToList();
    }

    /// <summary>
    /// Prüft alle Achievements und schaltet neue frei.
    /// </summary>
    public async Task CheckAndUnlockAsync(int userId)
    {
        var achievements = await _context.Achievements.ToListAsync();
        var alreadyUnlocked = await _context.UserAchievements
            .Where(ua => ua.UserId == userId)
            .Select(ua => ua.AchievementId)
            .ToHashSetAsync();

        var locked = achievements.Where(a => !alreadyUnlocked.Contains(a.Id)).ToList();
        if (locked.Count == 0) return;

        // Alle benötigten Stats auf einmal laden
        var stats = await GatherUserStatsAsync(userId);

        var user = await _context.Users
            .Include(u => u.Avatar)
            .FirstAsync(u => u.Id == userId);

        var newlyUnlocked = new List<Achievement>();

        foreach (var achievement in locked)
        {
            var value = GetStatValue(stats, achievement.Type);
            if (value >= achievement.TargetValue)
            {
                _context.UserAchievements.Add(new UserAchievement(userId, achievement.Id));
                newlyUnlocked.Add(achievement);
            }
        }

        if (newlyUnlocked.Count > 0)
        {
            // XP für freigeschaltete Achievements gutschreiben
            var totalXp = newlyUnlocked.Sum(a => a.XpReward);
            if (totalXp > 0)
            {
                await _userService.AddXpAndHandleLevelUp(user, totalXp);
            }
            await _context.SaveChangesAsync();
        }
    }

    /// <summary>
    /// Profil-Statistiken berechnen (Workouts, Zeit, Kalorien, Streak).
    /// </summary>
    public async Task<ProfileStatsDto> GetProfileStatsAsync(int userId)
    {
        var (longestStreak, currentStreak) = await _userService.GetStreaksAsync(userId);

        // Alle Exercise-Logs mit der Kategorie laden (Include MUSS vor Select kommen!)
        var logs = await _context.UserExerciseLogs
            .Include(l => l.Exercise)
            .Where(l => l.UserId == userId)
            .Select(l => new { l.Reps, l.Date, l.Exercise.Category })
            .ToListAsync();

        var totalWorkouts = logs.Select(l => l.Date).Distinct().Count();
        var totalExercises = logs.Sum(l => l.Reps);

        // Trainingszeit schätzen: ~2 Minuten pro Exercise-Eintrag
        var trainingMinutes = logs.Count * 2.0;
        var trainingHours = Math.Round(trainingMinutes / 60.0, 1);

        // Kalorien schätzen basierend auf Kategorie
        var caloriesBurned = logs.Sum(l => EstimateCalories(l.Category, l.Reps));

        return new ProfileStatsDto
        {
            TotalWorkouts = totalWorkouts,
            TotalExercises = totalExercises,
            TrainingHours = trainingHours,
            CaloriesBurned = caloriesBurned,
            LongestStreak = longestStreak,
            CurrentStreak = currentStreak
        };
    }

    /// <summary>
    /// Heutige XP berechnen aus Exercise-Logs.
    /// </summary>
    public async Task<int> GetTodayXpAsync(int userId)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var todayLogs = await _context.UserExerciseLogs
            .Where(l => l.UserId == userId && l.Date == today)
            .Select(l => new { l.Reps, l.Exercise.XpPerRep })
            .ToListAsync();

        return todayLogs.Sum(l => (int)Math.Round(l.Reps * l.XpPerRep));
    }

    /// <summary>
    /// Gesamt-XP aller Zeiten berechnen aus Level + aktuelle Experience.
    /// </summary>
    public async Task<int> GetTotalXpAsync(int userId)
    {
        var avatar = await _context.Avatars.FirstAsync(a => a.UserId == userId);
        // Summe aller XP die für Level 1 bis (currentLevel-1) nötig waren + aktuelle XP
        var total = 0;
        for (int lvl = 1; lvl < avatar.Level; lvl++)
        {
            total += 100 + lvl * lvl * 20; // gleiche Formel wie AvatarService.XpForNextLevel
        }
        total += avatar.Experience;
        return total;
    }

    //Stats (Workouts gesamt, Trainingszeit, Kalorien) werden aus den Exercise-Logs berechnet — Kalorien geschätzt nach Kategorie (~0.5 kcal/Rep Strength, ~1 kcal Cardio), Zeit ~2 Min pro Trainingseinheit
    private static int EstimateCalories(WorkoutCategory category, int reps)
    {
        // Geschätzte Kalorien pro Wiederholung je Kategorie
        return category switch
        {
            WorkoutCategory.Strength => (int)Math.Round(reps * 0.5),
            WorkoutCategory.Cardio => reps * 1,
            WorkoutCategory.Core => (int)Math.Round(reps * 0.4),
            WorkoutCategory.Flexibility => (int)Math.Round(reps * 0.2),
            _ => (int)Math.Round(reps * 0.3)
        };
    }

    // ── Interne Stats-Sammlung ──

    private async Task<UserStats> GatherUserStatsAsync(int userId)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var weekAgo = today.AddDays(-7);

        // Exercise Logs
        var exerciseLogs = await _context.UserExerciseLogs
            .Where(l => l.UserId == userId)
            .Select(l => new { l.Reps, l.Date, l.Exercise.Category })
            .ToListAsync();

        // Kilometer total
        var totalKilometers = await _context.ActivityLogs
            .Where(a => a.UserId == userId && a.Type == ActivityType.Kilometers)
            .SumAsync(a => a.Value);

        // Streaks
        var (_, currentStreak) = await _userService.GetStreaksAsync(userId);

        // Abgeschlossene Quests (beansprucht)
        var completedQuests = await _context.UserQuests
            .CountAsync(uq => uq.UserId == userId && uq.IsCompleted && uq.IsRewardClaimed);

        // Level
        var avatar = await _context.Avatars.FirstAsync(a => a.UserId == userId);

        // Leaderboard-Position
        var leaderboardRank = await GetLeaderboardRankAsync(userId);

        // Wöchentliche Kategorien (letzte 7 Tage)
        var weeklyCategories = exerciseLogs
            .Where(l => l.Date >= weekAgo)
            .Select(l => l.Category)
            .Distinct()
            .Count();

        // Wöchentliche Reps (letzte 7 Tage)
        var weeklyReps = exerciseLogs
            .Where(l => l.Date >= weekAgo)
            .Sum(l => l.Reps);

        // Abgeschlossene monatliche Quests
        var monthlyQuestsCompleted = await _context.UserQuests
            .CountAsync(uq => uq.UserId == userId
                && uq.IsCompleted
                && uq.Quest.Type == QuestType.Monthly);

        return new UserStats
        {
            TotalReps = exerciseLogs.Sum(l => l.Reps),
            TotalKilometers = totalKilometers,
            CurrentStreak = currentStreak,
            QuestsCompleted = completedQuests,
            Level = avatar.Level,
            LeaderboardRank = leaderboardRank,
            TrainingDays = exerciseLogs.Select(l => l.Date).Distinct().Count(),
            TotalWorkouts = exerciseLogs.Select(l => l.Date).Distinct().Count(),
            WeeklyCategories = weeklyCategories,
            WeeklyReps = weeklyReps,
            MonthlyQuestsCompleted = monthlyQuestsCompleted
        };
    }

    private async Task<int> GetLeaderboardRankAsync(int userId)
    {
        var users = await _context.Users
            .Include(u => u.Avatar)
            .Where(u => !u.IsAdmin)
            .OrderByDescending(u => u.Avatar.Level)
            .ThenByDescending(u => u.Avatar.Experience)
            .Select(u => u.Id)
            .ToListAsync();

        var index = users.IndexOf(userId);
        return index >= 0 ? index + 1 : int.MaxValue;
    }

    private static double GetStatValue(UserStats stats, AchievementType type)
    {
        return type switch
        {
            AchievementType.TotalKilometers => stats.TotalKilometers,
            AchievementType.TotalReps => stats.TotalReps,
            AchievementType.CurrentStreak => stats.CurrentStreak,
            AchievementType.QuestsCompleted => stats.QuestsCompleted,
            AchievementType.Level => stats.Level,
            AchievementType.LeaderboardRank => stats.LeaderboardRank == 1 ? 1 : 0, // Nur Rang 1 zählt
            AchievementType.TrainingDays => stats.TrainingDays,
            AchievementType.TotalWorkouts => stats.TotalWorkouts,
            AchievementType.WeeklyCategories => stats.WeeklyCategories,
            AchievementType.WeeklyReps => stats.WeeklyReps,
            AchievementType.MonthlyQuestsCompleted => stats.MonthlyQuestsCompleted,
            _ => 0
        };
    }

    private class UserStats
    {
        public int TotalReps { get; set; }
        public double TotalKilometers { get; set; }
        public int CurrentStreak { get; set; }
        public int QuestsCompleted { get; set; }
        public int Level { get; set; }
        public int LeaderboardRank { get; set; }
        public int TrainingDays { get; set; }
        public int TotalWorkouts { get; set; }
        public int WeeklyCategories { get; set; }
        public int WeeklyReps { get; set; }
        public int MonthlyQuestsCompleted { get; set; }
    }
}
