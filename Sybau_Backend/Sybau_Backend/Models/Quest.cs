using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Models;

public class Quest : BaseEntity<int>
{
#pragma warning disable CS8618
    protected Quest() { }
#pragma warning restore CS8618

    public Quest(string name, string description, QuestType type, ItemRarity rarity,
                 QuestTargetType targetType, int targetValue, int xpReward, int coinReward)
    {
        if (string.IsNullOrWhiteSpace(name)) throw new ArgumentNullException(nameof(name));
        if (targetValue < 1) throw new ArgumentOutOfRangeException(nameof(targetValue));
        if (xpReward < 0) throw new ArgumentOutOfRangeException(nameof(xpReward));
        if (coinReward < 0) throw new ArgumentOutOfRangeException(nameof(coinReward));

        Name = name;
        Description = description;
        Type = type;
        Rarity = rarity;
        TargetType = targetType;
        TargetValue = targetValue;
        XpReward = xpReward;
        CoinReward = coinReward;
    }

    public string Name { get; set; }
    public string Description { get; set; }
    public QuestType Type { get; set; }
    public ItemRarity Rarity { get; set; }
    public QuestTargetType TargetType { get; set; }
    public int TargetValue { get; set; }
    public int XpReward { get; set; }
    public int CoinReward { get; set; }

    public ICollection<UserQuest> UserQuests { get; set; } = new List<UserQuest>();
}
