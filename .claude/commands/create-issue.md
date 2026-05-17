# create-issue

Interactive skill to create a GitHub issue with priority and category labels.

## Step 1 — Gather inputs

Ask the user for the following, one at a time:

1. **Category** — choose one:
   - `bugs`
   - `docs`
   - `features`
   - `refactoring`
   - `tools`

2. **Priority** — choose one:
   - `must`
   - `should`
   - `could`
   - `won't`

3. **Title** — short, imperative sentence describing the issue.

4. **Body** — full description. Prompt the user to provide context, expected vs actual behavior (for bugs), or acceptance criteria (for features). Accept multi-line input.

## Step 2 — Confirm

Print a summary of the collected values and ask the user to confirm before creating the issue:

```
Title:    <title>
Labels:   <category>, <priority>
Body:
<body>
```

If the user requests changes, loop back and re-collect the relevant field(s).

## Step 3 — Create the issue

Run:

```bash
gh issue create \
  --title "<title>" \
  --body "<body>" \
  --label "<category>" \
  --label "<priority>"
```

Print the URL returned by `gh issue create` and note the issue number from the URL (e.g. `/issues/42` → issue number `42`).

## Step 4 — Switch to the spec branch

Wait 30 seconds for the GHA workflow to create the spec branch and draft PR, then run:

```bash
gh pr list --state open --json number,headRefName,body \
  | jq '.[] | select(.body | contains("#<issue_number>"))'
```

If no PR is found yet, retry once after another 15 seconds.

Once the draft spec PR is found, fetch and check out its branch:

```bash
git fetch origin
git checkout <headRefName>
```

Tell the user which branch is now active.

## Step 5 — Offer direct implementation

Ask the user:

> "Do you want me to implement this directly? I'll write the spec, get it reviewed, and start implementation once it's approved."

If the user says **no** (or does not respond), stop here. The user will run `/spec` and `/spec-dev` manually.

If the user says **yes**, continue to Step 6.

## Step 6 — Write and publish the spec

Run the `/spec` skill inline on the current branch. All inputs (issue number, title, category, priority, why, test approach) must be collected and confirmed before writing. Follow the full `/spec` skill flow including:

- Reading `specs/SPEC.md` for context
- Using the draft file from `specs/drafts/` if present
- Writing the spec file, updating `specs/QUEUE.md`
- Deleting the draft file if it existed

After the spec is written, commit and push:

```bash
git add specs/
git commit -m "spec: RIVER-<N> -- <title>"
git push origin HEAD
```

Then mark the spec PR as ready for review:

```bash
gh pr ready
```

Print the PR URL and tell the user the spec is ready for review.

## Step 7 — Review loop

Ask the user:

> "Is the spec approved, or are there comments to fix?"

**If there are comments:** ask the user to paste or describe them. Fix the relevant parts of the spec file, commit the fix, push, and reply to each comment thread:

```bash
gh pr comment <pr_number> --body "Fixed: <one-line summary of the change>"
```

Then ask again: "Anything else, or are we good to merge?"

Repeat until the user confirms approval.

**If approved:** continue to Step 8.

**If the user says to abandon:** stop and tell the user no changes were made to main.

## Step 8 — Merge, rebase, and implement

Merge the approved spec PR:

```bash
gh pr merge <pr_number> --squash --delete-branch
```

Switch to main and pull:

```bash
git checkout main
git pull origin main
```

Then run the `/spec-dev` skill to implement the spec. `/spec-dev` will locate the impl branch (created by GHA on spec PR merge), check it out, implement the spec, and open the impl PR.
