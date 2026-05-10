# HISTORY

Oldest first. Append new entries at the bottom.

---

### 2026-05-06 — RIVER-2: Open questions resolved

Rust river-sidecar confirmed as a permanent river-ingestion component (not a dev scaffold). .NET demo app will emit signals on a continuous background loop.

### 2026-05-07 — RIVER-3: Decisions recorded

Closed both open questions: raw OTLP protobuf as payload; object key includes service name from OTLP resource attributes (`spans/{service_name}/{timestamp}-{uuid}.pb`).

### 2026-05-07 — RIVER-3: Metric aggregation deferred

Metrics should be aggregated before batching to S3 rather than storing raw repeated points. Deferred to a future iteration — captured in Out scope.

### 2026-05-08 — RIVER-1: implementation done

Ingestion service implemented in Rust: S3 poll loop routing OTLP protobuf files by key prefix to VictoriaMetrics (metrics via OTLP HTTP) and ClickHouse (logs/traces via JSONEachRow). ClickHouse and VictoriaMetrics services added to docker-compose.

### 2026-05-08 — RIVER-4: implementation done

GitHub Actions CI workflow added: fmt-check, clippy (-D warnings), and test via mise tasks, followed by SonarQube scan and quality gate. Two pre-existing clippy issues in river-sidecar fixed as part of rollout.

### 2026-05-08 — RIVER-6: spec created

PO spec written for automated release and tagging workflow. Scope limited to tag-push trigger and GitHub release creation; binary asset uploads deferred until CI builds exist.

### 2026-05-08 — RIVER-6: implementation done

Release job added to ci.yml: runs after SonarQube on pushes to main. Uses cocogitto (`cog bump --auto`) for Conventional Commits versioning, `git push` to publish the tag, and `gh release create` for the GitHub release. No-op when no releasable commits are present.

### 2026-05-08 — RIVER-6: implementation done

Release job added to ci.yml: runs after SonarQube on pushes to main, creates a semver tag via Conventional Commits (mathieudutour/github-tag-action), and publishes a GitHub release. No-op if no releasable commits.

### 2026-05-09 — RIVER-10: implementation done

Migration management added to the river-ingestion service: SQL files under `infra/migrations/clickhouse/` are embedded in the binary and applied at startup via a `Migrator` that tracks versions in a `schema_migrations` table. `ensure_tables()` and all inline DDL removed from `clickhouse.rs`.

### 2026-05-09 — RIVER-12: implementation done

Grafana added to docker-compose with anonymous admin access and plugin-based ClickHouse datasource (`grafana-clickhouse-datasource`). VictoriaMetrics and ClickHouse are provisioned as datasources automatically. Two dashboards provisioned as code: APM (traces + logs correlated by service and time) and Metrics (request rate and total for demo-app).

### 2026-05-09 — RIVER-14: implementation done

SDD process updated to a fully branch-based flow: spec authoring and implementation now both go through PRs. QUEUE.md redesigned as a flat persistent list with strikethrough for done items. GHA extended to auto-create an impl branch and draft PR on spec PR merge. dev-spec updated to infer the task from the current branch name.

### 2026-05-10 — RIVER-16: implementation done

Query API implemented as a new `api` Rust binary (`src/river-query-api/`) using axum 0.8 with routes `GET /v1/logs`, `GET /v1/traces`, `GET /v1/metrics`, `GET /health`, and `GET /openapi.json`. A filter DSL parser translates `key:value`, comparison operators, `AND`/`OR`/`NOT`, and wildcards to ClickHouse SQL or VictoriaMetrics label selectors. OpenAPI 3.0 spec is generated from code using `utoipa`. `api` service added to docker-compose, listening on port 8080 via `RIVER_API_PORT`.

### 2026-05-10 — RIVER-16: Swagger UI added

Swagger UI mounted at `GET /swagger-ui/` via `utoipa-swagger-ui 9` (axum 0.8-compatible). The bundled UI fetches the spec from the existing `/openapi.json` endpoint.

### 2026-05-10 — RIVER-19: implementation done

Each crate (`api`, `river-ingestion`, `river-sidecar`) now has a `config.rs` module backed by the `config` crate. All env vars are standardised to the `RIVER_` prefix; `RIVER_CLICKHOUSE_USER` and `RIVER_CLICKHOUSE_PASSWORD` are required and cause an immediate startup failure if absent. docker-compose updated to use the new names.

### 2026-05-10 — RIVER-22: spec created

PO spec written for fixing Grafana trace linking. Root cause is a missing trace configuration in the ClickHouse datasource provisioning YAML; Grafana generates queries against the database name instead of the `traces` table and uses camelCase column names that don't match the schema.

### 2026-05-10 — RIVER-22: implementation done

Added trace configuration to the ClickHouse datasource provisioning YAML: database `river`, table `traces`, and all column mappings (`trace_id`, `span_id`, `parent_span_id`, `service_name`, `operation_name`, `start_time_unix_nano`, `duration_ns`). Grafana can now resolve trace links without SQL errors or configuration warnings.
