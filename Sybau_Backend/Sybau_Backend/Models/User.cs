using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;

namespace Sybau_Backend.Models;

public class User: BaseEntity<int>
{
#pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    protected User()
    {
    }
#pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.

    public User(string userName,string? firstName, string? lastName, string email, string passwordHash)
    {
        if(string.IsNullOrWhiteSpace(userName)) throw new ArgumentNullException(nameof(userName));
        if (string.IsNullOrWhiteSpace(email)) throw new ArgumentNullException(nameof(email));
        if(string.IsNullOrWhiteSpace(passwordHash)) throw new ArgumentNullException(nameof(passwordHash));
        
        UserName = userName;
        FirstName = firstName;
        LastName = lastName;
        Email = email;
        PasswordHash = passwordHash;
        
        Avatar = Avatar.CreateDefault();
        
        IsAdmin = false;
    }
    
    public string UserName { get; set; }
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    [EmailAddress] public string Email { get; set; }
    public bool IsAdmin { get; set; }
    public Avatar Avatar { get; set; }
    
    [DataType(DataType.Password)]
    public string PasswordHash { get; set; }

    public int Coins { get; set; } = 0;
    
    public ICollection<UserItem> UserItems { get; set; } = new List<UserItem>();
    public ICollection<UserChallenge> UserChallenges { get; set; } = new List<UserChallenge>();
    public ICollection<UserCoin> UserCoins { get; set; } = new List<UserCoin>();
}