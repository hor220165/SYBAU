namespace Sybau_Backend.Models;

public class UserItem:BaseEntity<int>
{
    #pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    protected UserItem() { }
    #pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.

    public UserItem(User user, Item item)
    {
        User = user;
        Item = item;
        UserId = user.Id;
        ItemId = item.Id;
        Quantity = 1;
        AcquiredAt=DateTime.UtcNow;
    }
    
    public int Quantity { get; set; }
    public DateTime AcquiredAt { get; set; }
    
    public int UserId { get; set; }
    public User User { get; set; }
    
    public int ItemId { get; set; }
    public Item Item { get; set; }
}