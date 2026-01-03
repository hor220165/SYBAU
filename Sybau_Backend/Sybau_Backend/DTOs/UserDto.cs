namespace Sybau_Backend.DTOs;

public class UserDto
{
    public int Id { get; set; }
    public string UserName { get; set; }
    public string Email { get; set; }
    public int Coins { get; set; }
    public AvatarDto Avatar { get; set; }
}
