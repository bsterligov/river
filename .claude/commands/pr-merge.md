# pr-merge

Reads the current feature plan, finds all open impl PRs for the current wave, and merges them one by one into main with conflict resolution.

Use this when `plan-dev`'s automatic wave-gate timed out, or when you want to trigger wave merges manually without running `plan-dev` again. Requires all PRs in the target wave to already be validated (non-draft, CI green, approved).

## Step 1 — Select the plan

If the user provided a plan name as an argument (e.g. `/pr-merge logs-ui-full-page`), resolve it to `specs/plans/{plan-name}.md`.

If no argument, list all files in `specs/plans/` and ask the user to choose one.

Read the plan file fully. Extract phase numbers, names, and dependency graph. Rebuild the wave execution order (same logic as `plan-dev` Step 1).

## Step 2 — Find open impl PRs for the plan

**2a. Find the issues for this plan:**
```bash
gh issue list --state all --json number,title,body \
  | jq '[.[] | select(.body | contains("Part of feature plan: {PLAN_NAME}"))]'
```

**2b. For each issue number, find the open impl PR:**
```bash
gh pr list --state open --json number,title,headRefName,isDraft,reviewDecision,statusCheckRollup,body \
  | jq '[.[] | select(.headRefName | startswith("impl/river-"))]'
```

Match PRs to issues by looking for `#{ISSUE_NUMBER}` in the PR body or by matching the branch name (`impl/river-{ISSUE_NUMBER}`).

Collect all matching open impl PRs. For each, track:
- `pr_number`
- `title`
- `headRefName`
- `issue_number`
- `phase_number` (derived from the plan)
- `isDraft`
- `reviewDecision`
- CI status: `green` if all `statusCheckRollup` entries have `conclusion: SUCCESS`; `pending` if any are `IN_PROGRESS`; `failed` otherwise

## Step 3 — Show status and confirm

Print a table grouped by wave:

```
Wave 1
  Phase | Issue | PR  | Branch        | Draft | CI     | Review
  ------+-------+-----+---------------+-------+--------+------------------
  1     | #42   | #60 | impl/river-42 | no    | green  | APPROVED
  2     | #43   | #61 | impl/river-43 | no    | green  | APPROVED

Wave 2
  Phase | Issue | PR  | Branch        | Draft | CI     | Review
  ------+-------+-----+---------------+-------+--------+------------------
  3     | #44   | #62 | impl/river-44 | yes   | pending| REVIEW_REQUIRED
```

**Validation check:** If any PR in the earliest incomplete wave is still draft, has failing CI, or is not approved, stop and list the blockers. Do not proceed until they are resolved.

If all PRs in the target wave are validated, confirm with the user:
> "Merging N impl PRs for Wave W in phase order. Proceed?"

Do not proceed without confirmation.

## Step 4 — Determine which wave to merge

Merge the lowest-numbered wave that has at least one open PR. Skip waves that have no open PRs (already merged or never created).

Within the wave, sort PRs by phase number (ascending) and merge them one by one.

## Step 5 — Merge PRs one by one

For each PR in phase order:

```bash
gh pr merge {PR_NUMBER} --merge
```

After each merge, verify it landed on main:
```bash
git fetch origin
git log origin/main --oneline -3
```

**Conflict resolution:** If a merge fails due to conflicts:

1. Check out the impl branch locally:
   ```bash
   git fetch origin
   git checkout {headRefName}
   ```
2. Rebase onto the latest main:
   ```bash
   git rebase origin/main
   ```
3. Resolve conflicts: for Rust source files, keep the incoming branch content unless the conflict is in a file that was changed by a previously merged phase in this same wave — in that case, manually merge both changes. For spec files (`specs/`), keep both changes (append the incoming section below the existing one).
4. Run tests to verify the rebase is clean:
   ```bash
   mise exec -- cargo fmt && mise exec -- cargo clippy -- -D warnings && mise exec -- cargo test
   ```
   For Flutter files: `mise exec -- flutter test`.
5. Force-push and re-merge:
   ```bash
   git push --force-with-lease origin {headRefName}
   gh pr merge {PR_NUMBER} --merge
   ```
6. If conflicts are ambiguous (unclear which content to keep), **pause and describe the conflict to the user** before resolving. Do not silently discard either side.

Wait for each merge to complete before starting the next one.

## Step 6 — Report results

After all PRs in the wave are merged, print a summary table:

```
Phase | Issue | PR  | Branch        | Status
------+-------+-----+---------------+--------
1     | #42   | #60 | impl/river-42 | merged
2     | #43   | #61 | impl/river-43 | merged (rebased)
3     | #44   | #62 | —             | skipped (conflict — needs manual resolution)
```

If any PR was skipped or requires manual follow-up, say so explicitly with the reason.

If there are more waves with open PRs remaining, remind the user:
> "Wave W complete. Wave W+1 has N PRs open — run `/pr-merge {PLAN_NAME}` again once they are validated."
