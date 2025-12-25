using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Models;

namespace Sybau_Backend.Data;

public class FitnessDbContext:DbContext
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Avatar> Avatars => Set<Avatar>();
    public FitnessDbContext(DbContextOptions<FitnessDbContext> options) : base(options){}

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(builder =>
        {
            builder.HasOne(p => p.Avatar)
                .WithOne()
                .HasForeignKey<Avatar>("UserId");
        });
    }
}