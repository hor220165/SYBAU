using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Sybau_Backend._Services;
using Sybau_Backend.Data;
using Sybau_Backend.DTOs;
using Sybau_Backend.Models;

namespace Sybau_Backend.Controllers
{
    [Route("[controller]")]
    [ApiController]
    public class UsersController : ControllerBase
    {
        private const int MaxProfileImageBytes = 5 * 1024 * 1024;

        private readonly UserService _userService;
        private readonly AchievementService _achievementService;
        private readonly BodyStageService _bodyStageService;
        private readonly AvatarService _avatarService;
        private readonly IWebHostEnvironment _environment;

        public UsersController(
            UserService userService,
            AchievementService achievementService,
            BodyStageService bodyStageService,
            AvatarService avatarService,
            IWebHostEnvironment environment)
        {
            _userService = userService;
            _achievementService = achievementService;
            _bodyStageService = bodyStageService;
            _avatarService = avatarService;
            _environment = environment;
        }
        
        // GET /users/profile
        [Authorize]
        [HttpGet("profile")]
        public async Task<IActionResult> GetProfile()
        {
            // UserId aus JWT Claims lesen
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var user = await _userService.GetUserById(userId);

            if (user == null) return NotFound();

            // Optional: Avatar, Boosts etc.
            var avatarDto = new AvatarDto
            {
                Id = user.Avatar.Id,
                Level = user.Avatar.Level,
                Experience = user.Avatar.Experience,
                BodyStage = _bodyStageService.GetBodyStage(user.Avatar.Level),
                XpForNextLevel = _avatarService.XpForNextLevel(user.Avatar.Level),
                Boost1 = user.Avatar.Boost1,
                Boost2 = user.Avatar.Boost2,
                Boost3 = user.Avatar.Boost3,
                Boost4 = user.Avatar.Boost4
            };

            return Ok(new UserDto
            {
                Id = user.Id,
                UserName = user.UserName,
                Email = user.Email,
                ProfileImageUrl = user.ProfileImageUrl,
                Coins = user.Coins,
                TotalXp = CalculateTotalXp(user.Avatar.Level, user.Avatar.Experience),
                Avatar = avatarDto,
                IsAdmin = user.IsAdmin,
            });
        }

        // GET /users/{id}/profile
        [Authorize]
        [HttpGet("{id:int}/profile")]
        public async Task<IActionResult> GetPublicProfile(int id)
        {
            var user = await _userService.GetUserById(id);
            if (user == null || user.IsAdmin) return NotFound();

            var avatarDto = new AvatarDto
            {
                Id = user.Avatar.Id,
                Level = user.Avatar.Level,
                Experience = user.Avatar.Experience,
                BodyStage = _bodyStageService.GetBodyStage(user.Avatar.Level),
                XpForNextLevel = _avatarService.XpForNextLevel(user.Avatar.Level),
                Boost1 = user.Avatar.Boost1,
                Boost2 = user.Avatar.Boost2,
                Boost3 = user.Avatar.Boost3,
                Boost4 = user.Avatar.Boost4
            };

            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var monday = today.AddDays(-(int)today.DayOfWeek + (today.DayOfWeek == DayOfWeek.Sunday ? -6 : 1));
            var sunday = monday.AddDays(6);

            ProfileStatsDto stats;
            List<AchievementDto> achievements;
            List<WeeklyActivityDto> weeklyActivity;
            List<RecentActivityDto> recentActivities;

            try
            {
                stats = await _achievementService.GetProfileStatsAsync(id);
            }
            catch
            {
                stats = new ProfileStatsDto();
            }

            try
            {
                achievements = await _achievementService.GetUserAchievementsReadOnlyAsync(id);
            }
            catch
            {
                achievements = new List<AchievementDto>();
            }

            try
            {
                weeklyActivity = await _userService.GetWeeklyActivityAsync(id, monday, sunday);
            }
            catch
            {
                weeklyActivity = new List<WeeklyActivityDto>();
            }

            try
            {
                recentActivities = await _userService.GetRecentActivitiesAsync(id, 8);
            }
            catch
            {
                recentActivities = new List<RecentActivityDto>();
            }

            return Ok(new PublicUserProfileDto
            {
                Id = user.Id,
                UserName = user.UserName,
                ProfileImageUrl = user.ProfileImageUrl,
                Avatar = avatarDto,
                TotalXp = CalculateTotalXp(user.Avatar.Level, user.Avatar.Experience),
                Stats = stats,
                Achievements = achievements,
                WeeklyActivity = weeklyActivity,
                RecentActivities = recentActivities
            });
        }
        
        // PUT /users/profile
        [Authorize]
        [HttpPut("profile")]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateUserDto dto)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var user = await _userService.GetUserById(userId);
            if (user == null) return NotFound();

            if (!string.IsNullOrEmpty(dto.Username))
                user.UserName = dto.Username;

            await _userService.UpdateUserAsync(user);

            return NoContent();
        }

        private static int CalculateTotalXp(int level, int experience)
        {
            var total = 0;
            for (var lvl = 1; lvl < level; lvl++)
            {
                total += 100 + lvl * lvl * 20;
            }

            return total + experience;
        }

        // POST /users/profile/image
        [Authorize]
        [HttpPost("profile/image")]
        [RequestSizeLimit(MaxProfileImageBytes)]
        public async Task<IActionResult> UploadProfileImage([FromForm] IFormFile image)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            if (image == null || image.Length == 0)
                return BadRequest("Kein Bild hochgeladen.");
            if (image.Length > MaxProfileImageBytes)
                return BadRequest("Profilbild darf maximal 5 MB groß sein.");

            var extension = Path.GetExtension(image.FileName);
            var allowedExtensions = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                ".jpg",
                ".jpeg",
                ".png",
                ".webp",
                ".heic",
                ".heif"
            };
            var hasImageContentType =
                !string.IsNullOrWhiteSpace(image.ContentType) &&
                image.ContentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase);
            var hasAllowedExtension =
                !string.IsNullOrWhiteSpace(extension) &&
                allowedExtensions.Contains(extension);

            if (!hasImageContentType && !hasAllowedExtension)
                return BadRequest("Nur Bilddateien sind erlaubt.");

            var userId = int.Parse(userIdClaim);
            var user = await _userService.GetUserById(userId);
            if (user == null) return NotFound();

            DeleteLocalUpload(user.ProfileImageUrl);

            if (string.IsNullOrWhiteSpace(extension))
            {
                extension = (image.ContentType ?? string.Empty).ToLowerInvariant() switch
                {
                    "image/png" => ".png",
                    "image/webp" => ".webp",
                    "image/heic" => ".heic",
                    "image/heif" => ".heif",
                    _ => ".jpg"
                };
            }

            await using var memory = new MemoryStream();
            await image.CopyToAsync(memory);

            var contentType = GetImageContentType(image.ContentType, extension);
            var profileImageUrl = $"data:{contentType};base64,{Convert.ToBase64String(memory.ToArray())}";
            await _userService.SetProfileImageUrlAsync(user.Id, profileImageUrl);

            return Ok(new { profileImageUrl });
        }

        private static string GetImageContentType(string? contentType, string extension)
        {
            if (!string.IsNullOrWhiteSpace(contentType) &&
                contentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase))
            {
                return contentType.Split(';', 2)[0].Trim().ToLowerInvariant();
            }

            return extension.ToLowerInvariant() switch
            {
                ".png" => "image/png",
                ".webp" => "image/webp",
                ".heic" => "image/heic",
                ".heif" => "image/heif",
                _ => "image/jpeg"
            };
        }

        private void DeleteLocalUpload(string? imageUrl)
        {
            if (string.IsNullOrWhiteSpace(imageUrl) ||
                !imageUrl.StartsWith("/uploads/", StringComparison.OrdinalIgnoreCase))
            {
                return;
            }

            var relativePath = imageUrl.TrimStart('/')
                .Replace('/', Path.DirectorySeparatorChar);
            var uploadsRoot = Path.GetFullPath(Path.Combine(_environment.ContentRootPath, "wwwroot", "uploads"));
            var fullPath = Path.GetFullPath(Path.Combine(_environment.ContentRootPath, "wwwroot", relativePath));

            if (!fullPath.StartsWith(uploadsRoot, StringComparison.OrdinalIgnoreCase))
            {
                return;
            }

            if (System.IO.File.Exists(fullPath))
            {
                System.IO.File.Delete(fullPath);
            }
        }

        // DELETE /users/profile/image
        [Authorize]
        [HttpDelete("profile/image")]
        public async Task<IActionResult> RemoveProfileImage()
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var user = await _userService.GetUserById(userId);
            if (user == null) return NotFound();

            DeleteLocalUpload(user.ProfileImageUrl);

            await _userService.SetProfileImageUrlAsync(user.Id, null);

            return NoContent();
        }
        
        [Authorize]
        [EnableRateLimiting("sensitive")]
        [HttpPost("profile/change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordDto dto)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var user = await _userService.GetUserById(userId);
            if (user == null) return NotFound();

            var passwordHasher = new PasswordHasher<User>();
            var result = passwordHasher.VerifyHashedPassword(user, user.PasswordHash, dto.OldPassword);

            if (result != PasswordVerificationResult.Success)
                return BadRequest("Altes Passwort ist falsch.");

            // Neues Passwort hashen
            user.PasswordHash = passwordHasher.HashPassword(user, dto.NewPassword);
            await _userService.UpdateUserAsync(user);

            return NoContent(); // 204 OK ohne Body
        }
        
        [Authorize]
        [HttpDelete("profile")]
        public async Task<IActionResult> DeleteAccount()
        {
            // UserId aus JWT Claims lesen
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var user = await _userService.GetUserById(userId);
            if (user == null) return NotFound();

            // User löschen
            await _userService.DeleteUserAsync(userId);

            return NoContent(); // 204 OK
        }
      
        
        [HttpGet("leaderboard")]
        public async Task<IActionResult> GetLeaderboard()
        {
            var topUsers = await _userService.GetLeaderboard();
            return Ok(topUsers);
        }

        // GET /users/profile/streaks
        [Authorize]
        [HttpGet("profile/streaks")]
        public async Task<IActionResult> GetStreaks()
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var (longestStreak, currentStreak) = await _userService.GetStreaksAsync(userId);

            return Ok(new { longestStreak, currentStreak });
        }

        // GET /users/profile/weekly-activity?from=2026-03-23&to=2026-03-29
        [Authorize]
        [HttpGet("profile/weekly-activity")]
        public async Task<IActionResult> GetWeeklyActivity([FromQuery] DateOnly from, [FromQuery] DateOnly to)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var activities = await _userService.GetWeeklyActivityAsync(userId, from, to);

            return Ok(activities);
        }

        // GET /users/profile/recent-activities?limit=10
        [Authorize]
        [HttpGet("profile/recent-activities")]
        public async Task<IActionResult> GetRecentActivities([FromQuery] int limit = 10)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var activities = await _userService.GetRecentActivitiesAsync(userId, limit);

            return Ok(activities);
        }

        // GET: api/<UsersController>
        [Authorize]
        [HttpGet]
        public async Task<IActionResult> GetUsers()
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (userIdClaim == null)
                return Unauthorized();

            var currentUserId = int.Parse(userIdClaim);
            
            var users = await _userService.GetUsersExcept(currentUserId);
            return Ok(users.Select(u => new UserDto
            {
                Id = u.Id,
                UserName = u.UserName,
                Email = u.Email,
                ProfileImageUrl = u.ProfileImageUrl,
                Coins = u.Coins,
                IsAdmin = u.IsAdmin,
                Avatar = new AvatarDto
                {
                    Id = u.Avatar.Id,
                    Level = u.Avatar.Level,
                    Experience = u.Avatar.Experience,
                    BodyStage = _bodyStageService.GetBodyStage(u.Avatar.Level),
                    XpForNextLevel = _avatarService.XpForNextLevel(u.Avatar.Level),
                    Boost1 = u.Avatar.Boost1,
                    Boost2 = u.Avatar.Boost2,
                    Boost3 = u.Avatar.Boost3,
                    Boost4 = u.Avatar.Boost4
                }
            }));
        }


        // GET api/<UsersController>/5
        [Authorize]
        [HttpGet("{id}")]
        public async Task<ActionResult<UserDto>> GetById(int id)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null)
                return Unauthorized();

            var currentUserId = int.Parse(userIdClaim);
            var isAdmin = User.HasClaim("isAdmin", "True");

            if (currentUserId != id && !isAdmin)
                return Forbid();

            var user = await _userService.GetUserById(id);

            if (user == null)
                return NotFound();
            
            var avatarDto = new AvatarDto{Id = user.Avatar.Id,Level = user.Avatar.Level,Experience = user.Avatar.Experience,XpForNextLevel = _avatarService.XpForNextLevel(user.Avatar.Level),Boost1 = user.Avatar.Boost1,Boost2 = user.Avatar.Boost2,Boost3 = user.Avatar.Boost3,Boost4 = user.Avatar.Boost4,BodyStage = _bodyStageService.GetBodyStage(user.Avatar.Level)};

            return Ok(new UserDto
            {
                Id = user.Id,
                UserName = user.UserName,
                Email = user.Email,
                ProfileImageUrl = user.ProfileImageUrl,
                Coins = user.Coins,
                Avatar = avatarDto,
                IsAdmin = user.IsAdmin
            });
        }
        
        // POST: api/users/{userId}/challenge/{challengeId}/complete
        [Authorize]
        [HttpPost("{userId}/challenge/{challengeId}/complete")]
        public async Task<IActionResult> CompleteChallenge(int userId, int challengeId)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null)
                return Unauthorized();

            var currentUserId = int.Parse(userIdClaim);
            var isAdmin = User.HasClaim("isAdmin", "True");

            if (currentUserId != userId && !isAdmin)
                return Forbid();

            var updatedAvatar = await _userService.CompleteChallengeAsync(userId, challengeId);

            if (updatedAvatar == null)
                return BadRequest("User oder Challenge nicht gefunden");

            return Ok(updatedAvatar);
        }
        
        // GET /users/boosts - Gekaufte Booster-Items des Users
        [Authorize]
        [HttpGet("boosts")]
        public async Task<IActionResult> GetUserBoosters()
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var boosters = await _userService.GetUserBoostersAsync(userId);
            return Ok(boosters);
        }

        // PUT /users/boosts/slots - Booster in Slots equippen
        [Authorize]
        [HttpPut("boosts/slots")]
        public async Task<IActionResult> UpdateBoostSlots([FromBody] DTOs.UpdateBoostSlotsDto dto)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var success = await _userService.UpdateBoostSlotsAsync(userId, dto.Slots);

            if (!success)
                return BadRequest("Ungültige Booster-Konfiguration. Prüfe ob du die Items besitzt.");

            return Ok();
        }
    }
}
