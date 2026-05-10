use opentelemetry_proto::tonic::collector::metrics::v1::ExportMetricsServiceRequest;
use prost::Message;

pub struct Writer {
    client: reqwest::Client,
    base_url: String,
}

impl Writer {
    pub fn new(client: reqwest::Client, base_url: String) -> Self {
        Writer { client, base_url }
    }

    pub async fn write(&self, data: &[u8]) -> anyhow::Result<()> {
        // S3 payload is length-delimited; OTLP HTTP expects plain protobuf
        let req = ExportMetricsServiceRequest::decode_length_delimited(&mut &data[..])?;
        let body = req.encode_to_vec();

        let url = format!("{}/opentelemetry/v1/metrics", self.base_url);
        let resp = self
            .client
            .post(&url)
            .header("Content-Type", "application/x-protobuf")
            .body(body)
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

#[cfg(test)]
#[allow(clippy::unwrap_used)]
mod tests {
    use super::*;
    use opentelemetry_proto::tonic::collector::metrics::v1::ExportMetricsServiceRequest;
    use prost::Message;
    use wiremock::{matchers::method, Mock, MockServer, ResponseTemplate};

    fn empty_payload() -> Vec<u8> {
        ExportMetricsServiceRequest::default().encode_length_delimited_to_vec()
    }

    async fn post_server(status: u16, body: &str) -> MockServer {
        let server = MockServer::start().await;
        Mock::given(method("POST"))
            .respond_with(ResponseTemplate::new(status).set_body_string(body))
            .mount(&server)
            .await;
        server
    }

    #[tokio::test]
    async fn write_returns_ok_on_200() {
        let server = post_server(200, "").await;
        Writer::new(reqwest::Client::new(), server.uri())
            .write(&empty_payload())
            .await
            .unwrap();
    }

    #[tokio::test]
    async fn write_returns_error_on_500() {
        let server = post_server(500, "storage error").await;
        let err = Writer::new(reqwest::Client::new(), server.uri())
            .write(&empty_payload())
            .await
            .unwrap_err();
        assert!(err.to_string().contains("victoriametrics write failed"));
    }

    #[tokio::test]
    async fn write_returns_error_for_invalid_protobuf() {
        let err = Writer::new(reqwest::Client::new(), "http://127.0.0.1:1".to_string())
            .write(b"not valid protobuf")
            .await
            .unwrap_err();
        assert!(!err.to_string().is_empty());
    }
}
