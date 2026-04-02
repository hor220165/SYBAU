using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Sybau_Backend.Migrations
{
    /// <inheritdoc />
    public partial class AddAchievementSystem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Achievements",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Key = table.Column<string>(type: "TEXT", nullable: false),
                    Title = table.Column<string>(type: "TEXT", nullable: false),
                    Description = table.Column<string>(type: "TEXT", nullable: false),
                    Type = table.Column<string>(type: "TEXT", nullable: false),
                    TargetValue = table.Column<int>(type: "INTEGER", nullable: false),
                    XpReward = table.Column<int>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Achievements", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "UserAchievements",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    UserId = table.Column<int>(type: "INTEGER", nullable: false),
                    AchievementId = table.Column<int>(type: "INTEGER", nullable: false),
                    UnlockedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserAchievements", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserAchievements_Achievements_AchievementId",
                        column: x => x.AchievementId,
                        principalTable: "Achievements",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserAchievements_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "Achievements",
                columns: new[] { "Id", "CreatedAt", "Description", "Key", "TargetValue", "Title", "Type", "UpdatedAt", "XpReward" },
                values: new object[,]
                {
                    { 1, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Laufe 5km unter 25 Min", "speedster", 5, "Speedster", "TotalKilometers", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 200 },
                    { 2, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Hebe 1000kg gesamt", "iron-body", 1000, "Iron Body", "TotalReps", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 300 },
                    { 3, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "5-Tage Streak", "on-fire", 5, "On Fire", "CurrentStreak", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 200 },
                    { 4, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "10 Quests abschließen", "quest-hunter", 10, "Quest Hunter", "QuestsCompleted", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 300 },
                    { 5, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Level 10 erreichen", "rising-star", 10, "Rising Star", "Level", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 500 },
                    { 6, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Platz 1 im Leaderboard", "champion", 1, "Champion", "LeaderboardRank", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1000 },
                    { 7, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Level 25 erreichen", "legend", 25, "Legend", "Level", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 800 },
                    { 8, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Alle Daily Quests 30 Tage", "perfectionist", 30, "Perfectionist", "TrainingDays", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1000 },
                    { 9, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Erreiche Level 50", "sky-rocket", 50, "Sky Rocket", "Level", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2000 },
                    { 10, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Trainiere 100 Tage in Folge", "diamond-grind", 100, "Diamond Grind", "CurrentStreak", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 3000 },
                    { 11, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "10km unter 40 Minuten", "speed-demon", 10, "Speed Demon", "TotalKilometers", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 400 },
                    { 12, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "500 Workouts absolviert", "workout-warrior", 500, "Workout Warrior", "TotalWorkouts", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 5000 },
                    { 13, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "3 Kategorien in einer Woche trainieren", "triathlon-master", 3, "Triathlon Master", "WeeklyCategories", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 500 },
                    { 14, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "60-Tage Streak", "shining-star", 60, "Shining Star", "CurrentStreak", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2000 },
                    { 15, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "1000 Wiederholungen in 7 Tagen", "bionic", 1000, "Bionic", "WeeklyReps", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1000 },
                    { 16, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "3 monatliche Quests abschließen", "elite-athlete", 3, "Elite Athlete", "MonthlyQuestsCompleted", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 3000 }
                });

            migrationBuilder.CreateIndex(
                name: "IX_UserAchievements_AchievementId",
                table: "UserAchievements",
                column: "AchievementId");

            migrationBuilder.CreateIndex(
                name: "IX_UserAchievements_UserId_AchievementId",
                table: "UserAchievements",
                columns: new[] { "UserId", "AchievementId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "UserAchievements");

            migrationBuilder.DropTable(
                name: "Achievements");
        }
    }
}
