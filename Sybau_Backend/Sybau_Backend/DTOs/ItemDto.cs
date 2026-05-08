using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Http;
using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.DTOs;

public class ItemDto
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Description { get; set; }
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public ItemType Type { get; set; }
    public int Price { get; set; }
    public int XpBoostPercentage { get; set; }
    public int CoinBoostPercentage { get; set; }
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public ItemRarity Rarity { get; set; }
    public int Quantity { get; set; }
    public int MaxQuantity { get; set; }
    public string? ImageUrl { get; set; }
}

public class ShopItemFormDto
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public ItemType Type { get; set; }
    public int Price { get; set; }
    public int XpBoostPercentage { get; set; }
    public int CoinBoostPercentage { get; set; }
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public ItemRarity Rarity { get; set; } = ItemRarity.Common;
    public int MaxQuantity { get; set; }
    public IFormFile? Image { get; set; }
}
