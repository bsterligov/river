use opentelemetry_proto::tonic::{
    collector::{logs::v1::ExportLogsServiceRequest, trace::v1::ExportTraceServiceRequest},
    common::v1::{any_value::Value as AV, KeyValue},
    resource::v1::Resource,
};
use prost::Message;
use serde_json::{json, Map, Value};

const CREATE_LOGS: &str = "CREATE TABLE IF NOT EXISTS logs (\
    timestamp UInt64, \
    service_name String, \
    severity_number Int32, \
    severity_text String, \
    body String, \
    trace_id String, \
    span_id String, \
    attributes String\
) ENGINE = MergeTree() ORDER BY (service_name, timestamp)";

const CREATE_TRACES: &str = "CREATE TABLE IF NOT EXISTS traces (\
    trace_id String, \
    span_id String, \
    parent_span_id String, \
    service_name String, \
    operation_name String, \
    start_time_unix_nano UInt64, \
    end_time_unix_nano UInt64, \
    duration_ns UInt64, \
    status_code Int32, \
    attributes String\
) ENGINE = MergeTree() ORDER BY (service_name, start_time_unix_nano)";

pub struct Writer {
    client: reqwest::Client,
    base_url: String,
    db: String,
    user: String,
    password: String,
}

impl Writer {
    pub fn new(
        client: reqwest::Client,
        base_url: String,
        db: String,
        user: String,
        password: String,
    ) -> Self {
        Writer {
            client,
            base_url,
            db,
            user,
            password,
        }
    }

    pub async fn ensure_tables(&self) -> anyhow::Result<()> {
        self.exec(CREATE_LOGS).await?;
        self.exec(CREATE_TRACES).await?;
        Ok(())
    }

    pub async fn insert_logs(&self, rows: &[Value]) -> anyhow::Result<()> {
        if rows.is_empty() {
            return Ok(());
        }
        self.insert("logs", rows).await
    }

    pub async fn insert_traces(&self, rows: &[Value]) -> anyhow::Result<()> {
        if rows.is_empty() {
            return Ok(());
        }
        self.insert("traces", rows).await
    }

    async fn exec(&self, ddl: &str) -> anyhow::Result<()> {
        let resp = self
            .client
            .post(&self.base_url)
            .query(&[
                ("query", ddl),
                ("user", &self.user),
                ("password", &self.password),
                ("database", &self.db),
            ])
            .send()
            .await?;
        if !resp.status().is_success() {
            let body = resp.text().await.unwrap_or_default();
            anyhow::bail!("clickhouse exec failed: {body}");
        }
        Ok(())
    }

    async fn insert(&self, table: &str, rows: &[Value]) -> anyhow::Result<()> {
        let body = rows
            .iter()
            .map(|r| r.to_string())
            .collect::<Vec<_>>()
            .join("\n");
        let query = format!("INSERT INTO {table} FORMAT JSONEachRow");
        let resp = self
            .client
            .post(&self.base_url)
            .query(&[
                ("query", query.as_str()),
                ("user", &self.user),
                ("password", &self.password),
                ("database", &self.db),
            ])
            .body(body)
            .send()
            .await?;
        if !resp.status().is_success() {
            let status = resp.status();
            let body = resp.text().await.unwrap_or_default();
            anyhow::bail!("clickhouse insert into {table} failed status={status}: {body}");
        }
        Ok(())
    }
}

pub fn parse_logs(data: &[u8]) -> anyhow::Result<Vec<Value>> {
    let req = ExportLogsServiceRequest::decode_length_delimited(&mut &data[..])?;
    let mut rows = Vec::new();
    for rl in &req.resource_logs {
        let service = service_name(&rl.resource);
        for sl in &rl.scope_logs {
            for log in &sl.log_records {
                rows.push(json!({
                    "timestamp": log.time_unix_nano,
                    "service_name": service,
                    "severity_number": log.severity_number,
                    "severity_text": log.severity_text,
                    "body": any_value_str(&log.body),
                    "trace_id": to_hex(&log.trace_id),
                    "span_id": to_hex(&log.span_id),
                    "attributes": attrs_map(&log.attributes).to_string(),
                }));
            }
        }
    }
    Ok(rows)
}

pub fn parse_traces(data: &[u8]) -> anyhow::Result<Vec<Value>> {
    let req = ExportTraceServiceRequest::decode_length_delimited(&mut &data[..])?;
    let mut rows = Vec::new();
    for rs in &req.resource_spans {
        let service = service_name(&rs.resource);
        for ss in &rs.scope_spans {
            for span in &ss.spans {
                rows.push(json!({
                    "trace_id": to_hex(&span.trace_id),
                    "span_id": to_hex(&span.span_id),
                    "parent_span_id": to_hex(&span.parent_span_id),
                    "service_name": service,
                    "operation_name": span.name,
                    "start_time_unix_nano": span.start_time_unix_nano,
                    "end_time_unix_nano": span.end_time_unix_nano,
                    "duration_ns": span.end_time_unix_nano.saturating_sub(span.start_time_unix_nano),
                    "status_code": span.status.as_ref().map(|s| s.code).unwrap_or(0),
                    "attributes": attrs_map(&span.attributes).to_string(),
                }));
            }
        }
    }
    Ok(rows)
}

fn service_name(resource: &Option<Resource>) -> String {
    resource
        .as_ref()
        .and_then(|r| {
            r.attributes
                .iter()
                .find(|kv| kv.key == "service.name")
                .and_then(|kv| kv.value.as_ref())
                .and_then(|av| av.value.as_ref())
                .and_then(|v| {
                    if let AV::StringValue(s) = v {
                        Some(s.clone())
                    } else {
                        None
                    }
                })
        })
        .unwrap_or_default()
}

fn any_value_str(av: &Option<opentelemetry_proto::tonic::common::v1::AnyValue>) -> String {
    av.as_ref()
        .and_then(|v| v.value.as_ref())
        .map(|v| match v {
            AV::StringValue(s) => s.clone(),
            AV::IntValue(i) => i.to_string(),
            AV::DoubleValue(d) => d.to_string(),
            AV::BoolValue(b) => b.to_string(),
            _ => String::new(),
        })
        .unwrap_or_default()
}

fn attrs_map(attrs: &[KeyValue]) -> Value {
    let map: Map<String, Value> = attrs
        .iter()
        .map(|kv| {
            let v = kv
                .value
                .as_ref()
                .and_then(|av| av.value.as_ref())
                .map(|val| match val {
                    AV::StringValue(s) => Value::String(s.clone()),
                    AV::IntValue(i) => json!(i),
                    AV::DoubleValue(d) => json!(d),
                    AV::BoolValue(b) => json!(b),
                    _ => Value::Null,
                })
                .unwrap_or(Value::Null);
            (kv.key.clone(), v)
        })
        .collect();
    Value::Object(map)
}

fn to_hex(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use opentelemetry_proto::tonic::{
        collector::{logs::v1::ExportLogsServiceRequest, trace::v1::ExportTraceServiceRequest},
        common::v1::{any_value::Value as AV, AnyValue, KeyValue},
        logs::v1::{LogRecord, ResourceLogs, ScopeLogs},
        resource::v1::Resource,
        trace::v1::{status::StatusCode, ResourceSpans, ScopeSpans, Span, Status},
    };
    use prost::Message;

    fn make_resource(service: &str) -> Option<Resource> {
        Some(Resource {
            attributes: vec![KeyValue {
                key: "service.name".to_string(),
                value: Some(AnyValue {
                    value: Some(AV::StringValue(service.to_string())),
                }),
            }],
            ..Default::default()
        })
    }

    #[test]
    fn parse_logs_extracts_fields() {
        let req = ExportLogsServiceRequest {
            resource_logs: vec![ResourceLogs {
                resource: make_resource("test-svc"),
                scope_logs: vec![ScopeLogs {
                    scope: None,
                    log_records: vec![LogRecord {
                        time_unix_nano: 1_000_000,
                        severity_number: 9,
                        severity_text: "INFO".to_string(),
                        body: Some(AnyValue {
                            value: Some(AV::StringValue("hello world".to_string())),
                        }),
                        trace_id: vec![0xabu8; 16],
                        span_id: vec![0xcdu8; 8],
                        attributes: vec![],
                        ..Default::default()
                    }],
                    schema_url: String::new(),
                }],
                schema_url: String::new(),
            }],
        };
        let rows = parse_logs(&req.encode_length_delimited_to_vec()).unwrap();
        assert_eq!(rows.len(), 1);
        assert_eq!(rows[0]["service_name"], "test-svc");
        assert_eq!(rows[0]["severity_text"], "INFO");
        assert_eq!(rows[0]["body"], "hello world");
        assert_eq!(rows[0]["timestamp"], 1_000_000u64);
        assert_eq!(rows[0]["trace_id"], "ab".repeat(16));
    }

    #[test]
    fn parse_traces_extracts_fields() {
        let req = ExportTraceServiceRequest {
            resource_spans: vec![ResourceSpans {
                resource: make_resource("trace-svc"),
                scope_spans: vec![ScopeSpans {
                    scope: None,
                    spans: vec![Span {
                        trace_id: vec![0x01u8; 16],
                        span_id: vec![0x02u8; 8],
                        parent_span_id: vec![],
                        name: "GET /api".to_string(),
                        start_time_unix_nano: 1000,
                        end_time_unix_nano: 2000,
                        status: Some(Status {
                            code: StatusCode::Ok as i32,
                            message: String::new(),
                        }),
                        ..Default::default()
                    }],
                    schema_url: String::new(),
                }],
                schema_url: String::new(),
            }],
        };
        let rows = parse_traces(&req.encode_length_delimited_to_vec()).unwrap();
        assert_eq!(rows.len(), 1);
        assert_eq!(rows[0]["service_name"], "trace-svc");
        assert_eq!(rows[0]["operation_name"], "GET /api");
        assert_eq!(rows[0]["duration_ns"], 1000u64);
        assert_eq!(rows[0]["status_code"], StatusCode::Ok as i32);
    }

    #[test]
    fn to_hex_encodes_bytes() {
        assert_eq!(to_hex(&[0xab, 0xcd]), "abcd");
        assert_eq!(to_hex(&[]), "");
    }

    #[test]
    fn parse_logs_empty_request_returns_no_rows() {
        let req = ExportLogsServiceRequest {
            resource_logs: vec![],
        };
        let rows = parse_logs(&req.encode_length_delimited_to_vec()).unwrap();
        assert!(rows.is_empty());
    }

    #[test]
    fn parse_traces_empty_request_returns_no_rows() {
        let req = ExportTraceServiceRequest {
            resource_spans: vec![],
        };
        let rows = parse_traces(&req.encode_length_delimited_to_vec()).unwrap();
        assert!(rows.is_empty());
    }
}
