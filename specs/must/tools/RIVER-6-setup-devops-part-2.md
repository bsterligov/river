# RIVER-6: Setup DevOps Part 2

Priority: Must
Test Approach: BDD
Why: The project has no automated release process — creating a git tag and GitHub release must be done manually, which is inconsistent and error-prone.
<!-- STOP -->

## Problem

After RIVER-4, merges to `main` are gated by CI. However, publishing a release still requires a developer to manually create a git tag and GitHub release. There is no canonical trigger, no consistent asset list, and no audit trail of who cut which release.

## Goal

Given a commit using the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) format lands on `main` and CI passes, when the release job runs, then:
- A new semver tag is created automatically (`fix:` → patch, `feat:` → minor, `BREAKING CHANGE:` → major)
- A GitHub release is created for that tag and marked as latest
- No tag or release is created if no releasable commits are present

## Scope

**In**
- Release job added to the existing `ci.yml`, running after `sonarqube` passes
- Job runs only on `push` to `main` (not on PRs)
- `mise :tag` task: `cog bump --auto` creates the local semver tag and writes `RELEASE_TAG` to `.release-env`
- `mise release:publish` task: sources `.release-env`, pushes the tag, creates the GitHub release via `gh release create`
- Job is skipped silently when no releasable commits exist

**Out**
- Binary artifact builds or asset uploads (no compiled binaries yet)
- Changelog generation or release notes automation
- Pre-release or draft release support
- Branch protection rules (manual step, outside code)

## Decisions

- Trigger is `push` to `main`, not a manual tag push — tags are created by the workflow
- `cocogitto` (`cog`) installed via mise handles Conventional Commits versioning
- `fix:` → patch, `feat:` → minor, breaking change indicator (`!` or `BREAKING CHANGE`) → major
- No releasable commits → task exits 0, no tag or release created
- Release title matches the generated tag name; no assets attached until binary builds exist
- `fetch-depth: 0` required so `git describe` and `git log` can walk full history
