# DRAFT -- Issue #46
# Run `/po-spec-writer` on this branch to generate the full spec.

Issue:    #46
Task:     RIVER-46
Title:    Set up SonarQube and tests CI run for Flutter code
Why:
Set up SonarQube static analysis and automated test execution for the Flutter codebase as part of CI.

Acceptance criteria:
- SonarQube analysis runs on every PR and push to main
- Flutter unit and widget tests run in CI
- Failures block merges
Priority: should
Category: tools
