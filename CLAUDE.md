# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**river** is an OpenTelemetry platform (early-stage — no build system or source files yet as of initial commit).

## Dev Environment

Runtime versions are managed by [mise](https://mise.jdx.dev/) and pinned in `.mise.toml`:

| Tool    | Version        |
|---------|----------------|
| Rust    | 1.95.0         |
| Flutter | 3.41.0         |

Run `mise install` once to provision the environment.

## Running Commands

**Always prefix commands with `mise exec --`** so the correct toolchain versions are used regardless of what is globally installed.

```bash
# Rust
mise exec -- cargo build
mise exec -- cargo test
mise exec -- cargo clippy

# Flutter
mise exec -- flutter build
mise exec -- flutter test
```

Never call `cargo`, `flutter`, or `dart` directly — always go through `mise exec --`.
