using System.ComponentModel.DataAnnotations;

namespace Sybau_Backend.Models;

public class Avatar:BaseEntity<int>
{
    [Required]
    public string Name { get; set; }
    
    public int Level { get; set; }
    
    public int Experience { get; set; }
}