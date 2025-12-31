
namespace Sybau_Backend.Models
{
    public class UserCoin : BaseEntity<int>
    {
#pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.
        protected UserCoin() { }
#pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider adding the 'required' modifier or declaring as nullable.

        public UserCoin(User user, int amount, string reason)
        {
            if (amount == 0) throw new ArgumentException("Amount cannot be zero");
            User = user ?? throw new ArgumentNullException(nameof(user));
            Amount = amount;
            Reason = reason ?? throw new ArgumentNullException(nameof(reason));
            CreatedAt = DateTime.UtcNow;
        }

        public int UserId { get; set; }
        public User User { get; set; }

        public int Amount { get; set; } // positiv = gutgeschrieben, negativ = ausgegeben
        public string Reason { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}