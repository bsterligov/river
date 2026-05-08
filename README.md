# river

> Experimental. Open-source observability platform — infinitely scalable, deployable anywhere.

For architecture, tech stack, and project decisions see [specs/SPEC.md](specs/SPEC.md).

---

## Spec-Driven Development (SDD)

River uses SDD natively — no external project management tools, no ticket trackers, no extra frameworks. Specs, skills, and context files live in the repo and are read directly by Claude. The entire workflow runs inside Claude Code.

**The key idea: we review specs, not code.** A spec PR is reviewed before any implementation starts. Once merged, code goes straight to main — no code review.

Work is linear — one spec at a time. Status lives in `specs/QUEUE.md`, not in filenames.

### Workflow

```
GitHub Issue → draft PR → checkout → /po-spec-writer → review & merge → /dev-spec → /sync-spec
```

### 1. Create a GitHub issue

Open an issue with:
- **Title** — short noun phrase
- **Body** — one sentence: the problem or goal (becomes the *Why*)

On issue open, the `spec-from-issue` workflow automatically:
- Creates branch `spec/RIVER-{number}`
- Adds a draft prompt to `specs/drafts/RIVER-{number}-title.md`
- Opens a **draft PR**

No API key or labels needed.

### 2. Write the spec locally

Checkout the branch and open Claude Code:

```bash
git checkout spec/RIVER-{number}
# then run in Claude Code:
/po-spec-writer
```

Claude reads the draft (task, title, why pre-filled from the issue) and only asks for priority, category, and test approach. It writes the real spec to `specs/{priority}/{category}/`, updates `QUEUE.md`, and deletes the draft file.

Push and mark the PR as ready for review.

### 3. Review

The PR is the spec contract — check before merging:
1. **Why line** — states the problem, not the solution. One sentence above `<!-- STOP -->`.
2. **Scope In** — every item is independently testable. Split if not.
3. **Scope Out** — explicitly lists what is deferred.

### 4. Implement

Once merged, run:

```
/dev-spec
```

Reads the spec, implements **Scope In**, commits to main, updates `QUEUE.md` and `HISTORY.md`. No code review.

### 5. Sync SPEC.md

```
/sync-spec
```

Patches `specs/SPEC.md` with architectural decisions from the completed spec. Read-only at all other times.

### Manual spec (no issue)

```
/po-spec-writer
```

Same as above but without the GHA step. Create a GitHub issue first — Claude will ask for the issue number and derive the task ID (`RIVER-{number}`) from it.

### Spec path

`specs/{priority}/{category}/RIVER-N-title.md`

| Priority | When |
|----------|------|
| `must` | Required for this iteration |
| `should` | Important but not blocking |
| `could` | Nice to have if time allows |
| `wont` | Explicitly out of scope |

| Category | Use for |
|----------|---------|
| `bugs` | Defects and regressions |
| `docs` | Documentation, guides, reference material |
| `features` | New user-facing or operator-facing capabilities |
| `refactoring` | Internal restructuring with no behavior change |
| `tools` | Dev tooling, CI, scripts, skills |

---

## License

See [LICENSE](LICENSE).
