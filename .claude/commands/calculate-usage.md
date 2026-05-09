# calculate-usage

Recalculates the Claude token usage table in `docs/token-usage.md` by correlating Claude Code session data with git history.

## Step 1 — Extract token events from Claude Code sessions

Parse all JSONL session files for this project and collect every assistant turn that has a `usage` field:

```python
import json, glob
from datetime import datetime, timezone

proj = "/Users/b.sterligov/.claude/projects/-Users-b-sterligov-projects-river/"
files = glob.glob(proj + "*.jsonl")

events = []
for fpath in files:
    with open(fpath) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except:
                continue
            if obj.get("type") != "assistant":
                continue
            ts_str = obj.get("timestamp")
            usage = obj.get("message", {}).get("usage")
            if not ts_str or not usage:
                continue
            ts = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
            events.append((
                ts,
                usage.get("input_tokens", 0),
                usage.get("cache_creation_input_tokens", 0),
                usage.get("cache_read_input_tokens", 0),
                usage.get("output_tokens", 0),
            ))

events.sort(key=lambda x: x[0])
```

## Step 2 — Extract RTK compression savings

Query the RTK SQLite database for saved tokens in this project, scoped by `project_path`:

```python
import sqlite3

RTK_DB = "/Users/b.sterligov/Library/Application Support/rtk/history.db"
PROJECT_PATH = "/Users/b.sterligov/projects/river"

rtk_events = []
try:
    con = sqlite3.connect(RTK_DB)
    cur = con.execute(
        "SELECT timestamp, saved_tokens FROM commands WHERE project_path = ? ORDER BY timestamp",
        (PROJECT_PATH,),
    )
    for ts_str, saved in cur.fetchall():
        ts = datetime.fromisoformat(ts_str).astimezone(timezone.utc)
        rtk_events.append((ts, saved))
    con.close()
except Exception as e:
    print(f"RTK DB unavailable: {e}")
    rtk_events = []
```

## Step 3 — Load git commits

```python
import subprocess

result = subprocess.run(
    ["git", "log", "--format=%aI|%H|%s"],
    capture_output=True, text=True
)
commits = []
for line in result.stdout.strip().splitlines():
    parts = line.split("|", 2)
    if len(parts) == 3:
        ts_str, sha, msg = parts
        ts = datetime.fromisoformat(ts_str).astimezone(timezone.utc)
        commits.append((ts, sha[:8], msg))
commits.sort(key=lambda x: x[0])
```

## Step 4 — Correlate by timestamp window

For each commit, sum the token usage from all assistant turns that occurred after the previous commit and up to and including this commit's timestamp. Do the same for RTK saved tokens. Skip commits with zero turns.

```python
boundaries = [None] + [c[0] for c in commits]

rows = []
for i, (commit_ts, sha, msg) in enumerate(commits):
    prev_ts = boundaries[i]
    window = [e for e in events if (prev_ts is None or e[0] > prev_ts) and e[0] <= commit_ts]
    if not window:
        continue
    rtk_window = [e for e in rtk_events if (prev_ts is None or e[0] > prev_ts) and e[0] <= commit_ts]
    rows.append({
        "sha": sha,
        "date": commit_ts.strftime("%m-%d %H:%M"),
        "input": sum(e[1] for e in window),
        "cache_create": sum(e[2] for e in window),
        "cache_read": sum(e[3] for e in window),
        "output": sum(e[4] for e in window),
        "turns": len(window),
        "rtk_saved": sum(e[1] for e in rtk_window),
        "subject": msg[:75],
    })
```

## Step 5 — Write docs/token-usage.md

Overwrite `docs/token-usage.md` with the updated table. Use today's date in the header. Include a totals row. Keep the Notes section from the current file if it is still accurate, or update it to reflect what the new numbers show.

Table columns: **Input**, **CacheC** (cache_creation), **CacheR** (cache_read), **Output**, **Turns**, **RTKSaved**, **Subject**.

**RTKSaved** = tokens that would have been fed back to Claude as tool results but were removed by RTK compression. This is additional context consumption that was avoided, on top of the billed input tokens.

Format numbers with thousands separators.
