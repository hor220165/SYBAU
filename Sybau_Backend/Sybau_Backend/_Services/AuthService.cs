using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Data;
using Sybau_Backend.Models;

namespace Sybau_Backend._Services;

public class AuthService
{
    private readonly FitnessDbContext _context;
    private readonly PasswordHasher<User> _passwordHasher;
    private readonly UserService _userService;
    
    public AuthService(FitnessDbContext context, UserService userService)
    {
        _context = context;
        _passwordHasher = new PasswordHasher<User>();
        _userService = userService;
    }

    public async Task<User?> LoginAsync(string email, string password)
    {
        var user = await _context.Users
            .Include(u => u.Avatar)
            .FirstOrDefaultAsync(u => u.Email == email);

        if (user == null) throw new Exception("Email not found");

        var result = _passwordHasher.VerifyHashedPassword(user, user.PasswordHash, password);
        return result == PasswordVerificationResult.Success ? user : throw new Exception("Invalid password");
    }

    public async Task<User> RegisterAsync(string userName, string email, string password)
    {
        if (await _context.Users.AnyAsync(u => u.Email == email))
            throw new Exception("Email is already in use");

        var tempUser = new User(userName, null, null, email, "tempHash");
        var passwordHash = _passwordHasher.HashPassword(tempUser, password);

        var user = new User(userName, null, null, email, passwordHash);

        _context.Users.Add(user);
        await _context.SaveChangesAsync();
        
        await _userService.AssignStartingChallengesAsync(user);

        return user;
    }
}