using Microsoft.AspNetCore.Mvc;
using Sybau_Backend._Services;
using Sybau_Backend.DTOs;

namespace Sybau_Backend.Controllers
{
    [Route("[controller]")]
    [ApiController]
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
            catch (Exception e)
            {
                return Unauthorized(e.Message);
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
            catch (Exception e)
            {
                return BadRequest(e.Message);
            }
        }
    }
}
