# RIVER-67: Fix Sonar Duplication and Trace Page

Priority: Must
Test Approach: BDD
Why: Sonar reports high code duplication blocking quality gates, and the Traces page fails to display data for users.
<!-- STOP -->

## Problem

Sonar's duplication metric is above the acceptable threshold, likely due to repeated widget or logic patterns in the Flutter UI that were not extracted during fast-paced feature delivery. Separately, the Traces page does not render trace data — the root cause is unknown but the symptom is a blank or broken page when navigating to Traces.

## Goal

Sonar duplication drops to an acceptable level (below the project threshold). A user who navigates to the Traces page sees a list of traces populated from the API.

## Scope

**In**
- Identify and extract duplicated Flutter code raising the Sonar duplication metric
- Fix the Traces page so it loads and displays trace rows correctly
- Verify Sonar duplication passes after changes

**Out**
- Sonar issues unrelated to duplication (coverage, code smells, security hotspots)
- Trace waterfall / detail panel (tracked separately in RIVER-59)

## Decisions

- Refactor scope is limited to reducing duplication — no broader restructuring unless duplication fix requires it

## Scenarios

**Given** I open River Dashboard and navigate to the Traces page
**When** the page finishes loading
**Then** I see a table of traces with Trace ID, Root Service, Root Operation, Duration, Spans, and Start Time

**Given** the Sonar analysis runs on the Flutter codebase after changes
**When** duplication is measured
**Then** the duplication percentage is below the project threshold
