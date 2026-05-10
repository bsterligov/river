use std::collections::HashSet;

pub fn filter_new(keys: &[String], seen: &HashSet<String>, start_ts_ms: u64) -> Vec<String> {
    keys.iter()
        .filter(|k| !seen.contains(*k) && ts_from_key(k) >= start_ts_ms)
        .cloned()
        .collect()
}

pub fn ts_from_key(key: &str) -> u64 {
    // key format: {signal}/{service}/{ts_ms}-{uuid}.pb
    key.rsplit('/')
        .next()
        .and_then(|f| f.split('-').next())
        .and_then(|s| s.parse().ok())
        .unwrap_or(0)
}

pub async fn list_keys(client: &aws_sdk_s3::Client, bucket: &str) -> anyhow::Result<Vec<String>> {
    let mut keys = Vec::new();
    let mut continuation: Option<String> = None;
    loop {
        let mut req = client.list_objects_v2().bucket(bucket);
        if let Some(t) = continuation {
            req = req.continuation_token(t);
        }
        let out = req.send().await?;
        for obj in out.contents() {
            if let Some(k) = obj.key() {
                keys.push(k.to_string());
            }
        }
        match out.next_continuation_token() {
            Some(t) => continuation = Some(t.to_string()),
            None => break,
        }
    }
    Ok(keys)
}

pub async fn download(
    client: &aws_sdk_s3::Client,
    bucket: &str,
    key: &str,
) -> anyhow::Result<Vec<u8>> {
    let out = client.get_object().bucket(bucket).key(key).send().await?;
    let bytes = out.body.collect().await?.into_bytes().to_vec();
    Ok(bytes)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ts_from_key_parses_correctly() {
        assert_eq!(
            ts_from_key("metrics/svc/1746700000000-some-uuid.pb"),
            1746700000000
        );
    }

    #[test]
    fn ts_from_key_returns_zero_for_bad_format() {
        assert_eq!(ts_from_key("bad"), 0);
    }

    #[test]
    fn filter_new_skips_keys_with_old_timestamps() {
        let keys = vec!["traces/svc/1000-uuid.pb".to_string()];
        let seen = HashSet::new();
        assert!(filter_new(&keys, &seen, 2000).is_empty());
    }

    #[test]
    fn filter_new_skips_already_seen_keys() {
        let key = "traces/svc/2000-uuid.pb".to_string();
        let mut seen = HashSet::new();
        seen.insert(key.clone());
        assert!(filter_new(&[key], &seen, 1000).is_empty());
    }

    #[test]
    fn filter_new_returns_eligible_keys() {
        let keys = vec!["traces/svc/2000-uuid.pb".to_string()];
        let seen = HashSet::new();
        assert_eq!(filter_new(&keys, &seen, 2000).len(), 1);
    }

    #[test]
    fn filter_new_includes_key_at_exact_start_ts() {
        let keys = vec!["logs/svc/5000-uuid.pb".to_string()];
        let seen = HashSet::new();
        assert_eq!(filter_new(&keys, &seen, 5000).len(), 1);
    }
}
