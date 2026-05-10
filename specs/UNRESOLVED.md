# UNRESOLVED

Open questions across all specs. Add when a question is raised, strike through and note resolution when closed.

Format: `- [RIVER-N] Question — **Resolved:** answer` once closed.

---

## Open

- [RIVER-14] How should parallel in-flight specs avoid conflicts when both target the same tracking files (QUEUE.md, HISTORY.md)?
- [RIVER-16] What is the exact filter DSL grammar? Specifically: field name set for each signal type (logs/traces/metrics), whether free-text body search is supported, and how nested attribute paths are expressed (e.g. `attributes.http.status:200`).

## Resolved

- [RIVER-2] ~~Should the Rust river-sidecar be the long-term river-ingestion entrypoint, or a temporary scaffold?~~ **Resolved:** permanent river-ingestion component.
- [RIVER-2] ~~What signal volume does the .NET demo app need to produce?~~ **Resolved:** continuous background emission.
