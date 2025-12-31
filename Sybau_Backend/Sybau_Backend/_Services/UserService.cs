using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Data;
using Sybau_Backend.Models;

namespace Sybau_Backend._Services;

public class UserService
{
    private readonly FitnessDbContext _context;

    public UserService(FitnessDbContext context)
    {
        _context = context;
    }

    // Alle User der Datenbank ausgeben
    public async Task<IEnumerable<User>> GetUsers()
    {
        return await _context.Users.ToListAsync();
    }
    
    //Einen genauen User ausgeben
    public async Task<User?> GetUserById(int id)
    {
        return await _context.Users
            .Include(u => u.Avatar)
            .SingleOrDefaultAsync(u => u.Id == id);
    }
}