using System.ComponentModel.DataAnnotations;
using Sybau_Backend.Validation;

namespace Sybau_Backend.DTOs;

public class RegisterDto
{
    [Required]
    [MinLength(2)]
    [MaxLength(50)]
    public string UserName { get; set; } = "";
    
    [Required]
    [EmailAddress]
    [NotDisposableEmail]
    [MaxLength(200)]
    public string Email { get; set; } = "";
    
    [Required]
    [MinLength(AuthValidation.MinPasswordLength, ErrorMessage = AuthValidation.PasswordPolicyMessage)]
    [MaxLength(AuthValidation.MaxPasswordLength)]
    [StrongPassword]
    public string Password { get; set; } = "";
}
