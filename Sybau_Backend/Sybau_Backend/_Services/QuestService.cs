using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Data;
using Sybau_Backend.DTOs;
using Sybau_Backend.Models;
using Sybau_Backend.Models.Enums;

namespace Sybau_Backend._Services;

public class QuestService
{
    private readonly FitnessDbContext _context;
    private readonly UserService _userService;

    public QuestService(FitnessDbContext context, UserService userService)
    {
        _context = context;
        _userService = userService;
    }

    /// <summary>
    /// Gibt alle aktiven Quests eines Users zurück. Erstellt/resettet Quests automatisch.
    /// </summary>
    public async Task<List<UserQuestDto>> GetUserQuestsAsync(int userId)
    {
        await EnsureUserQuestsAsync(userId);
        await RecalculateAllProgressAsync(userId);

        var userQuests = await _context.UserQuests
            .Include(uq => uq.Quest)
            .Where(uq => uq.UserId == userId)
            .OrderBy(uq => uq.Quest.Type)
            .ThenBy(uq => uq.Quest.Rarity)
            .ToListAsync();

        // Nur aktuelle Periode behalten
        var now = DateTime.UtcNow;
        var result = new List<UserQuestDto>();

        foreach (var uq in userQuests)
        {
            var currentPeriod = GetPeriodStart(uq.Quest.Type);
            if (uq.PeriodStart != currentPeriod) continue;

            result.Add(MapToDto(uq, now));
        }

        return result;
    }

    /// <summary>
    /// Belohnung für eine abgeschlossene Quest einfordern.
    /// </summary>
    public async Task<(bool success, string message, int xpEarned, int coinsEarned)> ClaimRewardAsync(int userId, int userQuestId)
    {
        var uq = await _context.UserQuests
            .Include(uq => uq.Quest)
            .FirstOrDefaultAsync(uq => uq.Id == userQuestId && uq.UserId == userId);

        if (uq == null)
            return (false, "Quest nicht gefunden.", 0, 0);

        if (!uq.IsCompleted)
            return (false, "Quest ist noch nicht abgeschlossen.", 0, 0);

        if (uq.IsRewardClaimed)
            return (false, "Belohnung wurde bereits eingefordert.", 0, 0);

        // Belohnung auszahlen
        var user = await _context.Users
            .Include(u => u.Avatar)
            .SingleAsync(u => u.Id == userId);

        if (uq.Quest.XpReward > 0)
            await _userService.AddXpAndHandleLevelUp(user, uq.Quest.XpReward);

        if (uq.Quest.CoinReward > 0)
            await _userService.AddCoinsAsync(user, uq.Quest.CoinReward, $"Quest: {uq.Quest.Name}");

        uq.IsRewardClaimed = true;
        await _context.SaveChangesAsync();

        return (true, $"Belohnung erhalten: +{uq.Quest.XpReward} XP, +{uq.Quest.CoinReward} Coins!", uq.Quest.XpReward, uq.Quest.CoinReward);
    }

    /// <summary>
    /// Nach einem Exercise-Log den Fortschritt ALLER aktiven Quests des Users aktualisieren.
    /// </summary>
    public async Task UpdateQuestProgressAsync(int userId)
    {
        await EnsureUserQuestsAsync(userId);
        await RecalculateAllProgressAsync(userId);
    }

    /// <summary>
    /// Quest-Statistiken für den User (abgeschlossen, aktiv, verdiente XP).
    /// </summary>
    public async Task<(int completed, int active, int totalXpEarned)> GetStatsAsync(int userId)
    {
        var allUserQuests = await _context.UserQuests
            .Include(uq => uq.Quest)
            .Where(uq => uq.UserId == userId)
            .ToListAsync();

        var completed = allUserQuests.Count(uq => uq.IsRewardClaimed);
        var totalXp = allUserQuests.Where(uq => uq.IsRewardClaimed).Sum(uq => uq.Quest.XpReward);

        var currentQuests = allUserQuests.Where(uq =>
        {
            var period = GetPeriodStart(uq.Quest.Type);
            return uq.PeriodStart == period && !uq.IsCompleted;
        }).Count();

        return (completed, currentQuests, totalXp);
    }

    // ─── Private Helpers ───

    /// <summary>
    /// Stellt sicher, dass der User für die aktuelle Periode UserQuest-Einträge hat.
    /// Erstellt neue Einträge für neue Perioden.
    /// </summary>
    private async Task EnsureUserQuestsAsync(int userId)
    {
        var allQuests = await _context.Quests.ToListAsync();
        var existingUserQuests = await _context.UserQuests
            .Where(uq => uq.UserId == userId)
            .ToListAsync();

        var changed = false;

        foreach (var quest in allQuests)
        {
            var currentPeriod = GetPeriodStart(quest.Type);

            var existing = existingUserQuests.FirstOrDefault(uq =>
                uq.QuestId == quest.Id && uq.PeriodStart == currentPeriod);

            if (existing == null)
            {
                _context.UserQuests.Add(new UserQuest(userId, quest.Id, currentPeriod));
                changed = true;
            }
        }

        if (changed)
            await _context.SaveChangesAsync();
    }

    /// <summary>
    /// Berechnet den Fortschritt aller nicht-abgeschlossenen Quests aus UserExerciseLogs und ActivityLogs.
    /// </summary>
    private async Task RecalculateAllProgressAsync(int userId)
    {
        var activeQuests = await _context.UserQuests
            .Include(uq => uq.Quest)
            .Where(uq => uq.UserId == userId && !uq.IsCompleted)
            .ToListAsync();

        if (activeQuests.Count == 0) return;

        var earliestPeriod = activeQuests.Min(uq => uq.PeriodStart);
        var startDate = DateOnly.FromDateTime(earliestPeriod);

        // Exercise-Logs laden
        var exerciseLogs = await _context.UserExerciseLogs
            .Where(l => l.UserId == userId && l.Date >= startDate)
            .Select(l => new { l.Date, l.Reps })
            .ToListAsync();

        // Activity-Logs laden (Schritte, Kilometer)
        var activityLogs = await _context.ActivityLogs
            .Where(a => a.UserId == userId && a.Date >= startDate)
            .Select(a => new { a.Date, a.Type, a.Value })
            .ToListAsync();

        foreach (var uq in activeQuests)
        {
            var periodStartDate = DateOnly.FromDateTime(uq.PeriodStart);
            var periodEndDate = DateOnly.FromDateTime(GetPeriodEnd(uq.Quest.Type, uq.PeriodStart));

            var periodExerciseLogs = exerciseLogs
                .Where(l => l.Date >= periodStartDate && l.Date < periodEndDate).ToList();

            var periodActivityLogs = activityLogs
                .Where(a => a.Date >= periodStartDate && a.Date < periodEndDate).ToList();

            uq.Progress = uq.Quest.TargetType switch
            {
                QuestTargetType.ExercisesCompleted => periodExerciseLogs.Count,
                QuestTargetType.TotalReps => periodExerciseLogs.Sum(l => l.Reps),
                QuestTargetType.TrainingDays => periodExerciseLogs.Select(l => l.Date).Distinct().Count(),
                QuestTargetType.Steps => (int)periodActivityLogs
                    .Where(a => a.Type == ActivityType.Steps).Sum(a => a.Value),
                QuestTargetType.Kilometers => (int)periodActivityLogs
                    .Where(a => a.Type == ActivityType.Kilometers).Sum(a => a.Value),
                _ => 0
            };

            if (uq.Progress > uq.Quest.TargetValue)
                uq.Progress = uq.Quest.TargetValue;

            if (uq.Progress >= uq.Quest.TargetValue && !uq.IsCompleted)
            {
                uq.IsCompleted = true;
                uq.CompletedAt = DateTime.UtcNow;
            }
        }

        await _context.SaveChangesAsync();
    }

    /// <summary>
    /// Berechnet den Periodenstart (Mitternacht UTC) für einen QuestType.
    /// </summary>
    private static DateTime GetPeriodStart(QuestType type)
    {
        var today = DateTime.UtcNow.Date;

        return type switch
        {
            QuestType.Daily => today,
            QuestType.Weekly => today.AddDays(-((int)today.DayOfWeek + 6) % 7),
            QuestType.Monthly => new DateTime(today.Year, today.Month, 1, 0, 0, 0, DateTimeKind.Utc),
            _ => today
        };
    }

    /// <summary>
    /// Berechnet das Periodenende für einen QuestType.
    /// </summary>
    private static DateTime GetPeriodEnd(QuestType type, DateTime periodStart)
    {
        return type switch
        {
            QuestType.Daily => periodStart.AddDays(1),
            QuestType.Weekly => periodStart.AddDays(7),
            QuestType.Monthly => periodStart.AddMonths(1),
            _ => periodStart.AddDays(1)
        };
    }

    private static UserQuestDto MapToDto(UserQuest uq, DateTime now)
    {
        var periodEnd = GetPeriodEnd(uq.Quest.Type, uq.PeriodStart);
        var remaining = periodEnd - now;

        string timeLeft;
        if (remaining.TotalDays >= 1)
            timeLeft = $"{(int)remaining.TotalDays}d {remaining.Hours}h";
        else if (remaining.TotalHours >= 1)
            timeLeft = $"{(int)remaining.TotalHours}h";
        else if (remaining.TotalMinutes >= 1)
            timeLeft = $"{(int)remaining.TotalMinutes}min";
        else
            timeLeft = "< 1min";

        return new UserQuestDto
        {
            Id = uq.Id,
            QuestId = uq.Quest.Id,
            Name = uq.Quest.Name,
            Description = uq.Quest.Description,
            Type = uq.Quest.Type.ToString().ToLower(),
            Rarity = uq.Quest.Rarity.ToString(),
            TargetType = uq.Quest.TargetType.ToString(),
            Progress = uq.Progress,
            TargetValue = uq.Quest.TargetValue,
            XpReward = uq.Quest.XpReward,
            CoinReward = uq.Quest.CoinReward,
            IsCompleted = uq.IsCompleted,
            IsRewardClaimed = uq.IsRewardClaimed,
            TimeLeft = timeLeft
        };
    }
}
