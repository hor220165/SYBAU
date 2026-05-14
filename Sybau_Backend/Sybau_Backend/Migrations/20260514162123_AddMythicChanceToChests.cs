using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Sybau_Backend.Data;

#nullable disable

namespace Sybau_Backend.Migrations
{
    [DbContext(typeof(FitnessDbContext))]
    [Migration("20260514162123_AddMythicChanceToChests")]
    public partial class AddMythicChanceToChests : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "MythicChance",
                table: "Chests",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "MythicChance",
                table: "Chests");
        }
    }
}
