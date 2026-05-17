use std::collections::{hash_map::Entry, HashMap};
use std::sync::Arc;
use std::time::{Duration, Instant};

use prost::Message;
use tokio::sync::Mutex;

use opentelemetry_proto::tonic::{
    collector::metrics::v1::ExportMetricsServiceRequest,
    common::v1::{InstrumentationScope, KeyValue},
    metrics::v1::{
        metric::Data, Gauge, Histogram, HistogramDataPoint, Metric, NumberDataPoint,
        ResourceMetrics, ScopeMetrics, Sum,
    },
    resource::v1::Resource,
};

use crate::batcher::Sink;

const KEY_SEPARATOR: &str = "\x00";

pub struct Config {
    pub flush_interval: Duration,
    pub key_prefix: String,
}

struct SeriesEntry {
    resource: Option<Resource>,
    scope_name: String,
    scope_version: String,
    metric_name: String,
    metric_description: String,
    metric_unit: String,
    kind: SeriesKind,
}

#[derive(Clone)]
enum SeriesKind {
    Gauge(NumberDataPoint),
    Sum {
        temporality: i32,
        is_monotonic: bool,
        point: NumberDataPoint,
    },
    Histogram {
        temporality: i32,
        point: HistogramDataPoint,
    },
}

struct State {
    series: HashMap<String, SeriesEntry>,
    service_name: String,
    last_flush: Instant,
}

pub struct MetricsAggregator {
    config: Config,
    state: Mutex<State>,
    sink: Arc<dyn Sink>,
}

impl MetricsAggregator {
    pub fn new(config: Config, sink: Arc<dyn Sink>) -> Self {
        MetricsAggregator {
            config,
            state: Mutex::new(State {
                series: HashMap::new(),
                service_name: "unknown".to_string(),
                last_flush: Instant::now(),
            }),
            sink,
        }
    }

    pub async fn push(
        &self,
        service_name: &str,
        req: ExportMetricsServiceRequest,
    ) -> anyhow::Result<()> {
        let mut state = self.state.lock().await;
        if state.series.is_empty() {
            state.service_name = service_name.to_string();
        }
        for rm in &req.resource_metrics {
            let rk = resource_key(&rm.resource);
            for sm in &rm.scope_metrics {
                let sn = sm.scope.as_ref().map(|s| s.name.as_str()).unwrap_or("");
                let sv = sm.scope.as_ref().map(|s| s.version.as_str()).unwrap_or("");
                for m in &sm.metrics {
                    ingest(&mut state.series, &rk, &rm.resource, sn, sv, m);
                }
            }
        }
        Ok(())
    }

    pub async fn tick(&self) -> anyhow::Result<()> {
        let to_flush = {
            let mut state = self.state.lock().await;
            if !state.series.is_empty() && state.last_flush.elapsed() >= self.config.flush_interval
            {
                Some(self.drain(&mut state))
            } else {
                None
            }
        };
        if let Some((key, buf)) = to_flush {
            self.sink.write(key, buf).await?;
        }
        Ok(())
    }

    pub async fn flush(&self) -> anyhow::Result<()> {
        let to_flush = {
            let mut state = self.state.lock().await;
            if !state.series.is_empty() {
                Some(self.drain(&mut state))
            } else {
                None
            }
        };
        if let Some((key, buf)) = to_flush {
            self.sink.write(key, buf).await?;
        }
        Ok(())
    }

    fn drain(&self, state: &mut State) -> (String, Vec<u8>) {
        let series = std::mem::take(&mut state.series);
        let series_count = series.len();
        let service = std::mem::replace(&mut state.service_name, "unknown".to_string());
        state.last_flush = Instant::now();

        let buf = build_request(series).encode_length_delimited_to_vec();
        let key = crate::batcher::make_s3_key(&self.config.key_prefix, &service);
        println!(
            "[flush:metrics] key={key} bytes={} series={series_count}",
            buf.len()
        );
        (key, buf)
    }
}

fn attrs_key(attrs: &[KeyValue]) -> String {
    let mut pairs: Vec<_> = attrs
        .iter()
        .map(|kv| format!("{}={:?}", kv.key, kv.value))
        .collect();
    pairs.sort();
    pairs.join("|")
}

fn resource_key(resource: &Option<Resource>) -> String {
    resource
        .as_ref()
        .map(|r| attrs_key(&r.attributes))
        .unwrap_or_default()
}

fn ingest_points<'a>(
    series: &mut HashMap<String, SeriesEntry>,
    rk: &str,
    resource: &Option<Resource>,
    scope_name: &str,
    scope_ver: &str,
    m: &Metric,
    points: impl Iterator<
        Item = (
            String,
            impl FnOnce() -> SeriesKind + 'a,
            impl FnOnce(&mut SeriesKind) + 'a,
        ),
    >,
) {
    for (pk, make, update) in points {
        upsert(
            series,
            rk,
            resource.clone(),
            scope_name,
            scope_ver,
            m,
            &pk,
            make,
            update,
        );
    }
}

fn ingest(
    series: &mut HashMap<String, SeriesEntry>,
    rk: &str,
    resource: &Option<Resource>,
    scope_name: &str,
    scope_ver: &str,
    m: &Metric,
) {
    match &m.data {
        Some(Data::Gauge(g)) => ingest_points(
            series,
            rk,
            resource,
            scope_name,
            scope_ver,
            m,
            g.data_points.iter().map(|p| {
                let pk = attrs_key(&p.attributes);
                (
                    pk,
                    move || SeriesKind::Gauge(p.clone()),
                    move |k: &mut SeriesKind| {
                        if let SeriesKind::Gauge(e) = k {
                            if p.time_unix_nano >= e.time_unix_nano {
                                *e = p.clone();
                            }
                        }
                    },
                )
            }),
        ),
        Some(Data::Sum(s)) => {
            let (t, mono) = (s.aggregation_temporality, s.is_monotonic);
            ingest_points(
                series,
                rk,
                resource,
                scope_name,
                scope_ver,
                m,
                s.data_points.iter().map(move |p| {
                    let pk = attrs_key(&p.attributes);
                    (
                        pk,
                        move || SeriesKind::Sum {
                            temporality: t,
                            is_monotonic: mono,
                            point: p.clone(),
                        },
                        move |k: &mut SeriesKind| {
                            if let SeriesKind::Sum { point: e, .. } = k {
                                if p.time_unix_nano >= e.time_unix_nano {
                                    *e = p.clone();
                                }
                            }
                        },
                    )
                }),
            );
        }
        Some(Data::Histogram(h)) => {
            let t = h.aggregation_temporality;
            ingest_points(
                series,
                rk,
                resource,
                scope_name,
                scope_ver,
                m,
                h.data_points.iter().map(move |p| {
                    let pk = attrs_key(&p.attributes);
                    (
                        pk,
                        move || SeriesKind::Histogram {
                            temporality: t,
                            point: p.clone(),
                        },
                        move |k: &mut SeriesKind| {
                            if let SeriesKind::Histogram { point: e, .. } = k {
                                if p.time_unix_nano >= e.time_unix_nano {
                                    *e = p.clone();
                                }
                            }
                        },
                    )
                }),
            );
        }
        _ => {} // ExponentialHistogram, Summary: not yet handled
    }
}

#[allow(clippy::too_many_arguments)]
fn upsert(
    series: &mut HashMap<String, SeriesEntry>,
    rk: &str,
    resource: Option<Resource>,
    scope_name: &str,
    scope_ver: &str,
    m: &Metric,
    point_key: &str,
    make: impl FnOnce() -> SeriesKind,
    update: impl FnOnce(&mut SeriesKind),
) {
    let sk = format!(
        "{rk}{KEY_SEPARATOR}{scope_name}{KEY_SEPARATOR}{}{KEY_SEPARATOR}{point_key}",
        m.name
    );
    match series.entry(sk) {
        Entry::Vacant(v) => {
            v.insert(SeriesEntry {
                resource,
                scope_name: scope_name.to_string(),
                scope_version: scope_ver.to_string(),
                metric_name: m.name.clone(),
                metric_description: m.description.clone(),
                metric_unit: m.unit.clone(),
                kind: make(),
            });
        }
        Entry::Occupied(mut o) => update(&mut o.get_mut().kind),
    }
}

fn build_request(series: HashMap<String, SeriesEntry>) -> ExportMetricsServiceRequest {
    let mut by_resource: HashMap<String, Vec<SeriesEntry>> = HashMap::new();
    for entry in series.into_values() {
        by_resource
            .entry(resource_key(&entry.resource))
            .or_default()
            .push(entry);
    }

    let resource_metrics = by_resource
        .into_values()
        .map(|entries| {
            let resource = entries[0].resource.clone();

            let mut by_scope: HashMap<String, Vec<SeriesEntry>> = HashMap::new();
            for e in entries {
                by_scope.entry(e.scope_name.clone()).or_default().push(e);
            }

            let scope_metrics = by_scope
                .into_values()
                .map(|entries| {
                    let scope_name = entries[0].scope_name.clone();
                    let scope_ver = entries[0].scope_version.clone();

                    let mut by_metric: HashMap<String, Vec<SeriesEntry>> = HashMap::new();
                    for e in entries {
                        by_metric.entry(e.metric_name.clone()).or_default().push(e);
                    }

                    ScopeMetrics {
                        scope: Some(InstrumentationScope {
                            name: scope_name,
                            version: scope_ver,
                            attributes: vec![],
                            dropped_attributes_count: 0,
                        }),
                        metrics: by_metric.into_values().map(|e| build_metric(&e)).collect(),
                        schema_url: String::new(),
                    }
                })
                .collect();

            ResourceMetrics {
                resource,
                scope_metrics,
                schema_url: String::new(),
            }
        })
        .collect();

    ExportMetricsServiceRequest { resource_metrics }
}

fn build_metric(entries: &[SeriesEntry]) -> Metric {
    let first = &entries[0];
    let data = match &first.kind {
        SeriesKind::Gauge(_) => Data::Gauge(Gauge {
            data_points: entries
                .iter()
                .filter_map(|e| {
                    if let SeriesKind::Gauge(p) = &e.kind {
                        Some(p.clone())
                    } else {
                        None
                    }
                })
                .collect(),
        }),
        SeriesKind::Sum {
            temporality,
            is_monotonic,
            ..
        } => Data::Sum(Sum {
            data_points: entries
                .iter()
                .filter_map(|e| {
                    if let SeriesKind::Sum { point, .. } = &e.kind {
                        Some(point.clone())
                    } else {
                        None
                    }
                })
                .collect(),
            aggregation_temporality: *temporality,
            is_monotonic: *is_monotonic,
        }),
        SeriesKind::Histogram { temporality, .. } => Data::Histogram(Histogram {
            data_points: entries
                .iter()
                .filter_map(|e| {
                    if let SeriesKind::Histogram { point, .. } = &e.kind {
                        Some(point.clone())
                    } else {
                        None
                    }
                })
                .collect(),
            aggregation_temporality: *temporality,
        }),
    };
    Metric {
        name: first.metric_name.clone(),
        description: first.metric_description.clone(),
        unit: first.metric_unit.clone(),
        data: Some(data),
        metadata: vec![],
    }
}

#[cfg(test)]
#[allow(clippy::unwrap_used, clippy::expect_used, clippy::type_complexity)]
mod tests {
    use super::*;
    use std::sync::Mutex as StdMutex;

    use crate::batcher::test_utils::CaptureSink;
    use opentelemetry_proto::tonic::{
        common::v1::{any_value::Value as AV, AnyValue},
        metrics::v1::number_data_point::Value,
    };

    fn make_agg(
        interval: Duration,
        captured: Arc<StdMutex<Vec<(String, Vec<u8>)>>>,
    ) -> MetricsAggregator {
        MetricsAggregator::new(
            Config {
                flush_interval: interval,
                key_prefix: "metrics".to_string(),
            },
            Arc::new(CaptureSink(captured)),
        )
    }

    fn num_point(ts_ns: u64, value: f64, attrs: Vec<KeyValue>) -> NumberDataPoint {
        NumberDataPoint {
            attributes: attrs,
            time_unix_nano: ts_ns,
            value: Some(Value::AsDouble(value)),
            ..Default::default()
        }
    }

    fn gauge_req(metric: &str, points: Vec<NumberDataPoint>) -> ExportMetricsServiceRequest {
        ExportMetricsServiceRequest {
            resource_metrics: vec![ResourceMetrics {
                resource: None,
                scope_metrics: vec![ScopeMetrics {
                    scope: None,
                    metrics: vec![Metric {
                        name: metric.to_string(),
                        description: String::new(),
                        unit: String::new(),
                        data: Some(Data::Gauge(Gauge {
                            data_points: points,
                        })),
                        metadata: vec![],
                    }],
                    schema_url: String::new(),
                }],
                schema_url: String::new(),
            }],
        }
    }

    fn decode(bytes: &[u8]) -> ExportMetricsServiceRequest {
        ExportMetricsServiceRequest::decode_length_delimited(&mut &bytes[..]).unwrap()
    }

    fn gauge_points(req: &ExportMetricsServiceRequest) -> &[NumberDataPoint] {
        if let Some(Data::Gauge(g)) = &req.resource_metrics[0].scope_metrics[0].metrics[0].data {
            &g.data_points
        } else {
            panic!("expected gauge");
        }
    }

    #[tokio::test]
    async fn keeps_latest_data_point() {
        let req = push_and_flush(vec![
            gauge_req("cpu", vec![num_point(1_000, 0.5, vec![])]),
            gauge_req("cpu", vec![num_point(2_000, 0.9, vec![])]),
        ])
        .await;
        let pts = gauge_points(&req);
        assert_eq!(pts.len(), 1);
        assert_eq!(pts[0].value, Some(Value::AsDouble(0.9)));
    }

    #[tokio::test]
    async fn does_not_overwrite_with_older_point() {
        let req = push_and_flush(vec![
            gauge_req("cpu", vec![num_point(2_000, 0.9, vec![])]),
            gauge_req("cpu", vec![num_point(1_000, 0.5, vec![])]),
        ])
        .await;
        assert_eq!(gauge_points(&req)[0].value, Some(Value::AsDouble(0.9)));
    }

    #[tokio::test]
    async fn different_attrs_are_separate_series() {
        let mk_attr = |v: &str| {
            vec![KeyValue {
                key: "host".to_string(),
                value: Some(AnyValue {
                    value: Some(AV::StringValue(v.to_string())),
                }),
            }]
        };

        let captured = Arc::new(StdMutex::new(vec![]));
        let agg = make_agg(Duration::from_secs(60), Arc::clone(&captured));

        agg.push(
            "svc",
            gauge_req("cpu", vec![num_point(1_000, 0.3, mk_attr("a"))]),
        )
        .await
        .unwrap();
        agg.push(
            "svc",
            gauge_req("cpu", vec![num_point(1_000, 0.7, mk_attr("b"))]),
        )
        .await
        .unwrap();

        agg.flush().await.unwrap();

        let flushed = captured.lock().unwrap();
        assert_eq!(gauge_points(&decode(&flushed[0].1)).len(), 2);
    }

    #[tokio::test]
    async fn flushes_on_interval() {
        let captured = Arc::new(StdMutex::new(vec![]));
        let agg = make_agg(Duration::from_millis(50), Arc::clone(&captured));

        agg.push("svc", gauge_req("cpu", vec![num_point(1_000, 0.5, vec![])]))
            .await
            .unwrap();
        tokio::time::sleep(Duration::from_millis(100)).await;
        agg.tick().await.unwrap();

        assert_eq!(captured.lock().unwrap().len(), 1);
    }

    #[tokio::test]
    async fn tick_does_not_flush_before_interval() {
        let captured = Arc::new(StdMutex::new(vec![]));
        let agg = make_agg(Duration::from_secs(60), Arc::clone(&captured));

        agg.push("svc", gauge_req("cpu", vec![num_point(1_000, 0.5, vec![])]))
            .await
            .unwrap();
        agg.tick().await.unwrap();

        assert_eq!(captured.lock().unwrap().len(), 0);
    }

    fn make_metric_req(name: &str, data: Data) -> ExportMetricsServiceRequest {
        ExportMetricsServiceRequest {
            resource_metrics: vec![ResourceMetrics {
                resource: None,
                scope_metrics: vec![ScopeMetrics {
                    scope: None,
                    metrics: vec![Metric {
                        name: name.to_string(),
                        description: String::new(),
                        unit: String::new(),
                        data: Some(data),
                        metadata: vec![],
                    }],
                    schema_url: String::new(),
                }],
                schema_url: String::new(),
            }],
        }
    }

    async fn push_and_flush(
        pairs: Vec<ExportMetricsServiceRequest>,
    ) -> ExportMetricsServiceRequest {
        let captured = Arc::new(StdMutex::new(vec![]));
        let agg = make_agg(Duration::from_secs(60), Arc::clone(&captured));
        for req in pairs {
            agg.push("svc", req).await.unwrap();
        }
        agg.flush().await.unwrap();
        let flushed = captured.lock().unwrap();
        decode(&flushed[0].1)
    }

    fn sum_req_mono(metric: &str, ts_ns: u64, value: f64) -> ExportMetricsServiceRequest {
        make_metric_req(
            metric,
            Data::Sum(Sum {
                data_points: vec![num_point(ts_ns, value, vec![])],
                aggregation_temporality: 2,
                is_monotonic: true,
            }),
        )
    }

    fn histogram_req_simple(metric: &str, ts_ns: u64) -> ExportMetricsServiceRequest {
        make_metric_req(
            metric,
            Data::Histogram(Histogram {
                data_points: vec![HistogramDataPoint {
                    time_unix_nano: ts_ns,
                    count: 5,
                    sum: Some(100.0),
                    ..Default::default()
                }],
                aggregation_temporality: 2,
            }),
        )
    }

    fn sum_point(req: &ExportMetricsServiceRequest) -> &NumberDataPoint {
        if let Some(Data::Sum(s)) = &req.resource_metrics[0].scope_metrics[0].metrics[0].data {
            &s.data_points[0]
        } else {
            panic!("expected Sum");
        }
    }

    fn histogram_point(req: &ExportMetricsServiceRequest) -> &HistogramDataPoint {
        if let Some(Data::Histogram(h)) = &req.resource_metrics[0].scope_metrics[0].metrics[0].data
        {
            &h.data_points[0]
        } else {
            panic!("expected Histogram");
        }
    }

    #[tokio::test]
    async fn sum_keeps_latest_data_point() {
        let req = push_and_flush(vec![
            sum_req_mono("reqs", 1_000, 10.0),
            sum_req_mono("reqs", 2_000, 20.0),
        ])
        .await;
        let s = sum_point(&req);
        assert_eq!(s.value, Some(Value::AsDouble(20.0)));
    }

    #[tokio::test]
    async fn sum_does_not_overwrite_with_older_point() {
        let req = push_and_flush(vec![
            sum_req_mono("reqs", 2_000, 20.0),
            sum_req_mono("reqs", 1_000, 10.0),
        ])
        .await;
        assert_eq!(sum_point(&req).value, Some(Value::AsDouble(20.0)));
    }

    #[tokio::test]
    async fn histogram_keeps_latest_data_point() {
        let req = push_and_flush(vec![
            histogram_req_simple("lat", 1_000),
            histogram_req_simple("lat", 2_000),
        ])
        .await;
        let h = histogram_point(&req);
        assert_eq!(h.time_unix_nano, 2_000);
        assert_eq!(h.count, 5);
    }

    #[tokio::test]
    async fn histogram_does_not_overwrite_with_older_point() {
        let req = push_and_flush(vec![
            histogram_req_simple("lat", 2_000),
            histogram_req_simple("lat", 1_000),
        ])
        .await;
        assert_eq!(histogram_point(&req).time_unix_nano, 2_000);
    }
}
