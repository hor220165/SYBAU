using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sybau_Backend.Migrations
{
    /// <inheritdoc />
    public partial class AddChestSystem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Chests",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Name = table.Column<string>(type: "TEXT", nullable: false),
                    Price = table.Column<int>(type: "INTEGER", nullable: false),
                    ImageUrl = table.Column<string>(type: "TEXT", nullable: false),
                    CommonChance = table.Column<int>(type: "INTEGER", nullable: false),
                    RareChance = table.Column<int>(type: "INTEGER", nullable: false),
                    EpicChance = table.Column<int>(type: "INTEGER", nullable: false),
                    LegendaryChance = table.Column<int>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Chests", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "ChestItems",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    ChestId = table.Column<int>(type: "INTEGER", nullable: false),
                    ItemId = table.Column<int>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChestItems", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ChestItems_Chests_ChestId",
                        column: x => x.ChestId,
                        principalTable: "Chests",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ChestItems_Items_ItemId",
                        column: x => x.ItemId,
                        principalTable: "Items",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ChestItems_ChestId_ItemId",
                table: "ChestItems",
                columns: new[] { "ChestId", "ItemId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ChestItems_ItemId",
                table: "ChestItems",
                column: "ItemId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ChestItems");

            migrationBuilder.DropTable(
                name: "Chests");
        }
    }
}
