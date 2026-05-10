# RIVER-3: LocalStack S3 — Sidecar Batching
Test Approach: TDD
Why: Telemetry data has no durable storage today, so anything in-flight is lost before the pipeline can process it.
<!-- STOP -->

## Problem

The river-sidecar currently receives OTLP spans and has nowhere to persist them. If the river-sidecar restarts or the downstream pipeline isn't ready, data is dropped. Local dev has no storage layer at all, making it impossible to test the full ingest → store → process flow end-to-end.

## Goal

Spans received by the river-sidecar are reliably written to S3 (LocalStack in local dev) before any downstream processing. An operator can tune how aggressively data is flushed by adjusting buffer size and flush interval without recompiling.

## Scope

**In**
- LocalStack S3 service added to `docker-compose.yml` with a pre-created bucket
- Sidecar buffers received spans in memory and flushes to S3 when either threshold is reached: 10 MB OR 10 seconds since last flush (whichever fires first)
- Configurable via `RIVER_BUFFER_MAX_BYTES` and `RIVER_FLUSH_INTERVAL_SECS`
- Metrics/log line emitted on each flush (bytes written, object key)
- Graceful shutdown flushes remaining buffer before exit
- TDD: unit tests covering buffer-full flush, interval flush, and the race between the two
- TDD: integration test that sends spans to river-sidecar and asserts objects appear in LocalStack bucket

**Out**
- Real AWS S3 configuration or credentials management
- Retry logic on S3 write failure
- Compression of batched payloads
- Metric aggregation before batching (delta → cumulative rollup, dedup of identical metric points)

## Decisions

- **Payload format:** raw OTLP protobuf bytes (no envelope wrapping)
- **Object key format:** `spans/{service_name}/{timestamp}-{uuid}.pb` — service name injected by the river-sidecar from the OTLP resource attributes
