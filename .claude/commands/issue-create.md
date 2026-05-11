# issue-create

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
