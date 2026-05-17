# RIVER-52: Logo and Window Title

Priority: Should
Test Approach: BDD
Why: The app has no visual identity and the window title is a generic placeholder, making it look unfinished to anyone who opens it.
<!-- STOP -->

## Problem

The app window title reads "UI" — the default Flutter project name — and there is no logo anywhere in the application. First impressions matter for an open-source tool; the current state signals an unfinished project to evaluators and contributors.

## Goal

A user who opens River sees a recognizable logo in the top bar and a window title that reads "River Dashboard".

**Scenarios**

Given the app is running,
When the user looks at the top bar,
Then they see the River logo displayed to the left of the "River" label.

Given the app is running,
When the user checks the OS window title or taskbar,
Then it reads "River Dashboard".

## Scope

**In**
- Generate or design a River logo (SVG or PNG asset)
- Add the logo to Flutter asset pipeline
- Display the logo in `TopPanel` (left side, next to the "River" label)
- Set the macOS window title to "River Dashboard" via Flutter window title API

**Out**
- Animated logo or splash screen
- Favicon or web target branding
- Icon in macOS Dock / app bundle icon

## Decisions

- Logo asset format: SVG preferred for crispness at all DPI; fall back to PNG if SVG rendering is problematic on macOS desktop
- Window title set via `setWindowTitle` from the `window_manager` package if already a dependency, otherwise via `flutter_window_title` or native macOS entitlement — confirm which package is already in use before adding a new one
