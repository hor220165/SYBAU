using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Models;
using Sybau_Backend.Models.Enums;

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
    public DbSet<Quest> Quests => Set<Quest>();
    public DbSet<UserQuest> UserQuests => Set<UserQuest>();
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

        // Quest Enum Conversions
        modelBuilder.Entity<Quest>(entity =>
        {
            entity.Property(e => e.Type).HasConversion<string>();
            entity.Property(e => e.Rarity).HasConversion<string>();
            entity.Property(e => e.TargetType).HasConversion<string>();
        });

        // UserQuest Relationships
        modelBuilder.Entity<UserQuest>(entity =>
        {
            entity.HasOne(uq => uq.User)
                .WithMany(u => u.UserQuests)
                .HasForeignKey(uq => uq.UserId)
                .IsRequired();

            entity.HasOne(uq => uq.Quest)
                .WithMany(q => q.UserQuests)
                .HasForeignKey(uq => uq.QuestId)
                .IsRequired();

            entity.HasIndex(uq => new { uq.UserId, uq.QuestId, uq.PeriodStart }).IsUnique();
        });

        // Quest Seed Data
        modelBuilder.Entity<Quest>().HasData(
            // Tägliche Quests (Common)
            new { Id = 1, Name = "Tägliches Training", Description = "Schließe eine Übung ab", Type = QuestType.Daily, Rarity = ItemRarity.Common, TargetType = QuestTargetType.ExercisesCompleted, TargetValue = 1, XpReward = 100, CoinReward = 10, CreatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc), UpdatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc) },
            new { Id = 2, Name = "Wiederholungsjäger", Description = "Mache insgesamt 100 Wiederholungen", Type = QuestType.Daily, Rarity = ItemRarity.Common, TargetType = QuestTargetType.TotalReps, TargetValue = 100, XpReward = 150, CoinReward = 15, CreatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc), UpdatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc) },
            new { Id = 3, Name = "Fleißiger Athlet", Description = "Schließe 3 verschiedene Übungen ab", Type = QuestType.Daily, Rarity = ItemRarity.Common, TargetType = QuestTargetType.ExercisesCompleted, TargetValue = 3, XpReward = 120, CoinReward = 12, CreatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc), UpdatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc) },
            // Wöchentliche Quests (Rare/Epic)
            new { Id = 4, Name = "Cardio Champion", Description = "Schließe 20 Übungen diese Woche ab", Type = QuestType.Weekly, Rarity = ItemRarity.Rare, TargetType = QuestTargetType.ExercisesCompleted, TargetValue = 20, XpReward = 500, CoinReward = 50, CreatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc), UpdatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc) },
            new { Id = 5, Name = "Kraft Krieger", Description = "Mache insgesamt 1.000 Wiederholungen diese Woche", Type = QuestType.Weekly, Rarity = ItemRarity.Rare, TargetType = QuestTargetType.TotalReps, TargetValue = 1000, XpReward = 600, CoinReward = 60, CreatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc), UpdatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc) },
            new { Id = 6, Name = "Consistency King", Description = "Trainiere an 5 verschiedenen Tagen diese Woche", Type = QuestType.Weekly, Rarity = ItemRarity.Epic, TargetType = QuestTargetType.TrainingDays, TargetValue = 5, XpReward = 800, CoinReward = 80, CreatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc), UpdatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc) },
            // Monatliche Quests (Legendary)
            new { Id = 7, Name = "Marathon Meister", Description = "Schließe 60 Übungen diesen Monat ab", Type = QuestType.Monthly, Rarity = ItemRarity.Legendary, TargetType = QuestTargetType.ExercisesCompleted, TargetValue = 60, XpReward = 2000, CoinReward = 200, CreatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc), UpdatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc) },
            new { Id = 8, Name = "Iron Body", Description = "Mache insgesamt 10.000 Wiederholungen diesen Monat", Type = QuestType.Monthly, Rarity = ItemRarity.Legendary, TargetType = QuestTargetType.TotalReps, TargetValue = 10000, XpReward = 3000, CoinReward = 300, CreatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc), UpdatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc) },
            new { Id = 9, Name = "Transformer", Description = "Trainiere an 20 verschiedenen Tagen diesen Monat", Type = QuestType.Monthly, Rarity = ItemRarity.Legendary, TargetType = QuestTargetType.TrainingDays, TargetValue = 20, XpReward = 5000, CoinReward = 500, CreatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc), UpdatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc) }
        );

    }
}