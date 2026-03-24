using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sybau_Backend.Migrations
{
    /// <inheritdoc />
    public partial class AddCoinBoostPercent : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "CoinBoostPercent",
                table: "Items",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CoinBoostPercent",
                table: "Items");
        }
    }
}
