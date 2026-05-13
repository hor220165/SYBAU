using Microsoft.EntityFrameworkCore;

namespace Sybau_Backend.Data;

public class PostgresFitnessDbContext : FitnessDbContext
{
    public PostgresFitnessDbContext(DbContextOptions<PostgresFitnessDbContext> options)
        : base(options)
    {
    }
}
