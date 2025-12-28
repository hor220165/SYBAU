using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sybau_Backend.Migrations
{
    /// <inheritdoc />
    public partial class Updates : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Avatars_Users_UserId",
                table: "Avatars");

            migrationBuilder.DropColumn(
                name: "Name",
                table: "Avatars");

            migrationBuilder.AlterColumn<int>(
                name: "UserId",
                table: "Avatars",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "INTEGER",
                oldNullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Boost1",
                table: "Avatars",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Boost2",
                table: "Avatars",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Boost3",
                table: "Avatars",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Boost4",
                table: "Avatars",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Avatars_Users_UserId",
                table: "Avatars",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Avatars_Users_UserId",
                table: "Avatars");

            migrationBuilder.DropColumn(
                name: "Boost1",
                table: "Avatars");

            migrationBuilder.DropColumn(
                name: "Boost2",
                table: "Avatars");

            migrationBuilder.DropColumn(
                name: "Boost3",
                table: "Avatars");

            migrationBuilder.DropColumn(
                name: "Boost4",
                table: "Avatars");

            migrationBuilder.AlterColumn<int>(
                name: "UserId",
                table: "Avatars",
                type: "INTEGER",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "INTEGER");

            migrationBuilder.AddColumn<string>(
                name: "Name",
                table: "Avatars",
                type: "TEXT",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddForeignKey(
                name: "FK_Avatars_Users_UserId",
                table: "Avatars",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id");
        }
    }
}
