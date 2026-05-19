using Microsoft.AspNetCore.Http;
using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.DTOs;

public class ChestDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int Price { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public int CommonChance { get; set; }
    public int RareChance { get; set; }
    public int EpicChance { get; set; }
    public int LegendaryChance { get; set; }
    public int MythicChance { get; set; }
    public List<ItemDto> Items { get; set; } = new();
}

public class ChestFormDto
{
    public string Name { get; set; } = string.Empty;
    public int Price { get; set; }
    public int CommonChance { get; set; } = 69;
    public int RareChance { get; set; } = 20;
    public int EpicChance { get; set; } = 8;
    public int LegendaryChance { get; set; } = 2;
    public int MythicChance { get; set; } = 1;
    public List<int> ItemIds { get; set; } = new();
    public IFormFile? Image { get; set; }
}

public class ChestOpenResultDto
{
    public ChestDto Chest { get; set; } = new();
    public ItemDto Item { get; set; } = new();
    public List<ItemDto> Items { get; set; } = new();
    public ItemRarity RolledRarity { get; set; }
    public List<ItemRarity> RolledRarities { get; set; } = new();
    public int OpenCount { get; set; }
    public int TotalCost { get; set; }
    public int RemainingCoins { get; set; }
}
