# dev-spec

Implementation skill. Reads the current in-progress spec, implements it, and closes out all tracking files. Run after the spec PR has been merged to main.

Do not start implementing until you have confirmed the spec PR is merged (the spec file exists on main).

## Step 1 — Load context

Read in this order:
1. `specs/SPEC.md` — project context, architecture, decisions
2. `specs/QUEUE.md` — find the spec currently listed under **In Progress**
3. The spec file itself — read fully, paying attention to Why, Goal, Scope In/Out, Test Approach, and Decisions

## Step 2 — Implement

Implement everything listed under **Scope In**. Follow the Test Approach declared in the spec header (TDD or BDD). Do not implement anything listed under **Scope Out**.


Before each commit, run and fix all failures from:
```bash
mise exec -- cargo fmt
mise exec -- cargo clippy -- -D warnings
mise exec -- cargo test
```

## Step 3 — Close out tracking files

When implementation is complete:

1. **Update `specs/QUEUE.md`** — remove the task from **In Progress**. Completed specs are not listed in QUEUE; they live in `HISTORY.md`.

3. **Append to `specs/HISTORY.md`** — add at the bottom:
   ```
   ### {DATE} — {TASK_NUMBER}: implementation done
   {1–2 sentences on what was built and any notable outcome.}
   ```



## Step 4 — Prompt for sync

Update `specs/SPEC.md` with any decisions from this spec.

## Step 5 — Stage changes

**Stage all tracking changes** in a single commit:
   ```
   <type: fix, feat, docs ...>: RIVER-N message
   ```
