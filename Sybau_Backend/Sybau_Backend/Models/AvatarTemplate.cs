namespace Sybau_Backend.Models;

public class AvatarTemplate : BaseEntity<int>
{
#pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    protected AvatarTemplate(){}
#pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    
    public string Name { get; set; }
    public int LevelRequired { get; set; }
    public string AnimationKey {get; set;}
    
    public ICollection<Avatar> UserAvatars { get; set; } = new List<Avatar>();
}