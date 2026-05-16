using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Sybau_Backend.Data;

#nullable disable

namespace Sybau_Backend.Migrations
{
    [DbContext(typeof(FitnessDbContext))]
    [Migration("20260516120610_AddUserProfilePrivacySqlite")]
    public partial class AddUserProfilePrivacySqlite : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsProfilePrivate",
                table: "Users",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsProfilePrivate",
                table: "Users");
        }
    }
}
