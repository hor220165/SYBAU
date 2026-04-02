namespace Sybau_Backend.Models;

public enum FriendshipStatus
{
    Pending,
    Accepted,
    Declined
}

public class Friendship : BaseEntity<int>
{
    protected Friendship() { }

    public Friendship(User requester, User addressee)
    {
        Requester = requester ?? throw new ArgumentNullException(nameof(requester));
        Addressee = addressee ?? throw new ArgumentNullException(nameof(addressee));
        Status = FriendshipStatus.Pending;
    }

    public int RequesterId { get; set; }
    public User Requester { get; set; } = null!;

    public int AddresseeId { get; set; }
    public User Addressee { get; set; } = null!;

    public FriendshipStatus Status { get; set; }
    public DateTime? AcceptedAt { get; set; }

    public void Accept()
    {
        Status = FriendshipStatus.Accepted;
        AcceptedAt = DateTime.UtcNow;
    }

    public void Decline()
    {
        Status = FriendshipStatus.Declined;
    }
}
