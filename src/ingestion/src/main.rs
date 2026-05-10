mod clickhouse;
mod config;
mod migrations;
mod poller;
mod router;
mod victoriametrics;

use std::collections::HashSet;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use anyhow::Result;

#[tokio::main]
async fn main() -> Result<()> {
    let cfg = config::Config::from_env()?;
    let poll_interval = Duration::from_secs(cfg.poll_interval_secs);
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
        cfg.s3_bucket, poll_interval
    );

    loop {
        match run_poll(&s3, &cfg.s3_bucket, start_ts_ms, &mut seen, &vm, &ch).await {
            Ok(0) => {}
            Ok(n) => println!("[poll] processed {n} files"),
            Err(e) => eprintln!("[poll] error: {e}"),
        }
        tokio::time::sleep(poll_interval).await;
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
