use async_trait::async_trait;
use aws_sdk_s3::primitives::ByteStream;

use crate::batcher::Sink;

pub struct S3Sink {
    client: aws_sdk_s3::Client,
    bucket: String,
}

impl S3Sink {
    pub fn new(client: aws_sdk_s3::Client, bucket: String) -> Self {
        S3Sink { client, bucket }
    }
}

#[async_trait]
impl Sink for S3Sink {
    async fn write(&self, key: String, data: Vec<u8>) -> anyhow::Result<()> {
        self.client
            .put_object()
            .bucket(&self.bucket)
            .key(&key)
            .body(ByteStream::from(data))
            .send()
            .await
            .map_err(|e| anyhow::anyhow!("s3 write failed key={key}: {e}"))?;
        Ok(())
    }
}
