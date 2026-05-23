using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sybau_Backend._Services;
using Sybau_Backend.Data;
using Sybau_Backend.Models;
using Sybau_Backend.DTOs;

namespace Sybau_Backend.Controllers
{
    [ApiController]
    [Route("admin")]
    [Authorize(Policy = "AdminOnly")]
    public class AdminController : ControllerBase
    {
        private readonly FitnessDbContext _context;
        private readonly ChallengeService _challengeService;
        private readonly UserService _userService;
        private readonly MediaStorageService _mediaStorage;
        private readonly DataImageMigrationService _imageMigration;

        public AdminController(
            FitnessDbContext context,
            ChallengeService challengeService,
            UserService userService,
            MediaStorageService mediaStorage,
            DataImageMigrationService imageMigration)
        {
            _context = context;
            _challengeService = challengeService;
            _userService = userService;
            _mediaStorage = mediaStorage;
            _imageMigration = imageMigration;
        }

        [HttpPost("media/migrate-images")]
        public async Task<IActionResult> MigrateImages()
        {
            await _mediaStorage.EnsureReadyAsync(HttpContext.RequestAborted);
            if (!_mediaStorage.IsConfigured)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new
                {
                    error = "Media storage is not configured."
                });
            }

            var migrated = await _imageMigration.MigrateAsync();
            return Ok(new { migrated });
        }

        // ===== CHALLENGES =====
        [HttpPut("challenges/{id}")]
        public async Task<IActionResult> UpdateChallenge(int id, [FromBody] ChallengeDto dto)
        {
            var challenge = await _challengeService.UpdateChallenge(id,dto);
            return Ok(challenge);
        }

        [HttpDelete("challenges/{id}")]
        public async Task<IActionResult> DeleteChallenge(int id)
        {
            await _challengeService.DeleteChallenge(id);
            return NoContent();
        }

        // ===== SHOP ITEMS =====
        [HttpPost("items")]
        public IActionResult CreateShopItem([FromBody] ItemDto dto)
        {
            return Ok(dto);
        }

        [HttpPut("items/{id}")]
        public IActionResult UpdateShopItem(int id, [FromBody] ItemDto dto)
        {
            return Ok(dto);
        }

        [HttpDelete("items/{id}")]
        public IActionResult DeleteShopItem(int id)
        {
            return NoContent();
        }

        // ===== USERS =====
        [HttpPut("users/{id}/role")]
        public IActionResult UpdateUserRole(int id, [FromBody] UpdateUserRoleDto dto)
        {
            var user = _context.Users.Find(id);
            if (user == null) return NotFound();

            user.IsAdmin = dto.IsAdmin;
            _context.SaveChanges();
            return Ok(user);
        }

        [HttpPut("users/{id}")]
        public async Task<IActionResult> UpdateUserAsAdmin(int id, [FromBody] UpdateUserDto dto)
        {
            // Admin darf jeden User updaten
            var user = await _userService.GetUserById(id);
            if(user == null) return NotFound();

            await _userService.UpdateUserAsync(user, dto);
            return Ok(user);
        }

        [HttpDelete("users/{id}")]
        public async Task<IActionResult> DeleteUser(int id)
        {
            var userExists = await _context.Users.AnyAsync(u => u.Id == id);
            if (!userExists) return NotFound();

            await _userService.DeleteUserAsync(id);
            return NoContent();
        }

        [HttpGet("users/{id}/stats")]
        public IActionResult GetUserStats(int id)
        {
            var user = _context.Users.Include(u => u.Avatar).FirstOrDefault(u => u.Id == id);
            if (user == null) return NotFound();

            var stats = new
            {
                user.UserName,
                user.Coins,
                user.Avatar.Level,
                user.Avatar.Experience
            };
            return Ok(stats);
        }
    }
}
