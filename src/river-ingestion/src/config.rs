use anyhow::Result;
use river_config::StorageConfig;
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct Config {
    pub s3_bucket: String,
    pub poll_interval_secs: u64,
    #[serde(flatten)]
    pub storage: StorageConfig,
}

impl Config {
    pub fn from_env() -> Result<Self> {
        river_config::build(
            river_config::storage_defaults(river_config::builder())?
                .set_default("s3_bucket", "river-telemetry")?
                .set_default("poll_interval_secs", 10)?,
        )
    }
}

#[cfg(test)]
#[allow(clippy::expect_used)]
mod tests {
    use super::*;

    #[test]
    fn reads_ingestion_fields_from_env() {
        temp_env::with_vars(
            [
                ("RIVER_CLICKHOUSE_USER", Some("u")),
                ("RIVER_CLICKHOUSE_PASSWORD", Some("p")),
                ("RIVER_S3_BUCKET", Some("my-bucket")),
                ("RIVER_POLL_INTERVAL_SECS", Some("30")),
            ],
            || {
                let cfg = Config::from_env().expect("should load");
                assert_eq!(cfg.s3_bucket, "my-bucket");
                assert_eq!(cfg.poll_interval_secs, 30);
            },
        );
    }

    #[test]
    fn defaults_ingestion_fields() {
        temp_env::with_vars(
            [
                ("RIVER_CLICKHOUSE_USER", Some("u")),
                ("RIVER_CLICKHOUSE_PASSWORD", Some("p")),
                ("RIVER_S3_BUCKET", None::<&str>),
                ("RIVER_POLL_INTERVAL_SECS", None::<&str>),
            ],
            || {
                let cfg = Config::from_env().expect("should load");
                assert_eq!(cfg.s3_bucket, "river-telemetry");
                assert_eq!(cfg.poll_interval_secs, 10);
            },
        );
    }
}
