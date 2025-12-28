using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Data;
using Sybau_Backend.DTOs;
using Sybau_Backend.Models;

namespace Sybau_Backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly FitnessDbContext _context;
        private readonly PasswordHasher<User> _passwordHasher;

        public AuthController(FitnessDbContext context)
        {
            _context = context;
            _passwordHasher = new PasswordHasher<User>();
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginDto dto)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == dto.Email);
            if (user == null) return Unauthorized("Email is incorrect");

            var result = _passwordHasher.VerifyHashedPassword(user, user.PasswordHash, dto.Password);

            if (result == PasswordVerificationResult.Failed) return Unauthorized("Invalid password");

            return Ok(new
            {
                user.Id,
                user.FirstName,
                user.Email
            });
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterDto dto)
        {
            bool emailExists =  await _context.Users.AnyAsync(u => u.Email == dto.Email);
            if (emailExists) return BadRequest("Email is already in use");

            // Dummy-User für Hash (wird nicht gespeichert!)
            var tempUser = new User(dto.UserName, null,null,dto.Email,"tempHash");
            
            // Passwort hashen
            var passwordHash = _passwordHasher.HashPassword(tempUser, dto.Password);
            
            // Richtigen User erstellen und direkt auch Avatar erstellen
            var user = new User(dto.UserName,null,null,dto.Email,passwordHash);
            
            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            
            return CreatedAtAction("Register", new { id = user.Id },
                new
            {
                user.Id,
                user.UserName,
                user.Email
            });
        }
    }
}
