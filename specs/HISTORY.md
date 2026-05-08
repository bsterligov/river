# HISTORY

Oldest first. Append new entries at the bottom.

---

### 2026-05-06 — RIVER-2: Open questions resolved

Rust sidecar confirmed as a permanent ingestion component (not a dev scaffold). .NET demo app will emit signals on a continuous background loop.

### 2026-05-07 — RIVER-3: Decisions recorded

Closed both open questions: raw OTLP protobuf as payload; object key includes service name from OTLP resource attributes (`spans/{service_name}/{timestamp}-{uuid}.pb`).

### 2026-05-07 — RIVER-3: Metric aggregation deferred

Metrics should be aggregated before batching to S3 rather than storing raw repeated points. Deferred to a future iteration — captured in Out scope.
