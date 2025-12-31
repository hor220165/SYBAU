using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sybau_Backend._Services;
using Sybau_Backend.Data;
using Sybau_Backend.DTOs;
using Sybau_Backend.Models;

namespace Sybau_Backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UsersController : ControllerBase
    {
        private readonly UserService _userService;

        public UsersController(UserService userService)
        {
            _userService = userService;
        }

        // GET: api/<UsersController>
        [HttpGet]
        public async Task<IActionResult> Get()
        {
            var users = await _userService.GetUsers();
            return Ok(users);
        }


        // GET api/<UsersController>/5
        [HttpGet("{id}")]
        public async Task<ActionResult<UserDto>> GetById(int id)
        {
            var user = await _userService.GetUserById(id);

            if (user == null)
                return NotFound();
            
            var avatarDto = new AvatarDto{Level = user.Avatar.Level,Experience = user.Avatar.Experience, Boost1 = user.Avatar.Boost1,Boost2 = user.Avatar.Boost2,Boost3 = user.Avatar.Boost3,Boost4 = user.Avatar.Boost4,};

            return Ok(new UserDto
            {
                Id = user.Id,
                UserName = user.UserName,
                Email = user.Email,
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

