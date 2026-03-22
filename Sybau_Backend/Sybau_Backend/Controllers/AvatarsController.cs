using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
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
    public class AvatarsController : ControllerBase
    {
        private readonly FitnessDbContext _context;
        private readonly BodyStageService  _bodyStageService;
        
        public AvatarsController(FitnessDbContext context,  BodyStageService bodyStageService)
        {
            _context = context;
            _bodyStageService = bodyStageService;
        }
        // GET: api/<AvatarsController>
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Avatar>>> Get()
        {
            var avatars = await _context.Avatars.Select(a => new AvatarDto
            {
                Id = a.Id,
                UserId = a.UserId,
                Level = a.Level,
                BodyStage = _bodyStageService.GetBodyStage(a.Level),
                Experience = a.Experience,
                Boost1 = a.Boost1,
                Boost2 = a.Boost2,
                Boost3 = a.Boost3,
                Boost4 = a.Boost4,
            }).ToListAsync();
            return Ok(avatars);
        }


        // GET api/<AvatarsController>/5
        [HttpGet("{id}")]
        public async Task<ActionResult<AvatarDto>> Get(int id)
        {
            var avatar = await _context.Avatars
                .Where(a => a.Id == id)
                .Select(a => new AvatarDto
                {
                    Id = a.Id,
                    UserId = a.UserId,
                    Level = a.Level,
                    BodyStage = _bodyStageService.GetBodyStage(a.Level),
                    Experience = a.Experience,
                    Boost1 = a.Boost1,
                    Boost2 = a.Boost2,
                    Boost3 = a.Boost3,
                    Boost4 = a.Boost4,
                }).FirstOrDefaultAsync();
            
            if (avatar == null) return NotFound();
            return Ok(avatar);
        }


        // POST api/<AvatarsController>/create
        [Authorize(Policy = "AdminOnly")]
        [HttpPost("create")]
        public async Task<ActionResult<AvatarDto>> Create()
        {
            var avatar = Avatar.CreateDefault();
            
            _context.Avatars.Add(avatar);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(Get), new { id = avatar.Id }, avatar);
        }

        // PUT api/<AvatarsController>/5
        [Authorize(Policy = "AdminOnly")]
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] AvatarDto dto)
        {
            var avatar = await _context.Avatars.FindAsync(id);
            if (avatar == null) return NotFound();

            if (dto.Level.HasValue)
                avatar.Level = dto.Level.Value;
            avatar.Experience = dto.Experience;
            
            await _context.SaveChangesAsync();
            return NoContent();
        }

        // DELETE api/<AvatarsController>/5
        [Authorize(Policy = "AdminOnly")]
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var avatar = await _context.Avatars.FindAsync(id);
            if (avatar == null) return NotFound();

            _context.Avatars.Remove(avatar);
            await _context.SaveChangesAsync();

            return NoContent();
        }
    }
}
