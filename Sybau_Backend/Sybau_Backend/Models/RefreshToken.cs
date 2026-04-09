using System;

namespace Sybau_Backend.Models;

public class RefreshToken : BaseEntity<int>
{
    #pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    protected RefreshToken() { }
    #pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.

    public RefreshToken(User user, string token, DateTime expiresAt)
    {
        User = user ?? throw new ArgumentNullException(nameof(user));
        Token = token ?? throw new ArgumentNullException(nameof(token));
        ExpiresAt = expiresAt;
        CreatedAt = DateTime.UtcNow;
    }

    public int UserId { get; set; }
    public User User { get; set; }
    
    public string Token { get; set; } // We'll store the hashed token for security
    public DateTime ExpiresAt { get; set; }
    public bool IsExpired => DateTime.UtcNow >= ExpiresAt;
    public bool IsRevoked { get; set; } = false;
    public DateTime? RevokedAt { get; set; }
    public string? ReplacedByToken { get; set; } // For token rotation
    public string? ReasonRevoked { get; set; } // Optional reason for revocation
}