using System.Diagnostics;
using System.Diagnostics.Metrics;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using OpenTelemetry.Logs;
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;

var builder = Host.CreateApplicationBuilder(args);

builder.Logging.ClearProviders();
builder.Logging.AddOpenTelemetry(opts =>
{
    opts.IncludeFormattedMessage = true;
    opts.AddOtlpExporter();
});

builder.Services.AddOpenTelemetry()
    .WithTracing(b => b
        .AddSource("demo-app")
        .AddOtlpExporter())
    .WithMetrics(b => b
        .AddMeter("demo-app")
        .AddOtlpExporter());

builder.Services.AddHostedService<EmitterService>();

await builder.Build().RunAsync();

sealed class EmitterService(ILogger<EmitterService> logger) : BackgroundService
{
    private static readonly ActivitySource Source = new("demo-app");
    private static readonly Meter Meter = new("demo-app");

    private readonly Counter<long> _requests = Meter.CreateCounter<long>(
        "demo.requests.total", description: "Total number of requests processed");
    private readonly Counter<long> _errors = Meter.CreateCounter<long>(
        "demo.errors.total", description: "Total number of failed requests");
    private readonly Histogram<double> _duration = Meter.CreateHistogram<double>(
        "demo.request.duration", unit: "ms", description: "Request processing duration");

    private static readonly Random Rng = new();

    protected override async Task ExecuteAsync(CancellationToken ct)
    {
        var iteration = 0L;
        while (!ct.IsCancellationRequested)
        {
            await HandleRequestAsync(iteration, ct);
            iteration++;
            await Task.Delay(2000, ct);
        }
    }

    private async Task HandleRequestAsync(long iteration, CancellationToken ct)
    {
        var sw = Stopwatch.StartNew();
        var isError = iteration % 5 == 4;

        using var root = Source.StartActivity("http.request");
        root?.SetTag("http.method", "GET");
        root?.SetTag("http.route", "/api/demo");
        root?.SetTag("demo.iteration", iteration);

        try
        {
            await RunDbQueryAsync(ct);
            await RunCacheGetAsync(ct);

            if (isError)
                throw new InvalidOperationException("simulated downstream failure");

            root?.SetStatus(ActivityStatusCode.Ok);
            logger.LogInformation("Request completed iteration={Iteration} duration_ms={Duration}",
                iteration, sw.ElapsedMilliseconds);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            root?.SetStatus(ActivityStatusCode.Error, ex.Message);
            root?.SetTag("error.type", ex.GetType().Name);
            _errors.Add(1);
            logger.LogWarning("Request failed iteration={Iteration} error={Error}",
                iteration, ex.Message);
        }

        sw.Stop();
        _requests.Add(1);
        _duration.Record(sw.Elapsed.TotalMilliseconds);
    }

    private async Task RunDbQueryAsync(CancellationToken ct)
    {
        using var span = Source.StartActivity("db.query");
        span?.SetTag("db.system", "postgresql");
        span?.SetTag("db.statement", "SELECT * FROM items LIMIT 10");
        await Task.Delay(Rng.Next(10, 60), ct);
    }

    private async Task RunCacheGetAsync(CancellationToken ct)
    {
        using var span = Source.StartActivity("cache.get");
        span?.SetTag("cache.system", "redis");
        span?.SetTag("cache.key", "demo:items");
        await Task.Delay(Rng.Next(1, 10), ct);
    }
}
