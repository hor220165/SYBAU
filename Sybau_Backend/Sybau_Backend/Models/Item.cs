using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Models;

public class Item : BaseEntity<int>
{
#pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    protected Item() { }
#pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.


    public Item(string name, string description, ItemType type, int price, int xpBoostPercent, int coinBoostPercent = 0, ItemRarity rarity = ItemRarity.Common)
    {
        if(string.IsNullOrWhiteSpace(name)) throw new ArgumentNullException(nameof(name));
        if(string.IsNullOrWhiteSpace(description)) throw new ArgumentNullException(nameof(description));
        if(price < 0) throw new ArgumentOutOfRangeException(nameof(price));
        if(type == ItemType.Booster && xpBoostPercent <= 0 && coinBoostPercent <= 0)
            throw new ArgumentException("XP- oder Coin-Boost muss > 0 sein.");
        
        Name = name;
        Description = description;
        Type = type;
        Price = price;
        XpBoostPercent = xpBoostPercent;
        CoinBoostPercent = coinBoostPercent;
        Rarity = rarity;
    }
    
    public string Name { get; set; }
    public string Description { get; set; }
    
    public ItemType Type { get; set; }
    public int Price { get; set; }
    public decimal? RealMoneyPrice { get; set; }
    public int XpBoostPercent { get; set; }
    public int CoinBoostPercent { get; set; }
    public ItemRarity Rarity { get; set; } = ItemRarity.Common;
    public int MaxQuantity { get; set; } = 5;
    public string? ImageUrl { get; set; }
    public ICollection<UserItem> UserItems { get; set; } = new List<UserItem>();
}
