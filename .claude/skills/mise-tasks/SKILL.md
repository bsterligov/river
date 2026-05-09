---
name: mise-tasks
description: Enforces the rule that all shell logic must live in mise tasks, not inline in scripts or CI workflows.
user-invocable: false
---

When writing any shell logic in this repository:

1. **Create a mise task first.** Shell logic belongs in `.mise/tasks/`, not inline in a GHA workflow or ad-hoc script.
2. **Call the task from CI.** GHA workflows call `mise run <task>`, not raw shell commands.
3. **If a task already exists, use it.** Check `.mise/tasks/` before writing new shell.

This applies to: GitHub Actions `run:` steps, one-off scripts, and any new automation.
