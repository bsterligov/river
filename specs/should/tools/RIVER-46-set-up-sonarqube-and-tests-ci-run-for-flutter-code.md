# RIVER-46: Set up SonarQube and Tests CI Run for Flutter Code

Priority: Should
Test Approach: BDD
Why: Flutter code has no static analysis or automated test execution in CI, so regressions and quality issues go undetected until code review.
<!-- STOP -->

## Problem

The Flutter UI codebase (`src/ui/`) has no CI gates. Tests exist locally but never run automatically, and there is no static analysis step to catch quality issues before review. Developers rely on manual discipline to run `flutter test` and `flutter analyze` before pushing, which is error-prone.

## Goal

Every PR and push to main triggers a CI job that runs Flutter unit and widget tests and a SonarQube analysis pass. Failures block the merge. A developer opening a PR can see test results and SonarQube findings without leaving GitHub.

**Scenarios**

*Given* a PR is opened against main,
*When* CI runs,
*Then* Flutter tests execute and report pass/fail on the PR status checks.

*Given* a PR is opened against main,
*When* CI runs,
*Then* SonarQube analysis completes and posts findings; a quality gate failure blocks the merge.

*Given* a push lands on main,
*When* CI runs,
*Then* both Flutter tests and SonarQube analysis run and their results are recorded.

## Scope

**In**
- GitHub Actions workflow that runs `flutter test` for `src/ui/`
- SonarQube analysis step integrated into the same (or a parallel) workflow
- Branch protection rule: both checks must pass before merge
- Test coverage report forwarded to SonarQube

**Out**
- SonarQube server provisioning (assumed already running or using SonarCloud)
- Dart/Flutter static analysis beyond what SonarQube covers (`flutter analyze` is out of scope for this ticket — a separate linting step can be added later)
- Android, iOS, or web build steps
- Performance or golden-file tests

## Decisions

- Use the existing GitHub Actions infrastructure; no new CI platform.
- SonarQube project key: `river-ui` (matches the Flutter package name pattern).
- Coverage is generated via `flutter test --coverage` and uploaded as `lcov.info`.
