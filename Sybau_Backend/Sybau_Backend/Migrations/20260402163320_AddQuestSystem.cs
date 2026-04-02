using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Sybau_Backend.Migrations
{
    /// <inheritdoc />
    public partial class AddQuestSystem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Quests",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Name = table.Column<string>(type: "TEXT", nullable: false),
                    Description = table.Column<string>(type: "TEXT", nullable: false),
                    Type = table.Column<string>(type: "TEXT", nullable: false),
                    Rarity = table.Column<string>(type: "TEXT", nullable: false),
                    TargetType = table.Column<string>(type: "TEXT", nullable: false),
                    TargetValue = table.Column<int>(type: "INTEGER", nullable: false),
                    XpReward = table.Column<int>(type: "INTEGER", nullable: false),
                    CoinReward = table.Column<int>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Quests", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "UserQuests",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    UserId = table.Column<int>(type: "INTEGER", nullable: false),
                    QuestId = table.Column<int>(type: "INTEGER", nullable: false),
                    Progress = table.Column<int>(type: "INTEGER", nullable: false),
                    IsCompleted = table.Column<bool>(type: "INTEGER", nullable: false),
                    IsRewardClaimed = table.Column<bool>(type: "INTEGER", nullable: false),
                    PeriodStart = table.Column<DateTime>(type: "TEXT", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "TEXT", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserQuests", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserQuests_Quests_QuestId",
                        column: x => x.QuestId,
                        principalTable: "Quests",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserQuests_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "Quests",
                columns: new[] { "Id", "CoinReward", "CreatedAt", "Description", "Name", "Rarity", "TargetType", "TargetValue", "Type", "UpdatedAt", "XpReward" },
                values: new object[,]
                {
                    { 1, 10, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Schließe eine Übung ab", "Tägliches Training", "Common", "ExercisesCompleted", 1, "Daily", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 100 },
                    { 2, 15, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Mache insgesamt 100 Wiederholungen", "Wiederholungsjäger", "Common", "TotalReps", 100, "Daily", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 150 },
                    { 3, 12, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Schließe 3 verschiedene Übungen ab", "Fleißiger Athlet", "Common", "ExercisesCompleted", 3, "Daily", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 120 },
                    { 4, 50, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Schließe 20 Übungen diese Woche ab", "Cardio Champion", "Rare", "ExercisesCompleted", 20, "Weekly", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 500 },
                    { 5, 60, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Mache insgesamt 1.000 Wiederholungen diese Woche", "Kraft Krieger", "Rare", "TotalReps", 1000, "Weekly", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 600 },
                    { 6, 80, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Trainiere an 5 verschiedenen Tagen diese Woche", "Consistency King", "Epic", "TrainingDays", 5, "Weekly", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 800 },
                    { 7, 200, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Schließe 60 Übungen diesen Monat ab", "Marathon Meister", "Legendary", "ExercisesCompleted", 60, "Monthly", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2000 },
                    { 8, 300, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Mache insgesamt 10.000 Wiederholungen diesen Monat", "Iron Body", "Legendary", "TotalReps", 10000, "Monthly", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 3000 },
                    { 9, 500, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Trainiere an 20 verschiedenen Tagen diesen Monat", "Transformer", "Legendary", "TrainingDays", 20, "Monthly", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 5000 }
                });

            migrationBuilder.CreateIndex(
                name: "IX_UserQuests_QuestId",
                table: "UserQuests",
                column: "QuestId");

            migrationBuilder.CreateIndex(
                name: "IX_UserQuests_UserId_QuestId_PeriodStart",
                table: "UserQuests",
                columns: new[] { "UserId", "QuestId", "PeriodStart" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "UserQuests");

            migrationBuilder.DropTable(
                name: "Quests");
        }
    }
}
