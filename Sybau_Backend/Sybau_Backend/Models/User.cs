using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;

namespace Sybau_Backend.Models;

public class User: BaseEntity<int>
{
    [Required] public required string FirstName { get; set; }
    [Required] public required string LastName { get; set; }
    [Required] [EmailAddress] public string Email { get; set; }
    [Required] public Avatar Avatar { get; set; }

    [Required]
    [DataType(DataType.Password)]
    public string Password { get; set; }

#pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
    protected User()
    {
    }
#pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.

    public User(string firstName, string lastName, string email, string password): base()
    {
        if (string.IsNullOrWhiteSpace(firstName)) throw new ArgumentNullException(nameof(firstName));
        if (string.IsNullOrWhiteSpace(lastName)) throw new ArgumentNullException(nameof(lastName));
        if (string.IsNullOrWhiteSpace(email)) throw new ArgumentNullException(nameof(email));
        if(string.IsNullOrWhiteSpace(password)) throw new ArgumentNullException(nameof(password));
        
        FirstName = firstName;
        LastName = lastName;
        Email = email;
        Password = password;
       
    }
}