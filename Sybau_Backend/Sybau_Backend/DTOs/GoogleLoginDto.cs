using System.ComponentModel.DataAnnotations;

namespace Sybau_Backend.DTOs;

public class GoogleLoginDto
{
    [Required]
    public string IdToken { get; set; } = "";
}
