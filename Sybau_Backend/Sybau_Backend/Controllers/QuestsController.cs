using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sybau_Backend._Services;

namespace Sybau_Backend.Controllers;

[ApiController]
[Route("[controller]")]
[Authorize]
public class QuestsController : ControllerBase
{
    private readonly QuestService _questService;

    public QuestsController(QuestService questService)
    {
        _questService = questService;
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

    private int? GetUserId()
    {
        var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return int.TryParse(claim, out var id) ? id : null;
    }
}
