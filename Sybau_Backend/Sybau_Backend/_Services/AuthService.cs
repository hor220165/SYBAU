using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
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
    
    public async Task<object> LoginWithTokenAsync(string email, string password, IConfiguration config)
    {
        var user = await LoginAsync(email, password); // existierender Login-Flow

        var token = GenerateJwtToken(user, config);

        return new
        {
            token,
            user = new
            {
                user.Id,
                user.UserName,
                user.Email,
                user.IsAdmin,
            }
        };
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
    
    
    //JWT erzeugen
    public string GenerateJwtToken(User user, IConfiguration config)
    {
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Name, user.UserName),
            new Claim("isAdmin", user.IsAdmin.ToString())
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(config["Jwt:Key"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            claims: claims,
            expires: DateTime.UtcNow.AddDays(7),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}