# RIVER-22: Error linking traces
Status: In Progress
Priority: Should
Test Approach: BDD
Why: Trace linking in Grafana is broken — clicking a trace ID returns a ClickHouse SQL error and the datasource trace configuration is unset, making distributed tracing unusable from the dashboard.
<!-- STOP -->

## Problem

When a developer clicks a trace ID link in Grafana's APM dashboard, ClickHouse returns `Unknown table expression identifier 'river'` because Grafana generates `FROM river` (the database name) instead of `FROM river.traces`. The ClickHouse datasource provisioning contains no trace configuration, so Grafana cannot resolve the correct table or map column names (`traceID` vs `trace_id`). Grafana also surfaces a warning asking for trace configuration to be set in the datasource settings.

## Goal

**Given** a trace has been recorded in ClickHouse (e.g., emitted by demo-app),
**When** a developer clicks a trace ID link in the Grafana APM dashboard,
**Then** the trace detail opens showing spans, durations, and service names — no SQL errors, no configuration warnings.

## Scope

**In**
- Add trace configuration to `infra/grafana/provisioning/datasources/datasources.yaml`: correct database (`river`), table (`traces`), and column mappings (`trace_id`, `span_id`, `parent_span_id`, `service_name`, `operation_name`, `start_time_unix_nano`, `duration_ns`)
- Verify the Grafana configuration warning disappears after provisioning

**Out**
- Changes to the `traces` ClickHouse table schema
- Changes to river-ingestion trace writing logic
- New Grafana dashboards
- Grafana auth / RBAC

## Decisions

- Column names in the datasource config must match the `traces` table (`trace_id`, not `traceID`)
- Trace configuration is set via `jsonData` in the datasource YAML — no manual Grafana UI steps required
