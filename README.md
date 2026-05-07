# river

> **Experimental.** This project is an exploration of how fast a full observability stack can be built from scratch — with the constraint that it must be infinitely scalable and deployable anywhere: any cloud provider or on-premises.

An open-source observability platform built for production workloads. River collects logs, metrics, and traces from your services via lightweight sidecar agents and provides a unified interface for storage and querying.

## Quick Start

```bash
docker compose up --build
```

This starts the full dev stack: LocalStack S3, a .NET demo app emitting OTel signals every 2 seconds, and the Rust sidecar on port 4317. The sidecar buffers incoming signals and flushes batches to S3:

```
river sidecar listening on 0.0.0.0:4317
[flush] key=traces/demo-app/1748345823001-550e8400-e29b-41d4.pb bytes=312
[flush] key=metrics/demo-app/1748345833002-a987fbc9-4bed-31da.pb bytes=204
```

Flushing is triggered when either threshold is reached: 10 MB of buffered data or 10 seconds since the last flush (both configurable via `SIDECAR_BUFFER_MAX_BYTES` and `SIDECAR_FLUSH_INTERVAL_SECS`).

## Repository Layout

```
src/
  sidecar/      # Rust — OTLP/gRPC receiver + S3 batcher (port 4317)
  demo-app/     # .NET 10 — continuous OTel signal emitter
specs/          # spec-driven development artifacts
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Your Services                      │
│                                                         │
│  [Service A] ──► [river-sidecar]                        │
│  [Service B] ──► [river-sidecar]                        │
│  [Service C] ──► [river-sidecar]                        │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
              [S3 — durable batch store]
              traces/{svc}/{ts}-{id}.pb
              metrics/{svc}/{ts}-{id}.pb
              logs/{svc}/{ts}-{id}.pb
                         │
                         ▼
                 [river-ingestion] 🔜
                         │
                    ┌────┴────┐
                    ▼         ▼
             [ClickHouse]  [VictoriaMetrics]
             logs & traces     metrics
                    │              │
                    └──────┬───────┘
                           ▼
                      [river-api] 🔜
                           │
                           ▼
                      [river-ui] 🔜
```

## Components

### `sidecar` — OTLP Receiver + S3 Batcher (Rust) ✅
Lightweight sidecar deployed alongside each service. Accepts logs, metrics, and traces over OTLP/gRPC (port 4317) and buffers them in memory. Flushes batches to S3 when either the buffer size or the flush interval threshold is reached. Each batch is a length-delimited OTLP protobuf file keyed by signal type and service name. On shutdown, the remaining buffer is flushed before exit.

### `demo-app` — Signal Emitter (.NET 10) ✅
A .NET 10 console app pre-configured with the OpenTelemetry SDK. Emits traces, metrics, and structured logs on a continuous 2-second loop. Used to drive development and validate the ingestion pipeline against real OTel data.

### `river-ingestion` — Ingestion Service (Rust) 🔜
Receives telemetry from the sidecar, validates and parses it, and writes to the appropriate storage backend:
- Logs and traces → ClickHouse
- Metrics → VictoriaMetrics

### Storage 🔜
| Signal  | Backend                                               |
|---------|-------------------------------------------------------|
| Logs    | [ClickHouse](https://clickhouse.com/) — columnar, fast full-text search |
| Traces  | [ClickHouse](https://clickhouse.com/) — efficient span storage and trace assembly |
| Metrics | [VictoriaMetrics](https://victoriametrics.com/) — high-performance time-series |

### `river-api` — Query API (Rust) 🔜
Unified HTTP/gRPC API that queries both ClickHouse and VictoriaMetrics and exposes results to the UI and external consumers.

### `river-ui` — Dashboard (Flutter) 🔜
Cross-platform frontend for exploring logs, traces, and metrics. Built with [Flutter](https://flutter.dev/) for web and desktop.

## Tech Stack

- **Backend:** Rust across all server-side components
- **Frontend:** Flutter (web + desktop)
- **Telemetry Buffer:** S3 (LocalStack in local dev, any S3-compatible store in production)
- **Log/Trace Storage:** ClickHouse
- **Metric Storage:** VictoriaMetrics
- **Wire Protocol:** OpenTelemetry Protocol (OTLP/gRPC)

## Dev Environment

Runtime versions are managed by [mise](https://mise.jdx.dev/). Run `mise install` once to provision the toolchain.

```bash
mise exec -- cargo build     # Rust
mise exec -- cargo test
mise exec -- flutter build   # Flutter
```

## Development Approach

River is built using **spec-driven development**. Each feature cycle begins and ends with a specification:

```
spec → code → spec → code → ...
```

**How it works:**
1. Write or refine a spec for the next increment
2. Implement against the spec
3. Update the spec to reflect what was built and what was learned
4. Repeat

**Prioritization** follows the [MoSCoW method](https://en.wikipedia.org/wiki/MoSCoW_method): every feature or requirement is tagged as Must have, Should have, Could have, or Won't have for the current iteration.

Specs, cursor rules, and AI skills are first-class artifacts in this repo — they live alongside the code and evolve with it.

## Status

Early development — not yet production ready.

## License

See [LICENSE](LICENSE).
