# HISTORY

Oldest first. Append new entries at the bottom.

---

### 2026-05-06 — RIVER-2: Open questions resolved

Rust sidecar confirmed as a permanent ingestion component (not a dev scaffold). .NET demo app will emit signals on a continuous background loop.

### 2026-05-07 — RIVER-3: Decisions recorded

Closed both open questions: raw OTLP protobuf as payload; object key includes service name from OTLP resource attributes (`spans/{service_name}/{timestamp}-{uuid}.pb`).

### 2026-05-07 — RIVER-3: Metric aggregation deferred

Metrics should be aggregated before batching to S3 rather than storing raw repeated points. Deferred to a future iteration — captured in Out scope.

### 2026-05-08 — RIVER-1: implementation done

Ingestion service implemented in Rust: S3 poll loop routing OTLP protobuf files by key prefix to VictoriaMetrics (metrics via OTLP HTTP) and ClickHouse (logs/traces via JSONEachRow). ClickHouse and VictoriaMetrics services added to docker-compose.

### 2026-05-08 — RIVER-4: implementation done

GitHub Actions CI workflow added: fmt-check, clippy (-D warnings), and test via mise tasks, followed by SonarQube scan and quality gate. Two pre-existing clippy issues in sidecar fixed as part of rollout.

### 2026-05-08 — RIVER-6: spec created

PO spec written for automated release and tagging workflow. Scope limited to tag-push trigger and GitHub release creation; binary asset uploads deferred until CI builds exist.

### 2026-05-08 — RIVER-6: implementation done

Release job added to ci.yml: runs after SonarQube on pushes to main. Uses cocogitto (`cog bump --auto`) for Conventional Commits versioning, `git push` to publish the tag, and `gh release create` for the GitHub release. No-op when no releasable commits are present.

### 2026-05-08 — RIVER-6: implementation done

Release job added to ci.yml: runs after SonarQube on pushes to main, creates a semver tag via Conventional Commits (mathieudutour/github-tag-action), and publishes a GitHub release. No-op if no releasable commits.
