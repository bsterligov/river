use std::sync::Arc;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use async_trait::async_trait;
use tokio::sync::Mutex;

#[async_trait]
pub trait Sink: Send + Sync {
    async fn write(&self, key: String, data: Vec<u8>) -> anyhow::Result<()>;
}

pub struct Config {
    pub max_bytes: usize,
    pub flush_interval: Duration,
    pub key_prefix: String,
}

struct State {
    buffer: Vec<u8>,
    service_name: String,
    last_flush: Instant,
}

pub struct Batcher {
    config: Config,
    state: Mutex<State>,
    sink: Arc<dyn Sink>,
}

impl Batcher {
    pub fn new(config: Config, sink: Arc<dyn Sink>) -> Self {
        Batcher {
            config,
            state: Mutex::new(State {
                buffer: Vec::new(),
                service_name: "unknown".to_string(),
                last_flush: Instant::now(),
            }),
            sink,
        }
    }

    pub async fn push(&self, service_name: &str, data: Vec<u8>) -> anyhow::Result<()> {
        let to_flush = {
            let mut state = self.state.lock().await;
            if state.buffer.is_empty() {
                state.service_name = service_name.to_string();
            }
            state.buffer.extend_from_slice(&data);
            if state.buffer.len() >= self.config.max_bytes {
                Some(self.drain(&mut state))
            } else {
                None
            }
        };
        if let Some((key, buf)) = to_flush {
            self.sink.write(key, buf).await?;
        }
        Ok(())
    }

    pub async fn flush(&self) -> anyhow::Result<()> {
        let to_flush = {
            let mut state = self.state.lock().await;
            if !state.buffer.is_empty() {
                Some(self.drain(&mut state))
            } else {
                None
            }
        };
        if let Some((key, buf)) = to_flush {
            self.sink.write(key, buf).await?;
        }
        Ok(())
    }

    pub async fn tick(&self) -> anyhow::Result<()> {
        let to_flush = {
            let mut state = self.state.lock().await;
            if !state.buffer.is_empty() && state.last_flush.elapsed() >= self.config.flush_interval
            {
                Some(self.drain(&mut state))
            } else {
                None
            }
        };
        if let Some((key, buf)) = to_flush {
            self.sink.write(key, buf).await?;
        }
        Ok(())
    }

    fn drain(&self, state: &mut State) -> (String, Vec<u8>) {
        let data = std::mem::take(&mut state.buffer);
        let service = std::mem::replace(&mut state.service_name, "unknown".to_string());
        state.last_flush = Instant::now();
        let ts = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_millis();
        let key = format!(
            "{}/{}/{}-{}.pb",
            self.config.key_prefix,
            service,
            ts,
            uuid::Uuid::new_v4()
        );
        println!("[flush] key={key} bytes={}", data.len());
        (key, data)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::Mutex as StdMutex;

    struct CaptureSink(Arc<StdMutex<Vec<(String, Vec<u8>)>>>);

    #[async_trait]
    impl Sink for CaptureSink {
        async fn write(&self, key: String, data: Vec<u8>) -> anyhow::Result<()> {
            self.0.lock().unwrap().push((key, data));
            Ok(())
        }
    }

    fn make_batcher(
        max_bytes: usize,
        flush_interval: Duration,
        captured: Arc<StdMutex<Vec<(String, Vec<u8>)>>>,
    ) -> Batcher {
        Batcher::new(
            Config {
                max_bytes,
                flush_interval,
                key_prefix: "traces".to_string(),
            },
            Arc::new(CaptureSink(captured)),
        )
    }

    #[tokio::test]
    async fn flushes_when_buffer_exceeds_max_bytes() {
        let captured = Arc::new(StdMutex::new(vec![]));
        let batcher = make_batcher(100, Duration::from_secs(60), Arc::clone(&captured));

        batcher.push("svc", vec![0u8; 101]).await.unwrap();

        let flushed = captured.lock().unwrap();
        assert_eq!(flushed.len(), 1);
        assert_eq!(flushed[0].1.len(), 101);
    }

    #[tokio::test]
    async fn no_flush_below_max_bytes() {
        let captured = Arc::new(StdMutex::new(vec![]));
        let batcher = make_batcher(100, Duration::from_secs(60), Arc::clone(&captured));

        batcher.push("svc", vec![0u8; 50]).await.unwrap();

        assert_eq!(captured.lock().unwrap().len(), 0);
    }

    #[tokio::test]
    async fn flushes_on_interval() {
        let captured = Arc::new(StdMutex::new(vec![]));
        let batcher = make_batcher(10_000_000, Duration::from_millis(50), Arc::clone(&captured));

        batcher.push("svc", vec![1u8; 10]).await.unwrap();
        tokio::time::sleep(Duration::from_millis(100)).await;
        batcher.tick().await.unwrap();

        assert_eq!(captured.lock().unwrap().len(), 1);
    }

    #[tokio::test]
    async fn tick_does_not_flush_before_interval() {
        let captured = Arc::new(StdMutex::new(vec![]));
        let batcher = make_batcher(10_000_000, Duration::from_secs(60), Arc::clone(&captured));

        batcher.push("svc", vec![1u8; 10]).await.unwrap();
        batcher.tick().await.unwrap();

        assert_eq!(captured.lock().unwrap().len(), 0);
    }

    #[tokio::test]
    async fn service_name_in_key() {
        let captured = Arc::new(StdMutex::new(vec![]));
        let batcher = make_batcher(1, Duration::from_secs(60), Arc::clone(&captured));

        batcher.push("my-service", vec![0u8]).await.unwrap();

        let flushed = captured.lock().unwrap();
        assert!(flushed[0].0.contains("my-service"));
    }

    #[tokio::test]
    async fn key_prefix_in_key() {
        let captured = Arc::new(StdMutex::new(vec![]));
        let batcher = make_batcher(1, Duration::from_secs(60), Arc::clone(&captured));

        batcher.push("svc", vec![0u8]).await.unwrap();

        let flushed = captured.lock().unwrap();
        assert!(flushed[0].0.starts_with("traces/"));
    }
}
