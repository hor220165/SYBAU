using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sybau_Backend.Migrations
{
    /// <inheritdoc />
    public partial class InitialPostgreSQLMigration : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_UserItems_UserId",
                table: "UserItems");

            migrationBuilder.DropIndex(
                name: "IX_UserChallenges_UserId",
                table: "UserChallenges");

            migrationBuilder.AddColumn<DateTime>(
                name: "ClaimedAt",
                table: "UserChallenges",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "AvatarStageId",
                table: "Avatars",
                type: "INTEGER",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "Achievements",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Name = table.Column<string>(type: "TEXT", nullable: false),
                    Description = table.Column<string>(type: "TEXT", nullable: true),
                    IconUrl = table.Column<string>(type: "TEXT", nullable: false),
                    XpReward = table.Column<int>(type: "INTEGER", nullable: false),
                    CoinReward = table.Column<int>(type: "INTEGER", nullable: false),
                    CriteriaType = table.Column<int>(type: "INTEGER", nullable: false),
                    CriteriaValue = table.Column<int>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Achievements", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "AvatarStages",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Name = table.Column<string>(type: "TEXT", nullable: false),
                    Description = table.Column<string>(type: "TEXT", nullable: true),
                    MinXp = table.Column<int>(type: "INTEGER", nullable: false),
                    MaxXp = table.Column<int>(type: "INTEGER", nullable: false),
                    ImageUrl = table.Column<string>(type: "TEXT", nullable: false),
                    UnlockRequirements = table.Column<string>(type: "TEXT", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AvatarStages", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "FitnessProviderLinks",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    UserId = table.Column<int>(type: "INTEGER", nullable: false),
                    ProviderType = table.Column<int>(type: "INTEGER", nullable: false),
                    ProviderUserId = table.Column<string>(type: "TEXT", nullable: false),
                    AccessToken = table.Column<string>(type: "TEXT", nullable: true),
                    RefreshToken = table.Column<string>(type: "TEXT", nullable: true),
                    ExpiresAt = table.Column<DateTime>(type: "TEXT", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    IsActive = table.Column<bool>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FitnessProviderLinks", x => x.Id);
                    table.ForeignKey(
                        name: "FK_FitnessProviderLinks_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "LeaderboardSnapshots",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    UserId = table.Column<int>(type: "INTEGER", nullable: false),
                    Xp = table.Column<int>(type: "INTEGER", nullable: false),
                    Rank = table.Column<int>(type: "INTEGER", nullable: false),
                    Type = table.Column<int>(type: "INTEGER", nullable: false),
                    SnapshotDate = table.Column<DateTime>(type: "TEXT", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LeaderboardSnapshots", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LeaderboardSnapshots_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Notifications",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    UserId = table.Column<int>(type: "INTEGER", nullable: false),
                    Title = table.Column<string>(type: "TEXT", nullable: false),
                    Message = table.Column<string>(type: "TEXT", nullable: false),
                    Type = table.Column<int>(type: "INTEGER", nullable: false),
                    IsRead = table.Column<bool>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Notifications", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Notifications_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Streaks",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    UserId = table.Column<int>(type: "INTEGER", nullable: false),
                    Type = table.Column<int>(type: "INTEGER", nullable: false),
                    CurrentStreak = table.Column<int>(type: "INTEGER", nullable: false),
                    LongestStreak = table.Column<int>(type: "INTEGER", nullable: false),
                    LastActivityDate = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Streaks", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Streaks_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "SyncLogs",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    UserId = table.Column<int>(type: "INTEGER", nullable: false),
                    ProviderType = table.Column<int>(type: "INTEGER", nullable: false),
                    SyncType = table.Column<int>(type: "INTEGER", nullable: false),
                    RecordsSynced = table.Column<int>(type: "INTEGER", nullable: false),
                    Status = table.Column<int>(type: "INTEGER", nullable: false),
                    ErrorMessage = table.Column<string>(type: "TEXT", nullable: true),
                    StartedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "TEXT", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SyncLogs", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SyncLogs_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "WorkoutLogs",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    UserId = table.Column<int>(type: "INTEGER", nullable: false),
                    WorkoutId = table.Column<int>(type: "INTEGER", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    XpEarned = table.Column<int>(type: "INTEGER", nullable: false),
                    CoinsEarned = table.Column<int>(type: "INTEGER", nullable: false),
                    PerformanceScore = table.Column<int>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WorkoutLogs", x => x.Id);
                    table.ForeignKey(
                        name: "FK_WorkoutLogs_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_WorkoutLogs_Workouts_WorkoutId",
                        column: x => x.WorkoutId,
                        principalTable: "Workouts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserAchievements",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    UserId = table.Column<int>(type: "INTEGER", nullable: false),
                    AchievementId = table.Column<int>(type: "INTEGER", nullable: false),
                    EarnedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserAchievements", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserAchievements_Achievements_AchievementId",
                        column: x => x.AchievementId,
                        principalTable: "Achievements",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserAchievements_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Users_Email",
                table: "Users",
                column: "Email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserItems_UserId_ItemId",
                table: "UserItems",
                columns: new[] { "UserId", "ItemId" });

            migrationBuilder.CreateIndex(
                name: "IX_UserChallenges_UserId_ChallengeId",
                table: "UserChallenges",
                columns: new[] { "UserId", "ChallengeId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Avatars_AvatarStageId",
                table: "Avatars",
                column: "AvatarStageId");

            migrationBuilder.CreateIndex(
                name: "IX_Achievements_CriteriaType",
                table: "Achievements",
                column: "CriteriaType");

            migrationBuilder.CreateIndex(
                name: "IX_AvatarStages_MinXp_MaxXp",
                table: "AvatarStages",
                columns: new[] { "MinXp", "MaxXp" });

            migrationBuilder.CreateIndex(
                name: "IX_FitnessProviderLinks_UserId_ProviderType",
                table: "FitnessProviderLinks",
                columns: new[] { "UserId", "ProviderType" });

            migrationBuilder.CreateIndex(
                name: "IX_LeaderboardSnapshots_SnapshotDate_Rank",
                table: "LeaderboardSnapshots",
                columns: new[] { "SnapshotDate", "Rank" });

            migrationBuilder.CreateIndex(
                name: "IX_LeaderboardSnapshots_UserId",
                table: "LeaderboardSnapshots",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_UserId_IsRead",
                table: "Notifications",
                columns: new[] { "UserId", "IsRead" });

            migrationBuilder.CreateIndex(
                name: "IX_Streaks_UserId_Type",
                table: "Streaks",
                columns: new[] { "UserId", "Type" });

            migrationBuilder.CreateIndex(
                name: "IX_SyncLogs_StartedAt",
                table: "SyncLogs",
                column: "StartedAt");

            migrationBuilder.CreateIndex(
                name: "IX_SyncLogs_UserId_ProviderType_SyncType",
                table: "SyncLogs",
                columns: new[] { "UserId", "ProviderType", "SyncType" });

            migrationBuilder.CreateIndex(
                name: "IX_UserAchievements_AchievementId",
                table: "UserAchievements",
                column: "AchievementId");

            migrationBuilder.CreateIndex(
                name: "IX_UserAchievements_UserId_AchievementId",
                table: "UserAchievements",
                columns: new[] { "UserId", "AchievementId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_WorkoutLogs_CompletedAt",
                table: "WorkoutLogs",
                column: "CompletedAt");

            migrationBuilder.CreateIndex(
                name: "IX_WorkoutLogs_UserId",
                table: "WorkoutLogs",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_WorkoutLogs_WorkoutId",
                table: "WorkoutLogs",
                column: "WorkoutId");

            migrationBuilder.AddForeignKey(
                name: "FK_Avatars_AvatarStages_AvatarStageId",
                table: "Avatars",
                column: "AvatarStageId",
                principalTable: "AvatarStages",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Avatars_AvatarStages_AvatarStageId",
                table: "Avatars");

            migrationBuilder.DropTable(
                name: "AvatarStages");

            migrationBuilder.DropTable(
                name: "FitnessProviderLinks");

            migrationBuilder.DropTable(
                name: "LeaderboardSnapshots");

            migrationBuilder.DropTable(
                name: "Notifications");

            migrationBuilder.DropTable(
                name: "Streaks");

            migrationBuilder.DropTable(
                name: "SyncLogs");

            migrationBuilder.DropTable(
                name: "UserAchievements");

            migrationBuilder.DropTable(
                name: "WorkoutLogs");

            migrationBuilder.DropTable(
                name: "Achievements");

            migrationBuilder.DropIndex(
                name: "IX_Users_Email",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_UserItems_UserId_ItemId",
                table: "UserItems");

            migrationBuilder.DropIndex(
                name: "IX_UserChallenges_UserId_ChallengeId",
                table: "UserChallenges");

            migrationBuilder.DropIndex(
                name: "IX_Avatars_AvatarStageId",
                table: "Avatars");

            migrationBuilder.DropColumn(
                name: "ClaimedAt",
                table: "UserChallenges");

            migrationBuilder.DropColumn(
                name: "AvatarStageId",
                table: "Avatars");

            migrationBuilder.CreateIndex(
                name: "IX_UserItems_UserId",
                table: "UserItems",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_UserChallenges_UserId",
                table: "UserChallenges",
                column: "UserId");
        }
    }
}
