# RIVER-6: Setup DevOps Part 2
Status: In Progress
Priority: Must
Test Approach: BDD
Why: The project has no automated release process — creating a git tag and GitHub release must be done manually, which is inconsistent and error-prone.
<!-- STOP -->

## Problem

After RIVER-4, merges to `main` are gated by CI. However, publishing a release still requires a developer to manually create a git tag and GitHub release. There is no canonical trigger, no consistent asset list, and no audit trail of who cut which release.

## Goal

Given a developer pushes a version tag (e.g. `v1.2.3`) to the repository, when the release workflow runs, then:
- A GitHub release is created for that tag
- The release is marked as the latest release
- The workflow fails loudly if the tag format is invalid or the release already exists

## Scope

**In**
- GitHub Actions workflow triggered on `push` of tags matching `v*.*.*`
- GitHub release creation using an official action (`softprops/action-gh-release` or `actions/create-release`)
- Workflow fails if tag does not match semver pattern

**Out**
- Binary artifact builds or asset uploads (no compiled binaries yet)
- Changelog generation or release notes automation
- Pre-release or draft release support
- Branch protection rules (manual step, outside code)

## Decisions

- Workflow triggers only on tag push, not on branch push or PR
- Release title matches the tag name
- No assets attached until binary builds exist in CI
