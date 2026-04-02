using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Models;

namespace Sybau_Backend.Data;

public class FitnessDbContext:DbContext
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Avatar> Avatars => Set<Avatar>();
    public DbSet<Item> Items => Set<Item>();
    public DbSet<Exercise> Exercises => Set<Exercise>();
    public DbSet<Workout> Workouts => Set<Workout>();
    public DbSet<WorkoutExercise> WorkoutExercises => Set<WorkoutExercise>();
    public DbSet<UserItem> UserItems => Set<UserItem>();
    public DbSet<UserCoin> UserCoins => Set<UserCoin>();
    public DbSet<Challenge> Challenges => Set<Challenge>();
    public DbSet<UserChallenge> UserChallenges => Set<UserChallenge>();
    public DbSet<UserExerciseLog> UserExerciseLogs => Set<UserExerciseLog>();
    public DbSet<Friendship> Friendships => Set<Friendship>();
    public DbSet<FriendChallenge> FriendChallenges => Set<FriendChallenge>();
    public FitnessDbContext(DbContextOptions<FitnessDbContext> options) : base(options){}

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        
        //1 to 1 Relationship: User 1-1 Avatar
        modelBuilder.Entity<User>(builder =>
        {
            builder.HasOne(p => p.Avatar)
                .WithOne(p => p.User)
                .HasForeignKey<Avatar>(p => p.UserId).IsRequired();
        });
        
        //One to Many: User 1-m UserCoin
        modelBuilder.Entity<UserCoin>(builder =>
        {
            builder.HasOne(c => c.User)
                .WithMany(u => u.UserCoins)
                .HasForeignKey(c => c.UserId)
                .IsRequired();
        });
        
        //Many to Many: User m-n Item
        modelBuilder.Entity<UserItem>(builder =>
        {
            builder.HasOne(p => p.Item).WithMany(i=>i.UserItems).HasForeignKey("ItemId").IsRequired();
            builder.HasOne(p => p.User).WithMany(u=>u.UserItems).HasForeignKey("UserId").IsRequired();
        });
        
        //Many to Many: User m-n Challenge
        modelBuilder.Entity<UserChallenge>(entity =>
        {
            entity.HasOne(p => p.User).WithMany(u=>u.UserChallenges).HasForeignKey("UserId").IsRequired();
            entity.HasOne(p => p.Challenge).WithMany(c => c.UserChallenges).HasForeignKey("ChallengeId").IsRequired();
        });
        
        //Item Enum Conversion
        modelBuilder.Entity<Item>(entity =>
        {
            entity.Property(e => e.Type).HasConversion<string>();
            entity.Property(e => e.Rarity).HasConversion<string>();
        });

        //Workout - Exercise Many-to-Many mit Tageslimit
        modelBuilder.Entity<WorkoutExercise>(entity =>
        {
            entity.HasOne(we => we.Workout)
                .WithMany(w => w.WorkoutExercises)
                .HasForeignKey(we => we.WorkoutId)
                .IsRequired();

            entity.HasOne(we => we.Exercise)
                .WithMany(e => e.WorkoutExercises)
                .HasForeignKey(we => we.ExerciseId)
                .IsRequired();

            entity.HasIndex(we => new { we.WorkoutId, we.ExerciseId }).IsUnique();
        });

        modelBuilder.Entity<Workout>(entity =>
        {
            entity.Property(e => e.Category).HasConversion<string>();
        });

        modelBuilder.Entity<Exercise>(entity =>
        {
            entity.Property(e => e.Category).HasConversion<string>();
            entity.Property(e => e.Difficulty).HasConversion<string>();
        });

        modelBuilder.Entity<UserExerciseLog>(entity =>
        {
            entity.HasOne(l => l.User)
                .WithMany()
                .HasForeignKey(l => l.UserId)
                .IsRequired();

            entity.HasOne(l => l.Exercise)
                .WithMany()
                .HasForeignKey(l => l.ExerciseId)
                .IsRequired();
        });

        // Friendship: User m-n User (self-referencing)
        modelBuilder.Entity<Friendship>(entity =>
        {
            entity.HasOne(f => f.Requester)
                .WithMany()
                .HasForeignKey(f => f.RequesterId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(f => f.Addressee)
                .WithMany()
                .HasForeignKey(f => f.AddresseeId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.Property(f => f.Status).HasConversion<string>();

            // Ein Paar kann nur eine Freundschaft haben
            entity.HasIndex(f => new { f.RequesterId, f.AddresseeId }).IsUnique();
        });

        // FriendChallenge: Challenges zwischen Freunden
        modelBuilder.Entity<FriendChallenge>(entity =>
        {
            entity.HasOne(fc => fc.Challenger)
                .WithMany()
                .HasForeignKey(fc => fc.ChallengerId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(fc => fc.Opponent)
                .WithMany()
                .HasForeignKey(fc => fc.OpponentId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(fc => fc.Winner)
                .WithMany()
                .HasForeignKey(fc => fc.WinnerId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.Property(fc => fc.Status).HasConversion<string>();
        });

    }
}