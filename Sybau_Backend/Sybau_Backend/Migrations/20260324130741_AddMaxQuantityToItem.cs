using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sybau_Backend.Migrations
{
    /// <inheritdoc />
    public partial class AddMaxQuantityToItem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "MaxQuantity",
                table: "Items",
                type: "INTEGER",
                nullable: false,
                defaultValue: 5);

            // Bestehende Items: MaxQuantity basierend auf Seltenheit setzen
            migrationBuilder.Sql(@"
                UPDATE Items SET MaxQuantity = CASE
                    WHEN XpBoostPercent >= 100 THEN 1
                    WHEN XpBoostPercent >= 60  THEN 2
                    WHEN XpBoostPercent >= 25  THEN 3
                    ELSE 5
                END;
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "MaxQuantity",
                table: "Items");
        }
    }
}
