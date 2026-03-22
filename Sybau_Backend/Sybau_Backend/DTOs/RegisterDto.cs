using System.ComponentModel.DataAnnotations;

namespace Sybau_Backend.DTOs;

public class RegisterDto
{
    [Required]
    [MinLength(2)]
    [MaxLength(50)]
    public string UserName { get; set; } = "";
    
    [Required]
    [EmailAddress]
    [MaxLength(200)]
    public string Email { get; set; } = "";
    
    [Required]
    [MinLength(6, ErrorMessage = "Passwort muss mindestens 6 Zeichen lang sein.")]
    [MaxLength(128)]
    public string Password { get; set; } = "";
}