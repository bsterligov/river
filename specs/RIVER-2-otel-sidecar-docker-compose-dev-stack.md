# RIVER-2: OTel Sidecar + Docker Compose Dev Stack
Status: Done
Priority: Must
Test Approach: BDD
Why: We need a local end-to-end signal flow so we can develop and validate the river ingestion pipeline against real OTel data.
<!-- STOP -->

## Problem

There is no local environment where river's ingestion pipeline can receive real OTel signals. Without a running signal source and a collector to receive it, pipeline development is blind — there is no way to validate that river processes actual logs, metrics, and traces correctly.

## Goal

A developer runs `docker compose up` and gets a working local stack: a .NET demo app emitting OTel signals, and a Rust sidecar receiving them. The developer can see that signals flow end-to-end without any manual wiring.

**Scenarios**

*Given* the Docker Compose stack is running,
*When* the .NET demo app starts,
*Then* it emits logs, metrics, and traces to the Rust sidecar via OTel gRPC.

*Given* the Rust sidecar is running,
*When* a signal arrives over gRPC,
*Then* the sidecar acknowledges receipt and outputs signal data (stdout or structured log) confirming the payload was received.

*Given* the stack is running end-to-end,
*When* a developer inspects sidecar output,
*Then* they can see all three signal types (logs, metrics, traces) arriving from the .NET app.

## Scope (MoSCoW)

**Must have**
- .NET demo app in `src/` with OTel SDK configured to export logs, metrics, and traces
- Rust sidecar service in `src/` that opens an OTel receiver endpoint and logs received signals
- Docker Compose file at the repo root that wires both services together
- OTel gRPC transport (OTLP/gRPC, port 4317) as the default protocol

**Should have**
- OTel gRPC as the only configured transport (explicitly default, not optional)

**Could have**
- OTel HTTP transport (OTLP/HTTP, port 4318) as an additional supported protocol

**Won't have (this iteration)**
- Persistent storage of received signals
- A UI or dashboard for signal inspection
- Authentication on the receiver endpoint

## Open Questions

- ~~Should the Rust sidecar be the long-term ingestion entrypoint, or is it a temporary scaffold for dev validation only?~~ **Resolved:** permanent ingestion component — this is the real receiver, not a throwaway.
- ~~What signal volume does the .NET demo app need to produce — constant background noise or on-demand via an endpoint?~~ **Resolved:** continuous background emission.

## Update History
<!-- append updates below, newest first -->

### 2026-05-06 — Open questions resolved

Rust sidecar confirmed as a permanent ingestion component (not a dev scaffold). .NET demo app will emit signals on a continuous background loop.
