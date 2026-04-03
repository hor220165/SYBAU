using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sybau_Backend._Services;
using Sybau_Backend.Data;
using Sybau_Backend.DTOs;
using Sybau_Backend.Models;

namespace Sybau_Backend.Controllers
{
    [Route("[controller]")]
    [ApiController]
    public class UsersController : ControllerBase
    {
        private readonly UserService _userService;
        private readonly BodyStageService _bodyStageService;
        private readonly AvatarService _avatarService;

        public UsersController(UserService userService, BodyStageService bodyStageService, AvatarService avatarService)
        {
            _userService = userService;
            _bodyStageService = bodyStageService;
            _avatarService = avatarService;
        }
        
        // GET /users/profile
        [Authorize]
        [HttpGet("profile")]
        public async Task<IActionResult> GetProfile()
        {
            // UserId aus JWT Claims lesen
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var user = await _userService.GetUserById(userId);

            if (user == null) return NotFound();

            // Optional: Avatar, Boosts etc.
            var avatarDto = new AvatarDto
            {
                Id = user.Avatar.Id,
                Level = user.Avatar.Level,
                Experience = user.Avatar.Experience,
                BodyStage = _bodyStageService.GetBodyStage(user.Avatar.Level),
                XpForNextLevel = _avatarService.XpForNextLevel(user.Avatar.Level),
                Boost1 = user.Avatar.Boost1,
                Boost2 = user.Avatar.Boost2,
                Boost3 = user.Avatar.Boost3,
                Boost4 = user.Avatar.Boost4
            };

            return Ok(new UserDto
            {
                Id = user.Id,
                UserName = user.UserName,
                Email = user.Email,
                Coins = user.Coins,
                Avatar = avatarDto,
                IsAdmin = user.IsAdmin,
            });
        }
        
        // PUT /users/profile
        [Authorize]
        [HttpPut("profile")]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateUserDto dto)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var user = await _userService.GetUserById(userId);
            if (user == null) return NotFound();

            if (!string.IsNullOrEmpty(dto.Username))
                user.UserName = dto.Username;

            await _userService.UpdateUserAsync(user);

            return NoContent();
        }
        
        [Authorize]
        [HttpPost("profile/change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordDto dto)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var user = await _userService.GetUserById(userId);
            if (user == null) return NotFound();

            var passwordHasher = new PasswordHasher<User>();
            var result = passwordHasher.VerifyHashedPassword(user, user.PasswordHash, dto.OldPassword);

            if (result != PasswordVerificationResult.Success)
                return BadRequest("Altes Passwort ist falsch.");

            // Neues Passwort hashen
            user.PasswordHash = passwordHasher.HashPassword(user, dto.NewPassword);
            await _userService.UpdateUserAsync(user);

            return NoContent(); // 204 OK ohne Body
        }
        
        [Authorize]
        [HttpDelete("profile")]
        public async Task<IActionResult> DeleteAccount()
        {
            // UserId aus JWT Claims lesen
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var user = await _userService.GetUserById(userId);
            if (user == null) return NotFound();

            // User löschen
            await _userService.DeleteUserAsync(userId);

            return NoContent(); // 204 OK
        }
      
        
        [HttpGet("leaderboard")]
        public async Task<IActionResult> GetLeaderboard()
        {
            var topUsers = await _userService.GetLeaderboard();
            return Ok(topUsers);
        }

        // GET /users/profile/streaks
        [Authorize]
        [HttpGet("profile/streaks")]
        public async Task<IActionResult> GetStreaks()
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var (longestStreak, currentStreak) = await _userService.GetStreaksAsync(userId);

            return Ok(new { longestStreak, currentStreak });
        }

        // GET /users/profile/weekly-activity?from=2026-03-23&to=2026-03-29
        [Authorize]
        [HttpGet("profile/weekly-activity")]
        public async Task<IActionResult> GetWeeklyActivity([FromQuery] DateOnly from, [FromQuery] DateOnly to)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var activities = await _userService.GetWeeklyActivityAsync(userId, from, to);

            return Ok(activities);
        }

        // GET /users/profile/recent-activities?limit=10
        [Authorize]
        [HttpGet("profile/recent-activities")]
        public async Task<IActionResult> GetRecentActivities([FromQuery] int limit = 10)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var activities = await _userService.GetRecentActivitiesAsync(userId, limit);

            return Ok(activities);
        }

        // GET: api/<UsersController>
        [Authorize]
        [HttpGet]
        public async Task<IActionResult> GetUsers()
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (userIdClaim == null)
                return Unauthorized();

            var currentUserId = int.Parse(userIdClaim);
            
            var users = await _userService.GetUsersExcept(currentUserId);
            return Ok(users.Select(u => new UserDto
            {
                Id = u.Id,
                UserName = u.UserName,
                Email = u.Email,
                Coins = u.Coins,
                IsAdmin = u.IsAdmin,
                Avatar = new AvatarDto
                {
                    Id = u.Avatar.Id,
                    Level = u.Avatar.Level,
                    Experience = u.Avatar.Experience,
                    BodyStage = _bodyStageService.GetBodyStage(u.Avatar.Level),
                    XpForNextLevel = _avatarService.XpForNextLevel(u.Avatar.Level),
                    Boost1 = u.Avatar.Boost1,
                    Boost2 = u.Avatar.Boost2,
                    Boost3 = u.Avatar.Boost3,
                    Boost4 = u.Avatar.Boost4
                }
            }));
        }


        // GET api/<UsersController>/5
        [Authorize]
        [HttpGet("{id}")]
        public async Task<ActionResult<UserDto>> GetById(int id)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null)
                return Unauthorized();

            var currentUserId = int.Parse(userIdClaim);
            var isAdmin = User.HasClaim("isAdmin", "True");

            if (currentUserId != id && !isAdmin)
                return Forbid();

            var user = await _userService.GetUserById(id);

            if (user == null)
                return NotFound();
            
            var avatarDto = new AvatarDto{Id = user.Avatar.Id,Level = user.Avatar.Level,Experience = user.Avatar.Experience,XpForNextLevel = _avatarService.XpForNextLevel(user.Avatar.Level),Boost1 = user.Avatar.Boost1,Boost2 = user.Avatar.Boost2,Boost3 = user.Avatar.Boost3,Boost4 = user.Avatar.Boost4,BodyStage = _bodyStageService.GetBodyStage(user.Avatar.Level)};

            return Ok(new UserDto
            {
                Id = user.Id,
                UserName = user.UserName,
                Email = user.Email,
                Coins = user.Coins,
                Avatar = avatarDto,
                IsAdmin = user.IsAdmin
            });
        }
        
        // POST: api/users/{userId}/challenge/{challengeId}/complete
        [Authorize]
        [HttpPost("{userId}/challenge/{challengeId}/complete")]
        public async Task<IActionResult> CompleteChallenge(int userId, int challengeId)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null)
                return Unauthorized();

            var currentUserId = int.Parse(userIdClaim);
            var isAdmin = User.HasClaim("isAdmin", "True");

            if (currentUserId != userId && !isAdmin)
                return Forbid();

            var updatedAvatar = await _userService.CompleteChallengeAsync(userId, challengeId);

            if (updatedAvatar == null)
                return BadRequest("User oder Challenge nicht gefunden");

            return Ok(updatedAvatar);
        }
        
        // GET /users/boosts - Gekaufte Booster-Items des Users
        [Authorize]
        [HttpGet("boosts")]
        public async Task<IActionResult> GetUserBoosters()
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var boosters = await _userService.GetUserBoostersAsync(userId);
            return Ok(boosters);
        }

        // PUT /users/boosts/slots - Booster in Slots equippen
        [Authorize]
        [HttpPut("boosts/slots")]
        public async Task<IActionResult> UpdateBoostSlots([FromBody] DTOs.UpdateBoostSlotsDto dto)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var success = await _userService.UpdateBoostSlotsAsync(userId, dto.Slots);

            if (!success)
                return BadRequest("Ungültige Booster-Konfiguration. Prüfe ob du die Items besitzt.");

            return Ok();
        }
    }
}

