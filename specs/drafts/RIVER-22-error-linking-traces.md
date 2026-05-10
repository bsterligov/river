# DRAFT -- Issue #22
# Run `/po-spec-writer` on this branch to generate the full spec.

Issue:    #22
Task:     RIVER-22
Title:    Error linking traces
Why:
When: try to search trace in Grafana

Observed: error querying the database: code: 60, message: Unknown table expression identifier 'river' in scope SELECT arrayMap((name, timestamp, attributes) -> CAST(tuple(name, toString(toUnixTimestamp64Milli(timestamp)), arrayMap(key -> map('key', key, 'value', attributes[key]), mapKeys(attributes))), 'Tuple(name String, timestamp String, fields Array(Map(String, String)))'), Events.Name, Events.Timestamp, Events.Attributes) AS logs, arrayMap((traceID, spanID, attributes) -> CAST(tuple(traceID, spanID, arrayMap(key -> map('key', key, 'value', attributes[key]), mapKeys(attributes))), 'Tuple(traceID String, spanID String, tags Array(Map(String, String)))'), Links.TraceId, Links.SpanId, Links.Attributes) AS references FROM river WHERE traceID = 'a58c319ea92044d56b66162d63144d88'

With a warning panel: To enable data linking, enter your default trace configuration in your [ClickHouse Data Source settings](http://localhost:3000/connections/datasources/edit/clickhouse#traces-config)
Trace ID

Expected: trace links work in Grafana 
Priority: should
Category: bugs
