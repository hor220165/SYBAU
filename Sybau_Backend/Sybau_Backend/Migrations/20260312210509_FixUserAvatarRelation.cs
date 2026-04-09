using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sybau_Backend.Migrations
{
    /// <inheritdoc />
    public partial class FixUserAvatarRelation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // No schema changes needed - the AvatarStageId column already exists in the database
            // This migration is primarily to update the EF Core model snapshot
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // No reversal needed
        }
    }
}