use opentelemetry_proto::tonic::{
    collector::{logs::v1::ExportLogsServiceRequest, trace::v1::ExportTraceServiceRequest},
    common::v1::{any_value::Value as AV, KeyValue},
    resource::v1::Resource,
};
use prost::Message;
use serde_json::{json, Map, Value};

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
    let rows = req
        .resource_logs
        .iter()
        .flat_map(|rl| {
            let service = service_name(&rl.resource);
            rl.scope_logs.iter().flat_map(move |sl| {
                let service = service.clone();
                sl.log_records.iter().map(move |log| {
                    json!({
                        "timestamp": log.time_unix_nano,
                        "service_name": service,
                        "severity_number": log.severity_number,
                        "severity_text": log.severity_text,
                        "body": any_value_str(&log.body),
                        "trace_id": to_hex(&log.trace_id),
                        "span_id": to_hex(&log.span_id),
                        "attributes": to_json_attrs(&log.attributes).to_string(),
                    })
                })
            })
        })
        .collect();
    Ok(rows)
}

pub fn parse_traces(data: &[u8]) -> anyhow::Result<Vec<Value>> {
    let req = ExportTraceServiceRequest::decode_length_delimited(&mut &data[..])?;
    let rows = req
        .resource_spans
        .iter()
        .flat_map(|rs| {
            let service = service_name(&rs.resource);
            rs.scope_spans.iter().flat_map(move |ss| {
                let service = service.clone();
                ss.spans.iter().map(move |span| {
                    let (event_names, event_timestamps, event_attributes) =
                        build_events(&span.events);
                    let (link_trace_ids, link_span_ids, link_attributes) =
                        build_links(&span.links);
                    json!({
                        "trace_id": to_hex(&span.trace_id),
                        "span_id": to_hex(&span.span_id),
                        "parent_span_id": to_hex(&span.parent_span_id),
                        "service_name": service,
                        "operation_name": span.name,
                        "start_time_unix_nano": span.start_time_unix_nano,
                        "end_time_unix_nano": span.end_time_unix_nano,
                        "duration_ns": span.end_time_unix_nano.saturating_sub(span.start_time_unix_nano),
                        "status_code": span.status.as_ref().map(|s| s.code).unwrap_or(0),
                        "attributes": to_json_attrs(&span.attributes).to_string(),
                        "Events.Name": event_names,
                        "Events.Timestamp": event_timestamps,
                        "Events.Attributes": event_attributes,
                        "Links.TraceId": link_trace_ids,
                        "Links.SpanId": link_span_ids,
                        "Links.Attributes": link_attributes,
                    })
                })
            })
        })
        .collect();
    Ok(rows)
}

fn build_events(
    events: &[opentelemetry_proto::tonic::trace::v1::span::Event],
) -> (Vec<Value>, Vec<Value>, Vec<Value>) {
    events
        .iter()
        .map(|e| {
            (
                json!(e.name),
                json!(e.time_unix_nano),
                to_string_attrs(&e.attributes),
            )
        })
        .fold(
            (Vec::new(), Vec::new(), Vec::new()),
            |(mut names, mut timestamps, mut attrs), (n, t, a)| {
                names.push(n);
                timestamps.push(t);
                attrs.push(a);
                (names, timestamps, attrs)
            },
        )
}

fn build_links(
    links: &[opentelemetry_proto::tonic::trace::v1::span::Link],
) -> (Vec<Value>, Vec<Value>, Vec<Value>) {
    links
        .iter()
        .map(|l| {
            (
                json!(to_hex(&l.trace_id)),
                json!(to_hex(&l.span_id)),
                to_string_attrs(&l.attributes),
            )
        })
        .fold(
            (Vec::new(), Vec::new(), Vec::new()),
            |(mut tids, mut sids, mut attrs), (tid, sid, a)| {
                tids.push(tid);
                sids.push(sid);
                attrs.push(a);
                (tids, sids, attrs)
            },
        )
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

fn to_json_attrs(attrs: &[KeyValue]) -> Value {
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

fn to_string_attrs(attrs: &[KeyValue]) -> Value {
    let map: Map<String, Value> = attrs
        .iter()
        .map(|kv| {
            let v = kv
                .value
                .as_ref()
                .and_then(|av| av.value.as_ref())
                .map(|val| match val {
                    AV::StringValue(s) => Value::String(s.clone()),
                    AV::IntValue(i) => Value::String(i.to_string()),
                    AV::DoubleValue(d) => Value::String(d.to_string()),
                    AV::BoolValue(b) => Value::String(b.to_string()),
                    _ => Value::String(String::new()),
                })
                .unwrap_or(Value::String(String::new()));
            (kv.key.clone(), v)
        })
        .collect();
    Value::Object(map)
}

fn to_hex(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}

#[cfg(test)]
#[allow(clippy::unwrap_used, clippy::expect_used)]
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
    use wiremock::{matchers::method, Mock, MockServer, ResponseTemplate};

    fn make_kv(key: &str, val: AV) -> KeyValue {
        KeyValue {
            key: key.to_string(),
            value: Some(AnyValue { value: Some(val) }),
        }
    }

    fn all_type_attrs() -> Vec<KeyValue> {
        vec![
            make_kv("s", AV::StringValue("hello".to_string())),
            make_kv("i", AV::IntValue(42)),
            make_kv("d", AV::DoubleValue(2.5)),
            make_kv("b", AV::BoolValue(true)),
            make_kv("x", AV::BytesValue(vec![1])),
            KeyValue {
                key: "n".to_string(),
                value: None,
            },
        ]
    }

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

    fn make_writer(url: String) -> Writer {
        Writer::new(
            reqwest::Client::new(),
            url,
            "river".to_string(),
            "river".to_string(),
            "river".to_string(),
        )
    }

    async fn post_server(status: u16, body: &str) -> MockServer {
        let server = MockServer::start().await;
        Mock::given(method("POST"))
            .respond_with(ResponseTemplate::new(status).set_body_string(body))
            .mount(&server)
            .await;
        server
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
        assert!(parse_logs(&req.encode_length_delimited_to_vec())
            .unwrap()
            .is_empty());
    }

    #[test]
    fn parse_traces_empty_request_returns_no_rows() {
        let req = ExportTraceServiceRequest {
            resource_spans: vec![],
        };
        assert!(parse_traces(&req.encode_length_delimited_to_vec())
            .unwrap()
            .is_empty());
    }

    #[test]
    fn parse_logs_returns_error_for_invalid_bytes() {
        assert!(parse_logs(b"not valid protobuf!!!").is_err());
    }

    #[test]
    fn parse_traces_returns_error_for_invalid_bytes() {
        assert!(parse_traces(b"not valid protobuf!!!").is_err());
    }

    #[test]
    fn service_name_returns_empty_when_resource_is_none() {
        assert_eq!(service_name(&None), "");
    }

    #[test]
    fn service_name_returns_empty_when_attr_missing() {
        let resource = Some(Resource {
            attributes: vec![KeyValue {
                key: "host.name".to_string(),
                value: Some(AnyValue {
                    value: Some(AV::StringValue("host".to_string())),
                }),
            }],
            ..Default::default()
        });
        assert_eq!(service_name(&resource), "");
    }

    #[test]
    fn any_value_str_variants() {
        assert_eq!(
            any_value_str(&Some(AnyValue {
                value: Some(AV::IntValue(42))
            })),
            "42"
        );
        assert_eq!(
            any_value_str(&Some(AnyValue {
                value: Some(AV::DoubleValue(3.14))
            })),
            "3.14"
        );
        assert_eq!(
            any_value_str(&Some(AnyValue {
                value: Some(AV::BoolValue(true))
            })),
            "true"
        );
        assert_eq!(
            any_value_str(&Some(AnyValue {
                value: Some(AV::BytesValue(vec![1, 2, 3]))
            })),
            ""
        );
        assert_eq!(any_value_str(&None), "");
    }

    #[test]
    fn attrs_map_handles_multiple_value_types() {
        let m = to_json_attrs(&all_type_attrs());
        assert_eq!(m["s"], serde_json::json!("hello"));
        assert_eq!(m["i"], serde_json::json!(42i64));
        assert_eq!(m["d"], serde_json::json!(2.5f64));
        assert_eq!(m["b"], serde_json::json!(true));
        assert_eq!(m["x"], serde_json::Value::Null);
        assert_eq!(m["n"], serde_json::Value::Null);
    }

    #[test]
    fn attrs_as_string_map_converts_all_types() {
        let m = to_string_attrs(&all_type_attrs());
        assert_eq!(m["s"], serde_json::json!("hello"));
        assert_eq!(m["i"], serde_json::json!("42"));
        assert_eq!(m["d"], serde_json::json!("2.5"));
        assert_eq!(m["b"], serde_json::json!("true"));
        assert_eq!(m["x"], serde_json::json!(""));
        assert_eq!(m["n"], serde_json::json!(""));
    }

    #[test]
    fn service_name_returns_empty_when_value_is_non_string() {
        let resource = Some(Resource {
            attributes: vec![make_kv("service.name", AV::IntValue(99))],
            ..Default::default()
        });
        assert_eq!(service_name(&resource), "");
    }

    #[test]
    fn parse_logs_without_resource_and_null_body() {
        let req = ExportLogsServiceRequest {
            resource_logs: vec![ResourceLogs {
                resource: None,
                scope_logs: vec![ScopeLogs {
                    scope: None,
                    log_records: vec![LogRecord {
                        time_unix_nano: 1,
                        body: None,
                        trace_id: vec![],
                        span_id: vec![],
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
        assert_eq!(rows[0]["service_name"], "");
        assert_eq!(rows[0]["body"], "");
        assert_eq!(rows[0]["trace_id"], "");
    }

    #[test]
    fn parse_traces_without_resource_and_no_status() {
        let req = ExportTraceServiceRequest {
            resource_spans: vec![ResourceSpans {
                resource: None,
                scope_spans: vec![ScopeSpans {
                    scope: None,
                    spans: vec![Span {
                        name: "op".to_string(),
                        start_time_unix_nano: 100,
                        end_time_unix_nano: 100,
                        status: None,
                        ..Default::default()
                    }],
                    schema_url: String::new(),
                }],
                schema_url: String::new(),
            }],
        };
        let rows = parse_traces(&req.encode_length_delimited_to_vec()).unwrap();
        assert_eq!(rows.len(), 1);
        assert_eq!(rows[0]["service_name"], "");
        assert_eq!(rows[0]["duration_ns"], 0u64);
        assert_eq!(rows[0]["status_code"], 0);
    }

    #[tokio::test]
    async fn insert_logs_noop_when_empty() {
        make_writer("http://127.0.0.1:1".to_string())
            .insert_logs(&[])
            .await
            .unwrap();
    }

    #[tokio::test]
    async fn insert_traces_noop_when_empty() {
        make_writer("http://127.0.0.1:1".to_string())
            .insert_traces(&[])
            .await
            .unwrap();
    }

    #[tokio::test]
    async fn insert_logs_sends_rows_to_clickhouse() {
        let server = post_server(200, "").await;
        make_writer(server.uri())
            .insert_logs(&[serde_json::json!({"service_name": "svc", "body": "hi"})])
            .await
            .unwrap();
    }

    #[tokio::test]
    async fn insert_traces_sends_rows_to_clickhouse() {
        let server = post_server(200, "").await;
        make_writer(server.uri())
            .insert_traces(&[serde_json::json!({"trace_id": "abc"})])
            .await
            .unwrap();
    }

    #[tokio::test]
    async fn insert_returns_error_on_clickhouse_failure() {
        let server = post_server(500, "DB error").await;
        let err = make_writer(server.uri())
            .insert_logs(&[serde_json::json!({"a": 1})])
            .await
            .unwrap_err();
        assert!(err.to_string().contains("500"));
    }
}
