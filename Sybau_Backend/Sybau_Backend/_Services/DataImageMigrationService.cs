using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Data;

namespace Sybau_Backend._Services;

public sealed class DataImageMigrationService
{
    private const string DataImageLikePattern = "data:image/%";

    private readonly FitnessDbContext _context;
    private readonly MediaStorageService _mediaStorage;
    private readonly ILogger<DataImageMigrationService> _logger;

    public DataImageMigrationService(
        FitnessDbContext context,
        MediaStorageService mediaStorage,
        ILogger<DataImageMigrationService> logger)
    {
        _context = context;
        _mediaStorage = mediaStorage;
        _logger = logger;
    }

    public async Task MigrateAsync()
    {
        var migrated = 0;

        var items = await _context.Items
            .Where(item => item.ImageUrl != null && EF.Functions.Like(item.ImageUrl, DataImageLikePattern))
            .ToListAsync();
        foreach (var item in items)
        {
            if (await TryMoveDataImageAsync(item.ImageUrl, "shop-items", $"item-{item.Id}") is { } imageUrl)
            {
                item.ImageUrl = imageUrl;
                migrated++;
            }
        }

        var chests = await _context.Chests
            .Where(chest => EF.Functions.Like(chest.ImageUrl, DataImageLikePattern))
            .ToListAsync();
        foreach (var chest in chests)
        {
            if (await TryMoveDataImageAsync(chest.ImageUrl, "chests", $"chest-{chest.Id}") is { } imageUrl)
            {
                chest.ImageUrl = imageUrl;
                migrated++;
            }
        }

        var users = await _context.Users
            .Where(user => user.ProfileImageUrl != null && EF.Functions.Like(user.ProfileImageUrl, DataImageLikePattern))
            .ToListAsync();
        foreach (var user in users)
        {
            if (await TryMoveDataImageAsync(user.ProfileImageUrl, "profile-images", $"profile-{user.Id}") is { } imageUrl)
            {
                user.ProfileImageUrl = imageUrl;
                migrated++;
            }
        }

        if (migrated <= 0) return;

        await _context.SaveChangesAsync();
        _logger.LogInformation("Migrated {Count} data-image database values to file uploads.", migrated);
    }

    private async Task<string?> TryMoveDataImageAsync(string? dataImageUrl, string category, string namePrefix)
    {
        if (string.IsNullOrWhiteSpace(dataImageUrl)) return null;
        if (!DataImageCache.TryDecodeDataImage(dataImageUrl, out var image, out var error) || image == null)
        {
            _logger.LogWarning("Could not migrate {Category} data image {NamePrefix}: {Error}", category, namePrefix, error);
            return null;
        }

        return await _mediaStorage.SaveDataImageAsync(image, category, namePrefix);
    }
}
