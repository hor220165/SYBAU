using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Data;
using Sybau_Backend.DTOs;
using Sybau_Backend.Models;

namespace Sybau_Backend._Services;

public class FriendChallengeService
{
    private const double RewardBoostMultiplier = 1.25;
    private readonly FitnessDbContext _context;
    private readonly FriendService _friendService;
    private readonly UserService _userService;

    public FriendChallengeService(FitnessDbContext context, FriendService friendService, UserService userService)
    {
        _context = context;
        _friendService = friendService;
        _userService = userService;
    }

    // Challenge erstellen
    public async Task<(bool success, string message, FriendChallengeDto? challenge)> CreateChallengeAsync(
        int challengerId, CreateFriendChallengeDto dto)
    {
        // Prüfe ob Freundschaft besteht
        if (!await _friendService.AreFriendsAsync(challengerId, dto.OpponentId))
            return (false, "Ihr seid nicht befreundet.", null);

        var challenger = await _context.Users.FindAsync(challengerId);
        var opponent = await _context.Users.FindAsync(dto.OpponentId);

        if (challenger == null || opponent == null)
            return (false, "Benutzer nicht gefunden.", null);

        if (dto.DurationHours < 1 || dto.DurationHours > 168) // max 7 Tage
            return (false, "Dauer muss zwischen 1 und 168 Stunden liegen.", null);
        if (dto.GoalAmount < 1 || dto.GoalAmount > 1000000)
            return (false, "Ziel muss zwischen 1 und 10.000 liegen.", null);

        var normalizedUnit = NormalizeGoalUnit(dto.GoalUnit);
        if (normalizedUnit == null)
            return (false, "Einheit muss reps, time oder distance sein.", null);

        var normalizedGoalAmount = NormalizeGoalAmount(dto.GoalAmount, normalizedUnit);
        if (normalizedGoalAmount < 1)
            return (false, "Ziel muss mindestens 1 sein.", null);

        var (xpReward, coinReward) = CalculateRewards(normalizedGoalAmount, normalizedUnit);

        var friendChallenge = new FriendChallenge(
            challenger, opponent,
            dto.Title, dto.Description,
            xpReward, coinReward,
            normalizedGoalAmount,
            normalizedUnit,
            DateTime.UtcNow.AddHours(dto.DurationHours));

        _context.FriendChallenges.Add(friendChallenge);
        await _context.SaveChangesAsync();

        return (true, "Challenge gesendet.", MapToDto(friendChallenge));
    }

    // Challenge annehmen
    public async Task<(bool success, string message)> AcceptChallengeAsync(int challengeId, int userId)
    {
        var challenge = await _context.FriendChallenges
            .Include(fc => fc.Challenger)
            .Include(fc => fc.Opponent)
            .FirstOrDefaultAsync(fc => fc.Id == challengeId && fc.OpponentId == userId);

        if (challenge == null)
            return (false, "Challenge nicht gefunden.");

        if (challenge.Status != FriendChallengeStatus.Pending)
            return (false, "Challenge ist nicht mehr offen.");

        challenge.Status = FriendChallengeStatus.Accepted;
        await _context.SaveChangesAsync();

        return (true, "Challenge angenommen!");
    }

    // Challenge ablehnen
    public async Task<(bool success, string message)> DeclineChallengeAsync(int challengeId, int userId)
    {
        var challenge = await _context.FriendChallenges
            .FirstOrDefaultAsync(fc => fc.Id == challengeId && fc.OpponentId == userId);

        if (challenge == null)
            return (false, "Challenge nicht gefunden.");

        if (challenge.Status != FriendChallengeStatus.Pending)
            return (false, "Challenge ist nicht mehr offen.");

        challenge.Status = FriendChallengeStatus.Declined;
        await _context.SaveChangesAsync();

        return (true, "Challenge abgelehnt.");
    }

    // Fortschritt aktualisieren (amount = tatsächliche Einheiten addieren)
    public async Task<(bool success, string message)> UpdateProgressAsync(int challengeId, int userId, int amount)
    {
        if (amount < 1)
            return (false, "Menge muss mindestens 1 sein.");

        var challenge = await _context.FriendChallenges
            .Include(fc => fc.Challenger).ThenInclude(u => u.Avatar)
            .Include(fc => fc.Opponent).ThenInclude(u => u.Avatar)
            .FirstOrDefaultAsync(fc => fc.Id == challengeId);

        if (challenge == null)
            return (false, "Challenge nicht gefunden.");

        if (challenge.Status != FriendChallengeStatus.Accepted)
            return (false, "Challenge ist nicht aktiv.");

        if (challenge.ExpiresAt < DateTime.UtcNow)
        {
            challenge.Status = FriendChallengeStatus.Expired;
            await _context.SaveChangesAsync();
            return (false, "Challenge ist abgelaufen.");
        }

        if (challenge.ChallengerId != userId && challenge.OpponentId != userId)
            return (false, "Du bist nicht Teil dieser Challenge.");

        // Fortschritt addieren (nicht ersetzen)
        if (challenge.ChallengerId == userId)
            challenge.ChallengerProgress += amount;
        else
            challenge.OpponentProgress += amount;

        var currentProgress = challenge.ChallengerId == userId
            ? challenge.ChallengerProgress
            : challenge.OpponentProgress;

        // Prüfe ob jemand das Ziel erreicht hat
        if (currentProgress >= challenge.GoalAmount)
        {
            challenge.Status = FriendChallengeStatus.Completed;
            challenge.CompletedAt = DateTime.UtcNow;
            challenge.WinnerId = userId;

            // Belohnungen verteilen – User explizit neu laden für sauberes Tracking
            var winner = await _context.Users
                .Include(u => u.Avatar)
                .Include(u => u.UserCoins)
                .FirstAsync(u => u.Id == userId);

            if (challenge.XpReward > 0)
                await _userService.AddXpAndHandleLevelUp(winner, challenge.XpReward);

            if (challenge.CoinReward > 0)
                await _userService.AddCoinsAsync(winner, challenge.CoinReward, "Freundes-Challenge gewonnen");
        }

        await _context.SaveChangesAsync();

        if (currentProgress >= challenge.GoalAmount)
            return (true, $"Challenge gewonnen! +{challenge.XpReward} XP, +{challenge.CoinReward} Coins erhalten.");

        return (true, $"Fortschritt: {currentProgress}/{challenge.GoalAmount}");
    }

    // Alle Challenges eines Users abrufen
    public async Task<IEnumerable<FriendChallengeDto>> GetUserChallengesAsync(int userId)
    {
        var challenges = await _context.FriendChallenges
            .Include(fc => fc.Challenger)
            .Include(fc => fc.Opponent)
            .Include(fc => fc.Winner)
            .Where(fc =>
                (fc.ChallengerId == userId && fc.ChallengerHiddenAt == null) ||
                (fc.OpponentId == userId && fc.OpponentHiddenAt == null))
            .OrderByDescending(fc => fc.CreatedAt)
            .ToListAsync();

        // Abgelaufene Challenges automatisch markieren
        foreach (var c in challenges.Where(c =>
            c.Status == FriendChallengeStatus.Accepted && c.ExpiresAt < DateTime.UtcNow))
        {
            c.Status = FriendChallengeStatus.Expired;
        }
        await _context.SaveChangesAsync();

        return challenges.Select(MapToDto);
    }

    // Offene Challenge-Einladungen
    public async Task<IEnumerable<FriendChallengeDto>> GetPendingChallengesAsync(int userId)
    {
        var challenges = await _context.FriendChallenges
            .Include(fc => fc.Challenger)
            .Include(fc => fc.Opponent)
            .Where(fc =>
                fc.OpponentId == userId &&
                fc.OpponentHiddenAt == null &&
                fc.Status == FriendChallengeStatus.Pending)
            .OrderByDescending(fc => fc.CreatedAt)
            .ToListAsync();

        return challenges.Select(MapToDto);
    }

    public async Task<(bool success, string message)> DeleteChallengeAsync(int challengeId, int userId)
    {
        var challenge = await _context.FriendChallenges
            .FirstOrDefaultAsync(fc => fc.Id == challengeId);

        if (challenge == null)
            return (false, "Challenge nicht gefunden.");

        if (challenge.ChallengerId != userId && challenge.OpponentId != userId)
            return (false, "Du darfst diese Challenge nicht ausblenden.");

        if (challenge.Status == FriendChallengeStatus.Accepted && challenge.ExpiresAt < DateTime.UtcNow)
        {
            challenge.Status = FriendChallengeStatus.Expired;
        }

        var hiddenAt = DateTime.UtcNow;
        if (challenge.ChallengerId == userId)
            challenge.ChallengerHiddenAt ??= hiddenAt;
        else
            challenge.OpponentHiddenAt ??= hiddenAt;

        await _context.SaveChangesAsync();
        return (true, "Challenge ausgeblendet.");
    }

    private static FriendChallengeDto MapToDto(FriendChallenge fc) => new()
    {
        Id = fc.Id,
        Title = fc.Title,
        Description = fc.Description,
        XpReward = fc.XpReward,
        CoinReward = fc.CoinReward,
        Status = fc.Status.ToString(),
        GoalAmount = fc.GoalAmount,
        GoalUnit = fc.GoalUnit,
        ExpiresAt = fc.ExpiresAt,
        CreatedAt = fc.CreatedAt,
        CompletedAt = fc.CompletedAt,
        ChallengerId = fc.ChallengerId,
        ChallengerUserName = fc.Challenger?.UserName ?? "",
        ChallengerProgress = fc.ChallengerProgress,
        ChallengerHiddenAt = fc.ChallengerHiddenAt,
        OpponentId = fc.OpponentId,
        OpponentUserName = fc.Opponent?.UserName ?? "",
        OpponentProgress = fc.OpponentProgress,
        OpponentHiddenAt = fc.OpponentHiddenAt,
        WinnerId = fc.WinnerId,
        WinnerUserName = fc.Winner?.UserName
    };

    private static string? NormalizeGoalUnit(string? rawUnit)
    {
        var normalized = rawUnit?.Trim().ToLowerInvariant();
        return normalized switch
        {
            "reps" or "rep" => "reps",
            "time" or "seconds" or "sek" or "sec" => "time",
            "distance" or "meter" or "m" => "m",
            "km" => "km",
            _ => null
        };
    }

    private static (int xpReward, int coinReward) CalculateRewards(int goalAmount, string goalUnit)
    {
        var baseXp = goalUnit switch
        {
            "time" => Math.Max(20, goalAmount / 3),
            "m" or "km" or "distance" => Math.Max(25, goalAmount / 12),
            _ => Math.Max(15, (int)Math.Round(goalAmount * 0.45))
        };

        var baseCoins = goalUnit switch
        {
            "time" => Math.Max(4, goalAmount / 45),
            "m" or "km" or "distance" => Math.Max(5, goalAmount / 180),
            _ => Math.Max(3, (int)Math.Round(goalAmount * 0.09))
        };

        var boostedXp = (int)Math.Ceiling(baseXp * RewardBoostMultiplier);
        var boostedCoins = (int)Math.Ceiling(baseCoins * RewardBoostMultiplier);

        return (boostedXp, boostedCoins);
    }

    private static int NormalizeGoalAmount(int goalAmount, string goalUnit)
    {
        return goalAmount;
    }
}
