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

        public AdminController(FitnessDbContext context, ChallengeService challengeService, UserService userService)
        {
            _context = context;
            _challengeService = challengeService;
            _userService = userService;
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
        public IActionResult DeleteUser(int id)
        {
            var user = _context.Users.Find(id);
            if (user == null) return NotFound();

            _context.Users.Remove(user);
            _context.SaveChanges();
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
