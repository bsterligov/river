use ::config::{Config as Cfg, Environment};
use anyhow::Result;
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct Config {
    pub api_port: u16,
    pub clickhouse_url: String,
    pub clickhouse_db: String,
    pub clickhouse_user: String,
    pub clickhouse_password: String,
    pub victoriametrics_url: String,
}

impl Config {
    pub fn from_env() -> Result<Self> {
        Ok(Cfg::builder()
            .set_default("api_port", 8080)?
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
                ("RIVER_CLICKHOUSE_URL", Some("http://custom:8123")),
                ("RIVER_API_PORT", Some("9090")),
            ],
            || {
                let cfg = Config::from_env().expect("config should load");
                assert_eq!(cfg.clickhouse_url, "http://custom:8123");
                assert_eq!(cfg.clickhouse_user, "myuser");
                assert_eq!(cfg.clickhouse_password, "mypass");
                assert_eq!(cfg.api_port, 9090);
            },
        );
    }

    #[test]
    fn uses_defaults_for_optional_vars() {
        temp_env::with_vars(
            [
                ("RIVER_CLICKHOUSE_USER", Some("u")),
                ("RIVER_CLICKHOUSE_PASSWORD", Some("p")),
                ("RIVER_CLICKHOUSE_URL", None),
                ("RIVER_API_PORT", None),
                ("RIVER_CLICKHOUSE_DB", None),
                ("RIVER_VICTORIAMETRICS_URL", None),
            ],
            || {
                let cfg = Config::from_env().expect("config should load");
                assert_eq!(cfg.clickhouse_url, "http://clickhouse:8123");
                assert_eq!(cfg.api_port, 8080);
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
