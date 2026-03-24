using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Data;
using Sybau_Backend.DTOs;
using Sybau_Backend.Models;

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

         var item = new Item(dto.Name,dto.Description,dto.Type,dto.Price,dto.XpBoostPercentage, dto.CoinBoostPercentage);
         
         _context.Items.Add(item);
         await _context.SaveChangesAsync();
         
         return item;
    }
    
    public async Task<bool> BuyItemAsync(int userId, int itemId)
    {
        var user = await _context.Users
            .Include(u => u.UserItems)
            .ThenInclude(ui => ui.Item)
            .FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null) return false;

        var item = await _context.Items.FindAsync(itemId);
        if (item == null) return false;

        // Coins prüfen
        if (user.Coins < item.Price)
            return false;

        // Coins abziehen
        user.Coins -= item.Price;

        // Prüfen ob User Item schon besitzt
        var userItem = user.UserItems.FirstOrDefault(ui => ui.Item.Id == itemId);

        if (userItem == null)
        {
            // Neues Item
            userItem = new UserItem(user, item);
            _context.UserItems.Add(userItem);
        }
        else
        {
            // Item existiert → Quantity erhöhen
            userItem.Quantity++;
        }

        //Coin-Historie
        var history = new UserCoin(user, -item.Price, $"Bought item: {item.Name}");
        _context.UserCoins.Add(history);

        await _context.SaveChangesAsync();
        return true;
    }
}