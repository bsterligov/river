# river

> **Experimental.** This project is an exploration of how fast a full observability stack can be built from scratch — with the constraint that it must be unlimitedly scalable and deployable anywhere: any cloud provider or on-premises.

An open-source observability platform built for production workloads. River collects logs, metrics, and traces from your services via lightweight sidecar agents and provides a unified interface for storage and querying.

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

### `river-agent` — Sidecar Collection Agent (Rust)
Lightweight sidecar deployed alongside each service. Collects logs, metrics, and traces and forwards them to the ingestion service. Fully compatible with the [OpenTelemetry](https://opentelemetry.io/) protocol (OTLP), so any OTel-instrumented service works out of the box.

### `river-ingestion` — Ingestion Service (Rust)
Receives telemetry data from agents, validates and parses it, and writes to the appropriate storage backend:
- Logs and traces → ClickHouse
- Metrics → VictoriaMetrics

### Storage
| Signal  | Backend                                               |
|---------|-------------------------------------------------------|
| Logs    | [ClickHouse](https://clickhouse.com/) — columnar, fast full-text search |
| Traces  | [ClickHouse](https://clickhouse.com/) — efficient span storage and trace assembly |
| Metrics | [VictoriaMetrics](https://victoriametrics.com/) — high-performance time-series |

### `river-api` — Query API (Rust)
Unified HTTP/gRPC API that queries both ClickHouse and VictoriaMetrics and exposes results to the UI and external consumers.

### `river-ui` — Dashboard (Flutter)
Cross-platform frontend for exploring logs, traces, and metrics. Built with [Flutter](https://flutter.dev/) for web and desktop.

## Tech Stack

- **Backend:** Rust across all server-side components
- **Frontend:** Flutter (web + desktop)
- **Log/Trace Storage:** ClickHouse
- **Metric Storage:** VictoriaMetrics
- **Wire Protocol:** OpenTelemetry Protocol (OTLP)

## Development Approach

River is built using **spec-driven development**. Rather than jumping straight to code, each feature cycle begins and ends with a specification:

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
