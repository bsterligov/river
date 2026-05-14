# dev-plan-impl

Merges all approved spec PRs for a feature plan and then spawns one subagent per phase to implement its spec using the dev-spec skill.

## Step 1 — Select the plan

If the user provided a plan name as an argument (e.g. `/dev-plan-impl logs-ui-full-page`), resolve it to `specs/plans/{plan-name}.md`.

If no argument, list all files in `specs/plans/` and ask the user to choose one.

Read the plan file fully. Extract:
- The plan name (file stem, e.g. `logs-ui-full-page`)
- The human-readable title from the first `# Plan:` heading
- Every `### Phase N — {Name}` section (number + name)
- For each phase: the **Depends on** list and the **Execution** value (`parallel` or `sequential`)

Build an execution graph: group phases into sequential waves. A wave is a set of phases whose dependencies are all satisfied by previous waves. Phases in the same wave can run in parallel. Example: if Phase 1 and 2 have no deps, they form Wave 1. Phase 3 depends on Phase 1, Phase 4 depends on Phase 2 — they form Wave 2 (parallel). Phase 5 depends on Phase 3 and 4 — it forms Wave 3 alone.

## Step 2 — Find related spec PRs

Spec PRs are created by the GHA when issues are opened. Their issue bodies contain `Part of feature plan: {PLAN_NAME}`. Search in two steps:

**2a. Find the issues:**
```bash
gh issue list --state all --json number,title,body \
  | jq '[.[] | select(.body | contains("Part of feature plan: {PLAN_NAME}"))]'
```

**2b. For each issue number, find the open spec PR that references it:**
```bash
gh pr list --state open --json number,title,headRefName,body,reviews,reviewDecision \
  | jq '[.[] | select(.body | contains("#{ISSUE_NUMBER}"))]'
```

Collect all matching PRs into a list. Each entry should track:
- `pr_number`
- `title`
- `headRefName` (the spec branch, e.g. `spec/river-42`)
- `reviewDecision` — `APPROVED`, `CHANGES_REQUESTED`, `REVIEW_REQUIRED`, or null
- `issue_number`

## Step 3 — Show status and confirm

Print a table:

```
Phase | Issue | PR    | Branch           | Review status
------+-------+-------+------------------+------------------
1     | #42   | #50   | spec/river-42    | APPROVED
2     | #43   | #51   | spec/river-43    | REVIEW_REQUIRED
3     | #44   | #52   | spec/river-44    | CHANGES_REQUESTED
```

If any PR is **not** `APPROVED`, stop and tell the user which PRs still need approval. Do not proceed until all are approved — re-running the command after approvals is the intended flow.

If all PRs are approved, print the resolved execution plan before confirming:

```
Wave 1 (parallel):  Phase 1 — {Name}, Phase 2 — {Name}
Wave 2 (parallel):  Phase 3 — {Name}, Phase 4 — {Name}
Wave 3 (sequential): Phase 5 — {Name}
```

Then confirm with the user:
> "All N spec PRs are approved. Merge and implement in the order above?"

Do not proceed without confirmation.

## Step 4 — Merge spec PRs one by one

Merge in phase order (ascending phase number). For each PR:

```bash
gh pr merge {PR_NUMBER} --merge --auto
```

After each merge, verify it landed on main:
```bash
git fetch origin
git log origin/main --oneline -3
```

**Conflict resolution:** If a merge fails due to conflicts:
1. Check out the spec branch locally.
2. Rebase it onto the latest main:
   ```bash
   git checkout {headRefName}
   git fetch origin
   git rebase origin/main
   ```
3. Resolve any conflicts in the spec files (keep the incoming spec content; the base is main's state of the specs directory).
4. Force-push the rebased branch and re-merge:
   ```bash
   git push --force-with-lease origin {headRefName}
   gh pr merge {PR_NUMBER} --merge
   ```
5. If conflicts are non-trivial (ambiguous which content to keep), pause and explain the conflict to the user before resolving.

Wait for each merge to complete before starting the next one.

## Step 5 — Wait for impl branches

After all spec PRs are merged, the GHA creates `impl/river-{N}` branches automatically. Poll until all impl branches exist (max 3 attempts, 30 s apart):

```bash
git fetch origin
git branch -r | grep "origin/impl/river-"
```

For each expected impl branch (derived from the issue numbers found in Step 2), confirm it is present. If a branch is still missing after 3 attempts, report it and skip that phase — do not block the others.

## Step 6 — Spawn subagents wave by wave

Process the execution waves in order. For each wave:

1. Spawn one subagent per phase in the wave simultaneously (all Agent calls in a single message with `isolation: "worktree"` and `run_in_background: true`).
2. Wait for all subagents in the wave to complete before starting the next wave.
3. If a subagent in the wave fails, report it but continue the wave — do not block other phases in the same wave. Do block dependent phases in subsequent waves: remove them from their wave and mark them as skipped with the reason.

Use this prompt template for each subagent (fill in placeholders):

---

You are working inside the River repository on the `impl/river-{ISSUE_NUMBER}` branch. Your job is to implement the spec for RIVER-{ISSUE_NUMBER} by invoking the dev-spec skill.

**Context:**
- Plan: {PLAN_TITLE}
- Phase {N}: {PHASE_NAME}
- Impl branch: `impl/river-{ISSUE_NUMBER}`
- Spec file location: find it under `specs/` with `find specs -name "*RIVER-{ISSUE_NUMBER}*"`

**Your steps:**

1. Check out the impl branch:
   ```bash
   git fetch origin
   git checkout impl/river-{ISSUE_NUMBER}
   ```

2. Invoke the dev-spec skill. It will:
   - Read `specs/SPEC.md`, `specs/QUEUE.md`, and the spec file
   - Implement everything in Scope In
   - Run `mise exec -- cargo fmt && mise exec -- cargo clippy -- -D warnings && mise exec -- cargo test`
   - Close out `specs/QUEUE.md` and `specs/HISTORY.md`
   - Open a draft impl PR targeting main

3. Report back: impl PR number, branch, and any test failures.

---

## Step 7 — Report results

After all subagents complete, print a summary table:

```
Phase | Issue | Impl branch          | Impl PR | Status
------+-------+----------------------+---------+--------
1     | #42   | impl/river-42        | #60     | done
2     | #43   | impl/river-43        | #61     | done
3     | #44   | —                    | —       | skipped (impl branch not created)
```

If any subagent failed or was skipped, tell the user what needs manual follow-up.
