# RIVER-16: Query API
Status: In Progress
Priority: Must
Test Approach: BDD
Why: The frontend cannot display observability data without a query layer — the API is the missing link between storage and UI.
<!-- STOP -->

## Problem

Logs, metrics, and traces are stored in ClickHouse and VictoriaMetrics but there is no way to retrieve them programmatically. The Grafana dashboards are dev tooling only. Building the Flutter UI requires a stable, structured API to query against. Without this, frontend development cannot start.

## Goal

A developer (or the future Flutter UI) can query logs, traces, and metrics over HTTP and receive structured JSON responses suitable for rendering.

**Scenario: query logs with filter**
- Given a client requests logs with `filter=service:myapp AND level:error` and a time range
- When the API receives the request
- Then it returns a JSON array of log entries matching both conditions, ordered by timestamp, with fields: timestamp, severity, service, body, trace_id

**Scenario: query traces with filter**
- Given a client requests traces with `filter=service:myapp AND duration_ms:>500`
- When the API receives the request
- Then it returns only spans matching all filter conditions, grouped by trace_id

**Scenario: query metrics**
- Given a client requests a metric with `filter=name:http_requests_total AND service:myapp` over a time range with a step
- When the API receives the request
- Then it returns a JSON array of time series points: { timestamp, value }

**Scenario: invalid filter syntax**
- Given a client sends a malformed filter expression
- When the API receives the request
- Then it returns a 400 with a human-readable parse error describing where the syntax is wrong

**Scenario: unhealthy backends**
- Given ClickHouse or VictoriaMetrics is unreachable
- When the API receives a query
- Then it returns a 503 with a clear error message identifying which backend is down

## Scope

**In**
- New `api` Rust binary under `src/api/`
- All routes versioned under `/v1/`: `GET /v1/logs`, `GET /v1/traces`, `GET /v1/metrics`
- `GET /v1/logs?filter=&from=&to=&limit=` → queries ClickHouse
- `GET /v1/traces?filter=&from=&to=&limit=` → queries ClickHouse
- `GET /v1/metrics?filter=&from=&to=&step=` → queries VictoriaMetrics HTTP API
- Filter DSL parser: `key:value`, `key:>value`, `AND`/`OR`/`NOT`, wildcard `*` — translated to ClickHouse SQL or VictoriaMetrics label selectors
- JSON responses, errors as `{ "error": "..." }`
- `GET /health` endpoint (unversioned)
- OpenAPI 3.0 spec served at `GET /openapi.json` — generated from code, not hand-written
- Add `api` service to `docker-compose.yml`
- Integration tests against the dev stack (ClickHouse + VictoriaMetrics running)

**Out**
- Flutter client generation (triggered by the frontend spec, consumes `/openapi.json`)
- Authentication and authorization
- gRPC transport (HTTP only for now)
- Full-text search / filtering beyond service name and time range
- Pagination / cursors
- Query caching or rate limiting
- `/v2/` routes

## Decisions

- HTTP REST over gRPC for the initial version — simpler to test with curl and compatible with the Flutter HTTP client
- URL path versioning (`/v1/`) — explicit, cache-friendly, easy to route in reverse proxies
- OpenAPI spec generated from code using `utoipa` (Rust crate) — keeps spec and implementation in sync; frontend auto-generates its HTTP client from `/openapi.json`
- Filter DSL syntax modelled on Datadog/Dynatrace: `key:value` pairs, comparison operators (`>`, `<`, `>=`, `<=`), boolean operators (`AND`, `OR`, `NOT`), wildcard `*`; grammar defined as an unresolved question (see UNRESOLVED.md)
- Filter translated at query time: to ClickHouse `WHERE` clauses for logs/traces, to VictoriaMetrics label selector strings for metrics
- Listen on port `8080`, env var `RIVER_API_PORT`
- All timestamps as RFC 3339 strings in query params and responses
- `limit` defaults to 100, max 1000
