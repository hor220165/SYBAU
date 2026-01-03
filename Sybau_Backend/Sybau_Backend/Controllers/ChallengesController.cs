using Microsoft.AspNetCore.Mvc;
using Sybau_Backend._Services;
using Sybau_Backend.DTOs;
using Sybau_Backend.Models;

namespace Sybau_Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class ChallengeController : ControllerBase
{
    private readonly ChallengeService _challengeService;

    public ChallengeController(ChallengeService challengeService)
    {
        _challengeService = challengeService;
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
    
    [HttpPost("add")]
    public async Task<IActionResult> Add([FromBody] ChallengeDto dto)
    {
        var challenge = _challengeService.CreateChallenge(dto);
        return Ok(challenge);
    }

}
