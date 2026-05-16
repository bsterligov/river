# Week 2 — In progress: from linear tasks to plan-driven multi-agent mode

From 14 May

Week 1 validated that the V0 spec-first loop works well for single, well-scoped tasks. The bottleneck that emerged: ambitious features with 3–6 moving parts still required the developer to manually decompose the work, create one issue at a time, and run each spec session sequentially. The workflow was sound but not scalable to larger initiatives.

Week 2 focus: lift the workflow one level up. Instead of driving individual tasks, the developer now drives a plan — and agents do the decomposition, issue creation, and spec writing in parallel.

**What changed:**

Three new commands were added above the existing V0 loops:

- `/create-feature` — interactive session that produces a phase-by-phase plan in `specs/plans/`. Claude asks for the why, scope boundaries, and constraints, then decomposes the feature into independently shippable phases with goals, steps, dependencies, done criteria, risks, and open questions.

- `/plan-spec {name}` — reads a saved plan and spawns one parallel subagent per phase. Each subagent runs in an isolated git work tree, creates the GitHub issue, waits for the GHA spec branch, and runs `/spec`. The result: all spec PRs for a feature open simultaneously rather than one at a time.

- `/plan-dev {name}` — closes the loop after spec review. Finds all open spec PRs for the plan, gates on approval status, merges them in phase order (rebasing and resolving conflicts automatically), then spawns one parallel subagent per phase to run `/spec-dev`. All impl PRs for a feature land simultaneously.

**Routing guidance** was also added to `CLAUDE.md` so Claude proactively suggests the right command based on task size — `/create-issue` for small self-contained tasks, `/create-feature` for anything that spans multiple components or requires design decisions first.

**API-equivalent cost so far** (Sonnet 4.6 pricing — $3/1M input, $3.75/1M cache write, $0.30/1M cache read, $15/1M output):

| Token type | Volume | Cost | Share |
|------------|--------|-----:|------:|
| Cache reads | 228.7M | $68.61 | 65% |
| Output | 1.3M | $19.25 | 18% |
| Cache writes | 4.7M | $17.81 | 17% |
| Input | 4K | $0.01 | <1% |
| **Total** | | **$105.69** | |

30 commits, 3,003 assistant turns. RTK compressed 73K additional tokens (~$0.22 avoided).

Full token breakdown: [docs/token-usage.md](token-usage.md)

For comparison, week 1 ran to **$126.63** across 35 commits and 3,309 turns. Week 2 is on track to exceed week 1 spend as more implementation work lands — the Flutter UI build is driving the bulk of context load.

**By phase:**

| Phase | Cost | Share |
|-------|-----:|------:|
| Implementation | $98.02 | 93% |
| Setup / tooling | $6.31 | 6% |
| Spec writing | $1.36 | 1% |

Spec writing remains nearly free — parallel `/plan-spec` subagents write specs with minimal context ($0.11–$0.13 each). Implementation now dominates at 93% as the full Flutter UI layer was built out.

**Most expensive session**: `impl: RIVER-31 -- UI: Log Distribution Histogram` at **$12.93** — 323 turns, building the histogram widget from scratch.

**Cheapest sessions**: parallel spec writes at **$0.11–$0.13** each.

**By MoSCoW priority:**

| Priority | Cost | Share |
|----------|-----:|------:|
| must | $78.45 | 74% |
| should | $27.24 | 26% |
| could | — | — |
| wont | — | — |

**By category:**

| Category | Cost | Share |
|----------|-----:|------:|
| features | $57.97 | 55% |
| tools | $36.08 | 34% |
| refactoring | $11.64 | 11% |

Features now dominate as the Flutter UI build ramps up. The `should` priority share (26%) reflects the UI layer being classified as non-critical infrastructure — logs table, histogram, facet panel, log detail.

**Open questions being studied in week 2:**

- Token cost of parallel agentic sessions vs. sequential: does parallelism increase total spend or shift it?
- Quality of subagent-written specs vs. interactive specs: does removing the human from the loop in spec writing degrade the output?
- Merge conflict rate in tracking files (`QUEUE.md`, `HISTORY.md`) when multiple spec branches land close together.
