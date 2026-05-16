namespace Sybau_Backend.DTOs;

public class UpdateUserDto
{
    public string? Username { get; set; }
    public string? Email { get; set; }
    public int? Coins { get; set; }
    public bool? IsProfilePrivate { get; set; }
    public AvatarDto? Avatar { get; set; }
}
