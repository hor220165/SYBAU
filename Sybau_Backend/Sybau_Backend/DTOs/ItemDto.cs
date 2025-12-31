using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.DTOs;

public class ItemDto
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Description { get; set; }
    public ItemType Type { get; set; }
    public int Price { get; set; }
    public int XpBoostPercentage { get; set; }
    
}