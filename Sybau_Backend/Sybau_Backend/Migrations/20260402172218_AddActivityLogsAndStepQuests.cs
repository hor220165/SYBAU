using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Sybau_Backend.Migrations
{
    /// <inheritdoc />
    public partial class AddActivityLogsAndStepQuests : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ActivityLogs",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    UserId = table.Column<int>(type: "INTEGER", nullable: false),
                    Type = table.Column<string>(type: "TEXT", nullable: false),
                    Value = table.Column<double>(type: "REAL", nullable: false),
                    Date = table.Column<DateOnly>(type: "TEXT", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ActivityLogs", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ActivityLogs_Users_UserId",
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
                    { 10, 12, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Laufe 10.000 Schritte", "Step Master", "Common", "Steps", 10000, "Daily", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 120 },
                    { 11, 50, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Laufe insgesamt 10 km diese Woche", "Wanderer", "Rare", "Kilometers", 10, "Weekly", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 500 },
                    { 12, 200, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Laufe insgesamt 42 km diesen Monat", "Marathon Läufer", "Legendary", "Kilometers", 42, "Monthly", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2000 }
                });

            migrationBuilder.CreateIndex(
                name: "IX_ActivityLogs_UserId",
                table: "ActivityLogs",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ActivityLogs");

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: 10);

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: 11);

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: 12);
        }
    }
}
