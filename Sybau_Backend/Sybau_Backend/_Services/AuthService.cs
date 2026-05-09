using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;
using Sybau_Backend.Data;
using Sybau_Backend.Models;

namespace Sybau_Backend._Services;

public class AuthService
{
    private static readonly ConfigurationManager<OpenIdConnectConfiguration> GoogleOidcConfigurationManager =
        new(
            "https://accounts.google.com/.well-known/openid-configuration",
            new OpenIdConnectConfigurationRetriever(),
            new HttpDocumentRetriever { RequireHttps = true }
        );

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

        return CreateAuthResponse(user, config);
    }

    public async Task<object> LoginWithGoogleTokenAsync(string idToken, IConfiguration config)
    {
        var principal = await ValidateGoogleIdTokenAsync(idToken, config);
        var email = principal.FindFirstValue(ClaimTypes.Email) ?? principal.FindFirstValue("email");
        if (string.IsNullOrWhiteSpace(email))
            throw new Exception("Google Konto enthält keine E-Mail.");

        var givenName = principal.FindFirstValue("given_name");
        var familyName = principal.FindFirstValue("family_name");
        var fullName = principal.FindFirstValue("name");
        var picture = principal.FindFirstValue("picture");

        var user = await _context.Users
            .Include(u => u.Avatar)
            .FirstOrDefaultAsync(u => u.Email == email);

        if (user == null)
        {
            var desiredUserName = BuildGoogleUserName(fullName, givenName, email);
            var uniqueUserName = await EnsureUniqueUserNameAsync(desiredUserName);
            var randomSecret = Convert.ToHexString(RandomNumberGenerator.GetBytes(24));
            var tempUser = new User(uniqueUserName, givenName, familyName, email, "tempHash");
            var passwordHash = _passwordHasher.HashPassword(tempUser, randomSecret);

            user = new User(uniqueUserName, givenName, familyName, email, passwordHash)
            {
                ProfileImageUrl = picture
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            await _userService.AssignStartingChallengesAsync(user);
        }
        else
        {
            var changed = false;
            if (string.IsNullOrWhiteSpace(user.FirstName) && !string.IsNullOrWhiteSpace(givenName))
            {
                user.FirstName = givenName;
                changed = true;
            }
            if (string.IsNullOrWhiteSpace(user.LastName) && !string.IsNullOrWhiteSpace(familyName))
            {
                user.LastName = familyName;
                changed = true;
            }
            if (string.IsNullOrWhiteSpace(user.ProfileImageUrl) && !string.IsNullOrWhiteSpace(picture))
            {
                user.ProfileImageUrl = picture;
                changed = true;
            }

            if (changed)
            {
                await _context.SaveChangesAsync();
            }
        }

        return CreateAuthResponse(user, config);
    }

    public async Task<User?> LoginAsync(string email, string password)
    {
        var user = await _context.Users
            .Include(u => u.Avatar)
            .FirstOrDefaultAsync(u => u.Email == email);

        if (user == null)
            throw new Exception("Ungültige E-Mail oder Passwort.");

        var result = _passwordHasher.VerifyHashedPassword(user, user.PasswordHash, password);
        return result == PasswordVerificationResult.Success
            ? user
            : throw new Exception("Ungültige E-Mail oder Passwort.");
    }

    public async Task<User> RegisterAsync(string userName, string email, string password)
    {
        if (await _context.Users.AnyAsync(u => u.Email == email))
            throw new Exception("Diese E-Mail wird bereits verwendet.");

        if (string.IsNullOrWhiteSpace(userName))
            throw new Exception("Benutzername darf nicht leer sein.");

        if (string.IsNullOrWhiteSpace(password) || password.Length < 6)
            throw new Exception("Passwort muss mindestens 6 Zeichen lang sein.");

        var tempUser = new User(userName, null, null, email, "tempHash");
        var passwordHash = _passwordHasher.HashPassword(tempUser, password);

        var user = new User(userName, null, null, email, passwordHash);

        _context.Users.Add(user);
        await _context.SaveChangesAsync();
        
        await _userService.AssignStartingChallengesAsync(user);

        return user;
    }

    private object CreateAuthResponse(User user, IConfiguration config)
    {
        var token = GenerateJwtToken(user, config);

        return new
        {
            token,
            user = new
            {
                user.Id,
                user.UserName,
                user.Email,
                user.ProfileImageUrl,
                user.IsAdmin,
            }
        };
    }

    private async Task<ClaimsPrincipal> ValidateGoogleIdTokenAsync(string idToken, IConfiguration config)
    {
        var audiences = new[]
        {
            config["GoogleAuth:WebClientId"],
            config["GoogleAuth:AndroidClientId"],
            config["GoogleAuth:IosClientId"],
            config["GoogleAuth:ServerClientId"],
        }
        .Where(v => !string.IsNullOrWhiteSpace(v))
        .Distinct()
        .ToArray();

        if (audiences.Length == 0)
            throw new Exception("Google Login ist auf dem Server noch nicht konfiguriert.");

        var googleConfig = await GoogleOidcConfigurationManager.GetConfigurationAsync(CancellationToken.None);
        var validationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuers = new[] { "accounts.google.com", "https://accounts.google.com" },
            ValidateAudience = true,
            ValidAudiences = audiences,
            ValidateIssuerSigningKey = true,
            IssuerSigningKeys = googleConfig.SigningKeys,
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromMinutes(1),
        };

        var handler = new JwtSecurityTokenHandler();
        return handler.ValidateToken(idToken, validationParameters, out _);
    }

    private string BuildGoogleUserName(string? fullName, string? givenName, string email)
    {
        var baseName = !string.IsNullOrWhiteSpace(fullName)
            ? fullName
            : !string.IsNullOrWhiteSpace(givenName)
                ? givenName
                : email.Split('@')[0];

        var sanitized = new string(baseName.Where(ch => char.IsLetterOrDigit(ch) || ch == '_' || ch == '-').ToArray()).Trim();
        if (string.IsNullOrWhiteSpace(sanitized))
            sanitized = email.Split('@')[0];

        return sanitized.Length > 24 ? sanitized[..24] : sanitized;
    }

    private async Task<string> EnsureUniqueUserNameAsync(string baseName)
    {
        var candidate = baseName;
        var suffix = 1;
        while (await _context.Users.AnyAsync(u => u.UserName == candidate))
        {
            candidate = $"{baseName}{suffix}";
            if (candidate.Length > 24)
            {
                var trimmedBase = baseName[..Math.Min(baseName.Length, 24 - suffix.ToString().Length)];
                candidate = $"{trimmedBase}{suffix}";
            }
            suffix++;
        }

        return candidate;
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
            issuer: config["Jwt:Issuer"],
            audience: config["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddDays(30),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
