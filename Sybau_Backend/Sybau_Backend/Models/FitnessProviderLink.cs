using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Models;

public class FitnessProviderLink: BaseEntity<int>
{
    #pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    protected FitnessProviderLink() { }
    #pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.

    public FitnessProviderLink(User user, FitnessProviderType providerType, string providerUserId)
    {
        if (string.IsNullOrWhiteSpace(providerUserId)) throw new ArgumentNullException(nameof(providerUserId));

        User = user;
        UserId = user.Id;
        ProviderType = providerType;
        ProviderUserId = providerUserId;
        CreatedAt = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
    }

    public int UserId { get; set; }
    public User User { get; set; }
    
    public FitnessProviderType ProviderType { get; set; }
    public string ProviderUserId { get; set; }
    public string? AccessToken { get; set; }
    public string? RefreshToken { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public new DateTime CreatedAt { get; set; }
    public new DateTime UpdatedAt { get; set; }
    public bool IsActive { get; set; } = true;
}

public enum FitnessProviderType
{
    GoogleFit,
    AppleHealth
}