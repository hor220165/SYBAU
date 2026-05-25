using System.ComponentModel.DataAnnotations;
using Sybau_Backend.Validation;

namespace Sybau_Backend.DTOs;

public class ChangePasswordDto
{
    [Required]
    public string OldPassword { get; set; } = string.Empty;
    
    [Required]
    [MinLength(AuthValidation.MinPasswordLength, ErrorMessage = AuthValidation.PasswordPolicyMessage)]
    [MaxLength(AuthValidation.MaxPasswordLength)]
    [StrongPassword]
    public string NewPassword { get; set; }  = string.Empty;
}
