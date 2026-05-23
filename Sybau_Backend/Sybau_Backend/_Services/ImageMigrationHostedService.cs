namespace Sybau_Backend._Services;

public sealed class ImageMigrationHostedService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<ImageMigrationHostedService> _logger;

    public ImageMigrationHostedService(
        IServiceScopeFactory scopeFactory,
        ILogger<ImageMigrationHostedService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        try
        {
            _logger.LogInformation("Image migration startup job scheduled.");
            await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);

            using var scope = _scopeFactory.CreateScope();
            var mediaStorage = scope.ServiceProvider.GetRequiredService<MediaStorageService>();
            _logger.LogInformation("Image migration startup job checking media storage.");

            await mediaStorage.EnsureReadyAsync(stoppingToken);
            if (!mediaStorage.IsConfigured)
            {
                _logger.LogWarning("Image migration startup job skipped because media storage is not configured.");
                return;
            }

            var imageMigration = scope.ServiceProvider.GetRequiredService<DataImageMigrationService>();
            var migrated = await imageMigration.MigrateAsync();
            _logger.LogInformation("Image migration startup job finished. Migrated {Count} image values.", migrated);
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            _logger.LogInformation("Image migration startup job was cancelled because the application is stopping.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Image migration startup job failed. The app keeps running.");
        }
    }
}
