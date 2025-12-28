using System.ComponentModel.DataAnnotations;

namespace Sybau_Backend.Models;

public class Avatar:BaseEntity<int>
{
#pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    protected Avatar() { }
#pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    
    public Avatar(AvatarTemplate template, int userId)
    {
        Name = template.Name;
        Level = template.LevelRequired;
        Experience = 0;
        UserId = userId;
        TemplateId = template.Id;
    }
    
    [Required]
    public string Name { get; set; }
    
    public int Level { get; set; }
    
    public int Experience { get; set; }
    public int UserId { get; set; }
    [Required]
    public User User { get; set; }
    
    public int TemplateId { get; set; }
    [Required]
    public AvatarTemplate Template { get; set; }
    // AnimationKey kann über Template im Frontend geladen werden
    public string GetAnimationKey() => Template.AnimationKey;
}