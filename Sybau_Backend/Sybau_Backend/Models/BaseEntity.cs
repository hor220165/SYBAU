namespace Sybau_Backend.Models;

public abstract class BaseEntity<T> where T: struct
{
    public T Id { get;protected set; }
    public DateTime CreatedAt { get; protected set; }
    public DateTime UpdatedAt { get; protected set; }
}