using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sybau_Backend._Services;
using Sybau_Backend.Data;
using Sybau_Backend.Models;
using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Controllers;

[ApiController]
[Route("[controller]")]
[Authorize]
public class QuestsController : ControllerBase
{
    private readonly QuestService _questService;
    private readonly FitnessDbContext _context;

    public QuestsController(QuestService questService, FitnessDbContext context)
    {
        _questService = questService;
        _context = context;
    }

    /// <summary>
    /// Alle aktiven Quests des eingeloggten Users laden.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetMyQuests()
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var quests = await _questService.GetUserQuestsAsync(userId.Value);
        return Ok(quests);
    }

    /// <summary>
    /// Statistiken: abgeschlossene Quests, aktive, gesamte XP.
    /// </summary>
    [HttpGet("stats")]
    public async Task<IActionResult> GetStats()
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var (completed, active, totalXp) = await _questService.GetStatsAsync(userId.Value);
        return Ok(new { completed, active, totalXpEarned = totalXp });
    }

    /// <summary>
    /// Belohnung für eine abgeschlossene Quest einfordern.
    /// </summary>
    [HttpPost("{userQuestId}/claim")]
    public async Task<IActionResult> ClaimReward(int userQuestId)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var (success, message, xpEarned, coinsEarned) = await _questService.ClaimRewardAsync(userId.Value, userQuestId);

        if (!success) return BadRequest(new { message });

        return Ok(new { message, xpEarned, coinsEarned });
    }

    /// <summary>
    /// Manuelle Aktivität loggen (Schritte oder Kilometer).
    /// </summary>
    [HttpPost("activity")]
    public async Task<IActionResult> LogActivity([FromBody] LogActivityRequest request)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        if (request.Value <= 0)
            return BadRequest(new { message = "Wert muss größer als 0 sein." });

        if (!Enum.TryParse<ActivityType>(request.Type, true, out var activityType))
            return BadRequest(new { message = "Ungültiger Aktivitätstyp. Erlaubt: Steps, Kilometers" });

        var log = new ActivityLog(userId.Value, activityType, request.Value);
        _context.ActivityLogs.Add(log);
        await _context.SaveChangesAsync();

        // Quest-Fortschritt aktualisieren
        await _questService.UpdateQuestProgressAsync(userId.Value);

        var unit = activityType == ActivityType.Steps ? "Schritte" : "km";
        return Ok(new { message = $"{request.Value:N0} {unit} erfolgreich eingetragen!" });
    }

    /// <summary>
    /// Heutige Activity-Zusammenfassung abrufen.
    /// </summary>
    [HttpGet("activity/today")]
    public async Task<IActionResult> GetTodayActivity()
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var logs = await _context.ActivityLogs
            .Where(a => a.UserId == userId.Value && a.Date == today)
            .ToListAsync();

        var steps = (int)logs.Where(a => a.Type == ActivityType.Steps).Sum(a => a.Value);
        var km = logs.Where(a => a.Type == ActivityType.Kilometers).Sum(a => a.Value);

        return Ok(new { steps, kilometers = Math.Round(km, 2) });
    }

    private int? GetUserId()
    {
        var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return int.TryParse(claim, out var id) ? id : null;
    }
}

public class LogActivityRequest
{
    public string Type { get; set; } = "";
    public double Value { get; set; }
}
