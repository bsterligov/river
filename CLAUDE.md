# CLAUDE.md

Instructions for Claude Code when working in this repository.

## Key files

| File | Purpose |
|------|---------|
| `specs/SPEC.md` | Project context — why, architecture, tech stack, decisions. Read first. Read-only during spec authoring. |
| `specs/QUEUE.md` | Work queue — one spec in progress at a time. |
| `specs/HISTORY.md` | Changelog — what changed across specs and when. Append at bottom. |
| `specs/UNRESOLVED.md` | Open questions — unresolved issues across all specs. |
| `.claude/commands/po-spec-writer.md` | Skill — write and update specs. Opens a PR with spec only; implementation follows after merge. |
| `.claude/commands/dev-spec.md` | Skill — implement the current in-progress spec, close tracking files, commit to main. |
| `.claude/commands/sync-spec.md` | Skill — run after implementation: patches `specs/SPEC.md` with decisions from the completed spec. |
| `.github/workflows/spec-from-issue.yml` | GHA — fires on issue open; creates branch + draft prompt + draft PR. No API key needed. |

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
