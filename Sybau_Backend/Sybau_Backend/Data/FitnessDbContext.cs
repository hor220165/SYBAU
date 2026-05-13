using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Models;
using Sybau_Backend.Models.Enums;

namespace Sybau_Backend.Data;

public class FitnessDbContext:DbContext
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Avatar> Avatars => Set<Avatar>();
    public DbSet<Item> Items => Set<Item>();
    public DbSet<Chest> Chests => Set<Chest>();
    public DbSet<ChestItem> ChestItems => Set<ChestItem>();
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
    public DbSet<ActivityLog> ActivityLogs => Set<ActivityLog>();
    public DbSet<Achievement> Achievements => Set<Achievement>();
    public DbSet<UserAchievement> UserAchievements => Set<UserAchievement>();
    public DbSet<Friendship> Friendships => Set<Friendship>();
    public DbSet<FriendChallenge> FriendChallenges => Set<FriendChallenge>();
    public FitnessDbContext(DbContextOptions options) : base(options){}

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

        modelBuilder.Entity<ChestItem>(entity =>
        {
            entity.HasOne(ci => ci.Chest)
                .WithMany(c => c.ChestItems)
                .HasForeignKey(ci => ci.ChestId)
                .IsRequired();

            entity.HasOne(ci => ci.Item)
                .WithMany()
                .HasForeignKey(ci => ci.ItemId)
                .IsRequired();

            entity.HasIndex(ci => new { ci.ChestId, ci.ItemId }).IsUnique();
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

        // ActivityLog
        modelBuilder.Entity<ActivityLog>(entity =>
        {
            entity.HasOne(a => a.User)
                .WithMany()
                .HasForeignKey(a => a.UserId)
                .IsRequired();

            entity.Property(a => a.Type).HasConversion<string>();
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
            new { Id = 9, Name = "Transformer", Description = "Trainiere an 20 verschiedenen Tagen diesen Monat", Type = QuestType.Monthly, Rarity = ItemRarity.Legendary, TargetType = QuestTargetType.TrainingDays, TargetValue = 20, XpReward = 5000, CoinReward = 500, CreatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc), UpdatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc) },
            // Schritte & Kilometer Quests
            new { Id = 10, Name = "Step Master", Description = "Laufe 10.000 Schritte", Type = QuestType.Daily, Rarity = ItemRarity.Common, TargetType = QuestTargetType.Steps, TargetValue = 10000, XpReward = 120, CoinReward = 12, CreatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc), UpdatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc) },
            new { Id = 11, Name = "Wanderer", Description = "Laufe insgesamt 10 km diese Woche", Type = QuestType.Weekly, Rarity = ItemRarity.Rare, TargetType = QuestTargetType.Kilometers, TargetValue = 10, XpReward = 500, CoinReward = 50, CreatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc), UpdatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc) },
            new { Id = 12, Name = "Marathon Läufer", Description = "Laufe insgesamt 42 km diesen Monat", Type = QuestType.Monthly, Rarity = ItemRarity.Legendary, TargetType = QuestTargetType.Kilometers, TargetValue = 42, XpReward = 2000, CoinReward = 200, CreatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc), UpdatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc) }
        );

        // Achievement Entity Config
        modelBuilder.Entity<Achievement>(entity =>
        {
            entity.Property(a => a.Type).HasConversion<string>();
        });

        modelBuilder.Entity<UserAchievement>(entity =>
        {
            entity.HasOne(ua => ua.User)
                .WithMany(u => u.UserAchievements)
                .HasForeignKey(ua => ua.UserId)
                .IsRequired();

            entity.HasOne(ua => ua.Achievement)
                .WithMany(a => a.UserAchievements)
                .HasForeignKey(ua => ua.AchievementId)
                .IsRequired();

            entity.HasIndex(ua => new { ua.UserId, ua.AchievementId }).IsUnique();
        });

        // Achievement Seed Data (passend zu den 16 Frontend-Achievements)
        var seedDate = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc);
        modelBuilder.Entity<Achievement>().HasData(
            new { Id = 1,  Key = "speedster",        Title = "Speedster",         Description = "Laufe insgesamt 5 km",                    Type = AchievementType.TotalKilometers,       TargetValue = 5,     XpReward = 200,  CreatedAt = seedDate, UpdatedAt = seedDate },
            new { Id = 2,  Key = "iron-body",        Title = "Iron Body",         Description = "Mache insgesamt 10.000 Wiederholungen",   Type = AchievementType.TotalReps,             TargetValue = 10000, XpReward = 300,  CreatedAt = seedDate, UpdatedAt = seedDate },
            new { Id = 3,  Key = "on-fire",          Title = "On Fire",           Description = "Erreiche eine 5-Tage Streak",             Type = AchievementType.CurrentStreak,         TargetValue = 5,     XpReward = 200,  CreatedAt = seedDate, UpdatedAt = seedDate },
            new { Id = 4,  Key = "quest-hunter",     Title = "Quest Hunter",      Description = "Schließe 10 Quests ab",                   Type = AchievementType.QuestsCompleted,       TargetValue = 10,    XpReward = 300,  CreatedAt = seedDate, UpdatedAt = seedDate },
            new { Id = 5,  Key = "rising-star",      Title = "Rising Star",       Description = "Erreiche Level 10",                       Type = AchievementType.Level,                 TargetValue = 10,    XpReward = 500,  CreatedAt = seedDate, UpdatedAt = seedDate },
            new { Id = 6,  Key = "champion",         Title = "Champion",          Description = "Erreiche Platz 1 im Leaderboard",         Type = AchievementType.LeaderboardRank,       TargetValue = 1,     XpReward = 1000, CreatedAt = seedDate, UpdatedAt = seedDate },
            new { Id = 7,  Key = "legend",           Title = "Legend",            Description = "Erreiche Level 25",                       Type = AchievementType.Level,                 TargetValue = 25,    XpReward = 800,  CreatedAt = seedDate, UpdatedAt = seedDate },
            new { Id = 8,  Key = "perfectionist",    Title = "Perfectionist",     Description = "Trainiere an 30 verschiedenen Tagen",     Type = AchievementType.TrainingDays,          TargetValue = 30,    XpReward = 1000, CreatedAt = seedDate, UpdatedAt = seedDate },
            new { Id = 9,  Key = "sky-rocket",       Title = "Sky Rocket",        Description = "Erreiche Level 50",                       Type = AchievementType.Level,                 TargetValue = 50,    XpReward = 2000, CreatedAt = seedDate, UpdatedAt = seedDate },
            new { Id = 10, Key = "diamond-grind",    Title = "Diamond Grind",     Description = "Trainiere 100 Tage in Folge",             Type = AchievementType.CurrentStreak,         TargetValue = 100,   XpReward = 3000, CreatedAt = seedDate, UpdatedAt = seedDate },
            new { Id = 11, Key = "speed-demon",      Title = "Speed Demon",       Description = "Laufe insgesamt 50 km",                   Type = AchievementType.TotalKilometers,       TargetValue = 50,    XpReward = 400,  CreatedAt = seedDate, UpdatedAt = seedDate },
            new { Id = 12, Key = "workout-warrior",  Title = "Workout Warrior",   Description = "Trainiere an 500 verschiedenen Tagen",    Type = AchievementType.TotalWorkouts,         TargetValue = 500,   XpReward = 5000, CreatedAt = seedDate, UpdatedAt = seedDate },
            new { Id = 13, Key = "triathlon-master", Title = "Triathlon Master",  Description = "Trainiere 3 Kategorien in einer Woche",   Type = AchievementType.WeeklyCategories,      TargetValue = 3,     XpReward = 500,  CreatedAt = seedDate, UpdatedAt = seedDate },
            new { Id = 14, Key = "shining-star",     Title = "Shining Star",      Description = "Erreiche eine 60-Tage Streak",            Type = AchievementType.CurrentStreak,         TargetValue = 60,    XpReward = 2000, CreatedAt = seedDate, UpdatedAt = seedDate },
            new { Id = 15, Key = "bionic",           Title = "Bionic",            Description = "Mache 1.000 Wiederholungen in 7 Tagen",   Type = AchievementType.WeeklyReps,            TargetValue = 1000,  XpReward = 1000, CreatedAt = seedDate, UpdatedAt = seedDate },
            new { Id = 16, Key = "elite-athlete",    Title = "Elite Athlete",     Description = "Schließe 3 monatliche Quests ab",         Type = AchievementType.MonthlyQuestsCompleted,TargetValue = 3,     XpReward = 3000, CreatedAt = seedDate, UpdatedAt = seedDate }
        );

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
