pub struct Writer {
    client: reqwest::Client,
    base_url: String,
}

impl Writer {
    pub fn new(client: reqwest::Client, base_url: String) -> Self {
        Writer { client, base_url }
    }

    pub async fn write(&self, data: &[u8]) -> anyhow::Result<()> {
        let url = format!("{}/opentelemetry/v1/metrics", self.base_url);
        let resp = self
            .client
            .post(&url)
            .header("Content-Type", "application/x-protobuf")
            .body(data.to_vec())
            .send()
            .await?;
        if !resp.status().is_success() {
            let status = resp.status();
            let body = resp.text().await.unwrap_or_default();
            anyhow::bail!("victoriametrics write failed status={status}: {body}");
        }
        Ok(())
    }
}
