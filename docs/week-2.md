# Week 2 — In progress: from linear tasks to plan-driven multi-agent mode

Week 1 validated that the V0 spec-first loop works well for single, well-scoped tasks. The bottleneck that emerged: ambitious features with 3–6 moving parts still required the developer to manually decompose the work, create one issue at a time, and run each spec session sequentially. The workflow was sound but not scalable to larger initiatives.

Week 2 focus: lift the workflow one level up. Instead of driving individual tasks, the developer now drives a plan — and agents do the decomposition, issue creation, and spec writing in parallel.

**What changed:**

Three new commands were added above the existing V0 loops:

- `/feature-plan` — interactive session that produces a phase-by-phase plan in `specs/plans/`. Claude asks for the why, scope boundaries, and constraints, then decomposes the feature into independently shippable phases with goals, steps, dependencies, done criteria, risks, and open questions.

- `/dev-plan {name}` — reads a saved plan and spawns one parallel subagent per phase. Each subagent runs in an isolated git work tree, creates the GitHub issue, waits for the GHA spec branch, and runs `/po-spec-writer`. The result: all spec PRs for a feature open simultaneously rather than one at a time.

- `/dev-plan-impl {name}` — closes the loop after spec review. Finds all open spec PRs for the plan, gates on approval status, merges them in phase order (rebasing and resolving conflicts automatically), then spawns one parallel subagent per phase to run `/dev-spec`. All impl PRs for a feature land simultaneously.

**Routing guidance** was also added to `CLAUDE.md` so Claude proactively suggests the right command based on task size — `/issue-create` for small self-contained tasks, `/feature-plan` for anything that spans multiple components or requires design decisions first.

**Open questions being studied in week 2:**

- Token cost of parallel agentic sessions vs. sequential: does parallelism increase total spend or shift it?
- Quality of subagent-written specs vs. interactive specs: does removing the human from the loop in spec writing degrade the output?
- Merge conflict rate in tracking files (`QUEUE.md`, `HISTORY.md`) when multiple spec branches land close together.
