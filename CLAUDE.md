# CLAUDE.md

Instructions for Claude Code when working in this repository.

## Key files

| File | Purpose |
|------|---------|
| `specs/SPEC.md` | Project context — why, architecture, tech stack, decisions. Read first. Read-only during spec authoring. |
| `specs/QUEUE.md` | Work queue — one spec in progress at a time. |
| `specs/HISTORY.md` | Changelog — what changed across specs and when. Append at bottom. |
| `specs/UNRESOLVED.md` | Open questions — unresolved issues across all specs. |
| `.claude/commands/spec.md` | Skill — write and update specs. Opens a PR with spec only; implementation follows after merge. |
| `.claude/commands/spec-dev.md` | Skill — implement the current in-progress spec, close tracking files, open impl PR. |
| `.claude/commands/create-issue.md` | Skill — create a GitHub issue with category and priority labels, then check out the GHA-created spec branch. |
| `.claude/commands/create-feature.md` | Skill — plan an ambitious feature: decompose into phases, document risks, save to `specs/plans/`. |
| `.claude/commands/plan-spec.md` | Skill — execute a saved plan: spawn one parallel subagent per phase to create issues and write specs. |
| `.claude/commands/plan-dev.md` | Skill — merge all approved spec PRs for a plan, then spawn one subagent per phase to implement its spec. After each wave completes, waits for all impl PRs to be validated before starting the next wave. |
| `.claude/commands/pr-merge.md` | Skill — merge all validated impl PRs for the current wave of a plan, one by one, with conflict resolution. |
| `.github/workflows/spec-from-issue.yml` | GHA — fires on issue open (spec draft) and on spec PR merge (impl branch + draft PR). No API key needed. |

## Choosing the right command

When a user describes something they want to build or fix, proactively suggest the right starting point before asking for further detail.

| Situation | Command to propose |
|-----------|--------------------|
| Small, well-scoped task (bug, doc, single endpoint, config change) | `/create-issue` — create an issue and jump straight to the spec branch |
| Feature with multiple moving parts or unclear scope | `/create-feature` — plan phases first, then `/plan-spec` to kick off specs in parallel |
| Spec branch already exists and is checked out | `/spec` — write the spec now |
| Spec PR is merged, impl branch is active | `/spec-dev` — implement what the spec says |
| All spec PRs for a plan are approved and ready to land | `/plan-dev` — merge them in order and kick off parallel implementation |
| Wave N impl PRs are validated and ready to land | `/pr-merge` — merge them into main one by one with conflict resolution |

If the user describes a task but does not specify a command, make a recommendation in one sentence ("This sounds like a `/create-issue` — want me to kick that off?") and wait for confirmation. Do not silently start a workflow.

Use `/create-feature` when:
- The task spans more than one component or codebase area
- The user uses words like "system", "pipeline", "full", "end-to-end", "redesign"
- The scope is unclear and decomposing it first would surface risks or open questions

Use `/create-issue` when:
- The task is contained in a single component
- Acceptance criteria can be stated in a few lines
- No design decisions need to be resolved before implementation begins

## Running Commands

Always prefix with `mise exec --` so the correct toolchain is used.

```bash
mise exec -- cargo build
mise exec -- cargo test
mise exec -- cargo clippy
mise exec -- flutter build
mise exec -- flutter test
```

Never call `cargo`, `flutter`, or `dart` directly.

## Style

- No emojis in any output, files, or code.
