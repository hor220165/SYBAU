using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Models;

public class AvatarStage: BaseEntity<int>
{
    #pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    protected AvatarStage() { }
    #pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.

    public AvatarStage(string name, string? description, int minXp, int maxXp, string imageUrl, string? unlockRequirements = null)
    {
        if (string.IsNullOrWhiteSpace(name)) throw new ArgumentNullException(nameof(name));
        if (string.IsNullOrWhiteSpace(imageUrl)) throw new ArgumentNullException(nameof(imageUrl));

        Name = name;
        Description = description;
        MinXp = minXp;
        MaxXp = maxXp;
        ImageUrl = imageUrl;
        UnlockRequirements = unlockRequirements;
        CreatedAt = DateTime.UtcNow;
    }

    public string Name { get; set; }
    public string? Description { get; set; }
    public int MinXp { get; set; }
    public int MaxXp { get; set; }
    public string ImageUrl { get; set; }
    public string? UnlockRequirements { get; set; } // JSON string describing requirements
    public new DateTime CreatedAt { get; set; }

    public ICollection<Avatar> Avatars { get; set; } = new List<Avatar>();
}