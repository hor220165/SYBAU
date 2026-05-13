using System.Reflection;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;
using Sybau_Backend.Data;

namespace Sybau_Backend.Tools;

public static class SqliteToPostgresImporter
{
    private static readonly HashSet<string> SeedTables = new(StringComparer.OrdinalIgnoreCase)
    {
        "Achievements",
        "Quests"
    };

    private static readonly MethodInfo CountMethod =
        typeof(SqliteToPostgresImporter).GetMethod(nameof(CountAsync), BindingFlags.NonPublic | BindingFlags.Static)!;

    private static readonly MethodInfo ImportMethod =
        typeof(SqliteToPostgresImporter).GetMethod(nameof(ImportAsync), BindingFlags.NonPublic | BindingFlags.Static)!;

    public static async Task RunAsync(
        IServiceProvider services,
        IWebHostEnvironment environment,
        string[] args,
        ILogger logger,
        CancellationToken cancellationToken = default)
    {
        var sqlitePath = GetOptionValue(args, "--sqlite-path")
            ?? Path.Combine(environment.ContentRootPath, "sybau.db");
        sqlitePath = Path.GetFullPath(sqlitePath);

        if (!File.Exists(sqlitePath))
        {
            throw new FileNotFoundException($"SQLite source database not found: {sqlitePath}", sqlitePath);
        }

        await using var scope = services.CreateAsyncScope();
        var target = scope.ServiceProvider.GetService<PostgresFitnessDbContext>()
            ?? throw new InvalidOperationException(
                "PostgresFitnessDbContext is not configured. Set ConnectionStrings__DefaultConnection to a PostgreSQL/Supabase connection string.");

        var sourceOptions = new DbContextOptionsBuilder<FitnessDbContext>()
            .UseSqlite($"Data Source={sqlitePath}")
            .Options;
        await using var source = new FitnessDbContext(sourceOptions);

        logger.LogInformation("Migrating PostgreSQL target before SQLite import.");
        await target.Database.MigrateAsync(cancellationToken);

        var importOrder = GetImportOrder(target.Model);
        await EnsureTargetIsSafeAsync(target, importOrder, args, logger, cancellationToken);

        await using var transaction = await target.Database.BeginTransactionAsync(cancellationToken);
        var totalInserted = 0;
        var totalUpdated = 0;

        foreach (var entityType in importOrder)
        {
            var result = await ImportEntityTypeAsync(source, target, entityType, cancellationToken);
            totalInserted += result.Inserted;
            totalUpdated += result.Updated;

            logger.LogInformation(
                "Imported {Table}: {Inserted} inserted, {Updated} updated.",
                entityType.GetTableName(),
                result.Inserted,
                result.Updated);
        }

        foreach (var entityType in importOrder)
        {
            await ResetIdentitySequenceAsync(target, entityType, cancellationToken);
        }

        await transaction.CommitAsync(cancellationToken);

        logger.LogInformation(
            "SQLite import complete. Source: {SqlitePath}. Inserted: {Inserted}. Updated: {Updated}.",
            sqlitePath,
            totalInserted,
            totalUpdated);
    }

    private static async Task EnsureTargetIsSafeAsync(
        PostgresFitnessDbContext target,
        IReadOnlyList<IEntityType> importOrder,
        string[] args,
        ILogger logger,
        CancellationToken cancellationToken)
    {
        var allowExistingData = HasFlag(args, "--allow-existing-data");
        var nonSeedTablesWithRows = new List<string>();

        foreach (var entityType in importOrder)
        {
            var tableName = entityType.GetTableName();
            if (string.IsNullOrWhiteSpace(tableName)) continue;

            var count = await CountEntityTypeAsync(target, entityType, cancellationToken);
            if (count <= 0) continue;

            if (!SeedTables.Contains(tableName))
            {
                nonSeedTablesWithRows.Add($"{tableName} ({count})");
            }
        }

        if (nonSeedTablesWithRows.Count == 0)
        {
            return;
        }

        if (allowExistingData)
        {
            logger.LogWarning(
                "Target already contains non-seed data and --allow-existing-data was provided. Import will upsert by primary key. Tables: {Tables}",
                string.Join(", ", nonSeedTablesWithRows));
            return;
        }

        throw new InvalidOperationException(
            "PostgreSQL target already contains non-seed data. Import aborted to avoid duplicates or overwrites. " +
            $"Tables: {string.Join(", ", nonSeedTablesWithRows)}. " +
            "Use --allow-existing-data only if you intentionally want to upsert by primary key.");
    }

    private static async Task<ImportTableResult> ImportEntityTypeAsync(
        FitnessDbContext source,
        PostgresFitnessDbContext target,
        IEntityType entityType,
        CancellationToken cancellationToken)
    {
        var task = (Task<ImportTableResult>)ImportMethod
            .MakeGenericMethod(entityType.ClrType)
            .Invoke(null, new object[] { source, target, entityType, cancellationToken })!;
        return await task;
    }

    private static async Task<ImportTableResult> ImportAsync<TEntity>(
        FitnessDbContext source,
        PostgresFitnessDbContext target,
        IEntityType entityType,
        CancellationToken cancellationToken)
        where TEntity : class
    {
        var primaryKey = entityType.FindPrimaryKey()
            ?? throw new InvalidOperationException($"Entity {entityType.DisplayName()} has no primary key.");
        var rows = await source.Set<TEntity>().ToListAsync(cancellationToken);
        var inserted = 0;
        var updated = 0;
        var pending = 0;

        foreach (var sourceEntity in rows)
        {
            var sourceEntry = source.Entry(sourceEntity);
            var keyValues = primaryKey.Properties
                .Select(property => sourceEntry.Property(property.Name).CurrentValue)
                .ToArray();

            var existing = await target.Set<TEntity>().FindAsync(keyValues, cancellationToken);
            var targetEntity = existing ?? (TEntity)Activator.CreateInstance(typeof(TEntity), nonPublic: true)!;

            if (existing == null)
            {
                target.Set<TEntity>().Add(targetEntity);
                inserted++;
            }
            else
            {
                updated++;
            }

            var targetEntry = target.Entry(targetEntity);
            foreach (var property in entityType.GetProperties())
            {
                if (existing != null && property.IsPrimaryKey())
                {
                    continue;
                }

                var value = NormalizeForPostgres(sourceEntry.Property(property.Name).CurrentValue);
                targetEntry.Property(property.Name).CurrentValue = value;
            }

            pending++;
            if (pending >= 100)
            {
                await target.SaveChangesAsync(cancellationToken);
                target.ChangeTracker.Clear();
                pending = 0;
            }
        }

        if (pending > 0)
        {
            await target.SaveChangesAsync(cancellationToken);
            target.ChangeTracker.Clear();
        }

        source.ChangeTracker.Clear();
        return new ImportTableResult(inserted, updated);
    }

    private static object? NormalizeForPostgres(object? value)
    {
        return value is DateTime dateTime
            ? dateTime.Kind switch
            {
                DateTimeKind.Utc => dateTime,
                DateTimeKind.Local => dateTime.ToUniversalTime(),
                _ => DateTime.SpecifyKind(dateTime, DateTimeKind.Utc)
            }
            : value;
    }

    private static IReadOnlyList<IEntityType> GetImportOrder(IModel model)
    {
        var entityTypes = model.GetEntityTypes()
            .Where(entityType => !entityType.IsOwned() && entityType.FindPrimaryKey() != null)
            .ToList();
        var entityTypeSet = entityTypes.ToHashSet();
        var dependencies = entityTypes.ToDictionary(
            entityType => entityType,
            entityType => entityType.GetForeignKeys()
                .Select(foreignKey => foreignKey.PrincipalEntityType)
                .Where(principal => principal != entityType && entityTypeSet.Contains(principal))
                .ToHashSet());
        var ordered = new List<IEntityType>();

        while (dependencies.Count > 0)
        {
            var ready = dependencies
                .Where(pair => pair.Value.Count == 0)
                .Select(pair => pair.Key)
                .OrderBy(entityType => entityType.GetTableName(), StringComparer.OrdinalIgnoreCase)
                .ToList();

            if (ready.Count == 0)
            {
                ordered.AddRange(dependencies.Keys.OrderBy(entityType => entityType.GetTableName(), StringComparer.OrdinalIgnoreCase));
                break;
            }

            foreach (var entityType in ready)
            {
                ordered.Add(entityType);
                dependencies.Remove(entityType);
            }

            foreach (var remainingDependencies in dependencies.Values)
            {
                foreach (var entityType in ready)
                {
                    remainingDependencies.Remove(entityType);
                }
            }
        }

        return ordered;
    }

    private static async Task<int> CountEntityTypeAsync(
        DbContext dbContext,
        IEntityType entityType,
        CancellationToken cancellationToken)
    {
        var task = (Task<int>)CountMethod
            .MakeGenericMethod(entityType.ClrType)
            .Invoke(null, new object[] { dbContext, cancellationToken })!;
        return await task;
    }

    private static Task<int> CountAsync<TEntity>(
        DbContext dbContext,
        CancellationToken cancellationToken)
        where TEntity : class
    {
        return dbContext.Set<TEntity>().CountAsync(cancellationToken);
    }

    private static async Task ResetIdentitySequenceAsync(
        DbContext target,
        IEntityType entityType,
        CancellationToken cancellationToken)
    {
        var primaryKey = entityType.FindPrimaryKey();
        if (primaryKey?.Properties.Count != 1) return;

        var keyProperty = primaryKey.Properties[0];
        var keyType = Nullable.GetUnderlyingType(keyProperty.ClrType) ?? keyProperty.ClrType;
        if (keyType != typeof(int) && keyType != typeof(long)) return;

        var tableName = entityType.GetTableName();
        if (string.IsNullOrWhiteSpace(tableName)) return;

        var schema = entityType.GetSchema();
        var table = StoreObjectIdentifier.Table(tableName, schema);
        var columnName = keyProperty.GetColumnName(table);
        if (string.IsNullOrWhiteSpace(columnName)) return;

        var qualifiedTable = schema is null
            ? QuoteIdentifier(tableName)
            : $"{QuoteIdentifier(schema)}.{QuoteIdentifier(tableName)}";
        var quotedColumn = QuoteIdentifier(columnName);
        var tableLiteral = EscapeSqlLiteral(qualifiedTable);
        var columnLiteral = EscapeSqlLiteral(columnName);

        var sql = $"""
            DO $$
            DECLARE
                seq text;
                has_rows boolean;
                max_id bigint;
            BEGIN
                seq := pg_get_serial_sequence('{tableLiteral}', '{columnLiteral}');
                IF seq IS NOT NULL THEN
                    EXECUTE 'SELECT COUNT(*) > 0, COALESCE(MAX({quotedColumn}), 0) FROM {qualifiedTable}'
                        INTO has_rows, max_id;
                    PERFORM setval(seq, GREATEST(max_id, 1), has_rows);
                END IF;
            END $$;
            """;

        await target.Database.ExecuteSqlRawAsync(sql, cancellationToken);
    }

    private static string? GetOptionValue(string[] args, string optionName)
    {
        for (var index = 0; index < args.Length - 1; index++)
        {
            if (string.Equals(args[index], optionName, StringComparison.OrdinalIgnoreCase))
            {
                return args[index + 1];
            }
        }

        return null;
    }

    private static bool HasFlag(string[] args, string flag)
    {
        return args.Any(arg => string.Equals(arg, flag, StringComparison.OrdinalIgnoreCase));
    }

    private static string QuoteIdentifier(string identifier)
    {
        return "\"" + identifier.Replace("\"", "\"\"") + "\"";
    }

    private static string EscapeSqlLiteral(string value)
    {
        return value.Replace("'", "''");
    }

    private sealed record ImportTableResult(int Inserted, int Updated);
}
