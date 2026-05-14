# Claude Token Usage by Commit

Generated 2026-05-14. Source: Claude Code session JSONL files (`~/.claude/projects/`), 3,618 assistant turns correlated with `git log` by timestamp. RTK savings from `~/Library/Application Support/rtk/history.db`, scoped to this project.

Columns: **Input** = fresh input tokens billed; **CacheC** = tokens written to prompt cache; **CacheR** = tokens read from prompt cache (cheap); **Output** = generated tokens; **Turns** = assistant API calls; **RTKSaved** = tokens removed by RTK compression before reaching Claude.

| Commit | Date | Input | CacheC | CacheR | Output | Turns | RTKSaved | Subject |
|--------|------|------:|-------:|-------:|-------:|------:|---------:|---------|
| 432097bb | 05-05 19:12 | 42 | 65,791 | 301,008 | 4,995 | 20 | 0 | day 0: define objectives & setup |
| a024726d | 05-05 19:27 | 89 | 35,883 | 1,583,346 | 22,769 | 55 | 0 | day 0: setup mise tools + skills |
| 4f596bf7 | 05-06 18:39 | 49 | 38,476 | 414,284 | 8,035 | 21 | 0 | spec: [RIVER-1] setup sidecar + demo app |
| 308f3123 | 05-06 19:03 | 76 | 340,094 | 1,952,926 | 97,697 | 51 | 0 | feat: [RIVER-2] Implement sidecar + demo |
| ab166cc0 | 05-07 18:39 | 121 | 122,985 | 3,483,120 | 99,077 | 75 | 0 | feat: [RIVER-3] s3 batch |
| a46e9424 | 05-07 19:06 | 82 | 93,613 | 3,996,021 | 98,812 | 46 | 0 | feat: [RIVER-3] metrics aggregation |
| 1697eeae | 05-08 07:53 | 492 | 232,188 | 22,006,299 | 153,411 | 299 | 0 | docs: [RIVER-4] setup SDD |
| aee23f2a | 05-08 08:11 | 30 | 38,293 | 353,661 | 6,475 | 18 | 0 | spec: RIVER-1 -- Ingestion service (#3) |
| 225fbd41 | 05-08 08:27 | 131 | 158,014 | 5,884,378 | 98,714 | 96 | 0 | feat: [RIVER-1] ingestion service |
| 5b9c519d | 05-08 08:38 | 26 | 10,480 | 1,560,962 | 4,069 | 16 | 0 | spec: RIVER-4 -- Setup DevOps (#5) |
| ce974698 | 05-08 09:05 | 195 | 93,913 | 15,481,193 | 77,188 | 127 | 0 | chore: [RIVER-4] add mise tasks + fix pre-existing clippy issues + SonarQub |
| b28440ce | 05-08 17:29 | 4,133 | 702,114 | 27,737,792 | 391,873 | 421 | 283 | spec: RIVER-6 -- Setup DevOps part 2 (#7) |
| 2afa1341 | 05-08 17:46 | 33 | 11,320 | 2,026,340 | 10,006 | 15 | 0 | fix: correct spec creation tasks |
| c51b803e | 05-09 07:40 | 44 | 75,984 | 422,057 | 8,300 | 24 | 135 | feat: update dependencies & remove "strange" code from dockerfile |
| 844e76df | 05-09 07:55 | 648 | 88,999 | 1,226,361 | 41,313 | 51 | 330 | spec: RIVER-10 -- Liquibase (#11) |
| d6921e42 | 05-09 08:18 | 201 | 162,256 | 8,566,807 | 94,917 | 149 | 405 | feat: RIVER-10 database migration management |
| 8172c1c3 | 05-09 08:45 | 32 | 37,889 | 399,495 | 5,552 | 20 | 40 | spec: RIVER-12 -- Grafana (#13) |
| 8469784f | 05-09 09:27 | 485 | 312,562 | 18,298,365 | 149,889 | 233 | 4,113 | feat: RIVER-12 enrich demo-app with child spans, error simulation, and dura |
| 0886301a | 05-09 10:37 | 131 | 300,782 | 8,698,314 | 89,288 | 101 | 390 | test: add unit tests to reach >80% line coverage for SonarQube |
| c6edbd9e | 05-09 11:13 | 70 | 99,533 | 1,309,634 | 22,677 | 42 | 195,783 | feat: skill to calculate tokens usage |
| 92ed37ee | 05-09 19:00 | 32 | 38,532 | 567,185 | 7,313 | 25 | 99 | spec: RIVER-14 -- Update SDD (#15) |
| 784acc7b | 05-09 19:16 | 128 | 154,275 | 4,071,664 | 48,442 | 91 | 636 | docs: RIVER-14 update SDD to branch-based impl flow |
| a924443a | 05-09 19:22 | 36 | 32,183 | 1,734,437 | 15,957 | 24 | 79 | feat: update calculate usage command |
| b115c81c | 05-10 05:54 | 58 | 246,172 | 2,571,346 | 14,240 | 31 | 120 | spec: RIVER-16 -- Query API (#17) |
| 89a5791a | 05-10 06:01 | 15 | 24,315 | 152,673 | 4,276 | 9 | 0 | fix: update workflow |
| b38c0ff0 | 05-10 08:32 | 6,868 | 856,149 | 14,680,514 | 177,094 | 231 | 1,349 | impl: RIVER-16 -- Query API (#18) |
| bdfccb53 | 05-10 11:58 | 82 | 76,417 | 1,495,651 | 27,138 | 52 | 407 | spec: RIVER-19 -- Configuration (#20) |
| ee2857f4 | 05-10 12:52 | 269 | 1,159,442 | 17,912,819 | 238,706 | 217 | 475 | spec: RIVER-22 -- Error linking traces (#23) |
| 0f9ce69f | 05-10 13:15 | 517 | 50,604 | 966,890 | 13,776 | 35 | 410 | impl: RIVER-19 -- Configuration (#21) |
| 0b561544 | 05-10 17:27 | 309 | 493,544 | 12,410,167 | 295,154 | 209 | 1,461 | docs: update readme & tools |
| 7e90aedb | 05-10 18:13 | 139 | 137,955 | 7,482,433 | 83,153 | 107 | 3,022 | impl: RIVER-22 -- Grafana trace links (#21) (#24) |
| ede8b859 | 05-10 19:42 | 111 | 158,061 | 1,564,576 | 27,842 | 61 | 0 | docs: add usage notice & update usage & spec |
| f077ac06 | 05-11 18:05 | 45 | 46,684 | 474,031 | 7,780 | 23 | 64 | docs: add issue create command |
| 513bc58a | 05-11 18:13 | 74 | 36,245 | 884,638 | 8,410 | 40 | 152 | spec: RIVER-25 -- Setup flutter MVP app (#26) |
| a3ee929b | 05-11 19:31 | 906 | 446,346 | 14,000,612 | 106,742 | 274 | 7,825 | impl: RIVER-25 -- Setup Flutter MVP app (#27) |
| 7ae1441f | 05-14 06:29 | 86 | 106,809 | 1,579,038 | 40,177 | 50 | 509 | docs: feature plan |
| d77e9f73 | 05-14 06:38 | 136 | 90,667 | 942,413 | 30,325 | 32 | 164 | docs: ui-logs-page |
| 8628b823 | 05-14 06:56 | 160 | 409,733 | 6,054,879 | 250,221 | 123 | 515 | docs: feat v1 process |
| db1896a0 | 05-14 06:57 | 29 | 60,346 | 611,358 | 6,157 | 23 | 86 | spec: RIVER-28 -- API: Histogram & Facets + Extend LogRow (#33) |
| 5c060e2d | 05-14 06:59 | 24 | 10,095 | 777,788 | 5,643 | 24 | 163 | spec: RIVER-29 -- UI: Page Layout + Time Range Selector + Search Bar (#32) |
| a1aa0730 | 05-14 07:00 | 8 | 2,892 | 294,537 | 1,022 | 8 | 0 | spec: RIVER-30 -- UI: Facet Panel (#34) |
| 04eab962 | 05-14 07:01 | 9 | 4,106 | 361,288 | 1,167 | 9 | 0 | spec: RIVER-31 -- UI: Log Distribution Histogram (#36) |
| 96ac016b | 05-14 07:01 | 7 | 3,261 | 304,612 | 1,070 | 7 | 0 | spec: RIVER-35 -- UI: Logs Table with Column Management and Sort (#38) |
| d0d09f1a | 05-14 07:02 | 7 | 3,230 | 324,703 | 1,097 | 7 | 0 | spec: RIVER-37 -- UI: Log Detail Panel (#39) |
| d1f2600b | 05-14 07:10 | 17 | 7,106 | 736,577 | 16,642 | 15 | 0 | fix: clean workspace |
| uncommitted | pending | 14 | 61,191 | 224,475 | 11,829 | 11 | 0 | (uncommitted work) |
| **TOTAL** | | **17,196** | **7,737,529** | **218,883,667** | **2,926,430** | **3,618** | **219,015** | |

## Notes

- **Input tokens are tiny** (17,196 total) because virtually everything is served from prompt cache (218,883,667 CacheR). Fresh context per turn averages ~5 tokens — essentially zero.
- **RTKSaved (219,015 total)** = tool result tokens compressed before reaching Claude. Zero for early commits — RTK was not yet active. The spike on `c6edbd9e` (195K) is from reading large JSONL files during the first calculate-usage run.
- **CacheC tracks context growth**: RIVER-22 spec (1.16M) and RIVER-16 impl (856K) are the two heaviest cache-writing sessions — long iterative loops with large growing context. The `docs: feat v1 process` session (409K) and RIVER-6 (702K) are also significant.
- **Heaviest sessions by output**: RIVER-6 (391K), `docs: feat v1 process` (250K), RIVER-22 spec (238K), RIVER-22 impl (244K), RIVER-16 impl (177K).
- **Heaviest by turns**: RIVER-6 (421), RIVER-4 docs (299), RIVER-25 impl (274), RIVER-16 impl (231), RIVER-22 spec (217).
- The first commit (`20dacb7b`) and `cd621e48` (refactor dotnet slnx) show no data — done outside Claude Code.
- Total API-equivalent cost: $138.63 across 3,618 turns.
