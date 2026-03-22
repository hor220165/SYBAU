using System.ComponentModel.DataAnnotations;

namespace Sybau_Backend.DTOs;

public class ChangePasswordDto
{
    [Required]
    public string OldPassword { get; set; } = string.Empty;
    
    [Required]
    [MinLength(4, ErrorMessage = "Neues Passwort muss mindestens 4 Zeichen lang sein.")]
    [MaxLength(128)]
    public string NewPassword { get; set; }  = string.Empty;
}