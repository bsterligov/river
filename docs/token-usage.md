# Claude Token Usage by Commit

Generated 2026-05-09. Source: Claude Code session JSONL files (`~/.claude/projects/`), 1,866 assistant turns correlated with `git log` by timestamp.

Columns: **Input** = fresh input tokens billed; **CacheC** = tokens written to prompt cache; **CacheR** = tokens read from prompt cache (cheap); **Output** = generated tokens; **Turns** = assistant API calls in session.

| Commit | Date | Input | CacheC | CacheR | Output | Turns | Subject |
|--------|------|------:|-------:|-------:|-------:|------:|---------|
| 432097bb | 05-05 19:12 | 42 | 65,791 | 301,008 | 4,995 | 20 | day 0: define objectives & setup |
| a024726d | 05-05 19:27 | 89 | 35,883 | 1,583,346 | 22,769 | 55 | day 0: setup mise tools + skills |
| 4f596bf7 | 05-06 18:39 | 49 | 38,476 | 414,284 | 8,035 | 21 | spec: [RIVER-1] setup sidecar + demo app |
| 308f3123 | 05-06 19:03 | 76 | 340,094 | 1,952,926 | 97,697 | 51 | feat: [RIVER-2] Implement sidecar + demo |
| ab166cc0 | 05-07 18:39 | 121 | 122,985 | 3,483,120 | 99,077 | 75 | feat: [RIVER-3] s3 batch |
| a46e9424 | 05-07 19:06 | 82 | 93,613 | 3,996,021 | 98,812 | 46 | feat: [RIVER-3] metrics aggregation |
| 1697eeae | 05-08 07:53 | 492 | 232,188 | 22,006,299 | 153,411 | 299 | docs: [RIVER-4] setup SDD |
| aee23f2a | 05-08 08:11 | 30 | 38,293 | 353,661 | 6,475 | 18 | spec: RIVER-1 -- Ingestion service (#3) |
| 225fbd41 | 05-08 08:27 | 131 | 158,014 | 5,884,378 | 98,714 | 96 | feat: [RIVER-1] ingestion service |
| 5b9c519d | 05-08 08:38 | 26 | 10,480 | 1,560,962 | 4,069 | 16 | spec: RIVER-4 -- Setup DevOps (#5) |
| ce974698 | 05-08 09:05 | 195 | 93,913 | 15,481,193 | 77,188 | 127 | chore: [RIVER-4] add mise tasks + fix clippy |
| b28440ce | 05-08 17:29 | 4,133 | 702,114 | 27,737,792 | 391,873 | 421 | spec: RIVER-6 -- Setup DevOps part 2 (#7) |
| 2afa1341 | 05-08 17:46 | 33 | 11,320 | 2,026,340 | 10,006 | 15 | fix: correct spec creation tasks |
| c51b803e | 05-09 07:40 | 44 | 75,984 | 422,057 | 8,300 | 24 | feat: update dependencies & remove strange code |
| 844e76df | 05-09 07:55 | 648 | 88,999 | 1,226,361 | 41,313 | 51 | spec: RIVER-10 -- Liquibase (#11) |
| d6921e42 | 05-09 08:18 | 201 | 162,256 | 8,566,807 | 94,917 | 149 | feat: RIVER-10 database migration management |
| 8172c1c3 | 05-09 08:45 | 32 | 37,889 | 399,495 | 5,552 | 20 | spec: RIVER-12 -- Grafana (#13) |
| 8469784f | 05-09 09:27 | 485 | 312,562 | 18,298,365 | 149,889 | 233 | feat: RIVER-12 enrich demo-app + pipeline debug |
| 0886301a | 05-09 10:37 | 131 | 300,782 | 8,698,314 | 89,288 | 101 | test: add unit tests for SonarQube >80% coverage |
| **TOTAL** | | **7,086** | **2,992,326** | **125,083,857** | **1,473,265** | **1,866** | |

## Notes

- **Input tokens are tiny** (7K total) because virtually everything is served from prompt cache (125M CacheR). Fresh context per turn is minimal.
- **CacheC tracks context growth**: sessions that write a lot to cache (RIVER-6 at 702K, RIVER-12 at 312K) were doing heavy iterative work building up large contexts.
- **Heaviest sessions by output**: RIVER-6 spec/DevOps (391K), RIVER-4 docs (153K), RIVER-12 pipeline (149K).
- **Heaviest by turns**: RIVER-6 (421 turns), RIVER-4 (299 turns), RIVER-12 (233 turns).
- **docs: [RIVER-4] setup SDD** has 299 turns with 22M cache reads — a very long iterative session.
- The first commit (`20dacb7b`) and `cd621e48` (refactor dotnet slnx) show no data — they pre-date RTK/session tracking or were done outside Claude Code.
