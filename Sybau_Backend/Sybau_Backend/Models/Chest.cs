using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Models;

public class Chest : BaseEntity<int>
{
#pragma warning disable CS8618
    protected Chest() { }
#pragma warning restore CS8618

    public Chest(string name, int price, string imageUrl)
    {
        if (string.IsNullOrWhiteSpace(name)) throw new ArgumentNullException(nameof(name));
        if (price <= 0) throw new ArgumentOutOfRangeException(nameof(price));
        if (string.IsNullOrWhiteSpace(imageUrl)) throw new ArgumentNullException(nameof(imageUrl));

        Name = name;
        Price = price;
        ImageUrl = imageUrl;
    }

    public string Name { get; set; }
    public int Price { get; set; }
    public string ImageUrl { get; set; }
    public int CommonChance { get; set; } = 69;
    public int RareChance { get; set; } = 20;
    public int EpicChance { get; set; } = 8;
    public int LegendaryChance { get; set; } = 2;
    public int MythicChance { get; set; } = 1;
    public ICollection<ChestItem> ChestItems { get; set; } = new List<ChestItem>();

    public int ChanceFor(ItemRarity rarity) => rarity switch
    {
        ItemRarity.Common => CommonChance,
        ItemRarity.Rare => RareChance,
        ItemRarity.Epic => EpicChance,
        ItemRarity.Legendary => LegendaryChance,
        ItemRarity.Mythic => MythicChance,
        _ => 0
    };
}
