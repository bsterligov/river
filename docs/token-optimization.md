# Token optimization

Two tools work in parallel to reduce the tokens Claude consumes per session.

## RTK — Bash output compression

[RTK](https://github.com/rtk-ai/rtk) intercepts every `Bash` tool call via a global `PreToolUse` hook. It rewrites commands to compressed equivalents (`git status` → `rtk git status`) and truncates verbose output before it reaches Claude's context window.

RTK is transparent — Claude issues normal commands and sees filtered results. No configuration needed per project; it is registered globally in `~/.claude/settings.json`.

## river-index — Read interception

`river-index` is a Rust crate in this repo (`src/river-index/`) that builds a SQLite index of the workspace. A project-level `PreToolUse` hook intercepts `Read` tool calls on source files and returns a compact summary instead of the full content.

Example — `src/river-query-api/src/main.rs` (504 lines):

```
src/river-query-api/src/main.rs rust 504L
structs: AppState ErrorBody RangeParams MetricsParams ApiDoc
enums: ApiError
fns: get_logs get_traces get_metrics get_health build_router main
deps: axum serde tokio utoipa victoriametrics
```

~60 tokens instead of ~1500 for an exploration read — a 20x reduction.

The index is kept fresh automatically: a `PostToolUse` hook on `Bash` detects `git commit` calls and triggers an incremental reindex in the background.

**Hook chain:**

| Hook | Scope | Trigger | What it does |
|------|-------|---------|--------------|
| `rtk hook claude` | Global | `PreToolUse` — every Bash | Rewrites + compresses Bash output |
| `river-index hook` | Project | `PreToolUse` — Read on `.rs`/`.dart` | Returns compact symbol summary, blocks raw read |
| `river-index post-commit-hook` | Project | `PostToolUse` — Bash after `git commit` | Incremental reindex of changed files |

**Passthrough rules for river-index** — raw content is returned to Claude when:

| Condition | Reason |
|-----------|--------|
| `.md`, `.yaml`, `.toml`, `.json`, `.sql` etc. | Specs and configs need full content |
| Read with `offset` or `limit` | Targeted read — Claude knows exactly what it wants |
| File outside the repo | Not indexed |
| File not in the index | Safe fallback |
| Binary not built or DB missing | Safe fallback |

**Setup** — build the release binary once:

```bash
mise run index:reindex
```

This builds `target/release/river-index`, indexes the workspace, and prints stats. Both hooks are wired in `.claude/settings.local.json` — no further configuration needed.

**Manual queries:**

```bash
./target/release/river-index file src/river-query-api/src/main.rs  # file summary
./target/release/river-index symbols "get_logs"                    # find symbol (% wildcard)
./target/release/river-index search "ClickHouse"                   # full-text search
./target/release/river-index deps "river_config"                   # dependency graph
./target/release/river-index status                                # index stats
```
