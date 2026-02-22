using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sybau_Backend._Services;
using Sybau_Backend.DTOs;
using Sybau_Backend.Models;

namespace Sybau_Backend.Controllers;

[Route("[controller]s")]
[ApiController]
public class ChallengeController : ControllerBase
{
    private readonly ChallengeService _challengeService;

    public ChallengeController(ChallengeService challengeService)
    {
        _challengeService = challengeService;
    }

    [HttpGet("")]
    public async Task<IActionResult> GetAllChallenges()
    {
        var challenges = await _challengeService.GetAllChallenges();
        return Ok(challenges);
    }

    [HttpGet("user/{userId}")]
    public async Task<IActionResult> GetUserChallenges(int userId)
    {
        var challenges = await _challengeService.GetUserChallengesAsync(userId);
        return Ok(challenges.Select(uc => new
        {
            uc.Challenge.Name,
            uc.Progress,
            uc.Completed,
            uc.CompletedAt
        }));
    }
    
    [Authorize(Policy = "AdminOnly")]
    [HttpPost("add")]
    public async Task<IActionResult> Add([FromBody] ChallengeDto dto)
    {
        var challenge = await _challengeService.CreateChallenge(dto);
        return Ok(challenge);
    }

}
