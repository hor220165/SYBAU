using System.Data;
using System.Globalization;
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
            var result = await ImportEntityTypeAsync(source, target, entityType, logger, cancellationToken);
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
        ILogger logger,
        CancellationToken cancellationToken)
    {
        var task = (Task<ImportTableResult>)ImportMethod
            .MakeGenericMethod(entityType.ClrType)
            .Invoke(null, new object[] { source, target, entityType, logger, cancellationToken })!;
        return await task;
    }

    private static async Task<ImportTableResult> ImportAsync<TEntity>(
        FitnessDbContext source,
        PostgresFitnessDbContext target,
        IEntityType entityType,
        ILogger logger,
        CancellationToken cancellationToken)
        where TEntity : class
    {
        var primaryKey = entityType.FindPrimaryKey()
            ?? throw new InvalidOperationException($"Entity {entityType.DisplayName()} has no primary key.");
        var tableName = entityType.GetTableName()
            ?? throw new InvalidOperationException($"Entity {entityType.DisplayName()} has no table name.");
        var tableIdentifier = StoreObjectIdentifier.Table(tableName, entityType.GetSchema());
        var sourceColumns = await GetSqliteColumnsAsync(source, tableName, cancellationToken);
        if (sourceColumns.Count == 0)
        {
            logger.LogWarning("SQLite table {Table} was not found or has no columns. Skipping.", tableName);
            return new ImportTableResult(0, 0);
        }

        var propertyMappings = entityType.GetProperties()
            .Select(property => new SourcePropertyMapping(
                property,
                property.GetColumnName(tableIdentifier) ?? property.Name))
            .ToList();
        var selectedMappings = propertyMappings
            .Where(mapping => sourceColumns.Contains(mapping.ColumnName))
            .ToList();
        var missingMappings = propertyMappings
            .Where(mapping => !sourceColumns.Contains(mapping.ColumnName))
            .ToList();
        var missingKeyColumns = primaryKey.Properties
            .Select(property => propertyMappings.First(mapping => mapping.Property == property))
            .Where(mapping => !sourceColumns.Contains(mapping.ColumnName))
            .ToList();

        if (missingKeyColumns.Count > 0)
        {
            logger.LogWarning(
                "SQLite table {Table} is missing primary key columns {Columns}. Skipping.",
                tableName,
                string.Join(", ", missingKeyColumns.Select(mapping => mapping.ColumnName)));
            return new ImportTableResult(0, 0);
        }

        if (missingMappings.Count > 0)
        {
            var missingNullableColumns = missingMappings
                .Where(mapping => IsNullableProperty(mapping.Property))
                .Select(mapping => mapping.ColumnName)
                .ToList();
            var missingRequiredColumns = missingMappings
                .Where(mapping => !IsNullableProperty(mapping.Property))
                .Select(mapping => mapping.ColumnName)
                .ToList();

            if (missingNullableColumns.Count > 0)
            {
                logger.LogWarning(
                    "SQLite table {Table} is missing nullable columns {Columns}. They will be imported as null.",
                    tableName,
                    string.Join(", ", missingNullableColumns));
            }

            if (missingRequiredColumns.Count > 0)
            {
                logger.LogWarning(
                    "SQLite table {Table} is missing required columns {Columns}. Type defaults will be used.",
                    tableName,
                    string.Join(", ", missingRequiredColumns));
            }
        }

        if (selectedMappings.Count == 0)
        {
            logger.LogWarning("SQLite table {Table} has no importable columns. Skipping.", tableName);
            return new ImportTableResult(0, 0);
        }

        var inserted = 0;
        var updated = 0;
        var pending = 0;
        var selectSql = BuildSelectSql(tableName, selectedMappings, primaryKey, propertyMappings);

        var connection = source.Database.GetDbConnection();
        if (connection.State != ConnectionState.Open)
        {
            await connection.OpenAsync(cancellationToken);
        }

        await using var command = connection.CreateCommand();
        command.CommandText = selectSql;
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        while (await reader.ReadAsync(cancellationToken))
        {
            var sourceValues = new Dictionary<IProperty, object?>();
            foreach (var mapping in selectedMappings)
            {
                var ordinal = reader.GetOrdinal(mapping.ColumnName);
                var rawValue = await reader.IsDBNullAsync(ordinal, cancellationToken)
                    ? null
                    : reader.GetValue(ordinal);
                sourceValues[mapping.Property] = ConvertForProperty(
                    rawValue,
                    mapping.Property,
                    tableName,
                    mapping.ColumnName,
                    logger);
            }

            foreach (var mapping in missingMappings)
            {
                sourceValues[mapping.Property] = GetMissingColumnDefault(mapping.Property);
            }

            var keyValues = primaryKey.Properties.Select(property => sourceValues[property]).ToArray();

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

                var value = sourceValues[property];
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

        return new ImportTableResult(inserted, updated);
    }

    private static async Task<HashSet<string>> GetSqliteColumnsAsync(
        DbContext source,
        string tableName,
        CancellationToken cancellationToken)
    {
        var columns = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var connection = source.Database.GetDbConnection();
        if (connection.State != ConnectionState.Open)
        {
            await connection.OpenAsync(cancellationToken);
        }

        await using var command = connection.CreateCommand();
        command.CommandText = $"PRAGMA table_info({QuoteIdentifier(tableName)})";
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            var name = reader["name"]?.ToString();
            if (!string.IsNullOrWhiteSpace(name))
            {
                columns.Add(name);
            }
        }

        return columns;
    }

    private static string BuildSelectSql(
        string tableName,
        IReadOnlyList<SourcePropertyMapping> selectedMappings,
        IKey primaryKey,
        IReadOnlyList<SourcePropertyMapping> propertyMappings)
    {
        var selectColumns = selectedMappings
            .Select(mapping => $"{QuoteIdentifier(mapping.ColumnName)} AS {QuoteIdentifier(mapping.ColumnName)}");
        var keyColumns = primaryKey.Properties
            .Select(property => propertyMappings.First(mapping => mapping.Property == property).ColumnName)
            .ToList();
        var orderBy = keyColumns.Count == 0
            ? string.Empty
            : $" ORDER BY {string.Join(", ", keyColumns.Select(QuoteIdentifier))}";

        return $"SELECT {string.Join(", ", selectColumns)} FROM {QuoteIdentifier(tableName)}{orderBy}";
    }

    private static object? ConvertForProperty(
        object? rawValue,
        IProperty property,
        string tableName,
        string columnName,
        ILogger logger)
    {
        if (rawValue is null)
        {
            return GetMissingColumnDefault(property);
        }

        var targetType = Nullable.GetUnderlyingType(property.ClrType) ?? property.ClrType;

        try
        {
            if (targetType == typeof(string))
            {
                return Convert.ToString(rawValue, CultureInfo.InvariantCulture) ?? string.Empty;
            }

            if (targetType == typeof(bool))
            {
                return rawValue switch
                {
                    bool value => value,
                    byte value => value != 0,
                    short value => value != 0,
                    int value => value != 0,
                    long value => value != 0,
                    string value when bool.TryParse(value, out var parsed) => parsed,
                    string value when long.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsed) => parsed != 0,
                    _ => Convert.ToBoolean(rawValue, CultureInfo.InvariantCulture)
                };
            }

            if (targetType == typeof(DateTime))
            {
                return NormalizeDateTime(rawValue);
            }

            if (targetType == typeof(DateOnly))
            {
                return NormalizeDateOnly(rawValue);
            }

            if (targetType.IsEnum)
            {
                return ConvertEnum(rawValue, targetType);
            }

            if (targetType == typeof(Guid))
            {
                return rawValue is Guid guid ? guid : Guid.Parse(rawValue.ToString()!);
            }

            return Convert.ChangeType(rawValue, targetType, CultureInfo.InvariantCulture);
        }
        catch (Exception ex) when (ex is FormatException or InvalidCastException or OverflowException or ArgumentException)
        {
            logger.LogWarning(
                ex,
                "Could not convert SQLite value for {Table}.{Column} to {Type}. A default value will be used.",
                tableName,
                columnName,
                property.ClrType.Name);
            return GetMissingColumnDefault(property);
        }
    }

    private static object? NormalizeDateTime(object rawValue)
    {
        var dateTime = rawValue switch
        {
            DateTime value => value,
            string value when DateTime.TryParse(
                value,
                CultureInfo.InvariantCulture,
                DateTimeStyles.AssumeUniversal | DateTimeStyles.AdjustToUniversal,
                out var parsed) => parsed,
            _ => Convert.ToDateTime(rawValue, CultureInfo.InvariantCulture)
        };

        return dateTime.Kind switch
        {
            DateTimeKind.Utc => dateTime,
            DateTimeKind.Local => dateTime.ToUniversalTime(),
            _ => DateTime.SpecifyKind(dateTime, DateTimeKind.Utc)
        };
    }

    private static object NormalizeDateOnly(object rawValue)
    {
        return rawValue switch
        {
            DateOnly value => value,
            DateTime value => DateOnly.FromDateTime(value),
            string value when DateOnly.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.None, out var parsed) => parsed,
            string value when DateTime.TryParse(
                value,
                CultureInfo.InvariantCulture,
                DateTimeStyles.AssumeUniversal | DateTimeStyles.AdjustToUniversal,
                out var parsed) => DateOnly.FromDateTime(parsed),
            _ => DateOnly.FromDateTime(Convert.ToDateTime(rawValue, CultureInfo.InvariantCulture))
        };
    }

    private static object ConvertEnum(object rawValue, Type enumType)
    {
        if (rawValue is string value)
        {
            if (long.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var numericValue))
            {
                return Enum.ToObject(enumType, numericValue);
            }

            return Enum.Parse(enumType, value, ignoreCase: true);
        }

        var underlyingType = Enum.GetUnderlyingType(enumType);
        var numeric = Convert.ChangeType(rawValue, underlyingType, CultureInfo.InvariantCulture);
        return Enum.ToObject(enumType, numeric!);
    }

    private static object? GetMissingColumnDefault(IProperty property)
    {
        if (IsNullableProperty(property))
        {
            return null;
        }

        var targetType = Nullable.GetUnderlyingType(property.ClrType) ?? property.ClrType;
        if (targetType == typeof(string))
        {
            return string.Empty;
        }

        if (targetType == typeof(bool))
        {
            return false;
        }

        if (targetType == typeof(DateTime))
        {
            return DateTime.UtcNow;
        }

        if (targetType == typeof(DateOnly))
        {
            return DateOnly.FromDateTime(DateTime.UtcNow);
        }

        if (targetType.IsEnum)
        {
            return Enum.ToObject(targetType, 0);
        }

        return Activator.CreateInstance(targetType);
    }

    private static bool IsNullableProperty(IProperty property)
    {
        return property.IsNullable || Nullable.GetUnderlyingType(property.ClrType) != null;
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

    private sealed record SourcePropertyMapping(IProperty Property, string ColumnName);
}
