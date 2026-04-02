namespace Sybau_Backend.DTOs;

public class UserQuestDto
{
    public int Id { get; set; }
    public int QuestId { get; set; }
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public string Type { get; set; } = "";
    public string Rarity { get; set; } = "";
    public string TargetType { get; set; } = "";
    public int Progress { get; set; }
    public int TargetValue { get; set; }
    public int XpReward { get; set; }
    public int CoinReward { get; set; }
    public bool IsCompleted { get; set; }
    public bool IsRewardClaimed { get; set; }
    public string TimeLeft { get; set; } = "";
}
