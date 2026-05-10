# dev-spec

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

## Step 2 — Check out the implementation branch

Implementation must happen on a feature branch, not main. The GHA creates it automatically on spec PR merge.

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

- **Code duplication** — if two functions share a repeated block (e.g. building a WHERE clause, parsing a filter, constructing the same struct), extract a shared helper. Three similar lines is a signal; near-identical 10-line blocks are always a bug.
- **Cognitive Complexity ≤ 15** — SonarQube enforces a maximum of 15 per function. Each level of nesting adds to the score (nested `if`/`for`/`match` compounds quickly). When a function exceeds 15, extract the inner logic into a named helper; do not just flatten with early returns if nesting is the root cause.

## Step 4 — Close out tracking files

When implementation is complete:

1. **Update `specs/QUEUE.md`** — mark the task done with strikethrough: `~~RIVER-N: Title~~`. Do not remove it from the list.

2. **Append to `specs/HISTORY.md`** — add at the bottom:
   ```
   ### {DATE} — {TASK_NUMBER}: implementation done
   {1–2 sentences on what was built and any notable outcome.}
   ```

## Step 5 — Sync SPEC.md

Update `specs/SPEC.md` with any decisions from this spec.

## Step 6 — Open a PR

Commit all changes (implementation + tracking files) and open a draft PR targeting main:

```bash
git add <files>
git commit -m "<type>: RIVER-N message"
gh pr create --title "impl: RIVER-N -- Title" --base main --draft
```

Do not push directly to main.
