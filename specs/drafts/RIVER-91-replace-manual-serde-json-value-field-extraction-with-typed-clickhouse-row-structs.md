# DRAFT -- Issue #91
# Run `/spec` on this branch to generate the full spec.

Issue:    #91
Task:     RIVER-91
Title:    Replace manual serde_json::Value field extraction with typed ClickHouse row structs
Why:
In `river-query-api/src/clickhouse.rs`, ClickHouse query results are deserialized as raw `serde_json::Value` rows and then manually mapped field-by-field to output DTOs (e.g. `row["severity_text"].as_str().unwrap_or_default().to_string()`). This is brittle and verbose.

**Acceptance criteria:**
- Introduce typed intermediate serde structs matching ClickHouse column names (e.g. `ChLogRow`, `ChSpanRow`) and deserialize with `serde_json::from_value`.
- Map to output DTOs only where a rename or conversion is needed (e.g. `duration_ns` → `duration_ms`, ClickHouse datetime → RFC3339).
- Replace or wrap the `query_json` helper with a generic `query_typed<T: DeserializeOwned>` to push deserialization into the query layer.
- All existing tests pass without modification.
- No behavior change — this is a pure refactor.
Priority: could
Category: refactoring
