# Week 2 — In progress: from linear tasks to plan-driven multi-agent mode

From 14 May

Week 1 validated that the V0 spec-first loop works well for single, well-scoped tasks. The bottleneck that emerged: ambitious features with 3–6 moving parts still required the developer to manually decompose the work, create one issue at a time, and run each spec session sequentially. The workflow was sound but not scalable to larger initiatives.

Week 2 focus: lift the workflow one level up. Instead of driving individual tasks, the developer now drives a plan — and agents do the decomposition, issue creation, and spec writing in parallel.

**What changed:**

Three new commands were added above the existing V0 loops:

- `/feature-plan` — interactive session that produces a phase-by-phase plan in `specs/plans/`. Claude asks for the why, scope boundaries, and constraints, then decomposes the feature into independently shippable phases with goals, steps, dependencies, done criteria, risks, and open questions.

- `/dev-plan {name}` — reads a saved plan and spawns one parallel subagent per phase. Each subagent runs in an isolated git work tree, creates the GitHub issue, waits for the GHA spec branch, and runs `/po-spec-writer`. The result: all spec PRs for a feature open simultaneously rather than one at a time.

- `/dev-plan-impl {name}` — closes the loop after spec review. Finds all open spec PRs for the plan, gates on approval status, merges them in phase order (rebasing and resolving conflicts automatically), then spawns one parallel subagent per phase to run `/dev-spec`. All impl PRs for a feature land simultaneously.

**Routing guidance** was also added to `CLAUDE.md` so Claude proactively suggests the right command based on task size — `/issue-create` for small self-contained tasks, `/feature-plan` for anything that spans multiple components or requires design decisions first.

**API-equivalent cost so far** (Sonnet 4.6 pricing — $3/1M input, $3.75/1M cache write, $0.30/1M cache read, $15/1M output):

| Token type | Volume | Cost | Share |
|------------|--------|-----:|------:|
| Cache reads | 93.6M | $28.09 | 58% |
| Output | 0.7M | $11.16 | 23% |
| Cache writes | 2.5M | $9.44 | 19% |
| Input | 2K | $0.01 | <1% |
| **Total** | | **$48.72** | |

17 commits, 1,384 assistant turns. RTK compressed 44K additional tokens (~$0.13 avoided).

Full token breakdown: [docs/token-usage.md](token-usage.md)

For comparison, week 1 ran to **$126.63** across 35 commits and 3,309 turns. The lower turn count in week 2 so far reflects the plan-driven parallel approach — fewer sequential context-heavy debug loops.

**By phase:**

| Phase | Cost | Share |
|-------|-----:|------:|
| Implementation | $35.12 | 72% |
| Setup / tooling | $12.24 | 25% |
| Spec writing | $1.36 | 3% |

Spec writing is nearly free in week 2 — the parallel `/dev-plan` subagents each write specs with minimal context, keeping individual session costs at $0.11–$0.36. Implementation dominates because it carries the full context of the codebase.

**Most expensive session**: `feat: add sqlite based index` at **$12.10** — 314 turns, building `river-index` from scratch.

**Cheapest sessions**: parallel spec writes at **$0.11–$0.36** each.

**By MoSCoW priority:**

| Priority | Cost | Share |
|----------|-----:|------:|
| must | $48.72 | 100% |
| should | — | — |
| could | — | — |
| wont | — | — |

**By category:**

| Category | Cost | Share |
|----------|-----:|------:|
| features | $24.38 | 50% |
| tools | $24.34 | 50% |

Features and tooling are evenly split — the `river-index` build ($12.10) accounts for most of the tooling cost and is a one-time investment.

**Open questions being studied in week 2:**

- Token cost of parallel agentic sessions vs. sequential: does parallelism increase total spend or shift it?
- Quality of subagent-written specs vs. interactive specs: does removing the human from the loop in spec writing degrade the output?
- Merge conflict rate in tracking files (`QUEUE.md`, `HISTORY.md`) when multiple spec branches land close together.
