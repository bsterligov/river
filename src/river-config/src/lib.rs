use ::config::{builder::DefaultState, Config as Cfg, ConfigBuilder, Environment};
use anyhow::Result;
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct StorageConfig {
    pub clickhouse_url: String,
    pub clickhouse_db: String,
    pub clickhouse_user: String,
    pub clickhouse_password: String,
    pub victoriametrics_url: String,
}

pub fn builder() -> ConfigBuilder<DefaultState> {
    Cfg::builder()
}

pub fn storage_defaults(b: ConfigBuilder<DefaultState>) -> Result<ConfigBuilder<DefaultState>> {
    Ok(b.set_default("clickhouse_url", "http://clickhouse:8123")?
        .set_default("clickhouse_db", "river")?
        .set_default("victoriametrics_url", "http://victoriametrics:8428")?)
}

pub fn build<T: serde::de::DeserializeOwned>(b: ConfigBuilder<DefaultState>) -> Result<T> {
    Ok(b.add_source(Environment::with_prefix("RIVER"))
        .build()?
        .try_deserialize()?)
}

#[cfg(test)]
#[allow(clippy::expect_used)]
mod tests {
    use super::*;

    #[test]
    fn storage_defaults_are_applied() {
        temp_env::with_vars(
            [
                ("RIVER_CLICKHOUSE_USER", Some("u")),
                ("RIVER_CLICKHOUSE_PASSWORD", Some("p")),
                ("RIVER_CLICKHOUSE_URL", None::<&str>),
                ("RIVER_CLICKHOUSE_DB", None::<&str>),
                ("RIVER_VICTORIAMETRICS_URL", None::<&str>),
            ],
            || {
                let cfg: StorageConfig =
                    build(storage_defaults(builder()).expect("defaults")).expect("build");
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
                assert!(
                    build::<StorageConfig>(storage_defaults(builder()).expect("defaults")).is_err()
                );
            },
        );
    }
}
