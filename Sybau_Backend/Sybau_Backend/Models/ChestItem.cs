namespace Sybau_Backend.Models;

public class ChestItem : BaseEntity<int>
{
#pragma warning disable CS8618
    protected ChestItem() { }
#pragma warning restore CS8618

    public ChestItem(Chest chest, Item item)
    {
        Chest = chest;
        Item = item;
    }

    public int ChestId { get; set; }
    public Chest Chest { get; set; }
    public int ItemId { get; set; }
    public Item Item { get; set; }
}
