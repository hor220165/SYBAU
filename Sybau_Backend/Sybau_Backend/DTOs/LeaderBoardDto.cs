namespace Sybau_Backend.DTOs;

public class LeaderBoardDto
{
    public int Id { get; set; }
    public int Rank { get; set; }
    public string UserName { get; set; }
    public string? ProfileImageUrl { get; set; }
    public int Experience { get; set; }
    public int TotalXp { get; set; }
    public int Level { get; set; }
}
