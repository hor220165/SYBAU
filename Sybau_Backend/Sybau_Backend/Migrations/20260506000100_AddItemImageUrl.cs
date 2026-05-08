using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Sybau_Backend.Data;

#nullable disable

namespace Sybau_Backend.Migrations
{
    [DbContext(typeof(FitnessDbContext))]
    [Migration("20260506000100_AddItemImageUrl")]
    public partial class AddItemImageUrl : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ImageUrl",
                table: "Items",
                type: "TEXT",
                nullable: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ImageUrl",
                table: "Items");
        }
    }
}
