namespace Sybau_Backend.DTOs;

public class FriendshipDto
{
    public int Id { get; set; }
    public int FriendId { get; set; }
    public string FriendUserName { get; set; } = null!;
    public int FriendLevel { get; set; }
    public int FriendExperience { get; set; }
    public string FriendBodyStage { get; set; } = null!;
    public DateTime FriendsSince { get; set; }
}

public class FriendRequestDto
{
    public int Id { get; set; }
    public int FromUserId { get; set; }
    public string FromUserName { get; set; } = null!;
    public int FromUserLevel { get; set; }
    public DateTime SentAt { get; set; }
}

public class SendFriendRequestDto
{
    public string UserName { get; set; } = null!;
}
