using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
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
        
        public AvatarsController(FitnessDbContext context)
        {
            _context = context;
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
        [HttpPost("create")]
        public async Task<ActionResult<AvatarDto>> Create()
        {
            var avatar = Avatar.CreateDefault();
            
            _context.Avatars.Add(avatar);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(Get), new { id = avatar.Id }, avatar);
        }

        // PUT api/<AvatarsController>/5
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] Avatar avatar)
        {
            if (id != avatar.Id) return BadRequest();

            _context.Entry(avatar).State = EntityState.Modified;
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // DELETE api/<AvatarsController>/5
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
