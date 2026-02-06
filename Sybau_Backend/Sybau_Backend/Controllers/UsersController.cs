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

        public UsersController(UserService userService)
        {
            _userService = userService;
        }
        
        // GET /users/profile
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
                XpForNextLevel = user.Avatar.XpForNextLevel(),
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
                Avatar = avatarDto
            });
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

        // GET: api/<UsersController>
        [HttpGet]
        public async Task<IActionResult> Get()
        {
            var users = await _userService.GetUsers();
            return Ok(users);
        }
        
        [HttpGet("leaderboard")]
        public async Task<IActionResult> GetLeaderboard()
        {
            var topUsers = await _userService.GetLeaderboard();
            return Ok(topUsers);
        }



        // GET api/<UsersController>/5
        [HttpGet("{id}")]
        public async Task<ActionResult<UserDto>> GetById(int id)
        {
            var user = await _userService.GetUserById(id);

            if (user == null)
                return NotFound();
            
            var avatarDto = new AvatarDto{Id = user.Avatar.Id,Level = user.Avatar.Level,Experience = user.Avatar.Experience, Boost1 = user.Avatar.Boost1,Boost2 = user.Avatar.Boost2,Boost3 = user.Avatar.Boost3,Boost4 = user.Avatar.Boost4,};

            return Ok(new UserDto
            {
                Id = user.Id,
                UserName = user.UserName,
                Email = user.Email,
                Coins = user.Coins,
                Avatar = avatarDto
            });
        }
        
        // POST: api/users/{userId}/challenge/{challengeId}/complete
        [HttpPost("{userId}/challenge/{challengeId}/complete")]
        public async Task<IActionResult> CompleteChallenge(int userId, int challengeId)
        {
            var updatedAvatar = await _userService.CompleteChallengeAsync(userId, challengeId);

            if (updatedAvatar == null)
                return BadRequest("User oder Challenge nicht gefunden");

            return Ok(updatedAvatar);
        }
    }
}

