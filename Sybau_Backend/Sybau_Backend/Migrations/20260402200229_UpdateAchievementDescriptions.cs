using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sybau_Backend.Migrations
{
    /// <inheritdoc />
    public partial class UpdateAchievementDescriptions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 1,
                column: "Description",
                value: "Laufe insgesamt 5 km");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "Description", "TargetValue" },
                values: new object[] { "Mache insgesamt 10.000 Wiederholungen", 10000 });

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 3,
                column: "Description",
                value: "Erreiche eine 5-Tage Streak");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 4,
                column: "Description",
                value: "Schließe 10 Quests ab");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 5,
                column: "Description",
                value: "Erreiche Level 10");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 6,
                column: "Description",
                value: "Erreiche Platz 1 im Leaderboard");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 7,
                column: "Description",
                value: "Erreiche Level 25");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 8,
                column: "Description",
                value: "Trainiere an 30 verschiedenen Tagen");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 11,
                columns: new[] { "Description", "TargetValue" },
                values: new object[] { "Laufe insgesamt 50 km", 50 });

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 12,
                column: "Description",
                value: "Trainiere an 500 verschiedenen Tagen");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 13,
                column: "Description",
                value: "Trainiere 3 Kategorien in einer Woche");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 14,
                column: "Description",
                value: "Erreiche eine 60-Tage Streak");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 15,
                column: "Description",
                value: "Mache 1.000 Wiederholungen in 7 Tagen");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 16,
                column: "Description",
                value: "Schließe 3 monatliche Quests ab");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 1,
                column: "Description",
                value: "Laufe 5km unter 25 Min");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "Description", "TargetValue" },
                values: new object[] { "Hebe 1000kg gesamt", 1000 });

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 3,
                column: "Description",
                value: "5-Tage Streak");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 4,
                column: "Description",
                value: "10 Quests abschließen");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 5,
                column: "Description",
                value: "Level 10 erreichen");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 6,
                column: "Description",
                value: "Platz 1 im Leaderboard");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 7,
                column: "Description",
                value: "Level 25 erreichen");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 8,
                column: "Description",
                value: "Alle Daily Quests 30 Tage");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 11,
                columns: new[] { "Description", "TargetValue" },
                values: new object[] { "10km unter 40 Minuten", 10 });

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 12,
                column: "Description",
                value: "500 Workouts absolviert");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 13,
                column: "Description",
                value: "3 Kategorien in einer Woche trainieren");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 14,
                column: "Description",
                value: "60-Tage Streak");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 15,
                column: "Description",
                value: "1000 Wiederholungen in 7 Tagen");

            migrationBuilder.UpdateData(
                table: "Achievements",
                keyColumn: "Id",
                keyValue: 16,
                column: "Description",
                value: "3 monatliche Quests abschließen");
        }
    }
}
