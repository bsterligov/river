CREATE TABLE IF NOT EXISTS traces (
    trace_id String,
    span_id String,
    parent_span_id String,
    service_name String,
    operation_name String,
    start_time_unix_nano UInt64,
    end_time_unix_nano UInt64,
    duration_ns UInt64,
    status_code Int32,
    attributes String
) ENGINE = MergeTree() ORDER BY (service_name, start_time_unix_nano);
