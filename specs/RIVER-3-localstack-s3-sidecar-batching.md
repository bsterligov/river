# RIVER-3: LocalStack S3 — Sidecar Batching
Status: Done
Priority: Must
Test Approach: TDD
Why: Telemetry data has no durable storage today, so anything in-flight is lost before the pipeline can process it.
<!-- STOP -->

## Problem

The sidecar currently receives OTLP spans and has nowhere to persist them. If the sidecar restarts or the downstream pipeline isn't ready, data is dropped. Local dev has no storage layer at all, making it impossible to test the full ingest → store → process flow end-to-end.

## Goal

Spans received by the sidecar are reliably written to S3 (LocalStack in local dev) before any downstream processing. An operator can tune how aggressively data is flushed by adjusting buffer size and flush interval without recompiling.

## Scope (MoSCoW)

**Must have**
- LocalStack S3 service added to `docker-compose.yml` with a pre-created bucket
- Sidecar buffers received spans in memory and flushes to S3 when either threshold is reached: buffer reaches 10 MB OR 10 seconds have elapsed since the last flush
- Flush is triggered by whichever condition fires first
- TDD: unit tests covering buffer-full flush, interval flush, and the race between the two

**Should have**
- Buffer size limit and flush interval are configurable via environment variables (`SIDECAR_BUFFER_MAX_BYTES`, `SIDECAR_FLUSH_INTERVAL_SECS`)
- TDD: integration test that sends spans to sidecar and asserts objects appear in LocalStack bucket

**Could have**
- Metrics/log line emitted on each flush (bytes written, object key)
- Graceful shutdown that flushes the remaining buffer before exit

**Won't have (this iteration)**
- Real AWS S3 configuration or credentials management
- Retry logic on S3 write failure
- Compression of batched payloads

## Open Questions

*(none)*

## Decisions

- **Payload format:** raw OTLP protobuf bytes (no envelope wrapping)
- **Object key format:** `spans/{service_name}/{timestamp}-{uuid}.pb` — service name injected by the sidecar from the OTLP resource attributes

## Update History
<!-- append updates below, newest first -->

### 2026-05-07 — Decisions recorded

Closed both open questions: raw OTLP protobuf as payload; object key includes service name from OTLP resource attributes (`spans/{service_name}/{timestamp}-{uuid}.pb`).
