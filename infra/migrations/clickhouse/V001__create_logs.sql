CREATE TABLE IF NOT EXISTS logs (
    timestamp UInt64,
    service_name String,
    severity_number Int32,
    severity_text String,
    body String,
    trace_id String,
    span_id String,
    attributes String
) ENGINE = MergeTree() ORDER BY (service_name, timestamp);
