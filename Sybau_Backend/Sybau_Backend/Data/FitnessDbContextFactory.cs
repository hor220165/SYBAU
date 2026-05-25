using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Sybau_Backend.Data;

public class FitnessDbContextFactory : IDesignTimeDbContextFactory<FitnessDbContext>
{
    public FitnessDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<FitnessDbContext>();
        optionsBuilder.UseSqlite("Data Source=sybau.db");
        return new FitnessDbContext(optionsBuilder.Options);
    }
}
