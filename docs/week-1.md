# Week 1 — MVP done

6 days, 35 committed sessions, 3,309 assistant turns.

From 6 May to 11 May

Built a working end-to-end observability pipeline with no custom frontend — Grafana as the UI layer. Components shipped: OTel sidecar, ingestion service, S3 batch storage, metrics aggregation, database migration management, query API, Grafana dashboards, and a full CI/CD setup. Test coverage above 80% (SonarQube gate).

Full token breakdown: [docs/token-usage.md](token-usage.md)

**API-equivalent cost** (Sonnet 4.6 pricing — $3/1M input, $3.75/1M cache write, $0.30/1M cache read, $15/1M output):

| Token type | Volume | Cost | Share |
|------------|--------|-----:|------:|
| Cache reads | 206.7M | $62.00 | 49% |
| Output | 2.6M | $38.42 | 30% |
| Cache writes | 7.0M | $26.17 | 21% |
| Input | 17K | $0.05 | <1% |
| **Total** | | **$126.63** | |

[RTK](https://github.com/rtk-ai/rtk) was used to compress Bash tool output — 218K additional input tokens avoided (~$0.65). Since week 1, a second layer (`river-index`) was added to intercept `Read` tool calls on source files and return compact summaries — see the Token optimization section in the README for details.

Advanced models such as Opus (which I have used in production contexts) are intentionally avoided, as they may introduce additional usage overhead that is not consistent with the objectives of this experiment.

On the other hand, lower-tier models such as Haiku are also not fully optimal in terms of token efficiency and code quality for complex tasks; however, they will be evaluated in the second week of the experiment, specifically during the frontend application creation phase, to better understand their trade-offs in real-world usage scenarios.

**By phase:**

| Phase | Cost | Share |
|-------|-----:|------:|
| Implementation | $51.70 | 41% |
| Setup / tooling | $37.81 | 30% |
| Spec writing | $37.12 | 29% |

Setup/tooling is higher than expected because the first week included bootstrapping the entire CI/CD pipeline, DevOps setup, and dev tooling from scratch — a one-time cost. Spec writing and implementation costs are close, which reflects the spec-first design: most spec sessions are cheap ($0.35–$0.50), but complex iterative specs (`RIVER-6` at $16.84, `RIVER-22` at $13.30) pull the phase cost up.

**Most expensive session**: `RIVER-6 — Setup DevOps part 2` at **$16.84** — 421 turns, 27.7M cache reads, long debug loop with growing context.

**Cheapest sessions**: simple spec writes and fixes at **$0.20–$0.41** each.

**By MoSCoW priority:**

MoSCoW labels are assigned when a spec is written. This makes it possible to see how much budget was spent on what the team decided was truly required vs. what was deferred.

| Priority | Cost | Share |
|----------|-----:|------:|
| must | $98.23 | 78% |
| should | $28.40 | 22% |
| could | — | — |
| wont | — | — |

**By category:**

| Category | Cost | Share |
|----------|-----:|------:|
| tools | $64.48 | 51% |
| features | $40.06 | 32% |
| bugs | $17.31 | 14% |
| docs | $2.95 | 2% |
| refactoring | $1.83 | 1% |

The tooling cost (51%) is high relative to features (32%) because of the one-time infrastructure bootstrap. Bugs are at 14% due to the RIVER-22 error-linking spec which required deep context analysis.
