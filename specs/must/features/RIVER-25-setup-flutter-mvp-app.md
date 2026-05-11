# RIVER-25: Setup Flutter MVP App
Status: In Progress
Priority: Must
Test Approach: BDD
Why: River has no UI — operators have no production-ready way to view observability data, and Grafana is explicitly dev-only.
<!-- STOP -->

## Problem

River's signal pipeline is complete but there is no UI. Operators who want to view logs must use Grafana (dev-only, no RBAC) or query the API directly. There is no path to a user-facing dashboard without first establishing the Flutter project foundation.

## Goal

An operator can launch the macOS desktop app, navigate via a left sidebar, open the Logs page, type into a search bar, and see a logs table — even if the table is empty or stubbed. The app connects (or is ready to connect) to the query-api via a generated client, and the visual style is controlled by a theme so future pages stay consistent.

**Scenarios**

*Given* the app is running on macOS,
*When* I open it,
*Then* I see a left navigation panel and a default page.

*Given* I am on the Logs page,
*When* the page loads,
*Then* I see a search bar and a logs table (empty or stubbed data is acceptable).

*Given* the project is built,
*When* I run `flutter build macos`,
*Then* the build succeeds with no errors.

## Scope

**In**
- macOS-only Flutter project (remove or never add iOS/Android/web targets)
- Left navigation sidebar for switching between pages
- Logs page: search bar + logs table (stub data acceptable)
- Theme configuration applied app-wide (light theme minimum)
- Generated Dart API client from `river-query-api`'s `/openapi.json`

**Out**
- Live data from ClickHouse (wired API calls)
- Authentication or user management
- Web or mobile build targets
- Dark theme (can be added later)
- Metrics or traces pages

## Decisions

- Generate the Dart client with `openapi-generator` (or equivalent) targeting the `river-query-api` OpenAPI spec; commit the generated files.
- Theme tokens live in a dedicated `theme/` directory under `lib/` so they are easy to extend.
- Navigation sidebar uses a `NavigationRail` or equivalent Flutter widget; no third-party nav library at this stage.
