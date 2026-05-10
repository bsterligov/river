use ::config::{Config as Cfg, Environment};
use anyhow::Result;
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct Config {
    pub s3_bucket: String,
    pub poll_interval_secs: u64,
    pub victoriametrics_url: String,
    pub clickhouse_url: String,
    pub clickhouse_db: String,
    pub clickhouse_user: String,
    pub clickhouse_password: String,
}

impl Config {
    pub fn from_env() -> Result<Self> {
        Ok(Cfg::builder()
            .set_default("s3_bucket", "river-telemetry")?
            .set_default("poll_interval_secs", 10)?
            .set_default("clickhouse_url", "http://clickhouse:8123")?
            .set_default("clickhouse_db", "river")?
            .set_default("victoriametrics_url", "http://victoriametrics:8428")?
            .add_source(Environment::with_prefix("RIVER"))
            .build()?
            .try_deserialize()?)
    }
}

#[cfg(test)]
#[allow(clippy::expect_used)]
mod tests {
    use super::*;

    #[test]
    fn reads_values_from_env() {
        temp_env::with_vars(
            [
                ("RIVER_CLICKHOUSE_USER", Some("myuser")),
                ("RIVER_CLICKHOUSE_PASSWORD", Some("mypass")),
                ("RIVER_S3_BUCKET", Some("my-bucket")),
                ("RIVER_POLL_INTERVAL_SECS", Some("30")),
            ],
            || {
                let cfg = Config::from_env().expect("config should load");
                assert_eq!(cfg.s3_bucket, "my-bucket");
                assert_eq!(cfg.poll_interval_secs, 30);
                assert_eq!(cfg.clickhouse_user, "myuser");
            },
        );
    }

    #[test]
    fn uses_defaults_for_optional_vars() {
        temp_env::with_vars(
            [
                ("RIVER_CLICKHOUSE_USER", Some("u")),
                ("RIVER_CLICKHOUSE_PASSWORD", Some("p")),
                ("RIVER_S3_BUCKET", None),
                ("RIVER_POLL_INTERVAL_SECS", None),
                ("RIVER_CLICKHOUSE_URL", None),
                ("RIVER_CLICKHOUSE_DB", None),
                ("RIVER_VICTORIAMETRICS_URL", None),
            ],
            || {
                let cfg = Config::from_env().expect("config should load");
                assert_eq!(cfg.s3_bucket, "river-telemetry");
                assert_eq!(cfg.poll_interval_secs, 10);
                assert_eq!(cfg.clickhouse_url, "http://clickhouse:8123");
                assert_eq!(cfg.clickhouse_db, "river");
                assert_eq!(cfg.victoriametrics_url, "http://victoriametrics:8428");
            },
        );
    }

    #[test]
    fn missing_credentials_returns_err() {
        temp_env::with_vars(
            [
                ("RIVER_CLICKHOUSE_USER", None::<&str>),
                ("RIVER_CLICKHOUSE_PASSWORD", None::<&str>),
            ],
            || {
                assert!(Config::from_env().is_err());
            },
        );
    }
}
