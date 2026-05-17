# RIVER-12: Grafana Local Dev Setup with APM and Metrics Dashboards

Priority: Should
Test Approach: BDD
Why: Developers have no unified view of signals in local dev — they must query ClickHouse and VictoriaMetrics separately with no dashboards.
<!-- STOP -->

## Problem

Running the stack locally produces logs, traces, and metrics, but there is no way to visualise them without writing ad-hoc queries. Debugging the signal flow end-to-end requires switching between multiple tools and interfaces. Onboarding new contributors is slowed by the lack of a ready-made observability view.

## Goal

A developer who starts the local stack can open Grafana, see an APM-style dashboard (traces and logs correlated by service and time), and a metrics overview dashboard — without any manual configuration steps.

**Scenarios:**

*Given* the local docker-compose stack is running,
*When* I open Grafana in a browser,
*Then* VictoriaMetrics and ClickHouse are already configured as data sources.

*Given* the data sources are connected,
*When* I open the APM dashboard,
*Then* I see trace spans and correlated logs filterable by service and time range.

*Given* the data sources are connected,
*When* I open the metrics overview dashboard,
*Then* I see key metrics (e.g. request rate, error rate, latency) emitted by the demo-app.

## Scope

**In**
- Grafana added to local docker-compose
- VictoriaMetrics data source provisioned automatically
- ClickHouse data source provisioned automatically (via Grafana ClickHouse plugin)
- APM-style dashboard: trace spans + logs, filterable by service and time
- Metrics overview dashboard: key OTLP metrics from demo-app
- Dashboards provisioned as code (no manual import required)

**Out**
- Production or staging Grafana deployment
- Alerting rules
- Authentication / RBAC (anonymous access is fine for local dev)
- Grafana as a permanent product component (this is dev tooling only)

## Decisions

- Dashboards provisioned via Grafana's built-in provisioning (`/etc/grafana/provisioning`) so no manual steps are needed after `docker-compose up`.
- ClickHouse plugin must be bundled or auto-installed at container start — note the plugin ID in the compose config.
- Dashboard JSON files live under `grafana/dashboards/` in the repo root.
