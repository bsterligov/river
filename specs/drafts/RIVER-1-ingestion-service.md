# DRAFT -- Issue #1
# Run `/po-spec-writer` on this branch to generate the full spec.

Issue:    #1
Task:     RIVER-1
Title:    Ingestion service
Why:
We need to add an ingestion service. 

For local setup it will poll data from s3 bucket (local stack) each 10 sec (only new data) and save metrics to VictoriaMetrics, logs & traces to ClickHouse.
Priority: must
Category: features
