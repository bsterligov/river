# river

> **Experimental.** This project is an exploration of how fast a full observability stack can be built from scratch — with the constraint that it must be infinitely scalable and deployable anywhere: any cloud provider or on-premises.

An open-source observability platform built for production workloads. River collects logs, metrics, and traces from your services via lightweight sidecar agents and provides a unified interface for storage and querying.

## Quick Start

```bash
docker compose up --build
```

This starts the full dev stack: a .NET demo app emitting OTel signals every 2 seconds, received by the Rust sidecar on port 4317. Sidecar output confirms all three signal types are arriving:

```
river sidecar listening on 0.0.0.0:4317
[traces] resource_spans=1 spans=1
[metrics] resource_metrics=1 metrics=1
[logs] resource_logs=1 records=1
```

## Repository Layout

```
src/
  sidecar/      # Rust — OTLP/gRPC receiver (port 4317)
  demo-app/     # .NET 10 — continuous OTel signal emitter
specs/          # spec-driven development artifacts
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Your Services                       │
│                                                         │
│  [Service A] ──► [river-agent]                          │
│  [Service B] ──► [river-agent]  ──► [river-ingestion]   │
│  [Service C] ──► [river-agent]                          │
└─────────────────────────────────────────────────────────┘
                                           │
                    ┌──────────────────────┤
                    │                      │
                    ▼                      ▼
             [ClickHouse]         [VictoriaMetrics]
             logs & traces             metrics
                    │                      │
                    └──────────┬───────────┘
                               ▼
                         [river-api]
                               │
                               ▼
                          [river-ui]
```

## Components

### `sidecar` — OTLP Receiver (Rust) ✅
Lightweight sidecar deployed alongside each service. Accepts logs, metrics, and traces over OTLP/gRPC (port 4317). This is the permanent ingestion entrypoint — not a dev scaffold.

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
