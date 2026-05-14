# feature-plan

Interactive skill to plan an ambitious feature. Produces a structured, phase-by-phase implementation plan saved to `specs/plans/`.

Read `specs/SPEC.md` before doing anything — use it to validate technical choices against the existing architecture.

## Step 1 — Gather inputs

Ask the user for the following if not already provided:

1. **Feature name** — short noun phrase (e.g. "alerting system", "multi-tenant auth")
2. **Why** — the real problem or goal; what breaks or becomes possible without/with it
3. **Scope boundaries** — what is explicitly in scope and what is out; keep the user honest here (ambitious does not mean unbounded)
4. **Constraints** — time, compatibility, team size, or architectural constraints to respect

## Step 2 — Decompose into phases

Break the feature into sequential phases. A phase is a coherent chunk of work that can be reviewed and merged independently. Rules:

- Each phase must be deliverable on its own (no half-finished states merged)
- Later phases must not require rewriting earlier ones
- Aim for 3–6 phases; fewer for simple features, more only if genuinely needed

For each phase, define:
- **Name** — short label
- **Goal** — what is true after this phase ships that was not true before
- **Steps** — ordered list of concrete implementation tasks (code to write, schemas to change, configs to add); be specific enough that a developer can start immediately
- **Dependencies** — other phases or external things that must be complete first
- **Done criteria** — observable, testable signal that this phase is complete (tests pass, endpoint returns X, UI shows Y)

## Step 3 — Identify risks and open questions

List risks (things that could derail the plan) and open questions (things that need a decision before or during implementation). Be specific — "it might be hard" is not a risk.

For each risk: name it, state the impact, suggest a mitigation.

For each open question: state it clearly, note who or what resolves it.

## Step 4 — Write the plan file

Create the directory if it does not exist:
```bash
mkdir -p specs/plans
```

Save the plan to `specs/plans/{kebab-case-feature-name}.md` using this exact format:

```markdown
# Plan: {Feature Name}
Date: {YYYY-MM-DD}
Why: {One sentence — the problem or goal this solves.}

## Phases

### Phase 1 — {Name}
**Goal:** {What is true after this phase ships.}

**Steps:**
1. …
2. …

**Dependencies:** {None | list}
**Done when:** {Observable, testable signal.}

### Phase 2 — {Name}
…

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| … | … | … |

## Open Questions

- [ ] {Question} — {who/what resolves it}
```

## Step 5 — Confirm and next action

Print the file path of the saved plan and tell the user:
- Which phase to start with and what the first concrete step is
- Whether a GitHub issue or spec is needed before implementation begins (use `/issue-create` or `/po-spec-writer` if so)
- Any open question that must be resolved before Phase 1 can start
