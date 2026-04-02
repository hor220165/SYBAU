using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sybau_Backend._Services;

namespace Sybau_Backend.Controllers;

[Route("[controller]")]
[ApiController]
[Authorize]
public class AchievementsController : ControllerBase
{
    private readonly AchievementService _achievementService;

    public AchievementsController(AchievementService achievementService)
    {
        _achievementService = achievementService;
    }

    private int GetUserId() => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// <summary>
    /// Alle Achievements mit Unlock-Status für den aktuellen User.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var achievements = await _achievementService.GetUserAchievementsAsync(GetUserId());
        return Ok(achievements);
    }

    /// <summary>
    /// Profil-Statistiken: Workouts gesamt, Trainingszeit, Kalorien, Streak.
    /// </summary>
    [HttpGet("stats")]
    public async Task<IActionResult> GetStats()
    {
        var stats = await _achievementService.GetProfileStatsAsync(GetUserId());
        return Ok(stats);
    }

    /// <summary>
    /// Heutige XP (Basis, ohne Booster).
    /// </summary>
    [HttpGet("today-xp")]
    public async Task<IActionResult> GetTodayXp()
    {
        var userId = GetUserId();
        var todayXp = await _achievementService.GetTodayXpAsync(userId);
        var totalXp = await _achievementService.GetTotalXpAsync(userId);
        return Ok(new { todayXp, totalXp });
    }
}
