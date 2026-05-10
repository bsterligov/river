# RIVER-2: OTel Sidecar + Docker Compose Dev Stack
Test Approach: BDD
Why: We need a local end-to-end signal flow so we can develop and validate the river river-ingestion pipeline against real OTel data.
<!-- STOP -->

## Problem

There is no local environment where river's river-ingestion pipeline can receive real OTel signals. Without a running signal source and a collector to receive it, pipeline development is blind — there is no way to validate that river processes actual logs, metrics, and traces correctly.

## Goal

A developer runs `docker compose up` and gets a working local stack: a .NET demo app emitting OTel signals, and a Rust river-sidecar receiving them. The developer can see that signals flow end-to-end without any manual wiring.

**Scenarios**

*Given* the Docker Compose stack is running,
*When* the .NET demo app starts,
*Then* it emits logs, metrics, and traces to the Rust river-sidecar via OTel gRPC.

*Given* the Rust river-sidecar is running,
*When* a signal arrives over gRPC,
*Then* the river-sidecar acknowledges receipt and outputs signal data (stdout or structured log) confirming the payload was received.

*Given* the stack is running end-to-end,
*When* a developer inspects river-sidecar output,
*Then* they can see all three signal types (logs, metrics, traces) arriving from the .NET app.

## Scope

**In**
- .NET demo app in `src/` with OTel SDK configured to export logs, metrics, and traces
- Rust river-sidecar service in `src/` that opens an OTel receiver endpoint and logs received signals
- Docker Compose file at the repo root that wires both services together
- OTel gRPC transport (OTLP/gRPC, port 4317) as the default protocol
- OTel gRPC as the only configured transport (explicitly default, not optional)

**Out**
- OTel HTTP transport (OTLP/HTTP, port 4318)
- Persistent storage of received signals
- UI or dashboard for signal inspection
- Authentication on the receiver endpoint
