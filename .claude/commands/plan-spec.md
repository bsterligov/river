# plan-spec

Reads a feature plan from `specs/plans/` and for each phase spawns a parallel subagent that creates a GitHub issue, waits for the GHA to create the spec branch, checks it out, and writes a spec using spec.

Subagents run with worktree isolation so they can work on separate branches in parallel without git conflicts.

## Step 1 — Locate the plan

The user provides the plan name as an argument (e.g. `/plan-spec alerting-system`). Resolve it to `specs/plans/{plan-name}.md`.

If the argument is missing, list all files in `specs/plans/` and ask the user to name one.

Read the plan file fully.

## Step 2 — Extract phases

Parse every `### Phase N — {Name}` section. For each phase, collect:
- **Number** — the phase number (1, 2, …)
- **Name** — the phase label after the dash
- **Goal** — the `**Goal:**` line
- **Steps** — the `**Steps:**` numbered list, joined as a single block of text
- **Done when** — the `**Done when:**` line

Also capture the plan-level **Why** from the `Why:` header line.

## Step 3 — Confirm before spawning

Print a table:

```
Phase | Name | Goal (truncated to 80 chars)
------+------+------------------------------
1     | …    | …
2     | …    | …
```

Ask the user:
1. **Which phases to process** — default is all; user can list numbers to skip (e.g. "skip 3, 4")
2. **Default priority** — must / should / could (applied to all phases uniformly)

Do not proceed until confirmed.

## Step 4 — Spawn one subagent per phase

For each confirmed phase, call the Agent tool with `isolation: "worktree"` and `run_in_background: true`.

Use this prompt template for each subagent (fill in the placeholders from the plan):

---

You are working inside the River repository. Your job is to create a GitHub issue for one phase of a feature plan, wait for the GHA to create a spec branch, check it out, and write a spec using spec.

**Context from the feature plan:**
- Why (plan-level): {WHY}
- Phase {N}: {PHASE_NAME}
- Goal: {GOAL}
- Steps:
{STEPS}
- Done when: {DONE_WHEN}

**Issue fields to use (do not ask the user — these are already decided):**
- Title: `{PHASE_NAME}`
- Category: `features`
- Priority: `{PRIORITY}`
- Body:
```
{GOAL}

Steps:
{STEPS}

Done when: {DONE_WHEN}

Part of feature plan: {PLAN_NAME}
Why: {WHY}
```

**Your steps:**

1. Create the GitHub issue:
   ```bash
   gh issue create \
     --title "{PHASE_NAME}" \
     --body "..." \
     --label "features" \
     --label "{PRIORITY}"
   ```
   Extract the issue number from the returned URL (e.g. `/issues/42` → `42`).

2. Wait 30 seconds for the GHA workflow to create the spec branch, then poll:
   ```bash
   gh pr list --state open --json number,headRefName,body \
     | jq '.[] | select(.body | contains("#<issue_number>"))'
   ```
   If no PR is found, retry once after 15 more seconds. If still not found after two attempts, report the issue number and stop — do not proceed without the branch.

3. Fetch and check out the spec branch in this worktree:
   ```bash
   git fetch origin
   git checkout <headRefName>
   ```

4. Invoke the spec skill. Pass it all context from the issue fields above so it does not need to ask for inputs — it should find the draft file in `specs/drafts/` (created by GHA) and proceed directly to proposing a test approach and writing the spec.

5. Report: issue number, branch name, spec file path created.

---

## Step 5 — Report results

After all subagents complete, print a summary table:

```
Phase | Issue | Branch           | Spec file                        | Status
------+-------+------------------+----------------------------------+--------
1     | #42   | spec/river-42    | specs/must/features/RIVER-42-…   | done
2     | #43   | spec/river-43    | specs/must/features/RIVER-43-…   | done
3     | —     | —                | —                                | failed (no PR found)
```

If any subagent failed, print its error and tell the user which phases need manual follow-up.
