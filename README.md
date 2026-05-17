# Hybrid AI-Augmented Development — Experiment

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=bsterligov_river&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=bsterligov_river)
[![Release](https://github.com/bsterligov/river/actions/workflows/release.yml/badge.svg)](https://github.com/bsterligov/river/actions/workflows/release.yml)

## ⚠️ Usage notice ⚠️

This experiment uses Claude Code interactively under an individual Claude Pro subscription.

The purpose of the experiment is to explore and validate a structured, cost-effective AI-assisted development workflow. Claude Code Pro is used here as a practical execution environment during the research phase, with the expectation that similar workflows could later be migrated to API-based infrastructure and standard token billing if needed.

A key dimension being studied is the tradeoff between autonomy and cost efficiency. More autonomous execution loops reduce the amount of human intervention required per development cycle, improving throughput and consistency, but typically increase token usage due to longer agentic sessions, higher context retention, and iterative reasoning overhead.

Any use of Claude Code should comply with Anthropic’s Terms of Service, subscription limits, acceptable use policies, and any applicable Claude Code usage guidelines. This repository does not endorse account sharing, unattended autonomous operation, rate-limit evasion, or using Pro subscriptions as a replacement for enterprise/API infrastructure outside the intended terms of use.

---

## Introduction

This repo is a working experiment in a hybrid approach to AI-assisted software development.

Two common extremes exist today:

- Fully agentic: an autonomous agent manages the software workflow end-to-end with minimal human intervention. Promising in theory, but truly robust long-term production examples remain limited.

- Ad hoc AI-augmented: AI is used opportunistically to solve immediate tasks without a broader workflow structure. Fast to adopt, but often difficult to scale and sustain.

The hypothesis behind this project is that a structured middle ground can progressively move toward high autonomy while preserving stable quality, architectural continuity between iterations, and sustainable token economics. Humans remain responsible for key review and decision gates, while AI performs most of the execution within those constraints under direct developer supervision.

Existing tools like OpenSpec, SpecKit, and similar spec-authoring frameworks were considered. The deliberate choice here is to use Claude-native instruments like slash commands, memory, hooks, rather than external tooling. The goal is to understand what a fully Claude-native development workflow looks like, not to evaluate third-party spec tools. Of the available Claude Code integrations, only the [GitHub integration](https://github.github.com/gh-aw/) is used, as it provides the coordination base for the agentic workflow loops.

---

## How it works

Three workflow versions exist, each building on the previous. Full details: [V0 — Single task](docs/v0.md) · [V1 — Ambitious features](docs/v1.md) · [V1.1 — Workflow refinements](docs/v1.1.md)

### V0 — Single task

`/create-issue` → GHA creates `spec/RIVER-N` branch → `/spec` writes spec → spec PR reviewed and merged → GHA creates `impl/RIVER-N` branch → `/spec-dev` implements → impl PR merged.

The spec PR is the only review gate. Implementation runs without further review — the spec already covered it.

### V1 — Ambitious features

V1 adds three commands above the V0 loops. `/create-feature` decomposes the feature into phases and assigns each one an execution mode — `parallel` (no dependencies, can run alongside others) or `sequential` (must wait for dependencies to land). `/plan-spec` and `/plan-dev` respect that order: independent phases spawn simultaneously, dependent phases wait for their wave to complete before starting.

Full command reference: [docs/v1.md](docs/v1.md)

### V1.1 — Workflow refinements

V1.1 tightens quality gates and reduces CI noise without adding new commands.

**What changed and why:**

| Change | What | Why |
|--------|------|-----|
| SonarQube out of CI | Sonar is now a `spec-dev` step: the agent runs it after the code is stable, before marking the PR ready. CI (lint + tests) still fires on `ready_for_review` as an independent check. | CI ran Sonar on every `ready_for_review` push. The agent never saw the result until after the commit — fixing issues meant another push and another CI queue wait. Running it in-session gives immediate feedback. |
| One impl PR at a time | `spec-dev` checks for open `impl/*` PRs before opening a new one and exits with an error if any exist. | Was documented convention, not enforced. Opening a second impl PR while the first was in review created merge conflicts in tracking files (`QUEUE.md`, `HISTORY.md`) and confused the review queue. |
| Mise tasks reorganized | Tasks moved from nested dirs (`cargo/`, `flutter/`, `sonar/`, etc.) to two flat buckets: `ci/` for stateless validation, `agent/` for agentic and developer workflow tasks. | The old structure mixed tasks with different lifecycles in the same namespace. `flutter:run` (local dev) sat next to `flutter:coverage` (CI). The new split makes the intent of each task immediately clear and lets CI jobs reference `ci:*` exclusively. |

Full details: [docs/v1.1.md](docs/v1.1.md)

---

## Results

| Week | Status | Summary |
|------|--------|---------|
| [Week 2](docs/week-2.md) | In progress | Plan-driven multi-agent mode — parallel spec and impl across phases |
| [Week 1](docs/week-1.md) | Done | MVP — end-to-end observability pipeline, $126.63 API-equivalent |

---

## Why Claude Code Pro instead of API

Cost and stability. Claude Code Pro is a flat subscription with no per-token billing. For an experiment that runs many spec + impl cycles, this matters. The tradeoff is that it only runs interactively (not as a fully autonomous background agent) — which is actually fine for this hybrid model, since human checkpoints are the point.

---

## Spec structure

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
| `docs` | Documentation, guides |
| `features` | New capabilities |
| `refactoring` | Internal restructuring, no behavior change |
| `tools` | Dev tooling, CI, scripts |

---

## Token optimization

[RTK](https://github.com/rtk-ai/rtk) compresses Bash tool output before it reaches Claude's context window. `river-index` intercepts `Read` calls on source files and returns compact symbol summaries (~60 tokens instead of ~1500). Full details: [docs/token-optimization.md](docs/token-optimization.md)

---

## The project itself

River is an OpenTelemetry-based observability platform — infinitely scalable, deployable anywhere. It exists here primarily as the subject of the experiment, not the goal. For architecture and tech stack see [specs/SPEC.md](specs/SPEC.md).

---

## License

See [LICENSE](LICENSE).
