using System.ComponentModel.DataAnnotations;
using Sybau_Backend.Validation;

namespace Sybau_Backend.DTOs;

public class LoginDto
{
    [Required]
    [EmailAddress]
    [NotDisposableEmail]
    public string Email { get; set; } = "";
    
    [Required]
    public string Password { get; set; } = "";
}
