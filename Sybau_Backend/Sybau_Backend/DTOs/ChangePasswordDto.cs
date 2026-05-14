using System.ComponentModel.DataAnnotations;

namespace Sybau_Backend.DTOs;

public class ChangePasswordDto
{
    [Required]
    public string OldPassword { get; set; } = string.Empty;
    
    [Required]
    [MinLength(6, ErrorMessage = "Neues Passwort muss mindestens 6 Zeichen lang sein.")]
    [MaxLength(128)]
    public string NewPassword { get; set; }  = string.Empty;
}
