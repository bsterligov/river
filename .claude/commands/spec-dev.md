# spec-dev

Implementation skill. Reads the current in-progress spec, implements it, and closes out all tracking files. Run after the spec PR has been merged to main.

Do not start implementing until you have confirmed the spec PR is merged (the spec file exists on main).

## Step 1 — Load context

Read in this order:
1. `specs/SPEC.md` — project context, architecture, decisions
2. `specs/QUEUE.md` — find the spec currently listed (not strikethrough)
3. The spec file itself — read fully, paying attention to Why, Goal, Scope In/Out, Test Approach, and Decisions

**Inferring the task from the current branch:**

Run `git branch --show-current`. If the branch is `impl/river-{N}`, derive the task ID as `RIVER-{N}` (uppercase) and look it up in `QUEUE.md`.

- If found and not struck through → use it, no need to ask.
- If not found in QUEUE, or already marked done, or the branch name does not match `impl/*` → ask the user which task to implement before continuing.

## Step 2 — Confirm the implementation branch

Implementation must happen on a feature branch, not main. Run `git branch --show-current` to confirm.

If already on `impl/river-{N}` (e.g. when called from a `plan-dev` subagent worktree), continue — no checkout needed.

If on main or a different branch, check out the impl branch:
```bash
git checkout impl/river-{N}
```

If the branch does not exist yet (GHA did not run), create it with the mise task:
```bash
SPEC_BRANCH=spec/river-{N} mise run spec:impl
git checkout impl/river-{N}
```

## Step 3 — Implement

Implement everything listed under **Scope In**. Follow the Test Approach declared in the spec header (TDD or BDD). Do not implement anything listed under **Scope Out**.

Before each commit, run and fix all failures from:
```bash
mise exec -- cargo fmt
mise exec -- cargo clippy -- -D warnings
mise exec -- cargo test
```

After implementation, review for:

- **Code duplication** — run the script below; fix anything it flags before opening the PR. Target: overall < 3%.

```bash
mise exec -- python - <<'PYEOF'
import os, hashlib, collections, sys

WINDOW = 8

def rs_files(root="src"):
    for dp, _, fs in os.walk(root):
        if "target" in dp:
            continue
        for f in fs:
            if f.endswith(".rs"):
                yield os.path.join(dp, f)

def read_normalized(path):
    with open(path) as fh:
        return [ln.strip() for ln in fh
                if ln.strip() and not ln.strip().startswith("//")]

files = {p: read_normalized(p) for p in rs_files()}

windows = collections.defaultdict(list)
for path, lines in files.items():
    for i in range(len(lines) - WINDOW + 1):
        h = hashlib.md5("\n".join(lines[i:i+WINDOW]).encode()).hexdigest()
        windows[h].append((path, i))

dup = collections.defaultdict(set)
for h, locs in windows.items():
    if len({p for p, _ in locs}) < 2:
        continue
    for path, start in locs:
        for j in range(WINDOW):
            dup[path].add(start + j)

total = sum(len(v) for v in files.values())
total_dup = sum(len(v) for v in dup.values())
pct = 100 * total_dup / total if total else 0

print(f"Overall: {total_dup}/{total} lines = {pct:.1f}%")
for path in sorted(dup, key=lambda p: -len(dup[p]))[:10]:
    fp = 100 * len(dup[path]) / max(len(files[path]), 1)
    print(f"  {path}: {fp:.1f}% ({len(dup[path])} lines)")

sys.exit(0 if pct < 3 else 1)
PYEOF
```
- **Cognitive Complexity ≤ 15** — SonarQube enforces a maximum of 15 per function. Each level of nesting adds to the score (nested `if`/`for`/`match` compounds quickly). When a function exceeds 15, extract the inner logic into a named helper; do not just flatten with early returns if nesting is the root cause.

## Step 4 — Run SonarQube

Run a branch scan and wait for the quality gate:

```bash
mise run sonar:scan   # generates lcov reports + submits scan
mise run sonar:check  # polls CE task, prints gate result and any failing conditions
```

`sonar:check` exits non-zero if the quality gate fails. Fix any reported issues before continuing. The dashboard URL is printed at the end for drill-down.

`SONAR_TOKEN` must be set in the environment (add it to your shell profile or `.env.local` if not already present).

## Step 5 — Close out tracking files

When implementation is complete:

1. **Update `specs/QUEUE.md`** — mark the task done with strikethrough: `~~RIVER-N: Title~~`. Do not remove it from the list.

2. **Append to `specs/HISTORY.md`** — add at the bottom:
   ```
   ### {DATE} — {TASK_NUMBER}: implementation done
   {1–2 sentences on what was built and any notable outcome.}
   ```

## Step 6 — Sync SPEC.md

Update `specs/SPEC.md` with any decisions from this spec.

## Step 7 — Open a PR

Commit all changes (implementation + tracking files), push the branch, and open a draft PR targeting main:

```bash
git add <files>
git commit -m "<type>: RIVER-N message"
git push origin HEAD
gh pr create --title "impl: RIVER-N -- Title" --base main --draft
```
