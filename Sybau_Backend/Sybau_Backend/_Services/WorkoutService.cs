using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Data;
using Sybau_Backend.DTOs;
using Sybau_Backend.Models;
using Sybau_Backend.Models.Enums;

namespace Sybau_Backend._Services;

public class WorkoutService
{
    private readonly FitnessDbContext _context;
    private readonly UserService _userService;
    private readonly QuestService _questService;
    private readonly AchievementService _achievementService;

    public WorkoutService(FitnessDbContext context, UserService userService, QuestService questService, AchievementService achievementService)
    {
        _context = context;
        _userService = userService;
        _questService = questService;
        _achievementService = achievementService;
    }

    public async Task<ExerciseDto> CreateExerciseAsync(CreateExerciseDto dto)
    {
        if (dto == null) throw new ArgumentNullException(nameof(dto));

        var exercise = new Exercise(dto.Name, dto.Description, dto.Category, dto.Difficulty, dto.XpPerRep, dto.DailyLimit);
        _context.Exercises.Add(exercise);
        await _context.SaveChangesAsync();

        return new ExerciseDto
        {
            Id = exercise.Id,
            Name = exercise.Name,
            Description = exercise.Description,
            Category = exercise.Category,
            Difficulty = exercise.Difficulty,
            XpPerRep = exercise.XpPerRep,
            DailyLimit = exercise.DailyLimit,
            TodayCount = 0
        };
    }

    public async Task<List<ExerciseDto>> GetExercisesAsync(WorkoutCategory? category, int? userId = null)
    {
        var query = _context.Exercises.AsQueryable();

        if (category.HasValue)
        {
            query = query.Where(e => e.Category == category.Value);
        }

        var today = DateOnly.FromDateTime(DateTime.UtcNow);

        var exercises = await query
            .OrderBy(e => e.Name)
            .Select(e => new ExerciseDto
            {
                Id = e.Id,
                Name = e.Name,
                Description = e.Description,
                Category = e.Category,
                Difficulty = e.Difficulty,
                XpPerRep = e.XpPerRep,
                DailyLimit = e.DailyLimit,
                TodayCount = userId.HasValue
                    ? _context.UserExerciseLogs
                        .Where(l => l.UserId == userId.Value && l.ExerciseId == e.Id && l.Date == today)
                        .Sum(l => l.Reps)
                    : 0
            })
            .ToListAsync();

        return exercises;
    }

    public async Task<WorkoutDto> CreateWorkoutAsync(CreateWorkoutDto dto)
    {
        if (dto == null) throw new ArgumentNullException(nameof(dto));
        if (dto.Exercises.Count == 0) throw new ArgumentException("Workout braucht mindestens eine Übung.");

        var exerciseIds = dto.Exercises
            .Select(e => e.ExerciseId)
            .Distinct()
            .ToList();

        if (exerciseIds.Count != dto.Exercises.Count)
            throw new ArgumentException("Doppelte Übungen sind im Workout nicht erlaubt.");

        var exercises = await _context.Exercises
            .Where(e => exerciseIds.Contains(e.Id))
            .ToListAsync();

        if (exercises.Count != exerciseIds.Count)
            throw new ArgumentException("Eine oder mehrere Übungen wurden nicht gefunden.");

        if (dto.Exercises.Any(e => e.DailyLimit < 1))
            throw new ArgumentException("DailyLimit muss mindestens 1 sein.");

        var workout = new Workout(dto.Name, dto.Description, dto.Category);
        _context.Workouts.Add(workout);

        foreach (var item in dto.Exercises)
        {
            var exercise = exercises.Single(e => e.Id == item.ExerciseId);
            _context.WorkoutExercises.Add(new WorkoutExercise(workout, exercise, item.DailyLimit));
        }

        await _context.SaveChangesAsync();

        return await GetWorkoutByIdAsync(workout.Id)
               ?? throw new InvalidOperationException("Workout konnte nach Erstellung nicht geladen werden.");
    }

    public async Task<List<WorkoutDto>> GetWorkoutsAsync(WorkoutCategory? category)
    {
        var query = _context.Workouts
            .Include(w => w.WorkoutExercises)
            .ThenInclude(we => we.Exercise)
            .AsQueryable();

        if (category.HasValue)
        {
            query = query.Where(w => w.Category == category.Value);
        }

        var workouts = await query
            .OrderBy(w => w.Name)
            .ToListAsync();

        return workouts.Select(MapWorkoutToDto).ToList();
    }

    public async Task<WorkoutDto?> GetWorkoutByIdAsync(int id)
    {
        var workout = await _context.Workouts
            .Include(w => w.WorkoutExercises)
            .ThenInclude(we => we.Exercise)
            .FirstOrDefaultAsync(w => w.Id == id);

        if (workout == null) return null;
        return MapWorkoutToDto(workout);
    }

    private static WorkoutDto MapWorkoutToDto(Workout workout)
    {
        return new WorkoutDto
        {
            Id = workout.Id,
            Name = workout.Name,
            Description = workout.Description,
            Category = workout.Category,
            Exercises = workout.WorkoutExercises
                .OrderBy(we => we.Exercise.Name)
                .Select(we => new WorkoutExerciseDto
                {
                    ExerciseId = we.ExerciseId,
                    ExerciseName = we.Exercise.Name,
                    ExerciseCategory = we.Exercise.Category,
                    Difficulty = we.Exercise.Difficulty,
                    DailyLimit = we.DailyLimit
                })
                .ToList()
        };
    }

    /// <summary>
    /// Berechnet XP- und Coin-Boost-Prozentsatz aller equippten Booster eines Users.
    /// </summary>
    public async Task<(int xpBoost, int coinBoost)> GetEquippedBoostsAsync(int userId)
    {
        var avatar = await _context.Avatars
            .Where(a => a.UserId == userId)
            .Select(a => new { a.Boost1, a.Boost2, a.Boost3, a.Boost4 })
            .FirstOrDefaultAsync();

        if (avatar == null) return (0, 0);

        var slotNames = new[] { avatar.Boost1, avatar.Boost2, avatar.Boost3, avatar.Boost4 }
            .Where(n => !string.IsNullOrEmpty(n))
            .ToList();

        if (slotNames.Count == 0) return (0, 0);

        var boosterValues = await _context.Items
            .Where(i => i.Type == ItemType.Booster && slotNames.Contains(i.Name))
            .Select(i => new { i.Name, i.XpBoostPercent, i.CoinBoostPercent })
            .ToListAsync();

        var lookup = boosterValues.ToDictionary(b => b.Name);

        var xpBoost = slotNames.Sum(name => name != null && lookup.TryGetValue(name, out var v) ? v.XpBoostPercent : 0);
        var coinBoost = slotNames.Sum(name => name != null && lookup.TryGetValue(name, out var v) ? v.CoinBoostPercent : 0);

        return (xpBoost, coinBoost);
    }

    public async Task<ExerciseDto?> LogExerciseAsync(int userId, int exerciseId, int reps)
    {
        if (reps < 1) throw new ArgumentOutOfRangeException(nameof(reps));

        var user = await _context.Users.FindAsync(userId);
        if (user == null) return null;

        var exercise = await _context.Exercises.FindAsync(exerciseId);
        if (exercise == null) return null;

        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var todayTotal = await _context.UserExerciseLogs
            .Where(l => l.UserId == userId && l.ExerciseId == exerciseId && l.Date == today)
            .SumAsync(l => l.Reps);

        if (todayTotal + reps > exercise.DailyLimit)
            throw new InvalidOperationException($"Tageslimit von {exercise.DailyLimit} überschritten. Bereits {todayTotal} gemacht.");

        var log = new UserExerciseLog(user, exercise, reps);
        _context.UserExerciseLogs.Add(log);
        await _context.SaveChangesAsync();

        // Boosts laden
        var (xpBoostPct, coinBoostPct) = await GetEquippedBoostsAsync(userId);

        // XP berechnen mit Booster-Boost
        var baseXp = (int)Math.Round(exercise.XpPerRep * reps);
        var bonusXp = (int)Math.Round(baseXp * xpBoostPct / 100.0);
        var totalXp = baseXp + bonusXp;

        // Coins berechnen: 1 Coin pro 10 Reps als Basis (mindestens 1 Coin)
        var baseCoins = Math.Max(1, reps / 10);
        var bonusCoins = (int)Math.Round(baseCoins * coinBoostPct / 100.0);
        var totalCoins = baseCoins + bonusCoins;

        var userWithAvatar = await _context.Users
            .Include(u => u.Avatar)
            .SingleAsync(u => u.Id == userId);

        if (totalXp > 0)
            await _userService.AddXpAndHandleLevelUp(userWithAvatar, totalXp);

        if (totalCoins > 0)
            await _userService.AddCoinsAsync(userWithAvatar, totalCoins, $"Exercise: {exercise.Name}");

        // Quest-Fortschritt aktualisieren
        await _questService.UpdateQuestProgressAsync(userId);

        // Achievement-Check
        await _achievementService.CheckAndUnlockAsync(userId);

        return new ExerciseDto
        {
            Id = exercise.Id,
            Name = exercise.Name,
            Description = exercise.Description,
            Category = exercise.Category,
            Difficulty = exercise.Difficulty,
            XpPerRep = exercise.XpPerRep,
            DailyLimit = exercise.DailyLimit,
            TodayCount = todayTotal + reps,
            XpEarned = totalXp,
            BonusXp = bonusXp,
            BoostPercent = xpBoostPct,
            CoinsEarned = totalCoins,
            BonusCoins = bonusCoins,
            CoinBoostPercent = coinBoostPct
        };
    }
}