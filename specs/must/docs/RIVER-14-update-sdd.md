# RIVER-14: Update SDD
Status: Done
Priority: Must
Test Approach: BDD
Why: The current SDD process pushes implementation directly to main and has a confusing queue lifecycle, which creates merge risk and slows the team down.
<!-- STOP -->

## Problem

Spec authoring already uses a branch+PR flow, but implementation (`/spec-dev`) pushes straight to main. This risks conflicts and bypasses review. The queue states (`In Progress`, `Pending`) are unclear, and completed tasks disappear from the queue — making it hard to see what has been done or what is next.

## Goal

A developer can take a spec from creation to done entirely through PRs, without ever committing implementation work directly to main. The queue is a simple, persistent list where done tasks stay visible.

**Scenario: creating a spec**
- Given a developer opens a GitHub issue
- When the GHA fires and they run `/spec`
- Then a feature branch and draft PR are created; the spec is authored there, not on main

**Scenario: moving to implementation**
- Given a spec PR is merged to main
- When GHA fires on the merge event
- Then a new feature branch and draft implementation PR are automatically created

**Scenario: completing implementation**
- Given the implementation PR is merged
- When the developer closes the tracking files
- Then the task is marked done in `QUEUE.md` (strikethrough or `[done]` marker) and a history entry is appended — the task is never deleted from the queue

**Scenario: reading the queue**
- Given multiple specs exist in various states
- When a developer opens `QUEUE.md`
- Then they see one section listing queued tasks and done tasks are visually distinct, with no ambiguous intermediate states

## Scope

**In**
- Update `QUEUE.md` format: remove `In Progress` / `Pending` sections; replace with a single queue list where done items are marked with `~~strikethrough~~`
- Update `/spec` skill: add task to queue (not to `Pending`); do not move between sections during authoring
- Update `/spec-dev` skill: implementation must happen on a feature branch + PR, not a direct push to main; mark task done in queue on completion
- Update GHA `spec-from-issue.yml`: on spec PR merge to main, auto-create an implementation branch and draft PR
- Update `SPEC.md` workflow line to reflect the new branch-based flow
- Update `CLAUDE.md` key files table if any skill file descriptions change

**Out**
- Conflict resolution strategy for parallel in-flight specs (tracked in UNRESOLVED.md)
- Changes to the spec file format or storage paths
- Any UI or API component changes

## Decisions

- Queue has one flat list; done tasks stay in the list, marked with strikethrough
- GHA triggers on PR merge (not issue close) to create the implementation branch
- Implementation PRs target main, same as spec PRs
