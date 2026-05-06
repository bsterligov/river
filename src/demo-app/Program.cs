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
    private readonly Counter<long> _requests = Meter.CreateCounter<long>("demo.requests.total");

    protected override async Task ExecuteAsync(CancellationToken ct)
    {
        var iteration = 0L;
        while (!ct.IsCancellationRequested)
        {
            using (var activity = Source.StartActivity("demo-operation"))
            {
                activity?.SetTag("demo.iteration", iteration);
                _requests.Add(1, new KeyValuePair<string, object?>("iteration", iteration));
                logger.LogInformation("Emitting telemetry iteration={Iteration}", iteration);
            }

            iteration++;
            await Task.Delay(2000, ct);
        }
    }
}
