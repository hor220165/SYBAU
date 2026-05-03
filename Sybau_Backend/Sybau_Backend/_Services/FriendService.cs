using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Data;
using Sybau_Backend.DTOs;
using Sybau_Backend.Hubs;
using Sybau_Backend.Models;
using Sybau_Backend.Models.Enums;

namespace Sybau_Backend._Services;

public class FriendService
{
    private readonly FitnessDbContext _context;
    private readonly BodyStageService _bodyStageService;
    private readonly IHubContext<NotificationHub> _hubContext;

    public FriendService(FitnessDbContext context, BodyStageService bodyStageService, IHubContext<NotificationHub> hubContext)
    {
        _context = context;
        _bodyStageService = bodyStageService;
        _hubContext = hubContext;
    }

    // Freundschaftsanfrage senden
    public async Task<(bool success, string message)> SendFriendRequestAsync(int requesterId, string addresseeUserName)
    {
        var addressee = await _context.Users
            .FirstOrDefaultAsync(u => u.UserName == addresseeUserName);

        if (addressee == null)
            return (false, "Benutzer nicht gefunden.");

        if (addressee.Id == requesterId)
            return (false, "Du kannst dir nicht selbst eine Anfrage senden.");

        // Prüfe ob schon eine Freundschaft/Anfrage existiert
        var existing = await _context.Friendships
            .FirstOrDefaultAsync(f =>
                (f.RequesterId == requesterId && f.AddresseeId == addressee.Id) ||
                (f.RequesterId == addressee.Id && f.AddresseeId == requesterId));

        if (existing != null)
        {
            if (existing.Status == FriendshipStatus.Accepted)
                return (false, "Ihr seid bereits befreundet.");
            if (existing.Status == FriendshipStatus.Pending)
                return (false, "Es gibt bereits eine offene Anfrage.");
            // Bei Declined: erneute Anfrage erlauben
            if (existing.Status == FriendshipStatus.Declined)
            {
                _context.Friendships.Remove(existing);
                await _context.SaveChangesAsync();
            }
        }

        var requester = await _context.Users.FindAsync(requesterId);
        if (requester == null)
            return (false, "Requester nicht gefunden.");

        var friendship = new Friendship(requester, addressee);
        _context.Friendships.Add(friendship);
        await _context.SaveChangesAsync();

        // Live-Benachrichtigung an den Empfänger
        await _hubContext.Clients.Group($"user_{addressee.Id}").SendAsync("FriendRequestReceived", new
        {
            friendshipId = friendship.Id,
            fromUserName = requester.UserName
        });

        return (true, "Freundschaftsanfrage gesendet.");
    }

    // Anfrage annehmen
    public async Task<(bool success, string message)> AcceptFriendRequestAsync(int friendshipId, int userId)
    {
        var friendship = await _context.Friendships
            .FirstOrDefaultAsync(f => f.Id == friendshipId && f.AddresseeId == userId);

        if (friendship == null)
            return (false, "Anfrage nicht gefunden.");

        if (friendship.Status != FriendshipStatus.Pending)
            return (false, "Anfrage ist nicht mehr offen.");

        friendship.Accept();
        await _context.SaveChangesAsync();

        // Live-Benachrichtigung an den Anfragensteller
        await _hubContext.Clients.Group($"user_{friendship.RequesterId}").SendAsync("FriendRequestAccepted", new
        {
            friendshipId = friendship.Id,
            byUserName = (await _context.Users.FindAsync(userId))?.UserName ?? "Jemand"
        });

        return (true, "Freundschaftsanfrage angenommen.");
    }

    // Anfrage ablehnen
    public async Task<(bool success, string message)> DeclineFriendRequestAsync(int friendshipId, int userId)
    {
        var friendship = await _context.Friendships
            .FirstOrDefaultAsync(f => f.Id == friendshipId && f.AddresseeId == userId);

        if (friendship == null)
            return (false, "Anfrage nicht gefunden.");

        if (friendship.Status != FriendshipStatus.Pending)
            return (false, "Anfrage ist nicht mehr offen.");

        friendship.Decline();
        await _context.SaveChangesAsync();

        return (true, "Freundschaftsanfrage abgelehnt.");
    }

    // Freundschaft entfernen
    public async Task<(bool success, string message)> RemoveFriendAsync(int friendshipId, int userId)
    {
        var friendship = await _context.Friendships
            .FirstOrDefaultAsync(f => f.Id == friendshipId &&
                (f.RequesterId == userId || f.AddresseeId == userId));

        if (friendship == null)
            return (false, "Freundschaft nicht gefunden.");

        _context.Friendships.Remove(friendship);
        await _context.SaveChangesAsync();

        return (true, "Freundschaft entfernt.");
    }

    // Alle Freunde abrufen
    public async Task<IEnumerable<FriendshipDto>> GetFriendsAsync(int userId)
    {
        var friendships = await _context.Friendships
            .Include(f => f.Requester).ThenInclude(u => u.Avatar)
            .Include(f => f.Addressee).ThenInclude(u => u.Avatar)
            .Where(f => (f.RequesterId == userId || f.AddresseeId == userId)
                        && f.Status == FriendshipStatus.Accepted)
            .ToListAsync();

        return friendships.Select(f =>
        {
            var friend = f.RequesterId == userId ? f.Addressee : f.Requester;
            return new FriendshipDto
            {
                Id = f.Id,
                FriendId = friend.Id,
                FriendUserName = friend.UserName,
                FriendProfileImageUrl = friend.ProfileImageUrl,
                FriendLevel = friend.Avatar.Level,
                FriendExperience = friend.Avatar.Experience,
                FriendBodyStage = _bodyStageService.GetBodyStage(friend.Avatar.Level).ToString(),
                FriendsSince = f.AcceptedAt ?? f.CreatedAt
            };
        });
    }

    // Eingehende Anfragen abrufen
    public async Task<IEnumerable<FriendRequestDto>> GetPendingRequestsAsync(int userId)
    {
        var requests = await _context.Friendships
            .Include(f => f.Requester).ThenInclude(u => u.Avatar)
            .Where(f => f.AddresseeId == userId && f.Status == FriendshipStatus.Pending)
            .ToListAsync();

        return requests.Select(f => new FriendRequestDto
        {
            Id = f.Id,
            FromUserId = f.Requester.Id,
            FromUserName = f.Requester.UserName,
            FromUserProfileImageUrl = f.Requester.ProfileImageUrl,
            FromUserLevel = f.Requester.Avatar.Level,
            SentAt = f.CreatedAt
        });
    }

    // Ausgehende offene Anfragen abrufen
    public async Task<IEnumerable<SentFriendRequestDto>> GetSentRequestsAsync(int userId)
    {
        var requests = await _context.Friendships
            .Include(f => f.Addressee).ThenInclude(u => u.Avatar)
            .Where(f => f.RequesterId == userId && f.Status == FriendshipStatus.Pending)
            .ToListAsync();

        return requests.Select(f => new SentFriendRequestDto
        {
            Id = f.Id,
            ToUserId = f.Addressee.Id,
            ToUserName = f.Addressee.UserName,
            ToUserProfileImageUrl = f.Addressee.ProfileImageUrl,
            ToUserLevel = f.Addressee.Avatar.Level,
            SentAt = f.CreatedAt
        });
    }

    // Freundes-Bestenliste
    public async Task<IEnumerable<LeaderBoardDto>> GetFriendsLeaderboardAsync(int userId)
    {
        // Alle Freund-IDs ermitteln
        var friendIds = await _context.Friendships
            .Where(f => (f.RequesterId == userId || f.AddresseeId == userId)
                        && f.Status == FriendshipStatus.Accepted)
            .Select(f => f.RequesterId == userId ? f.AddresseeId : f.RequesterId)
            .ToListAsync();

        // Sich selbst auch mit einbeziehen
        friendIds.Add(userId);

        var users = await _context.Users
            .Include(u => u.Avatar)
            .Where(u => friendIds.Contains(u.Id))
            .OrderByDescending(u => u.Avatar.Experience)
            .ToListAsync();

        return users.Select((u, index) => new LeaderBoardDto
        {
            Id = u.Id,
            Rank = index + 1,
            UserName = u.UserName,
            ProfileImageUrl = u.ProfileImageUrl,
            Experience = u.Avatar.Experience,
            Level = u.Avatar.Level
        });
    }

    // Prüfen ob zwei User befreundet sind
    public async Task<bool> AreFriendsAsync(int userId1, int userId2)
    {
        return await _context.Friendships
            .AnyAsync(f =>
                ((f.RequesterId == userId1 && f.AddresseeId == userId2) ||
                 (f.RequesterId == userId2 && f.AddresseeId == userId1))
                && f.Status == FriendshipStatus.Accepted);
    }
}
