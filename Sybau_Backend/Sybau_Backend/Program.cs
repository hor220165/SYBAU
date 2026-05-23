using System.Text;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.AspNetCore.StaticFiles;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Scalar.AspNetCore;
using Sybau_Backend._Services;
using Sybau_Backend.Data;
using Sybau_Backend.Hubs;
using Sybau_Backend.Tools;

var builder = WebApplication.CreateEmptyBuilder(
    new WebApplicationOptions
    {
        Args = args,
        ContentRootPath = Directory.GetCurrentDirectory(),
        EnvironmentName = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT")
            ?? Environment.GetEnvironmentVariable("DOTNET_ENVIRONMENT")
            ?? Environments.Production
    }
);
builder.WebHost.UseKestrel();
var port = Environment.GetEnvironmentVariable("PORT") ?? "5243";
builder.WebHost.UseUrls($"http://0.0.0.0:{port}");
builder.Configuration
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: false)
    .AddJsonFile($"appsettings.{builder.Environment.EnvironmentName}.json", optional: true, reloadOnChange: false)
    .AddEnvironmentVariables()
    .AddCommandLine(args);
builder.Logging.AddConfiguration(builder.Configuration.GetSection("Logging"));
builder.Logging.AddConsole();

var connectionString = NormalizePostgresConnectionString(builder.Configuration.GetConnectionString("DefaultConnection"));
var usePostgres = builder.Environment.IsProduction()
    || IsRenderRuntime()
    || IsPostgresConnectionString(connectionString);
if (usePostgres && !IsPostgresConnectionString(connectionString))
{
    throw new InvalidOperationException(
        "ConnectionStrings:DefaultConnection must be configured with a PostgreSQL/Supabase connection string for Production/Render.");
}

var jwtKey = builder.Configuration["Jwt:Key"];
if (string.IsNullOrWhiteSpace(jwtKey))
{
    throw new InvalidOperationException("Jwt:Key must be configured.");
}

static bool IsPostgresConnectionString(string? value)
{
    if (string.IsNullOrWhiteSpace(value)) return false;
    return value.Contains("Host=", StringComparison.OrdinalIgnoreCase)
        || value.StartsWith("postgres://", StringComparison.OrdinalIgnoreCase)
        || value.StartsWith("postgresql://", StringComparison.OrdinalIgnoreCase);
}

static string? NormalizePostgresConnectionString(string? value)
{
    if (string.IsNullOrWhiteSpace(value) ||
        (!value.StartsWith("postgres://", StringComparison.OrdinalIgnoreCase) &&
         !value.StartsWith("postgresql://", StringComparison.OrdinalIgnoreCase)))
    {
        return value;
    }

    var uri = new Uri(value);
    var userInfo = uri.UserInfo.Split(':', 2);
    var username = userInfo.Length > 0 ? Uri.UnescapeDataString(userInfo[0]) : string.Empty;
    var password = userInfo.Length > 1 ? Uri.UnescapeDataString(userInfo[1]) : string.Empty;
    var database = Uri.UnescapeDataString(uri.AbsolutePath.TrimStart('/'));
    var parameters = QueryParameters(uri.Query);

    var builder = new Npgsql.NpgsqlConnectionStringBuilder
    {
        Host = uri.Host,
        Port = uri.IsDefaultPort ? 5432 : uri.Port,
        Database = database,
        Username = username,
        Password = password,
        GssEncryptionMode = Npgsql.GssEncryptionMode.Disable
    };

    if (parameters.TryGetValue("sslmode", out var sslMode) &&
        Enum.TryParse<Npgsql.SslMode>(sslMode.Replace("-", string.Empty), ignoreCase: true, out var parsedSslMode))
    {
        builder.SslMode = parsedSslMode;
    }
    else
    {
        builder.SslMode = Npgsql.SslMode.Require;
    }

    if (parameters.TryGetValue("channel_binding", out var channelBinding) &&
        Enum.TryParse<Npgsql.ChannelBinding>(channelBinding.Replace("-", string.Empty), ignoreCase: true, out var parsedChannelBinding))
    {
        builder.ChannelBinding = parsedChannelBinding;
    }

    return builder.ConnectionString;
}

static Dictionary<string, string> QueryParameters(string query)
{
    var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
    if (string.IsNullOrWhiteSpace(query)) return result;

    foreach (var part in query.TrimStart('?').Split('&', StringSplitOptions.RemoveEmptyEntries))
    {
        var pair = part.Split('=', 2);
        var key = Uri.UnescapeDataString(pair[0].Replace("+", " "));
        var parameterValue = pair.Length > 1
            ? Uri.UnescapeDataString(pair[1].Replace("+", " "))
            : string.Empty;
        result[key] = parameterValue;
    }

    return result;
}

static bool IsRenderRuntime()
{
    return !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("RENDER"))
        || !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("RENDER_SERVICE_ID"))
        || !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("RENDER_EXTERNAL_URL"));
}

static string RateLimitPartitionKey(HttpContext context)
{
    var forwardedFor = context.Request.Headers["X-Forwarded-For"].FirstOrDefault();
    if (!string.IsNullOrWhiteSpace(forwardedFor))
    {
        return forwardedFor.Split(',', 2)[0].Trim();
    }

    return context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
}

static string SensitiveRateLimitPartitionKey(HttpContext context)
{
    var userId = context.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
    return string.IsNullOrWhiteSpace(userId)
        ? RateLimitPartitionKey(context)
        : $"user:{userId}";
}

// Add services to the container.
builder.Services.AddMemoryCache(options =>
{
    options.SizeLimit = 128 * 1024 * 1024;
});
builder.Services.AddSingleton<DataImageCache>();
builder.Services.AddHttpClient<MediaStorageService>();
builder.Services.AddScoped<DataImageMigrationService>();
builder.Services.AddSignalR();
builder.Services.AddScoped<UserService>();
builder.Services.AddScoped<AuthService>();
builder.Services.AddScoped<ChallengeService>();
builder.Services.AddScoped<ShopService>();
builder.Services.AddScoped<BodyStageService>();
builder.Services.AddScoped<AvatarService>();
builder.Services.AddScoped<WorkoutService>();
builder.Services.AddScoped<QuestService>();
builder.Services.AddScoped<AchievementService>();
builder.Services.AddScoped<FriendService>();
builder.Services.AddScoped<FriendChallengeService>();

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwtKey)
            ),
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromMinutes(1)
        };

        // SignalR sendet JWT als Query-Parameter
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];
                var path = context.HttpContext.Request.Path;
                if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs"))
                {
                    context.Token = accessToken;
                }
                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy =>
        policy.RequireClaim("isAdmin", "True"));
});


builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.ReferenceHandler =
            System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;

        options.JsonSerializerOptions.Converters.Add(
            new System.Text.Json.Serialization.JsonStringEnumConverter(System.Text.Json.JsonNamingPolicy.CamelCase)
        );
    });

// CORS — in Produktion auf deine Domain(s) einschränken
builder.Services.AddCors(options =>
{
    options.AddPolicy("Default", policy =>
    {
        var configuredOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];
        var allowedOrigins = configuredOrigins
            .Concat([
                "https://sybau-fitness.at",
                "https://www.sybau-fitness.at",
                "http://sybau-fitness.at",
                "http://www.sybau-fitness.at"
            ])
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();
        if (allowedOrigins is { Length: > 0 } && !allowedOrigins.Contains("*"))
        {
            bool IsAllowedOrigin(string origin)
            {
                if (allowedOrigins.Contains(origin, StringComparer.OrdinalIgnoreCase))
                {
                    return true;
                }

                if (!Uri.TryCreate(origin, UriKind.Absolute, out var uri))
                {
                    return false;
                }

                return uri.Scheme == Uri.UriSchemeHttps
                    && uri.Host.EndsWith(".netlify.app", StringComparison.OrdinalIgnoreCase)
                    && uri.Host.Contains("sybau", StringComparison.OrdinalIgnoreCase);
            }

            policy.SetIsOriginAllowed(IsAllowedOrigin)
                .AllowAnyMethod()
                .AllowAnyHeader()
                .AllowCredentials();
        }
        else
        {
            // Fallback für Development – erlaubt alle Origins mit Credentials
            policy.SetIsOriginAllowed(_ => true)
                .AllowAnyMethod()
                .AllowAnyHeader()
                .AllowCredentials();
        }
    });
});

// Rate-Limiting für Auth-Endpunkte (Brute-Force-Schutz)
builder.Services.AddRateLimiter(options =>
{
    options.AddPolicy("auth", context =>
        RateLimitPartition.GetFixedWindowLimiter(
            RateLimitPartitionKey(context),
            _ => new FixedWindowRateLimiterOptions
            {
                AutoReplenishment = true,
                PermitLimit = 10,
                QueueLimit = 0,
                Window = TimeSpan.FromMinutes(1)
            }));
    options.AddPolicy("sensitive", context =>
        RateLimitPartition.GetFixedWindowLimiter(
            SensitiveRateLimitPartitionKey(context),
            _ => new FixedWindowRateLimiterOptions
            {
                AutoReplenishment = true,
                PermitLimit = 5,
                QueueLimit = 0,
                Window = TimeSpan.FromMinutes(5)
            }));
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
});

if (usePostgres)
{
    builder.Services.AddDbContext<PostgresFitnessDbContext>(options =>
        options.UseNpgsql(connectionString!)
    );
    builder.Services.AddScoped<FitnessDbContext>(sp =>
        sp.GetRequiredService<PostgresFitnessDbContext>()
    );
}
else
{
    builder.Services.AddDbContext<FitnessDbContext>(options =>
        options.UseSqlite(connectionString ?? "Data Source=sybau.db")
    );
}
builder.Services.AddOpenApi();

var app = builder.Build();

if (args.Any(arg => string.Equals(arg, "--import-sqlite", StringComparison.OrdinalIgnoreCase)))
{
    await SqliteToPostgresImporter.RunAsync(app.Services, app.Environment, args, app.Logger);
    return;
}

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<FitnessDbContext>();
    db.Database.Migrate();
    app.Logger.LogInformation("Database provider: {ProviderName}", db.Database.ProviderName);
}

_ = Task.Run(async () =>
{
    try
    {
        await Task.Delay(TimeSpan.FromSeconds(5));
        using var scope = app.Services.CreateScope();
        var mediaStorage = scope.ServiceProvider.GetRequiredService<MediaStorageService>();
        await mediaStorage.EnsureReadyAsync();
        if (!mediaStorage.IsConfigured)
        {
            return;
        }

        var imageMigration = scope.ServiceProvider.GetRequiredService<DataImageMigrationService>();
        await imageMigration.MigrateAsync();
    }
    catch (Exception ex)
    {
        app.Logger.LogError(ex, "Image migration to configured media storage failed. The app keeps running.");
    }
});

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}

// Global Exception Handler — verhindert Stack-Trace-Leaks
app.UseExceptionHandler(errorApp =>
{
    errorApp.Run(async context =>
    {
        context.Response.StatusCode = StatusCodes.Status500InternalServerError;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsJsonAsync(new { error = "Ein interner Fehler ist aufgetreten." });
    });
});

//app.UseHttpsRedirection();

// CORS muss VOR Auth und MapControllers stehen
app.UseCors("Default");
app.Use(async (context, next) =>
{
    context.Response.OnStarting(() =>
    {
        context.Response.Headers["X-Content-Type-Options"] = "nosniff";
        context.Response.Headers["X-Frame-Options"] = "DENY";
        context.Response.Headers["Referrer-Policy"] = "no-referrer";
        context.Response.Headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()";
        return Task.CompletedTask;
    });

    var path = context.Request.Path;
    var isShopImageResponse =
        path.StartsWithSegments("/shop") &&
        path.Value?.EndsWith("/image", StringComparison.OrdinalIgnoreCase) == true;
    var isProfileImageResponse =
        path.StartsWithSegments("/users") &&
        path.Value?.EndsWith("/profile/image", StringComparison.OrdinalIgnoreCase) == true;
    var isDynamicApiResponse =
        path.StartsWithSegments("/auth") ||
        path.StartsWithSegments("/users") ||
        path.StartsWithSegments("/friends") ||
        path.StartsWithSegments("/quests") ||
        path.StartsWithSegments("/achievements") ||
        path.StartsWithSegments("/workouts") ||
        path.StartsWithSegments("/shop") ||
        path.StartsWithSegments("/admin");

    if (isDynamicApiResponse && !isShopImageResponse && !isProfileImageResponse)
    {
        context.Response.OnStarting(() =>
        {
            context.Response.Headers.CacheControl = "no-store, no-cache, must-revalidate";
            context.Response.Headers.Pragma = "no-cache";
            context.Response.Headers.Expires = "0";
            return Task.CompletedTask;
        });
    }

    await next();
});
var staticFileContentTypes = new FileExtensionContentTypeProvider();
staticFileContentTypes.Mappings[".heic"] = "image/heic";
staticFileContentTypes.Mappings[".heif"] = "image/heif";
app.UseStaticFiles(new StaticFileOptions
{
    ContentTypeProvider = staticFileContentTypes,
    OnPrepareResponse = context =>
    {
        if (context.Context.Request.Path.StartsWithSegments("/uploads"))
        {
            context.Context.Response.Headers.CacheControl = "public, max-age=2592000, immutable";
        }
    }
});

app.UseRateLimiter();

app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/health", () => Results.Ok(new { status = "ok", app = "sybau" }));
app.MapControllers();
app.MapHub<NotificationHub>("/hubs/notifications");

app.Run();
