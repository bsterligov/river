#[derive(Debug, PartialEq)]
pub enum SignalType {
    Metrics,
    Traces,
    Logs,
}

pub fn classify(key: &str) -> Option<SignalType> {
    if key.starts_with("metrics/") {
        Some(SignalType::Metrics)
    } else if key.starts_with("traces/") {
        Some(SignalType::Traces)
    } else if key.starts_with("logs/") {
        Some(SignalType::Logs)
    } else {
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn classifies_metrics() {
        assert_eq!(
            classify("metrics/svc/123-uuid.pb"),
            Some(SignalType::Metrics)
        );
    }

    #[test]
    fn classifies_traces() {
        assert_eq!(classify("traces/svc/123-uuid.pb"), Some(SignalType::Traces));
    }

    #[test]
    fn classifies_logs() {
        assert_eq!(classify("logs/svc/123-uuid.pb"), Some(SignalType::Logs));
    }

    #[test]
    fn unknown_prefix_returns_none() {
        assert_eq!(classify("other/svc/123-uuid.pb"), None);
    }
}
