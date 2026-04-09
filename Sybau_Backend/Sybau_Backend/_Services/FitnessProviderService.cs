using Sybau_Backend.Models;
using Sybau_Backend.Models.Enums;
using Sybau_Backend.Data;
using Microsoft.EntityFrameworkCore;

namespace Sybau_Backend._Services;

public interface IFitnessProviderService
{
    Task<bool> LinkProviderAsync(int userId, FitnessProviderType providerType, string providerUserId, string accessToken, string refreshToken, DateTime expiresAt);
    Task<bool> UnlinkProviderAsync(int userId, FitnessProviderType providerType);
    Task<bool> SyncDataAsync(int userId, FitnessProviderType providerType, SyncType syncType);
    Task<FitnessProviderLink?> GetProviderLinkAsync(int userId, FitnessProviderType providerType);
    Task<List<FitnessProviderLink>> GetProviderLinksAsync(int userId);
}

public class FitnessProviderService : IFitnessProviderService
{
    private readonly FitnessDbContext _context;

    public FitnessProviderService(FitnessDbContext context)
    {
        _context = context;
    }

    public async Task<bool> LinkProviderAsync(int userId, FitnessProviderType providerType, string providerUserId, string accessToken, string refreshToken, DateTime expiresAt)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return false;

        // Check if link already exists
        var existingLink = await _context.FitnessProviderLinks
            .FirstOrDefaultAsync(fpl => fpl.UserId == userId && fpl.ProviderType == providerType);

        if (existingLink != null)
        {
            // Update existing link
            existingLink.ProviderUserId = providerUserId;
            existingLink.AccessToken = accessToken;
            existingLink.RefreshToken = refreshToken;
            existingLink.ExpiresAt = expiresAt;
            existingLink.IsActive = true;
            existingLink.UpdatedAt = DateTime.UtcNow;
        }
        else
        {
            // Create new link
            var link = new FitnessProviderLink(user, providerType, providerUserId)
            {
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                ExpiresAt = expiresAt,
                IsActive = true
            };
            _context.FitnessProviderLinks.Add(link);
        }

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> UnlinkProviderAsync(int userId, FitnessProviderType providerType)
    {
        var link = await _context.FitnessProviderLinks
            .FirstOrDefaultAsync(fpl => fpl.UserId == userId && fpl.ProviderType == providerType);

        if (link == null) return false;

        link.IsActive = false;
        link.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> SyncDataAsync(int userId, FitnessProviderType providerType, SyncType syncType)
    {
        var link = await _context.FitnessProviderLinks
            .FirstOrDefaultAsync(fpl => fpl.UserId == userId && fpl.ProviderType == providerType && fpl.IsActive);

        if (link == null) return false;

        // Create sync log entry
        var syncLog = new SyncLog(
            await _context.Users.FindAsync(userId)!,
            providerType,
            syncType
        );

        _context.SyncLogs.Add(syncLog);

        try
        {
            // Here would be the actual integration with Google Fit/Apple Health APIs
            // For now, we'll simulate successful sync
            await Task.Delay(100); // Simulate network delay

            // Update sync log with success
            syncLog.RecordsSynced = new Random().Next(1, 100); // Simulate some records
            syncLog.Status = SyncStatus.Completed;
            syncLog.CompletedAt = DateTime.UtcNow;
            syncLog.UpdatedAt = DateTime.UtcNow;

            // TODO: Process synced data and update user stats, workouts, etc.
            // This would involve mapping provider data to our domain model

            await _context.SaveChangesAsync();
            return true;
        }
        catch (Exception ex)
        {
            // Update sync log with failure
            syncLog.Status = SyncStatus.Failed;
            syncLog.ErrorMessage = ex.Message;
            syncLog.CompletedAt = DateTime.UtcNow;
            syncLog.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return false;
        }
    }

    public async Task<FitnessProviderLink?> GetProviderLinkAsync(int userId, FitnessProviderType providerType)
    {
        return await _context.FitnessProviderLinks
            .FirstOrDefaultAsync(fpl => fpl.UserId == userId && fpl.ProviderType == providerType && fpl.IsActive);
    }

    public async Task<List<FitnessProviderLink>> GetProviderLinksAsync(int userId)
    {
        return await _context.FitnessProviderLinks
            .Where(fpl => fpl.UserId == userId && fpl.IsActive)
            .ToListAsync();
    }
}