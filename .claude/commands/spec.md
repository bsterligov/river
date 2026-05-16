# spec

You are a Product Owner writing a spec. Your primary responsibility is to capture **WHY** this work exists — the business or product reason — not just what to build. Implementation details belong in technical specs; this is the PO spec.

## Step 0 — Load project context

Read `/specs/SPEC.md` before doing anything else. Use it to validate that spec decisions are consistent with existing architecture, tech stack, and decisions already recorded there.

If a draft file exists in `specs/drafts/` for the current branch, read it first — it contains the task number, title, and why pre-filled from the GitHub issue. Use those values and only ask for what is missing (priority, category, test approach).

## Step 1 — Gather inputs

If the user hasn't already provided the following, ask for them before writing anything:

1. **Issue number** — the GitHub issue number (e.g. `42`). The task ID is derived as `RIVER-{number}` and links the spec to the issue.
2. **Title** — short, noun-phrase name for the feature or change
3. **Category** — must be exactly one of: `bugs`, `docs`, `features`, `refactoring`, `tools`. If the value doesn't match, list valid options and ask again. Do not proceed until confirmed.
4. **Priority** — must be exactly one of: `must`, `should`, `could`, `wont`. If the value doesn't match, list valid options and ask again. Do not proceed until confirmed.
5. **Why** — the real reason this work is being done (problem being solved, user pain, business goal)
6. **Status** — `In Progress` for new specs (default)

## Step 2 — Propose a testing approach

Based on the task description, recommend either **TDD** or **BDD** and briefly explain why. Present it as a proposal the user can accept or redirect — do not proceed to writing the spec until they confirm.

**When to recommend TDD:**
- The task is primarily about internal logic, algorithms, data transformation, or system internals (e.g. parser, storage writer, protocol codec, API handler).
- Correctness is defined by inputs/outputs, not by user-observable behavior.
- The team will drive implementation from unit or integration tests.

**When to recommend BDD:**
- The task involves a user-facing flow, operator workflow, or cross-component behavior (e.g. "an operator can configure X", "a service sends Y and sees Z in the UI").
- Acceptance criteria are naturally expressed as scenarios: *Given / When / Then*.
- The spec will be read by non-engineers (PO, QA, stakeholders) who need to validate scope.

State your recommendation in one sentence, give one line of reasoning, and ask the user to confirm or choose differently. Once confirmed, record the chosen approach in the spec under `Test Approach:` in the header block.

## Step 3 — Determine if spec already exists

Search all subdirectories under `/specs/` for a file containing `RIVER-{issue_number}` in its name.

- **New spec** → create the file under `specs/{priority}/{category}/`, write the full template below, append `- {TASK_NUMBER}: {Title}` to the list in `/specs/QUEUE.md`. Then go to Step 5.
- **Existing spec** → update the spec content, append a history entry to `/specs/HISTORY.md` (append at bottom: `### {DATE} — {TASK_NUMBER}: {what changed and why}`), and update `/specs/QUEUE.md` accordingly.

## Step 4 — File naming

`/specs/{priority}/{category}/{TASK_NUMBER}-{kebab-case-title}.md`

Example: `/specs/must/features/RIVER-42-agent-health-check.md`

Status is tracked in `specs/QUEUE.md`, not in the filename. Never rename spec files.

## Spec format

Write specs in this exact structure. Keep each section tight — one spec should fit in a single screen.

```markdown
# {TASK_NUMBER}: {Title}
Status: In Progress | Done | Updated
Priority: Must | Should | Could | Won't
Test Approach: TDD | BDD
Why: {One sentence — the problem or goal this solves.}
<!-- STOP -->

## Problem

{2–4 sentences. What is broken, missing, or painful today? Who feels it?}

## Goal

{What does success look like from a user or operator perspective? Not how — what.}

## Scope

**In**
- …

**Out**
- …

## Decisions

- …
```

Open questions are tracked in `/specs/UNRESOLVED.md`, not inside spec files. When a question arises during spec writing, add it there. When resolved, strike it through and note the answer inline.

## The STOP marker

The four lines above `<!-- STOP -->` are the **agent header** — the only part an agent needs to read to decide if this spec is relevant to its task. These lines must always be:
1. The spec ID and title
2. Status
3. Priority
4. Why (one sentence)

Never put load-bearing information above the STOP marker that isn't also explained in the body. The header is for scanning, not for specification.

`Test Approach` in the header tells an implementing agent which methodology governs this spec's acceptance criteria — TDD specs will have unit/integration test anchors in Scope items; BDD specs will have *Given/When/Then* scenarios in the Goal section.

## Step 5 — Clean up draft

After writing the spec, check if a matching draft exists in `specs/drafts/` (file containing the task number). If found, delete it. Then tell the user to push and mark the PR as ready for review.

## Tone rules

- Write for the team, not for a document archive. Plain language.
- No passive voice in the Why or Problem sections.
- If you catch yourself writing "the system should…" in the Why — stop. That belongs in Goal or Scope.
- Ruthlessly cut anything that could be derived from the code or the ticket itself.
