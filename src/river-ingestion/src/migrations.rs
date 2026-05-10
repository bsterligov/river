use anyhow::Result;

const MIGRATIONS: &[(&str, &str)] = &[
    (
        "V001__create_logs",
        include_str!("../../../infra/migrations/clickhouse/V001__create_logs.sql"),
    ),
    (
        "V002__create_traces",
        include_str!("../../../infra/migrations/clickhouse/V002__create_traces.sql"),
    ),
    (
        "V003__alter_logs_timestamp",
        include_str!("../../../infra/migrations/clickhouse/V003__alter_logs_timestamp.sql"),
    ),
];

pub struct Migrator {
    client: reqwest::Client,
    base_url: String,
    db: String,
    user: String,
    password: String,
}

impl Migrator {
    pub fn new(
        client: reqwest::Client,
        base_url: String,
        db: String,
        user: String,
        password: String,
    ) -> Self {
        Migrator {
            client,
            base_url,
            db,
            user,
            password,
        }
    }

    pub async fn run(&self) -> Result<()> {
        self.ensure_tracking_table().await?;
        let applied = self.applied_versions().await?;
        for (version, sql) in MIGRATIONS {
            if applied.contains(&version.to_string()) {
                continue;
            }
            println!("[migrations] applying {version}");
            self.exec(sql).await?;
            self.record_version(version).await?;
        }
        Ok(())
    }

    async fn ensure_tracking_table(&self) -> Result<()> {
        let ddl = "CREATE TABLE IF NOT EXISTS schema_migrations (\
            version String, \
            applied_at DateTime DEFAULT now()\
        ) ENGINE = MergeTree() ORDER BY version";
        self.exec(ddl).await
    }

    async fn applied_versions(&self) -> Result<Vec<String>> {
        let query = "SELECT version FROM schema_migrations ORDER BY version";
        let resp = self
            .client
            .get(&self.base_url)
            .query(&[
                ("query", query),
                ("user", self.user.as_str()),
                ("password", self.password.as_str()),
                ("database", self.db.as_str()),
            ])
            .send()
            .await?;
        if !resp.status().is_success() {
            let body = resp.text().await.unwrap_or_default();
            anyhow::bail!("failed to query schema_migrations: {body}");
        }
        let body = resp.text().await?;
        Ok(body
            .lines()
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .map(String::from)
            .collect())
    }

    async fn record_version(&self, version: &str) -> Result<()> {
        let query = format!("INSERT INTO schema_migrations (version) VALUES ('{version}')");
        self.exec(&query).await
    }

    async fn exec(&self, sql: &str) -> Result<()> {
        let resp = self
            .client
            .post(&self.base_url)
            .query(&[
                ("user", self.user.as_str()),
                ("password", self.password.as_str()),
                ("database", self.db.as_str()),
            ])
            .body(sql.to_string())
            .send()
            .await?;
        if !resp.status().is_success() {
            let body = resp.text().await.unwrap_or_default();
            anyhow::bail!("clickhouse exec failed: {body}");
        }
        Ok(())
    }
}

#[cfg(test)]
#[allow(clippy::unwrap_used, clippy::expect_used)]
mod tests {
    use super::*;
    use wiremock::{matchers::method, Mock, MockServer, ResponseTemplate};

    fn migrator_from_env() -> Option<Migrator> {
        let url = std::env::var("CLICKHOUSE_URL").ok()?;
        Some(Migrator::new(
            reqwest::Client::new(),
            url,
            std::env::var("CLICKHOUSE_DB").unwrap_or_else(|_| "river".to_string()),
            std::env::var("CLICKHOUSE_USER").unwrap_or_else(|_| "river".to_string()),
            std::env::var("CLICKHOUSE_PASSWORD").unwrap_or_else(|_| "river".to_string()),
        ))
    }

    async fn query_rows(migrator: &Migrator, sql: &str) -> Vec<String> {
        let resp = migrator
            .client
            .get(&migrator.base_url)
            .query(&[
                ("query", sql),
                ("user", migrator.user.as_str()),
                ("password", migrator.password.as_str()),
                ("database", migrator.db.as_str()),
            ])
            .send()
            .await
            .expect("clickhouse query failed");
        assert!(resp.status().is_success(), "query returned error status");
        resp.text()
            .await
            .unwrap()
            .lines()
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .map(String::from)
            .collect()
    }

    #[tokio::test]
    async fn migrations_create_logs_and_traces_tables() {
        let Some(m) = migrator_from_env() else {
            println!("CLICKHOUSE_URL not set — skipping integration test");
            return;
        };

        m.run().await.expect("migrations failed");

        let logs_cols: Vec<String> = query_rows(
            &m,
            "SELECT name FROM system.columns WHERE database = currentDatabase() AND table = 'logs' ORDER BY name",
        )
        .await;
        let expected_logs = [
            "attributes",
            "body",
            "service_name",
            "severity_number",
            "severity_text",
            "span_id",
            "timestamp",
            "trace_id",
        ];
        for col in expected_logs {
            assert!(
                logs_cols.iter().any(|c| c == col),
                "missing logs column: {col}"
            );
        }

        let traces_cols: Vec<String> = query_rows(
            &m,
            "SELECT name FROM system.columns WHERE database = currentDatabase() AND table = 'traces' ORDER BY name",
        )
        .await;
        let expected_traces = [
            "Events.Attributes",
            "Events.Name",
            "Events.Timestamp",
            "Links.Attributes",
            "Links.SpanId",
            "Links.TraceId",
            "attributes",
            "duration_ns",
            "end_time_unix_nano",
            "operation_name",
            "parent_span_id",
            "service_name",
            "span_id",
            "start_time_unix_nano",
            "status_code",
            "trace_id",
        ];
        for col in expected_traces {
            assert!(
                traces_cols.iter().any(|c| c == col),
                "missing traces column: {col}"
            );
        }
    }

    #[tokio::test]
    async fn migrations_are_idempotent() {
        let Some(m) = migrator_from_env() else {
            println!("CLICKHOUSE_URL not set — skipping integration test");
            return;
        };

        m.run().await.expect("first run failed");
        m.run().await.expect("second run failed");

        let versions: Vec<String> =
            query_rows(&m, "SELECT version FROM schema_migrations ORDER BY version").await;
        assert!(versions.contains(&"V001__create_logs".to_string()));
        assert!(versions.contains(&"V002__create_traces".to_string()));
        assert!(versions.contains(&"V003__alter_logs_timestamp".to_string()));
    }

    fn make_migrator(base_url: String) -> Migrator {
        Migrator::new(
            reqwest::Client::new(),
            base_url,
            "river".to_string(),
            "river".to_string(),
            "river".to_string(),
        )
    }

    async fn mock_server(http_method: &str, status: u16, body: &str) -> MockServer {
        let server = MockServer::start().await;
        Mock::given(method(http_method))
            .respond_with(ResponseTemplate::new(status).set_body_string(body))
            .mount(&server)
            .await;
        server
    }

    #[tokio::test]
    async fn exec_returns_ok_on_200() {
        let server = mock_server("POST", 200, "").await;
        make_migrator(server.uri())
            .exec("CREATE TABLE foo (id UInt64) ENGINE = Memory")
            .await
            .unwrap();
    }

    #[tokio::test]
    async fn exec_returns_error_on_500() {
        let server = mock_server("POST", 500, "DB error").await;
        let err = make_migrator(server.uri())
            .exec("bad sql")
            .await
            .unwrap_err();
        assert!(err.to_string().contains("clickhouse exec failed"));
    }

    #[tokio::test]
    async fn applied_versions_returns_lines() {
        let server = mock_server("GET", 200, "V001__create_logs\nV002__create_traces\n").await;
        let versions = make_migrator(server.uri())
            .applied_versions()
            .await
            .unwrap();
        assert_eq!(versions, vec!["V001__create_logs", "V002__create_traces"]);
    }

    #[tokio::test]
    async fn applied_versions_returns_empty_for_blank_body() {
        let server = mock_server("GET", 200, "").await;
        assert!(make_migrator(server.uri())
            .applied_versions()
            .await
            .unwrap()
            .is_empty());
    }

    #[tokio::test]
    async fn applied_versions_returns_error_on_500() {
        let server = mock_server("GET", 500, "access denied").await;
        let err = make_migrator(server.uri())
            .applied_versions()
            .await
            .unwrap_err();
        assert!(err
            .to_string()
            .contains("failed to query schema_migrations"));
    }

    #[tokio::test]
    async fn run_applies_all_migrations_when_none_applied() {
        let server = MockServer::start().await;
        Mock::given(method("GET"))
            .respond_with(ResponseTemplate::new(200).set_body_string(""))
            .mount(&server)
            .await;
        Mock::given(method("POST"))
            .respond_with(ResponseTemplate::new(200))
            .mount(&server)
            .await;
        make_migrator(server.uri()).run().await.unwrap();
    }

    #[tokio::test]
    async fn run_skips_already_applied_migrations() {
        let server = MockServer::start().await;
        Mock::given(method("GET"))
            .respond_with(
                ResponseTemplate::new(200)
                    .set_body_string("V001__create_logs\nV002__create_traces\n"),
            )
            .mount(&server)
            .await;
        Mock::given(method("POST"))
            .respond_with(ResponseTemplate::new(200))
            .mount(&server)
            .await;
        make_migrator(server.uri()).run().await.unwrap();
    }
}
