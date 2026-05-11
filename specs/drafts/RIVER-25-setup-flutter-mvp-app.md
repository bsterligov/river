# DRAFT -- Issue #25
# Run `/po-spec-writer` on this branch to generate the full spec.

Issue:    #25
Task:     RIVER-25
Title:    Setup flutter MVP app
Why:
Set up the Flutter application as a macOS-only desktop app with a minimal but structured foundation.

**UI layout**
- Left navigation panel (sidebar) for switching between pages
- Log page with a search bar and a logs table

**Project structure**
- Theme system (light/dark or design tokens) configured from the start
- Code-generated API client from the query-api OpenAPI spec

**Platform**
- macOS only; do not configure iOS/Android/web targets

**Acceptance criteria**
- `flutter build macos` succeeds
- Log page renders with search bar and an empty/stub logs table
- API client is generated and importable
- Theme is applied app-wide
Priority: must
Category: features
