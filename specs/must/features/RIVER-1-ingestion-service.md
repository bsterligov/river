# RIVER-1: Ingestion Service
Status: In Progress
Priority: Must
Test Approach: TDD
Why: Signals accumulate in S3 but nothing reads them — the pipeline has no path from buffer to queryable storage.
<!-- STOP -->

## Problem

The river-sidecar batches and writes OTLP protobuf files to S3, but no component consumes them. Metrics never reach VictoriaMetrics; logs and traces never reach ClickHouse. The observability pipeline is broken at the handoff from buffer to storage.

## Goal

An river-ingestion service runs continuously, polls S3 every 10 seconds for unprocessed files, parses each file's raw OTLP protobuf, and writes the signals to the correct backend — metrics to VictoriaMetrics, logs and traces to ClickHouse. After a run, each processed file is not reprocessed on the next poll.

## Scope

**In**
- S3 poll loop with a 10-second interval, configurable via `RIVER_POLL_INTERVAL_SECS`
- Process only new S3 objects (cursor or marker to track last-seen key)
- Parse raw OTLP protobuf (same format written by the river-sidecar)
- Write metrics to VictoriaMetrics via remote-write
- Write logs and traces to ClickHouse via HTTP insert
- LocalStack-compatible (dev environment only for now)

**Out**
- Production/cloud S3 support
- Streaming river-ingestion (Kafka, SQS, etc.)
- Backfill or replay of already-processed files
- API or query layer
- UI

## Decisions

- Signal routing is determined by the OTLP message type: `ExportMetricsServiceRequest` → VictoriaMetrics; `ExportLogsServiceRequest` / `ExportTraceServiceRequest` → ClickHouse
- Poll interval is runtime-configurable via `RIVER_POLL_INTERVAL_SECS` (default 10)
- Processed-key tracking uses an in-memory set per process lifetime; restart re-scans from the latest S3 timestamp prefix to avoid full-bucket scans
