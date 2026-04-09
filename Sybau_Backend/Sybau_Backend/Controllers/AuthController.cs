using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Sybau_Backend._Services;
using Sybau_Backend.DTOs;
using Sybau_Backend.Models;

namespace Sybau_Backend.Controllers
{
    [Route("[controller]")]
    [ApiController]
    [EnableRateLimiting("auth")]
    public class AuthController : ControllerBase
    {
        private readonly AuthService _authService;
        private readonly IConfiguration _config;

        public AuthController(AuthService authService,IConfiguration config)
        {
            _authService = authService;
            _config = config;
        }

        [HttpPost("login")] 
        public async Task<IActionResult> Login([FromBody] LoginDto dto)
        {
            try
            {
                var result = await _authService.LoginWithTokenAsync(dto.Email, dto.Password, _config);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return Unauthorized(new { message = ex.Message });
            }
        }

        [HttpPost("refresh-token")]
        public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenDto dto)
        {
            try
            {
                var result = await _authService.RefreshTokenAsync(dto.RefreshToken, _config);
                return Ok(result);
            }
            catch (Exception e)
            {
                return Unauthorized("Ungültiger Refresh Token.");
            }
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterDto dto)
        {
            try
            {
                var user = await _authService.RegisterAsync(dto.UserName, dto.Email, dto.Password);
                return CreatedAtAction("Register", new { id = user.Id }, new
                {
                    user.Id,
                    user.UserName,
                    user.Email
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}
