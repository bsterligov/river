CREATE TABLE IF NOT EXISTS traces (
    trace_id String,
    span_id String,
    parent_span_id String,
    service_name String,
    operation_name String,
    start_time_unix_nano DateTime64(9),
    end_time_unix_nano DateTime64(9),
    duration_ns UInt64,
    status_code Int32,
    attributes String,
    `Events.Name` Array(String),
    `Events.Timestamp` Array(DateTime64(9)),
    `Events.Attributes` Array(Map(String, String)),
    `Links.TraceId` Array(String),
    `Links.SpanId` Array(String),
    `Links.Attributes` Array(Map(String, String))
) ENGINE = MergeTree() ORDER BY (service_name, start_time_unix_nano)
