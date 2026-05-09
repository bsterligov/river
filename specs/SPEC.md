# River — Project Context
> Agent-facing. Read before specs/decisions. Update when a spec changes anything here.

## Why
Open-source observability platform: infinitely scalable, deployable anywhere. Collects logs, metrics, traces via Rust sidecars; unified storage + querying.

## Signal Flow
`Service → Sidecar (OTLP/gRPC:4317) → S3 buffer → Ingestion → Storage → API → UI`

## Components
| Component | Lang | St | Role |
|-----------|------|----|------|
| sidecar | Rust | done | OTLP/gRPC receiver, in-memory buffer, S3 batch writer |
| demo-app | .NET 10 | done | Continuous OTel emitter (dev/validation) |
| ingestion | Rust | planned | S3 → ClickHouse / VictoriaMetrics |
| api | Rust | planned | Unified HTTP/gRPC query layer |
| ui | Flutter | planned | Cross-platform dashboard |

## Tech Stack
| Concern | Choice |
|---------|--------|
| Backend | Rust 1.95.0 |
| Frontend | Flutter 3.41.0 (web + desktop) |
| Wire protocol | OTLP/gRPC |
| Log/Trace storage | ClickHouse |
| Metric storage | VictoriaMetrics |
| Buffer | S3-compatible (LocalStack in dev) |
| Toolchain mgmt | mise |

## Decisions
- **S3 buffer** — decouples ingestion from processing; survives restarts
- **Raw OTLP protobuf** — no envelope; wire format preserved for downstream
- **Sidecar is permanent** — production entrypoint, not a scaffold
- **ClickHouse + VictoriaMetrics** — best-of-breed per signal type
- **Flutter UI** — one codebase for web + desktop
- **S3 key schema:** `{signal}/{service}/{timestamp}-{uuid}.pb`
- **Env vars:** all prefixed `RIVER_` (e.g. `RIVER_BUFFER_MAX_BYTES`, `RIVER_FLUSH_INTERVAL_SECS`)

## Spec System
`/po-spec-writer` → PR (spec + QUEUE) → merge(main) → `/dev-spec` → push (main)
Path: `/specs/{priority}/{category}/RIVER-{issue_number}-title.md`
Priorities: `must` `should` `could` `wont`
Categories: `bugs` `docs` `features` `refactoring` `tools`
Status tracked in `specs/QUEUE.md` · History in `specs/HISTORY.md`
