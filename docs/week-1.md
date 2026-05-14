# Week 1 — MVP done

6 days, 29 committed sessions, 2,762 assistant turns.

Built a working end-to-end observability pipeline with no custom frontend — Grafana as the UI layer. Components shipped: OTel sidecar, ingestion service, S3 batch storage, metrics aggregation, database migration management, query API, Grafana dashboards, and a full CI/CD setup. Test coverage above 80% (SonarQube gate).

Full token breakdown: [docs/token-usage.md](token-usage.md)

**API-equivalent cost** (Sonnet 4.6 pricing — $3/1M input, $3.75/1M cache write, $0.30/1M cache read, $15/1M output):

| Token type | Volume | Cost | Share |
|------------|--------|-----:|------:|
| Cache reads | 190M | $57.06 | 49% |
| Output | 2.4M | $36.32 | 31% |
| Cache writes | 6.4M | $23.86 | 20% |
| Input | 16K | $0.05 | <1% |
| **Total** | | **$117.29** | |

[RTK](https://github.com/rtk-ai/rtk) was used to compress Bash tool output — 210K additional input tokens avoided (~$0.63). Since week 1, a second layer (`river-index`) was added to intercept `Read` tool calls on source files and return compact summaries — see the Token optimization section in the README for details.

Advanced models such as Opus (which I have used in production contexts) are intentionally avoided, as they may introduce additional usage overhead that is not consistent with the objectives of this experiment.

On the other hand, lower-tier models such as Haiku are also not fully optimal in terms of token efficiency and code quality for complex tasks; however, they will be evaluated in the second week of the experiment, specifically during the frontend application creation phase, to better understand their trade-offs in real-world usage scenarios.

**By phase:**

| Phase | Cost | Share |
|-------|-----:|------:|
| Implementation | $61.93 | 56% |
| Spec writing | $36.60 | 33% |
| Setup / tooling | $12.25 | 11% |

Spec writing is the cheapest phase — most spec sessions cost $0.35–$0.50 each. The outliers (`RIVER-6` at $16.84, `RIVER-22` at $13.30) were complex iterative specs with many rounds of context growth, not a structural problem with spec-first gating.

**Most expensive session**: `RIVER-6 — Setup DevOps part 2` at **$16.84** — 421 turns, 27.7M cache reads, long debug loop with growing context.

**Cheapest sessions**: simple spec writes at **$0.20–$0.35** each.

**By MoSCoW priority:**

MoSCoW labels are assigned when a spec is written. This makes it possible to see how much budget was spent on what the team decided was truly required vs. what was deferred.

| Priority | Cost | Share |
|----------|-----:|------:|
| must | $110.23 | 80% |
| should | $28.40 | 20% |
| could | — | — |
| wont | — | — |

**By category:**

| Category | Cost | Share |
|----------|-----:|------:|
| tools | $75.12 | 54% |
| features | $41.42 | 30% |
| bugs | $17.31 | 12% |
| docs | $2.95 | 2% |
| refactoring | $1.83 | 1% |

The tooling cost (54%) is high relative to features (27%) because the first week included bootstrapping the entire CI/CD pipeline, DevOps setup, and dev tooling from scratch — a one-time cost. Refactoring is cheapest because it was minimal; bugs are unexpectedly high, driven by the RIVER-22 error-linking spec which required deep context analysis.
