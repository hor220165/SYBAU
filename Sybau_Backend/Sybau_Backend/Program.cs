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
        ContentRootPath = Directory.GetCurrentDirectory()
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

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
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

static bool IsRenderRuntime()
{
    return !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("RENDER"))
        || !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("RENDER_SERVICE_ID"))
        || !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("RENDER_EXTERNAL_URL"));
}

// Add services to the container.
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
            policy.WithOrigins(allowedOrigins)
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
    options.AddFixedWindowLimiter("auth", limiter =>
    {
        limiter.PermitLimit = 10;
        limiter.Window = TimeSpan.FromMinutes(1);
        limiter.QueueLimit = 0;
    });
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

Directory.CreateDirectory(Path.Combine(app.Environment.ContentRootPath, "wwwroot", "uploads", "profile-images"));
Directory.CreateDirectory(Path.Combine(app.Environment.ContentRootPath, "wwwroot", "uploads", "shop-items"));
Directory.CreateDirectory(Path.Combine(app.Environment.ContentRootPath, "wwwroot", "uploads", "chests"));

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
var staticFileContentTypes = new FileExtensionContentTypeProvider();
staticFileContentTypes.Mappings[".heic"] = "image/heic";
staticFileContentTypes.Mappings[".heif"] = "image/heif";
app.UseStaticFiles(new StaticFileOptions
{
    ContentTypeProvider = staticFileContentTypes
});

app.UseRateLimiter();

app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/health", () => Results.Ok(new { status = "ok", app = "sybau" }));
app.MapControllers();
app.MapHub<NotificationHub>("/hubs/notifications");

app.Run();
