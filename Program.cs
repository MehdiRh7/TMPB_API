using System.Text;

using NexusCore.Application.Common;
using NexusCore.Application;
using NexusCore.Application.Endpoints;
using NexusCore.Application.Identity.Permissions;

using NexusCore.Infrastructure;
using NexusCore.Infrastructure.Identity;
using NexusCore.Infrastructure.Persistence;
using NexusCore.Infrastructure.Security;

using Chat.Api.Endpoints;
using Chat.Api.Hubs;
using Chat.Application;
using Chat.Infrastructure;
using Chat.Infrastructure.Persistence;

using Notifications.Api.Endpoints;
using Notifications.Api.Hubs;
using Notifications.Application;
using Notifications.Infrastructure;
using Notifications.Infrastructure.Persistence;

using Nexus.TaskManagement;
using Nexus.TaskManagement.Endpoints;
using Nexus.TaskManagement.Infrastructure;

using Nexus.Integrations.TaskNotifications;

using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

using Serilog;


var builder = WebApplication.CreateBuilder(args);


// ======================================================
// Logging
// ======================================================

builder.Host.UseSerilog((context, configuration) =>
    configuration
        .ReadFrom.Configuration(context.Configuration)
        .WriteTo.Console());


// ======================================================
// Application Modules
// ======================================================

// Shared Core / Identity
builder.Services.AddApplication();

// Chat
builder.Services.AddChatApplication();

// Notifications
builder.Services.AddNotificationApplication();

// Task Management
builder.Services.AddTaskManagement();

// Integration between TaskManagement and Notifications
builder.Services.AddTaskNotificationsIntegration();


// ======================================================
// Infrastructure Modules
// ======================================================

// Shared Core / Identity
builder.Services.AddInfrastructure(builder.Configuration);

// Chat
builder.Services.AddChatInfrastructure(builder.Configuration);

// Notifications
builder.Services.AddNotificationInfrastructure(builder.Configuration);

// Task Management
builder.Services.AddTaskManagementInfrastructure(
    builder.Configuration);


// ======================================================
// Authorization
// ======================================================

builder.Services.AddSingleton<
    IAuthorizationHandler,
    PermissionAuthorizationHandler>();

builder.Services.AddAuthorization(options =>
{
    foreach (var permission in IdentityPermissions.All)
    {
        options.AddPolicy(
            permission.Name,
            policy => policy
                .RequireAuthenticatedUser()
                .AddRequirements(
                    new PermissionRequirement(permission.Name)));
    }
});


// ======================================================
// SignalR
// ======================================================

builder.Services.AddSignalR();


// ======================================================
// JSON Configuration
// ======================================================

builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.Converters.Add(
        new System.Text.Json.Serialization.JsonStringEnumConverter());
});


// ======================================================
// API Explorer + Swagger
// ======================================================

builder.Services.AddEndpointsApiExplorer();

builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "TMPB API",
        Version = "v1",
        Description = "TMPB - Built on NexusCore modular platform."
    });

    options.AddSecurityDefinition(
        "Bearer",
        new OpenApiSecurityScheme
        {
            Name = "Authorization",
            Type = SecuritySchemeType.Http,
            Scheme = "bearer",
            BearerFormat = "JWT",
            In = ParameterLocation.Header,
            Description = "Enter a valid JWT bearer token."
        });

    options.AddSecurityRequirement(
        new OpenApiSecurityRequirement
        {
            {
                new OpenApiSecurityScheme
                {
                    Reference = new OpenApiReference
                    {
                        Type = ReferenceType.SecurityScheme,
                        Id = "Bearer"
                    }
                },
                []
            }
        });
});


// ======================================================
// JWT Authentication
// ======================================================

var jwtOptions =
    builder.Configuration
        .GetSection(JwtOptions.SectionName)
        .Get<JwtOptions>()
    ?? new JwtOptions();

if (builder.Environment.IsProduction())
{
    // Placeholder values shipped as defaults/examples in source - never acceptable as the real
    // production signing key. A production host must not start with a missing, placeholder, or
    // too-short key - that would let anyone forge a valid access token.
    var insecureJwtSigningKeys = new HashSet<string>(StringComparer.Ordinal)
    {
        "",
        "change-me-to-a-strong-production-secret-at-least-32-characters",
        "replace-this-development-secret-with-a-production-secret-32chars",
    };

    if (string.IsNullOrWhiteSpace(jwtOptions.SigningKey)
        || insecureJwtSigningKeys.Contains(jwtOptions.SigningKey)
        || jwtOptions.SigningKey.Length < 32)
    {
        throw new InvalidOperationException(
            "Jwt:SigningKey is missing, a development placeholder, or shorter than 32 characters. " +
            "Set a real secret via the Jwt__SigningKey environment variable (or another production " +
            "configuration source) before starting this service in a production environment.");
    }
}

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.MapInboundClaims = false;

        options.TokenValidationParameters =
            new TokenValidationParameters
            {
                ValidateIssuer = true,

                ValidateAudience = true,

                ValidateIssuerSigningKey = true,

                ValidateLifetime = true,

                ValidIssuer = jwtOptions.Issuer,

                ValidAudience = jwtOptions.Audience,

                IssuerSigningKey =
                    new SymmetricSecurityKey(
                        Encoding.UTF8.GetBytes(
                            jwtOptions.SigningKey)),

                ClockSkew = TimeSpan.FromMinutes(1)
            };

        // SignalR authentication
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken =
                    context.Request.Query["access_token"];

                var path =
                    context.HttpContext.Request.Path;

                if (!string.IsNullOrEmpty(accessToken)
                    && path.StartsWithSegments("/hubs"))
                {
                    context.Token = accessToken;
                }

                return Task.CompletedTask;
            }
        };
    });


// ======================================================
// CORS
// ======================================================

var corsAllowedOrigins =
    builder.Configuration
        .GetSection("Cors:AllowedOrigins")
        .Get<string[]>()
    ?? [];

builder.Services.AddCors(options =>
{
    options.AddPolicy("FrontendPolicy", policy =>
    {
        if (corsAllowedOrigins.Length > 0)
        {
            policy
                .WithOrigins(corsAllowedOrigins)
                .AllowAnyMethod()
                .AllowAnyHeader()
                .AllowCredentials();
        }
    });
});


// ======================================================
// Build Application
// ======================================================

var app = builder.Build();


// ======================================================
// Middleware
// ======================================================

app.UseSafeErrorResponses();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();

    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseCors("FrontendPolicy");

app.UseSerilogRequestLogging();

app.UseAuthentication();

app.UseAuthorization();


// ======================================================
// Root Endpoint
// ======================================================

app.MapGet("/", () =>
    Results.Redirect("/swagger"))
    .ExcludeFromDescription();


// ======================================================
// NexusCore / Identity Endpoints
// ======================================================

app.MapIdentityEndpoints();
Console.WriteLine(
    $"UserGroups Enabled: {builder.Configuration.IsUserGroupFeatureEnabled()}"
);
if (builder.Configuration.IsUserGroupFeatureEnabled())
{
    app.MapUserGroupEndpoints();
}


// ======================================================
// Task Management Endpoints
// ======================================================

app.MapTaskManagementEndpoints();


// ======================================================
// Notification Endpoints
// ======================================================

app.MapNotificationEndpoints();


// ======================================================
// Chat Endpoints
// ======================================================

app.MapChatEndpoints();


// ======================================================
// SignalR Hubs
// ======================================================

app.MapHub<ChatHub>("/hubs/chat");

app.MapHub<NotificationHub>("/hubs/notifications");


// ======================================================
// Database Initialization
// ======================================================

if (builder.Configuration.GetValue(
    "Database:SeedOnStartup",
    true))
{
    using var scope = app.Services.CreateScope();

    var services = scope.ServiceProvider;

    var cancellationToken =
        CancellationToken.None;


    // Core Identity, initial tenant and administrator
    await services
        .GetRequiredService<DefaultDataSeeder>()
        .SeedAsync(cancellationToken);


    // TaskManagement schema
    await ModuleSchemaInitializer.EnsureCreatedAsync(
        services.GetRequiredService<TaskManagementDbContext>(),
        cancellationToken);


    // Notifications schema
    await ModuleSchemaInitializer.EnsureCreatedAsync(
        services.GetRequiredService<NotificationDbContext>(),
        cancellationToken);


    // Chat schema
    await ModuleSchemaInitializer.EnsureCreatedAsync(
        services.GetRequiredService<ChatDbContext>(),
        cancellationToken);
}


// ======================================================
// Run
// ======================================================

app.Run();