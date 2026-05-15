using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Sybau_Backend.Migrations.Postgres
{
    /// <inheritdoc />
    public partial class AddMoreAchievementsPostgres : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "Achievements",
                columns: new[] { "Id", "CreatedAt", "Description", "Key", "TargetValue", "Title", "Type", "UpdatedAt", "XpReward" },
                values: new object[,]
                {
                    { 17, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Laufe insgesamt 1 km", "first-kilometer", 1, "First Kilometer", "TotalKilometers", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 100 },
                    { 18, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Laufe insgesamt 10 km", "distance-rookie", 10, "Distance Rookie", "TotalKilometers", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 250 },
                    { 19, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Laufe insgesamt 25 km", "road-runner", 25, "Road Runner", "TotalKilometers", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 350 },
                    { 20, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Laufe insgesamt 100 km", "ultra-runner", 100, "Ultra Runner", "TotalKilometers", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 800 },
                    { 21, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Laufe insgesamt 250 km", "horizon-chaser", 250, "Horizon Chaser", "TotalKilometers", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1600 },
                    { 22, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Laufe insgesamt 500 km", "world-walker", 500, "World Walker", "TotalKilometers", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 3000 },
                    { 23, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Mache insgesamt 500 Wiederholungen", "rep-starter", 500, "Rep Starter", "TotalReps", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 150 },
                    { 24, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Mache insgesamt 2.500 Wiederholungen", "rep-machine", 2500, "Rep Machine", "TotalReps", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 300 },
                    { 25, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Mache insgesamt 5.000 Wiederholungen", "steel-engine", 5000, "Steel Engine", "TotalReps", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 450 },
                    { 26, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Mache insgesamt 25.000 Wiederholungen", "titan-arms", 25000, "Titan Arms", "TotalReps", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1200 },
                    { 27, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Mache insgesamt 50.000 Wiederholungen", "rep-overlord", 50000, "Rep Overlord", "TotalReps", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2200 },
                    { 28, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Mache insgesamt 100.000 Wiederholungen", "motion-master", 100000, "Motion Master", "TotalReps", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 4000 },
                    { 29, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Erreiche eine 3-Tage Streak", "spark-streak", 3, "Spark Streak", "CurrentStreak", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 150 },
                    { 30, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Erreiche eine 7-Tage Streak", "week-flame", 7, "Week Flame", "CurrentStreak", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 300 },
                    { 31, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Erreiche eine 14-Tage Streak", "two-week-burn", 14, "Two Week Burn", "CurrentStreak", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 500 },
                    { 32, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Erreiche eine 30-Tage Streak", "monthly-fire", 30, "Monthly Fire", "CurrentStreak", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 900 },
                    { 33, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Erreiche eine 180-Tage Streak", "unstoppable", 180, "Unstoppable", "CurrentStreak", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 3500 },
                    { 34, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Erreiche eine 365-Tage Streak", "year-of-fire", 365, "Year of Fire", "CurrentStreak", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 7000 },
                    { 35, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Schließe 1 Quest ab", "quest-initiate", 1, "Quest Initiate", "QuestsCompleted", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 100 },
                    { 36, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Schließe 25 Quests ab", "quest-veteran", 25, "Quest Veteran", "QuestsCompleted", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 600 },
                    { 37, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Schließe 50 Quests ab", "quest-master", 50, "Quest Master", "QuestsCompleted", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1100 },
                    { 38, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Schließe 100 Quests ab", "quest-legend", 100, "Quest Legend", "QuestsCompleted", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2200 },
                    { 39, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Erreiche Level 5", "level-spark", 5, "Level Spark", "Level", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 200 },
                    { 40, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Erreiche Level 15", "ascender", 15, "Ascender", "Level", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 600 },
                    { 41, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Erreiche Level 35", "power-house", 35, "Power House", "Level", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1200 },
                    { 42, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Erreiche Level 75", "apex-level", 75, "Apex Level", "Level", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 3000 },
                    { 43, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Erreiche Level 100", "level-immortal", 100, "Level Immortal", "Level", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 5000 },
                    { 44, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Trainiere an 7 verschiedenen Tagen", "steady-start", 7, "Steady Start", "TrainingDays", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 250 },
                    { 45, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Trainiere an 14 verschiedenen Tagen", "disciplined", 14, "Disciplined", "TrainingDays", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 400 },
                    { 46, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Trainiere an 60 verschiedenen Tagen", "habit-forged", 60, "Habit Forged", "TrainingDays", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1200 },
                    { 47, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Trainiere an 100 verschiedenen Tagen", "century-club", 100, "Century Club", "TrainingDays", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2000 },
                    { 48, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Mache 2.500 Wiederholungen in 7 Tagen", "weekly-beast", 2500, "Weekly Beast", "WeeklyReps", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 700 },
                    { 49, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Schließe 6 monatliche Quests ab", "monthly-collector", 6, "Monthly Collector", "MonthlyQuestsCompleted", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1500 },
                    { 50, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Trainiere 4 Kategorien in einer Woche", "full-spectrum", 4, "Full Spectrum", "WeeklyCategories", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 800 }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 17);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 18);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 19);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 20);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 21);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 22);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 23);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 24);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 25);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 26);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 27);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 28);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 29);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 30);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 31);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 32);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 33);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 34);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 35);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 36);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 37);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 38);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 39);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 40);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 41);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 42);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 43);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 44);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 45);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 46);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 47);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 48);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 49);

            migrationBuilder.DeleteData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 50);
        }
    }
}
