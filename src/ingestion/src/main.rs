mod clickhouse;
mod migrations;
mod poller;
mod router;
mod victoriametrics;

use std::collections::HashSet;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use anyhow::Result;

struct Config {
    bucket: String,
    poll_interval: Duration,
    victoriametrics_url: String,
    clickhouse_url: String,
    clickhouse_db: String,
    clickhouse_user: String,
    clickhouse_password: String,
}

impl Config {
    fn from_env() -> Self {
        Config {
            bucket: std::env::var("S3_BUCKET").unwrap_or_else(|_| "river-telemetry".to_string()),
            poll_interval: Duration::from_secs(
                std::env::var("RIVER_POLL_INTERVAL_SECS")
                    .ok()
                    .and_then(|v| v.parse().ok())
                    .unwrap_or(10u64),
            ),
            victoriametrics_url: std::env::var("VICTORIAMETRICS_URL")
                .unwrap_or_else(|_| "http://victoriametrics:8428".to_string()),
            clickhouse_url: std::env::var("CLICKHOUSE_URL")
                .unwrap_or_else(|_| "http://clickhouse:8123".to_string()),
            clickhouse_db: std::env::var("CLICKHOUSE_DB").unwrap_or_else(|_| "river".to_string()),
            clickhouse_user: std::env::var("CLICKHOUSE_USER")
                .unwrap_or_else(|_| "river".to_string()),
            clickhouse_password: std::env::var("CLICKHOUSE_PASSWORD")
                .unwrap_or_else(|_| "river".to_string()),
        }
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    let cfg = Config::from_env();
    let aws_cfg = aws_config::load_from_env().await;
    let s3 = aws_sdk_s3::Client::from_conf(
        aws_sdk_s3::config::Builder::from(&aws_cfg)
            .force_path_style(true)
            .build(),
    );
    let http = reqwest::Client::new();

    let vm = victoriametrics::Writer::new(http.clone(), cfg.victoriametrics_url.clone());
    let ch = clickhouse::Writer::new(
        http.clone(),
        cfg.clickhouse_url.clone(),
        cfg.clickhouse_db.clone(),
        cfg.clickhouse_user.clone(),
        cfg.clickhouse_password.clone(),
    );

    let migrator = migrations::Migrator::new(
        http.clone(),
        cfg.clickhouse_url.clone(),
        cfg.clickhouse_db.clone(),
        cfg.clickhouse_user.clone(),
        cfg.clickhouse_password.clone(),
    );
    migrator.run().await?;

    let mut seen: HashSet<String> = HashSet::new();
    let start_ts_ms = SystemTime::now().duration_since(UNIX_EPOCH)?.as_millis() as u64;

    println!(
        "river ingestion starting bucket={} interval={:?}",
        cfg.bucket, cfg.poll_interval
    );

    loop {
        match run_poll(&s3, &cfg.bucket, start_ts_ms, &mut seen, &vm, &ch).await {
            Ok(0) => {}
            Ok(n) => println!("[poll] processed {n} files"),
            Err(e) => eprintln!("[poll] error: {e}"),
        }
        tokio::time::sleep(cfg.poll_interval).await;
    }
}

async fn run_poll(
    s3: &aws_sdk_s3::Client,
    bucket: &str,
    start_ts_ms: u64,
    seen: &mut HashSet<String>,
    vm: &victoriametrics::Writer,
    ch: &clickhouse::Writer,
) -> Result<usize> {
    let all_keys = poller::list_keys(s3, bucket).await?;
    let new_keys = poller::filter_new(&all_keys, seen, start_ts_ms);
    let count = new_keys.len();

    for key in &new_keys {
        let data = poller::download(s3, bucket, key).await?;
        match router::classify(key) {
            Some(router::SignalType::Metrics) => vm.write(&data).await?,
            Some(router::SignalType::Logs) => {
                let rows = clickhouse::parse_logs(&data)?;
                ch.insert_logs(&rows).await?;
            }
            Some(router::SignalType::Traces) => {
                let rows = clickhouse::parse_traces(&data)?;
                ch.insert_traces(&rows).await?;
            }
            None => eprintln!("[poll] skipping unknown key prefix: {key}"),
        }
        seen.insert(key.clone());
    }

    Ok(count)
}
