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
SPEC_BRANCH=spec/river-{N} mise run agent:spec-impl
git checkout impl/river-{N}
```

## Step 3 — Implement

Implement everything listed under **Scope In**. Follow the Test Approach declared in the spec header (TDD or BDD). Do not implement anything listed under **Scope Out**.

**Mise tasks** — if a `mise run` call fails or the spec requires automation that has no task yet, create or fix the task file before continuing. Tasks live in `.mise/tasks/ci/` (stateless validation, suitable for CI) or `.mise/tasks/agent/` (agent and developer workflow steps). Write tasks directly in Python (`#!/usr/bin/env python3`) or Bash (`#!/usr/bin/env bash`) with a `#MISE description=` header line. Do not inline scripts in command specs — if a script is needed, it belongs in a task file.

Before each commit, run and fix all failures from:
```bash
mise exec -- cargo fmt
mise exec -- cargo clippy -- -D warnings
mise exec -- cargo test
```

After implementation, review for:

- **Code duplication** — run the check below; fix anything it flags before opening the PR. Target: overall < 3%.

```bash
mise run agent:check-duplication
```
- **Cognitive Complexity ≤ 15** — SonarQube enforces a maximum of 15 per function. Each level of nesting adds to the score (nested `if`/`for`/`match` compounds quickly). When a function exceeds 15, extract the inner logic into a named helper; do not just flatten with early returns if nesting is the root cause.

## Step 4 — Run SonarQube

Load `SONAR_TOKEN` from `.env.local` if it is not already in the environment:
```bash
export SONAR_TOKEN=$(grep '^SONAR_TOKEN' .env.local | cut -d'"' -f2)
```

Run a scan and wait for the quality gate:

```bash
mise run ci:sonar-scan   # generates lcov reports + submits PR or branch scan
mise run ci:sonar-check  # polls CE task, prints gate result and any failing conditions
```

`ci:sonar-scan` automatically uses PR mode when an open PR exists (passes `sonar.pullrequest.*`), falling back to branch mode otherwise.

`ci:sonar-check` exits non-zero if the quality gate fails. When it does, fetch the new issues introduced by this PR and fix every one before continuing:

```bash
export SONAR_TOKEN=$(grep '^SONAR_TOKEN' .env.local | cut -d'"' -f2)
mise run agent:sonar-issues
```

After fixing, re-run `ci:sonar-scan` + `ci:sonar-check` until the gate passes. The dashboard URL is printed at the end for drill-down.

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

Before opening the PR, check that no other `impl/*` PR is already open. One impl PR at a time is the rule — it keeps the review queue clean and prevents merge conflicts from piling up.

```bash
mise run agent:check-impl-pr
```

If the check passes, commit all changes (implementation + tracking files), push, and open the draft PR:

```bash
git add <files>
git commit -m "<type>: RIVER-N message"
git push origin HEAD
gh pr create --title "impl: RIVER-N -- Title" --base main --draft
```
