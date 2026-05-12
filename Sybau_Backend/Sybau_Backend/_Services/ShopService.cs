using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Data;
using Sybau_Backend.DTOs;
using Sybau_Backend.Models;
using Sybau_Backend.Models.Enums;

namespace Sybau_Backend._Services;

public class ShopService
{
    private readonly FitnessDbContext _context;
    private readonly UserService _userService;

    public ShopService(FitnessDbContext context,UserService userService)
    {
        _context = context;
        _userService = userService;
    }

    public async Task<IEnumerable<Item>> GetItemsAsync()
    {
        return await _context.Items.ToListAsync();
    }

    public async Task<Item?> GetItemAsync(int id)
    {
        return await _context.Items
            .FirstOrDefaultAsync(i => i.Id == id);
    }

    public async Task<Item> AddItemAsync(ItemDto dto)
    {
         if(dto == null)throw new ArgumentNullException(nameof(dto));

         var item = new Item(dto.Name,dto.Description,dto.Type,dto.Price,dto.XpBoostPercentage, dto.CoinBoostPercentage, dto.Rarity);
         if (dto.MaxQuantity > 0) item.MaxQuantity = dto.MaxQuantity;
         item.ImageUrl = dto.ImageUrl;
         
         _context.Items.Add(item);
         await _context.SaveChangesAsync();
         
         return item;
    }

    public async Task<Item?> UpdateItemAsync(int id, ItemDto dto)
    {
        if (dto == null) throw new ArgumentNullException(nameof(dto));

        var item = await _context.Items.FindAsync(id);
        if (item == null) return null;

        item.Name = dto.Name;
        item.Description = dto.Description;
        item.Type = dto.Type;
        item.Price = dto.Price;
        item.XpBoostPercent = dto.XpBoostPercentage;
        item.CoinBoostPercent = dto.CoinBoostPercentage;
        item.Rarity = dto.Rarity;
        item.MaxQuantity = dto.MaxQuantity > 0 ? dto.MaxQuantity : item.MaxQuantity;
        if (!string.IsNullOrWhiteSpace(dto.ImageUrl))
        {
            item.ImageUrl = dto.ImageUrl;
        }

        await _context.SaveChangesAsync();
        return item;
    }

    public async Task<bool> DeleteItemAsync(int id)
    {
        var item = await _context.Items
            .Include(i => i.UserItems)
            .FirstOrDefaultAsync(i => i.Id == id);

        if (item == null) return false;

        var chestItems = await _context.ChestItems.Where(ci => ci.ItemId == id).ToListAsync();
        _context.ChestItems.RemoveRange(chestItems);
        _context.UserItems.RemoveRange(item.UserItems);
        _context.Items.Remove(item);
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<IEnumerable<ChestDto>> GetChestsAsync()
    {
        var chests = await _context.Chests
            .Include(c => c.ChestItems)
            .ThenInclude(ci => ci.Item)
            .ToListAsync();

        return chests.Select(ToChestDto);
    }

    public async Task<ChestDto?> GetChestAsync(int id)
    {
        var chest = await _context.Chests
            .Include(c => c.ChestItems)
            .ThenInclude(ci => ci.Item)
            .FirstOrDefaultAsync(c => c.Id == id);

        return chest == null ? null : ToChestDto(chest);
    }

    public async Task<Chest?> GetChestEntityAsync(int id)
    {
        return await _context.Chests
            .Include(c => c.ChestItems)
            .ThenInclude(ci => ci.Item)
            .FirstOrDefaultAsync(c => c.Id == id);
    }

    public async Task<ChestDto> AddChestAsync(ChestFormDto dto, string imageUrl)
    {
        ValidateChest(dto, requireItems: true);
        var itemIds = dto.ItemIds.Distinct().ToList();
        var items = await _context.Items.Where(i => itemIds.Contains(i.Id)).ToListAsync();
        if (items.Count != itemIds.Count) throw new ArgumentException("Mindestens ein Chest-Item wurde nicht gefunden.");

        var chest = new Chest(dto.Name, dto.Price, imageUrl)
        {
            CommonChance = dto.CommonChance,
            RareChance = dto.RareChance,
            EpicChance = dto.EpicChance,
            LegendaryChance = dto.LegendaryChance
        };

        foreach (var item in items)
        {
            chest.ChestItems.Add(new ChestItem(chest, item));
        }

        _context.Chests.Add(chest);
        await _context.SaveChangesAsync();
        return ToChestDto(chest);
    }

    public async Task<ChestDto?> UpdateChestAsync(int id, ChestFormDto dto, string? imageUrl)
    {
        ValidateChest(dto, requireItems: true);
        var chest = await _context.Chests
            .Include(c => c.ChestItems)
            .ThenInclude(ci => ci.Item)
            .FirstOrDefaultAsync(c => c.Id == id);
        if (chest == null) return null;

        var itemIds = dto.ItemIds.Distinct().ToList();
        var items = await _context.Items.Where(i => itemIds.Contains(i.Id)).ToListAsync();
        if (items.Count != itemIds.Count) throw new ArgumentException("Mindestens ein Chest-Item wurde nicht gefunden.");

        chest.Name = dto.Name;
        chest.Price = dto.Price;
        chest.CommonChance = dto.CommonChance;
        chest.RareChance = dto.RareChance;
        chest.EpicChance = dto.EpicChance;
        chest.LegendaryChance = dto.LegendaryChance;
        if (!string.IsNullOrWhiteSpace(imageUrl))
        {
            chest.ImageUrl = imageUrl;
        }

        _context.ChestItems.RemoveRange(chest.ChestItems);
        chest.ChestItems = items.Select(item => new ChestItem(chest, item)).ToList();

        await _context.SaveChangesAsync();
        return ToChestDto(chest);
    }

    public async Task<bool> DeleteChestAsync(int id)
    {
        var chest = await _context.Chests
            .Include(c => c.ChestItems)
            .FirstOrDefaultAsync(c => c.Id == id);
        if (chest == null) return false;

        _context.ChestItems.RemoveRange(chest.ChestItems);
        _context.Chests.Remove(chest);
        await _context.SaveChangesAsync();
        return true;
    }
    
    public async Task<string?> BuyItemAsync(int userId, int itemId)
    {
        var user = await _context.Users
            .Include(u => u.UserItems)
            .ThenInclude(ui => ui.Item)
            .FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null) return "Benutzer nicht gefunden";

        var item = await _context.Items.FindAsync(itemId);
        if (item == null) return "Item nicht gefunden";

        // Coins prüfen
        if (user.Coins < item.Price)
            return "Nicht genug Coins";

        // Prüfen ob User Item schon besitzt
        var userItem = user.UserItems.FirstOrDefault(ui => ui.Item.Id == itemId);

        // Coins abziehen
        user.Coins -= item.Price;

        AddItemToUser(user, item, userItem);

        //Coin-Historie
        var history = new UserCoin(user, -item.Price, $"Bought item: {item.Name}");
        _context.UserCoins.Add(history);

        await _context.SaveChangesAsync();
        return null; // null = Erfolg
    }

    public async Task<(string? error, object? result)> SellItemAsync(int userId, int itemId)
    {
        var user = await _context.Users
            .Include(u => u.Avatar)
            .Include(u => u.UserItems)
            .ThenInclude(ui => ui.Item)
            .FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null) return ("Benutzer nicht gefunden", null);

        var userItem = user.UserItems.FirstOrDefault(ui => ui.Item.Id == itemId);
        if (userItem == null || userItem.Quantity <= 0)
            return ("Du besitzt dieses Item nicht.", null);

        var item = userItem.Item;
        var sellPrice = Math.Max(1, (int)Math.Floor(item.Price * 0.5));

        userItem.Quantity--;
        user.Coins += sellPrice;

        if (userItem.Quantity <= 0)
        {
            _context.UserItems.Remove(userItem);
        }

        TrimEquippedBoostsAfterSale(user, item, Math.Max(0, userItem.Quantity));
        _context.UserCoins.Add(new UserCoin(user, sellPrice, $"Sold item: {item.Name}"));

        await _context.SaveChangesAsync();

        return (null, new
        {
            ItemId = item.Id,
            Quantity = Math.Max(0, userItem.Quantity),
            SellPrice = sellPrice,
            RemainingCoins = user.Coins
        });
    }

    public async Task<(string? error, ChestOpenResultDto? result)> OpenChestAsync(int userId, int chestId)
    {
        var user = await _context.Users
            .Include(u => u.UserItems)
            .ThenInclude(ui => ui.Item)
            .FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null) return ("Benutzer nicht gefunden", null);

        var chest = await _context.Chests
            .Include(c => c.ChestItems)
            .ThenInclude(ci => ci.Item)
            .FirstOrDefaultAsync(c => c.Id == chestId);
        if (chest == null) return ("Chest nicht gefunden", null);
        if (!chest.ChestItems.Any()) return ("Diese Chest hat keine Items", null);
        if (user.Coins < chest.Price) return ("Nicht genug Coins", null);

        var rolledRarity = RollRarity(chest);
        var availableItems = chest.ChestItems
            .Select(ci => ci.Item)
            .ToList();

        var rarityItems = availableItems.Where(item => item.Rarity == rolledRarity).ToList();
        var pool = rarityItems.Any() ? rarityItems : availableItems;
        var wonItem = pool[Random.Shared.Next(pool.Count)];

        user.Coins -= chest.Price;
        var userItem = user.UserItems.FirstOrDefault(ui => ui.Item.Id == wonItem.Id);
        AddItemToUser(user, wonItem, userItem);
        _context.UserCoins.Add(new UserCoin(user, -chest.Price, $"Opened chest: {chest.Name}"));

        await _context.SaveChangesAsync();

        return (null, new ChestOpenResultDto
        {
            Chest = ToChestDto(chest),
            Item = ToItemDto(wonItem, user.UserItems.FirstOrDefault(ui => ui.Item.Id == wonItem.Id)?.Quantity ?? 1),
            RolledRarity = wonItem.Rarity,
            RemainingCoins = user.Coins
        });
    }

    private void AddItemToUser(User user, Item item, UserItem? userItem)
    {
        if (userItem == null)
        {
            userItem = new UserItem(user, item);
            _context.UserItems.Add(userItem);
        }
        else
        {
            userItem.Quantity++;
        }
    }

    private static void TrimEquippedBoostsAfterSale(User user, Item item, int remainingQuantity)
    {
        if (item.Type != ItemType.Booster || user.Avatar == null) return;

        var slots = new[]
        {
            user.Avatar.Boost1,
            user.Avatar.Boost2,
            user.Avatar.Boost3,
            user.Avatar.Boost4
        };

        var equippedCount = slots.Count(slot => slot == item.Name);
        var removeCount = Math.Max(0, equippedCount - remainingQuantity);
        if (removeCount <= 0) return;

        for (var i = slots.Length - 1; i >= 0 && removeCount > 0; i--)
        {
            if (slots[i] != item.Name) continue;
            slots[i] = null;
            removeCount--;
        }

        user.Avatar.Boost1 = slots[0];
        user.Avatar.Boost2 = slots[1];
        user.Avatar.Boost3 = slots[2];
        user.Avatar.Boost4 = slots[3];
    }

    private static ItemRarity RollRarity(Chest chest)
    {
        var chances = new[]
        {
            (Rarity: ItemRarity.Common, Chance: Math.Max(0, chest.CommonChance)),
            (Rarity: ItemRarity.Rare, Chance: Math.Max(0, chest.RareChance)),
            (Rarity: ItemRarity.Epic, Chance: Math.Max(0, chest.EpicChance)),
            (Rarity: ItemRarity.Legendary, Chance: Math.Max(0, chest.LegendaryChance))
        };
        var total = chances.Sum(c => c.Chance);
        if (total <= 0) return ItemRarity.Common;

        var roll = Random.Shared.Next(1, total + 1);
        var current = 0;
        foreach (var chance in chances)
        {
            current += chance.Chance;
            if (roll <= current) return chance.Rarity;
        }

        return ItemRarity.Common;
    }

    private static void ValidateChest(ChestFormDto dto, bool requireItems)
    {
        if (dto == null) throw new ArgumentNullException(nameof(dto));
        if (string.IsNullOrWhiteSpace(dto.Name)) throw new ArgumentException("Chest-Name ist Pflicht.");
        if (dto.Price <= 0) throw new ArgumentException("Chest-Preis muss groesser als 0 sein.");
        if (requireItems && !dto.ItemIds.Any()) throw new ArgumentException("Eine Chest braucht mindestens ein Item.");

        var totalChance = dto.CommonChance + dto.RareChance + dto.EpicChance + dto.LegendaryChance;
        if (totalChance != 100) throw new ArgumentException("Die Rarity-Prozentzahlen muessen zusammen 100 ergeben.");
        if (new[] { dto.CommonChance, dto.RareChance, dto.EpicChance, dto.LegendaryChance }.Any(chance => chance < 0))
            throw new ArgumentException("Rarity-Prozentzahlen duerfen nicht negativ sein.");
    }

    private static ChestDto ToChestDto(Chest chest)
    {
        return new ChestDto
        {
            Id = chest.Id,
            Name = chest.Name,
            Price = chest.Price,
            ImageUrl = chest.ImageUrl,
            CommonChance = chest.CommonChance,
            RareChance = chest.RareChance,
            EpicChance = chest.EpicChance,
            LegendaryChance = chest.LegendaryChance,
            Items = chest.ChestItems.Select(ci => ToItemDto(ci.Item)).ToList()
        };
    }

    private static ItemDto ToItemDto(Item item, int quantity = 0)
    {
        return new ItemDto
        {
            Id = item.Id,
            Name = item.Name,
            Description = item.Description,
            Type = item.Type,
            Price = item.Price,
            XpBoostPercentage = item.XpBoostPercent,
            CoinBoostPercentage = item.CoinBoostPercent,
            Rarity = item.Rarity,
            Quantity = quantity,
            MaxQuantity = item.MaxQuantity,
            ImageUrl = item.ImageUrl
        };
    }
}
