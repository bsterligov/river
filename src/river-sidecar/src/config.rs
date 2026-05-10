use ::config::{Config as Cfg, Environment};
use anyhow::Result;
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct Config {
    pub buffer_max_bytes: u64,
    pub flush_interval_secs: u64,
    pub s3_bucket: String,
}

impl Config {
    pub fn from_env() -> Result<Self> {
        Ok(Cfg::builder()
            .set_default("buffer_max_bytes", 10_485_760i64)?
            .set_default("flush_interval_secs", 10)?
            .set_default("s3_bucket", "river-telemetry")?
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
                ("RIVER_BUFFER_MAX_BYTES", Some("5242880")),
                ("RIVER_FLUSH_INTERVAL_SECS", Some("30")),
                ("RIVER_S3_BUCKET", Some("my-bucket")),
            ],
            || {
                let cfg = Config::from_env().expect("config should load");
                assert_eq!(cfg.buffer_max_bytes, 5_242_880);
                assert_eq!(cfg.flush_interval_secs, 30);
                assert_eq!(cfg.s3_bucket, "my-bucket");
            },
        );
    }

    #[test]
    fn uses_defaults_when_vars_absent() {
        temp_env::with_vars(
            [
                ("RIVER_BUFFER_MAX_BYTES", None::<&str>),
                ("RIVER_FLUSH_INTERVAL_SECS", None::<&str>),
                ("RIVER_S3_BUCKET", None::<&str>),
            ],
            || {
                let cfg = Config::from_env().expect("config should load");
                assert_eq!(cfg.buffer_max_bytes, 10_485_760);
                assert_eq!(cfg.flush_interval_secs, 10);
                assert_eq!(cfg.s3_bucket, "river-telemetry");
            },
        );
    }
}
