using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Sybau_Backend.Data;

public class PostgresFitnessDbContextFactory : IDesignTimeDbContextFactory<PostgresFitnessDbContext>
{
    public PostgresFitnessDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<PostgresFitnessDbContext>();
        var connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
            ?? "Host=localhost;Port=5432;Database=sybau;Username=postgres";

        optionsBuilder.UseNpgsql(connectionString);

        return new PostgresFitnessDbContext(optionsBuilder.Options);
    }
}
