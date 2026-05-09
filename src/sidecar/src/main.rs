use std::net::SocketAddr;
use std::sync::Arc;
use std::time::Duration;

use opentelemetry_proto::tonic::collector::{
    logs::v1::{
        logs_service_server::{LogsService, LogsServiceServer},
        ExportLogsServiceRequest, ExportLogsServiceResponse,
    },
    metrics::v1::{
        metrics_service_server::{MetricsService, MetricsServiceServer},
        ExportMetricsServiceRequest, ExportMetricsServiceResponse,
    },
    trace::v1::{
        trace_service_server::{TraceService, TraceServiceServer},
        ExportTraceServiceRequest, ExportTraceServiceResponse,
    },
};
use prost::Message;
use tonic::{transport::Server, Request, Response, Status};

mod batcher;
mod metrics_aggregator;
mod sink;

use batcher::{Batcher, Config};
use metrics_aggregator::MetricsAggregator;
use sink::S3Sink;

fn service_name(attrs: &[opentelemetry_proto::tonic::common::v1::KeyValue]) -> String {
    use opentelemetry_proto::tonic::common::v1::any_value::Value;
    attrs
        .iter()
        .find(|kv| kv.key == "service.name")
        .and_then(|kv| kv.value.as_ref())
        .and_then(|v| match &v.value {
            Some(Value::StringValue(s)) => Some(s.clone()),
            _ => None,
        })
        .unwrap_or_else(|| "unknown".to_string())
}

#[derive(Clone)]
struct Receiver {
    traces: Arc<Batcher>,
    metrics: Arc<MetricsAggregator>,
    logs: Arc<Batcher>,
}

#[tonic::async_trait]
impl TraceService for Receiver {
    async fn export(
        &self,
        request: Request<ExportTraceServiceRequest>,
    ) -> Result<Response<ExportTraceServiceResponse>, Status> {
        let req = request.into_inner();
        let svc = req
            .resource_spans
            .first()
            .and_then(|rs| rs.resource.as_ref())
            .map(|r| service_name(&r.attributes))
            .unwrap_or_else(|| "unknown".to_string());
        self.traces
            .push(&svc, req.encode_length_delimited_to_vec())
            .await
            .map_err(|e| Status::internal(e.to_string()))?;
        Ok(Response::new(ExportTraceServiceResponse {
            partial_success: None,
        }))
    }
}

#[tonic::async_trait]
impl MetricsService for Receiver {
    async fn export(
        &self,
        request: Request<ExportMetricsServiceRequest>,
    ) -> Result<Response<ExportMetricsServiceResponse>, Status> {
        let req = request.into_inner();
        let svc = req
            .resource_metrics
            .first()
            .and_then(|rm| rm.resource.as_ref())
            .map(|r| service_name(&r.attributes))
            .unwrap_or_else(|| "unknown".to_string());
        self.metrics
            .push(&svc, req)
            .await
            .map_err(|e| Status::internal(e.to_string()))?;
        Ok(Response::new(ExportMetricsServiceResponse {
            partial_success: None,
        }))
    }
}

#[tonic::async_trait]
impl LogsService for Receiver {
    async fn export(
        &self,
        request: Request<ExportLogsServiceRequest>,
    ) -> Result<Response<ExportLogsServiceResponse>, Status> {
        let req = request.into_inner();
        let svc = req
            .resource_logs
            .first()
            .and_then(|rl| rl.resource.as_ref())
            .map(|r| service_name(&r.attributes))
            .unwrap_or_else(|| "unknown".to_string());
        self.logs
            .push(&svc, req.encode_length_delimited_to_vec())
            .await
            .map_err(|e| Status::internal(e.to_string()))?;
        Ok(Response::new(ExportLogsServiceResponse {
            partial_success: None,
        }))
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let max_bytes: usize = std::env::var("SIDECAR_BUFFER_MAX_BYTES")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(10 * 1024 * 1024);

    let flush_interval = Duration::from_secs(
        std::env::var("SIDECAR_FLUSH_INTERVAL_SECS")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(10u64),
    );

    let bucket = std::env::var("S3_BUCKET").unwrap_or_else(|_| "river-telemetry".to_string());

    let aws_cfg = aws_config::load_from_env().await;
    let s3 = aws_sdk_s3::Client::from_conf(
        aws_sdk_s3::config::Builder::from(&aws_cfg)
            .force_path_style(true)
            .build(),
    );

    let make = |prefix: &str| {
        Arc::new(Batcher::new(
            Config {
                max_bytes,
                flush_interval,
                key_prefix: prefix.to_string(),
            },
            Arc::new(S3Sink::new(s3.clone(), bucket.clone())),
        ))
    };

    let traces = make("traces");
    let logs = make("logs");

    let metrics = Arc::new(MetricsAggregator::new(
        metrics_aggregator::Config {
            flush_interval,
            key_prefix: "metrics".to_string(),
        },
        Arc::new(S3Sink::new(s3.clone(), bucket.clone())),
    ));

    {
        let t = Arc::clone(&traces);
        let m = Arc::clone(&metrics);
        let l = Arc::clone(&logs);
        tokio::spawn(async move {
            loop {
                tokio::time::sleep(Duration::from_secs(1)).await;
                if let Err(e) = t.tick().await {
                    eprintln!("[tick] traces error: {e}");
                }
                if let Err(e) = m.tick().await {
                    eprintln!("[tick] metrics error: {e}");
                }
                if let Err(e) = l.tick().await {
                    eprintln!("[tick] logs error: {e}");
                }
            }
        });
    }

    let receiver = Receiver {
        traces: Arc::clone(&traces),
        metrics: Arc::clone(&metrics),
        logs: Arc::clone(&logs),
    };

    let addr: SocketAddr = "0.0.0.0:4317".parse()?;
    println!("river sidecar listening on {addr}");

    Server::builder()
        .add_service(TraceServiceServer::new(receiver.clone()))
        .add_service(MetricsServiceServer::new(receiver.clone()))
        .add_service(LogsServiceServer::new(receiver))
        .serve_with_shutdown(addr, shutdown_signal())
        .await?;

    println!("[shutdown] flushing remaining buffers");
    let _ = traces.flush().await;
    let _ = metrics.flush().await;
    let _ = logs.flush().await;
    println!("[shutdown] done");

    Ok(())
}

async fn shutdown_signal() {
    let ctrl_c = async { tokio::signal::ctrl_c().await.ok() };

    #[cfg(unix)]
    let terminate = async {
        match tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate()) {
            Ok(mut stream) => stream.recv().await,
            Err(_) => None,
        }
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => {},
        _ = terminate => {},
    }
    println!("[shutdown] signal received");
}
