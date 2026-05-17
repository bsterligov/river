# RIVER-4: Setup DevOps

Priority: Must
Test Approach: BDD
Why: Merges to main have no automated quality gate — broken formatting, lint errors, and test failures can land undetected.
<!-- STOP -->

## Problem

The repository has no CI. A developer can merge code that fails `cargo fmt`, `cargo clippy`, or `cargo test` without anyone noticing until the next person pulls. SonarQube analysis has never run, so there is no baseline for code quality or security issues.

## Goal

Given a push or pull request to `main`, when GitHub Actions runs, then:
- `cargo fmt --check` passes (no unformatted code)
- `cargo clippy -- -D warnings` passes (no lint warnings)
- `cargo test` passes (no failing tests)
- SonarQube analysis completes and the quality gate passes

A failing quality gate blocks the merge.

## Scope

**In**
- GitHub Actions workflow on `push` and `pull_request` to `main`
- `mise` tasks for fmt check, clippy, and test (used by all CI steps)
- Official GitHub Actions only (`actions/checkout`, `dtolnay/rust-toolchain` or equivalent)
- Official SonarQube action (`SonarSource/sonarqube-scan-action`)
- SonarQube quality gate check as a blocking step

**Out**
- Docker image builds in CI
- Deployment pipelines
- Coverage upload to services other than SonarQube
- Branch protection rule configuration (manual step, outside code)

## Decisions

- All Rust steps use `mise exec --` to match local toolchain (per project convention)
- SonarQube project key derived from repository name
- Workflow fails fast: fmt and clippy run before tests to surface cheap errors first
