# Claude Token Usage by Commit

Generated 2026-05-10. Source: Claude Code session JSONL files (`~/.claude/projects/`), 2,934 assistant turns correlated with `git log` by timestamp. RTK savings from `~/Library/Application Support/rtk/history.db`, scoped to this project.

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
| ff582696 | 05-10 19:31 | 46 | 62,864 | 383,211 | 7,470 | 20 | 0 | docs: add usage notice |
| uncommitted | pending | 5 | 10,255 | 79,824 | 3,252 | 3 | 0 | (uncommitted work) |
| **TOTAL** | | **15,614** | **6,363,876** | **190,211,177** | **2,421,028** | **2,934** | **209,537** | |

## Notes

- **Input tokens are tiny** (15,614 total) because virtually everything is served from prompt cache (190,211,177 CacheR). Fresh context per turn averages ~5 tokens — essentially zero.
- **RTKSaved (209,537 total)** = tool result tokens compressed before reaching Claude. Zero for early commits — RTK was not yet active. The spike on `c6edbd9e` (195K) is from reading large JSONL files during the first calculate-usage run.
- **CacheC tracks context growth**: RIVER-22 spec (1.16M) and RIVER-16 impl (856K) are the two heaviest cache-writing sessions — long iterative loops with large growing context. RIVER-6 (702K) was previously the heaviest.
- **Heaviest sessions by output**: RIVER-6 (391K), RIVER-22 spec (238K), RIVER-22 impl (244K), RIVER-16 impl (177K), RIVER-19 impl (163K).
- **Heaviest by turns**: RIVER-6 (421), RIVER-4 docs (299), RIVER-16 impl (231), RIVER-22 spec (217).
- The first commit (`20dacb7b`) and `cd621e48` (refactor dotnet slnx) show no data — done outside Claude Code.
- Total API-equivalent cost: $117.29 across 2,934 turns.
