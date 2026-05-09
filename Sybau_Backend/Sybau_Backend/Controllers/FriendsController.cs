using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sybau_Backend._Services;
using Sybau_Backend.DTOs;

namespace Sybau_Backend.Controllers;

[Route("[controller]")]
[ApiController]
[Authorize]
public class FriendsController : ControllerBase
{
    private readonly FriendService _friendService;
    private readonly FriendChallengeService _friendChallengeService;

    public FriendsController(FriendService friendService, FriendChallengeService friendChallengeService)
    {
        _friendService = friendService;
        _friendChallengeService = friendChallengeService;
    }

    private int? GetUserId()
    {
        var claim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return claim != null ? int.Parse(claim) : null;
    }

    // ───── FREUNDSCHAFTEN ─────

    // GET /friends
    [HttpGet]
    public async Task<IActionResult> GetFriends()
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var friends = await _friendService.GetFriendsAsync(userId.Value);
        return Ok(friends);
    }

    // GET /friends/requests
    [HttpGet("requests")]
    public async Task<IActionResult> GetPendingRequests()
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var requests = await _friendService.GetPendingRequestsAsync(userId.Value);
        return Ok(requests);
    }

    // GET /friends/requests/sent
    [HttpGet("requests/sent")]
    public async Task<IActionResult> GetSentRequests()
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var requests = await _friendService.GetSentRequestsAsync(userId.Value);
        return Ok(requests);
    }

    // POST /friends/request
    [HttpPost("request")]
    public async Task<IActionResult> SendFriendRequest([FromBody] SendFriendRequestDto dto)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var (success, message) = await _friendService.SendFriendRequestAsync(userId.Value, dto.UserName);
        if (!success) return BadRequest(new { message });

        return Ok(new { message });
    }

    // POST /friends/requests/{id}/accept
    [HttpPost("requests/{id}/accept")]
    public async Task<IActionResult> AcceptRequest(int id)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var (success, message) = await _friendService.AcceptFriendRequestAsync(id, userId.Value);
        if (!success) return BadRequest(new { message });

        return Ok(new { message });
    }

    // POST /friends/requests/{id}/decline
    [HttpPost("requests/{id}/decline")]
    public async Task<IActionResult> DeclineRequest(int id)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var (success, message) = await _friendService.DeclineFriendRequestAsync(id, userId.Value);
        if (!success) return BadRequest(new { message });

        return Ok(new { message });
    }

    // DELETE /friends/{id}
    [HttpDelete("{id}")]
    public async Task<IActionResult> RemoveFriend(int id)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var (success, message) = await _friendService.RemoveFriendAsync(id, userId.Value);
        if (!success) return BadRequest(new { message });

        return Ok(new { message });
    }

    // GET /friends/leaderboard
    [HttpGet("leaderboard")]
    public async Task<IActionResult> GetFriendsLeaderboard()
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var leaderboard = await _friendService.GetFriendsLeaderboardAsync(userId.Value);
        return Ok(leaderboard);
    }

    // ───── FREUNDES-CHALLENGES ─────

    // GET /friends/challenges
    [HttpGet("challenges")]
    public async Task<IActionResult> GetChallenges()
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var challenges = await _friendChallengeService.GetUserChallengesAsync(userId.Value);
        return Ok(challenges);
    }

    // GET /friends/challenges/pending
    [HttpGet("challenges/pending")]
    public async Task<IActionResult> GetPendingChallenges()
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var challenges = await _friendChallengeService.GetPendingChallengesAsync(userId.Value);
        return Ok(challenges);
    }

    // POST /friends/challenges
    [HttpPost("challenges")]
    public async Task<IActionResult> CreateChallenge([FromBody] CreateFriendChallengeDto dto)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var (success, message, challenge) = await _friendChallengeService.CreateChallengeAsync(userId.Value, dto);
        if (!success) return BadRequest(new { message });

        return Ok(new { message, challenge });
    }

    // POST /friends/challenges/{id}/accept
    [HttpPost("challenges/{id}/accept")]
    public async Task<IActionResult> AcceptChallenge(int id)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var (success, message) = await _friendChallengeService.AcceptChallengeAsync(id, userId.Value);
        if (!success) return BadRequest(new { message });

        return Ok(new { message });
    }

    // POST /friends/challenges/{id}/decline
    [HttpPost("challenges/{id}/decline")]
    public async Task<IActionResult> DeclineChallenge(int id)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var (success, message) = await _friendChallengeService.DeclineChallengeAsync(id, userId.Value);
        if (!success) return BadRequest(new { message });

        return Ok(new { message });
    }

    // PUT /friends/challenges/{id}/progress
    [HttpPut("challenges/{id}/progress")]
    public async Task<IActionResult> UpdateProgress(int id, [FromBody] UpdateFriendChallengeProgressDto dto)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var (success, message) = await _friendChallengeService.UpdateProgressAsync(id, userId.Value, dto.Amount);
        if (!success) return BadRequest(new { message });

        return Ok(new { message });
    }

    // DELETE /friends/challenges/{id}
    [HttpDelete("challenges/{id}")]
    public async Task<IActionResult> DeleteChallenge(int id)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var (success, message) = await _friendChallengeService.DeleteChallengeAsync(id, userId.Value);
        if (!success) return BadRequest(new { message });

        return Ok(new { message });
    }
}
