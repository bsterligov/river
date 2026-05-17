# Token Usage — updated 2026-05-17

**RTKSaved** = tokens removed by RTK compression before reaching Claude (avoided context, on top of billed input).

| Date | SHA | Input | CacheC | CacheR | Output | Turns | RTKSaved | Subject |
|------|-----|------:|-------:|-------:|-------:|------:|---------:|---------|
| 05-05 19:12 | 432097bb | 42 | 65,791 | 301,008 | 4,995 | 20 | 0 | day 0: define objectives & setup |
| 05-05 19:27 | a024726d | 89 | 35,883 | 1,583,346 | 22,769 | 55 | 0 | day 0: setup mise tools + skills |
| 05-06 18:39 | 4f596bf7 | 49 | 38,476 | 414,284 | 8,035 | 21 | 0 | spec: [RIVER-1] setup sidecar + demo app |
| 05-06 19:03 | 308f3123 | 76 | 340,094 | 1,952,926 | 97,697 | 51 | 0 | feat: [RIVER-2] Implement sidecar + demo |
| 05-07 18:39 | ab166cc0 | 121 | 122,985 | 3,483,120 | 99,077 | 75 | 0 | feat: [RIVER-3] s3 batch |
| 05-07 19:06 | a46e9424 | 82 | 93,613 | 3,996,021 | 98,812 | 46 | 0 | feat: [RIVER-3] metrics aggregation |
| 05-08 07:53 | 1697eeae | 492 | 232,188 | 22,006,299 | 153,411 | 299 | 0 | docs: [RIVER-4] setup SDD |
| 05-08 08:11 | aee23f2a | 30 | 38,293 | 353,661 | 6,475 | 18 | 0 | spec: RIVER-1 -- Ingestion service (#3) |
| 05-08 08:27 | 225fbd41 | 131 | 158,014 | 5,884,378 | 98,714 | 96 | 0 | feat: [RIVER-1] ingestion service |
| 05-08 08:38 | 5b9c519d | 26 | 10,480 | 1,560,962 | 4,069 | 16 | 0 | spec: RIVER-4 -- Setup DevOps (#5) |
| 05-08 09:05 | ce974698 | 195 | 93,913 | 15,481,193 | 77,188 | 127 | 0 | chore: [RIVER-4] add mise tasks + fix pre-existing clippy issues + SonarQub |
| 05-08 17:29 | b28440ce | 4,133 | 702,114 | 27,737,792 | 391,873 | 421 | 283 | spec: RIVER-6 -- Setup DevOps part 2 (#7) |
| 05-08 17:46 | 2afa1341 | 33 | 11,320 | 2,026,340 | 10,006 | 15 | 0 | fix: correct spec creation tasks |
| 05-09 07:40 | c51b803e | 44 | 75,984 | 422,057 | 8,300 | 24 | 135 | feat: update dependencies & remove "strange" code from dockerfile |
| 05-09 07:55 | 844e76df | 648 | 88,999 | 1,226,361 | 41,313 | 51 | 330 | spec: RIVER-10 -- Liquibase (#11) |
| 05-09 08:18 | d6921e42 | 201 | 162,256 | 8,566,807 | 94,917 | 149 | 405 | feat: RIVER-10 database migration management |
| 05-09 08:45 | 8172c1c3 | 32 | 37,889 | 399,495 | 5,552 | 20 | 40 | spec: RIVER-12 -- Grafana (#13) |
| 05-09 09:27 | 8469784f | 485 | 312,562 | 18,298,365 | 149,889 | 233 | 4,113 | feat: RIVER-12 enrich demo-app with child spans, error simulation, and dura |
| 05-09 10:37 | 0886301a | 131 | 300,782 | 8,698,314 | 89,288 | 101 | 390 | test: add unit tests to reach >80% line coverage for SonarQube |
| 05-09 11:13 | c6edbd9e | 70 | 99,533 | 1,309,634 | 22,677 | 42 | 195,783 | feat: skill to calculate tokens usage |
| 05-09 19:00 | 92ed37ee | 32 | 38,532 | 567,185 | 7,313 | 25 | 99 | spec: RIVER-14 -- Update SDD (#15) |
| 05-09 19:16 | 784acc7b | 128 | 154,275 | 4,071,664 | 48,442 | 91 | 636 | docs: RIVER-14 update SDD to branch-based impl flow |
| 05-09 19:22 | a924443a | 36 | 32,183 | 1,734,437 | 15,957 | 24 | 79 | feat: update calculate usage command |
| 05-10 05:54 | b115c81c | 58 | 246,172 | 2,571,346 | 14,240 | 31 | 120 | spec: RIVER-16 -- Query API (#17) |
| 05-10 06:01 | 89a5791a | 15 | 24,315 | 152,673 | 4,276 | 9 | 0 | fix: update workflow |
| 05-10 08:32 | b38c0ff0 | 6,868 | 856,149 | 14,680,514 | 177,094 | 231 | 1,349 | impl: RIVER-16 -- Query API (#18) |
| 05-10 11:58 | bdfccb53 | 82 | 76,417 | 1,495,651 | 27,138 | 52 | 407 | spec: RIVER-19 -- Configuration (#20) |
| 05-10 12:52 | ee2857f4 | 269 | 1,159,442 | 17,912,819 | 238,706 | 217 | 475 | spec: RIVER-22 -- Error linking traces (#23) |
| 05-10 13:15 | 0f9ce69f | 517 | 50,604 | 966,890 | 13,776 | 35 | 410 | impl: RIVER-19 -- Configuration (#21) |
| 05-10 17:27 | 0b561544 | 309 | 493,544 | 12,410,167 | 295,154 | 209 | 1,461 | docs: update readme & tools |
| 05-10 18:13 | 7e90aedb | 139 | 137,955 | 7,482,433 | 83,153 | 107 | 3,022 | impl: RIVER-22 -- Grafana trace links (#21) (#24) |
| 05-10 19:42 | ede8b859 | 111 | 158,061 | 1,564,576 | 27,842 | 61 | 0 | docs: add usage notice & update usage & spec |
| 05-11 18:05 | f077ac06 | 45 | 46,684 | 474,031 | 7,780 | 23 | 64 | docs: add issue create command |
| 05-11 18:13 | 513bc58a | 74 | 36,245 | 884,638 | 8,410 | 40 | 152 | spec: RIVER-25 -- Setup flutter MVP app (#26) |
| 05-11 19:31 | a3ee929b | 906 | 446,346 | 14,000,612 | 106,742 | 274 | 7,825 | impl: RIVER-25 -- Setup Flutter MVP app (#27) |
| 05-14 06:29 | 7ae1441f | 86 | 106,809 | 1,579,038 | 40,177 | 50 | 509 | docs: feature plan |
| 05-14 06:38 | d77e9f73 | 136 | 90,667 | 942,413 | 30,325 | 32 | 164 | docs: ui-logs-page |
| 05-14 06:56 | 8628b823 | 160 | 409,733 | 6,054,879 | 250,221 | 123 | 515 | docs: feat v1 process |
| 05-14 06:57 | db1896a0 | 29 | 60,346 | 611,358 | 6,157 | 23 | 86 | spec: RIVER-28 -- API: Histogram & Facets + Extend LogRow (#33) |
| 05-14 06:59 | 5c060e2d | 24 | 10,095 | 777,788 | 5,643 | 24 | 163 | spec: RIVER-29 -- UI: Page Layout + Time Range Selector + Search Bar (#32) |
| 05-14 07:00 | a1aa0730 | 8 | 2,892 | 294,537 | 1,022 | 8 | 0 | spec: RIVER-30 -- UI: Facet Panel (#34) |
| 05-14 07:01 | 04eab962 | 9 | 4,106 | 361,288 | 1,167 | 9 | 0 | spec: RIVER-31 -- UI: Log Distribution Histogram (#36) |
| 05-14 07:01 | 96ac016b | 7 | 3,261 | 304,612 | 1,070 | 7 | 0 | spec: RIVER-35 -- UI: Logs Table with Column Management and Sort (#38) |
| 05-14 07:02 | d0d09f1a | 7 | 3,230 | 324,703 | 1,097 | 7 | 0 | spec: RIVER-37 -- UI: Log Detail Panel (#39) |
| 05-14 07:10 | d1f2600b | 17 | 7,106 | 736,577 | 16,642 | 15 | 0 | fix: clean workspace |
| 05-14 07:13 | b918625c | 21 | 87,117 | 482,988 | 24,951 | 18 | 0 | docs: update token usage |
| 05-14 14:05 | 002b7863 | 414 | 888,005 | 24,335,309 | 98,006 | 314 | 0 | feat: add sqlite based index |
| 05-14 17:02 | c8e7da67 | 73 | 88,959 | 1,714,271 | 24,678 | 45 | 454 | docs: split readme & update commands |
| 05-14 17:34 | 7ad4c8d8 | 154 | 136,906 | 6,551,034 | 33,735 | 130 | 2,254 | impl: RIVER-28 -- API: Histogram & Facets + Extend LogRow (#40) |
| 05-14 18:31 | cf1ea892 | 291 | 232,710 | 23,315,588 | 78,015 | 260 | 38,756 | impl: RIVER-29 -- UI: Page Layout + Time Range Selector + Search Bar (#41) |
| 05-14 18:58 | 330edc13 | 125 | 147,018 | 6,573,746 | 40,245 | 111 | 309 | impl: RIVER-30 -- UI: Facet Panel (#42) |
| 05-14 19:35 | 2b336370 | 264 | 237,992 | 18,674,218 | 90,878 | 208 | 621 | impl: RIVER-37 -- UI: Log Detail Panel (#43) |
| 05-14 19:48 | 2c336d65 | 54 | 63,045 | 1,325,574 | 20,789 | 38 | 356 | docs: update token usage |
| 05-15 07:46 | e702ddb9 | 402 | 629,250 | 27,534,962 | 153,607 | 323 | 2,860 | impl: RIVER-31 -- UI: Log Distribution Histogram (#44) |
| 05-15 08:38 | 9f793f6f | 268 | 294,214 | 24,143,783 | 102,976 | 240 | 561 | impl: RIVER-35 -- UI: Logs Table with Column Management and Sort (#45) |
| 05-15 08:49 | 4275c18e | 625 | 86,729 | 1,332,774 | 8,950 | 59 | 338 | spec: RIVER-46 -- Set up SonarQube and tests CI run for Flutter code (#47) |
| 05-15 09:22 | 13d84612 | 200 | 248,606 | 8,429,003 | 32,774 | 148 | 17,271 | impl: RIVER-46 (#48) |
| 05-15 09:30 | ff951a22 | 9 | 4,859 | 466,194 | 1,407 | 5 | 0 | chore: exclude test files from SonarQube duplication and coverage |
| 05-15 09:50 | d7e1a8d9 | 93 | 59,797 | 7,046,938 | 20,068 | 63 | 201 | fix: install Flutter in sonarqube job so S2260 false positives disappear |
| 05-15 10:09 | d6b2987e | 25 | 4,811 | 2,135,209 | 2,729 | 17 | 78 | fix: run flutter pub get before sonar scan to resolve package imports |
| 05-15 11:36 | 8fc89a6f | 37 | 272,778 | 4,374,721 | 9,138 | 33 | 0 | fix: resolve all SonarQube issues (const constructors, withValues, S3962) |
| 05-15 15:53 | 7f5a3d00 | 114 | 41,227 | 2,787,524 | 12,065 | 94 | 116 | spec: RIVER-49 -- Refactor UI layout: move app name to top panel with datet |
| 05-15 17:07 | 5a21c483 | 302 | 260,559 | 27,683,222 | 79,075 | 278 | 6,847 | impl: RIVER-49 (#51) |
| 05-15 17:12 | 9d73c836 | 49 | 29,085 | 811,153 | 5,020 | 34 | 147 | spec: RIVER-52 -- Add logo and update window title to "River Dashboard" (#5 |
| 05-15 17:57 | 44662899 | 391 | 237,889 | 27,004,290 | 90,947 | 287 | 714 | impl: RIVER-52 (#54) |
| 05-15 18:03 | 726f1798 | 41 | 45,717 | 957,014 | 20,328 | 31 | 263 | docs: update token u |
| 05-15 18:10 | fd3f808d | 18 | 30,004 | 332,261 | 4,908 | 14 | 1,504 | docs: trace feature |
| 05-15 18:21 | 877d1268 | 43 | 35,384 | 1,011,491 | 12,786 | 26 | 0 | spec: RIVER-55 -- Single-trace API endpoint (#57) |
| 05-15 18:22 | 10c4ebd0 | 20 | 6,351 | 1,017,187 | 2,708 | 20 | 69 | spec: RIVER-56 -- Trace list page (Flutter) (#58) |
| 05-15 18:23 | 8554b57b | 9 | 2,624 | 496,955 | 985 | 9 | 70 | spec: RIVER-59 -- Trace waterfall detail panel (Flutter) (#60) |
| 05-15 18:23 | c17fc9fc | 12 | 10,350 | 711,597 | 2,451 | 12 | 54 | spec: RIVER-61 -- Span attributes panel (#62) |
| 05-15 18:35 | dc801af1 | 63 | 27,530 | 2,694,801 | 7,777 | 39 | 321 | impl: RIVER-55 -- Single-trace API endpoint (#63) |
| 05-15 18:36 | 61dfa984 | 15 | 14,773 | 1,274,535 | 3,969 | 15 | 37 | impl: RIVER-56 (#64) |
| 05-15 18:38 | ae8890a6 | 21 | 5,358 | 1,192,490 | 3,170 | 13 | 702 | fix: restore river_api package name in generated pubspec |
| 05-15 18:44 | 1446bef1 | 48 | 29,111 | 4,696,074 | 8,725 | 46 | 45 | fix: restore missing generated client types lost during Phase 1 regen |
| 05-15 18:46 | a661e83e | 24 | 6,143 | 2,014,470 | 3,217 | 18 | 0 | fix: add FacetField, FacetValue, HistogramBucket to deserializer switch |
| 05-15 19:10 | 85b4b97d | 54 | 30,823 | 1,003,705 | 4,978 | 34 | 39 | spec: RIVER-67 -- Fix sonar duplication and trace page (#68) |
| 05-15 19:33 | e5a81a79 | 201 | 178,442 | 15,749,907 | 42,402 | 191 | 1,119 | impl: RIVER-67 (#69) |
| 05-16 05:12 | 460dbe28 | 14 | 17,734 | 194,752 | 1,727 | 10 | 0 | tools: ignore run analysis on draft PRs |
| 05-16 05:38 | 9e10c84d | 225 | 231,363 | 6,384,489 | 62,652 | 153 | 740 | docs: update commands naming & process |
| 05-16 06:41 | 3fb759c5 | 1,401 | 555,618 | 41,016,484 | 155,865 | 490 | 1,522 | impl: RIVER-59 -- Trace waterfall detail panel (Flutter) (#65) |
| 05-16 07:54 | bdfdaf87 | 367 | 201,107 | 7,772,844 | 27,905 | 122 | 37,335 | impl: RIVER-70 (#72) |
| 05-16 08:15 | 7dba6d8b | 84 | 86,846 | 10,293,989 | 25,912 | 81 | 591 | impl: RIVER-61 (#66) |
| 05-16 08:23 | 25b9d8d4 | 49 | 45,610 | 1,127,585 | 8,728 | 35 | 3,162 | spec: RIVER-73 -- Refactor Flutter widgets: extract duplicates, split large |
| 05-16 08:58 | 32655ccc | 254 | 276,995 | 21,561,550 | 79,621 | 218 | 9,107 | spec: RIVER-76 -- Unify traces table with logs table: shared columns, colum |
| 05-16 12:39 | aae6e0cd | 1,899 | 790,403 | 34,325,840 | 116,208 | 354 | 27,315 | impl: RIVER-76 (#78) |
| 05-17 06:51 | 3bb73622 | 55 | 45,053 | 1,118,334 | 10,627 | 35 | 17,742 | spec: RIVER-79 -- Fix Rust code quality issues found in analysis (#80) |
| 05-17 07:30 | 01ca1783 | 207 | 281,941 | 19,603,214 | 87,652 | 198 | 649 | impl: RIVER-79 -- Fix Rust Code Quality Issues Found in Analysis (#81) |
| 05-17 07:45 | fa2b3a6b | 56 | 50,510 | 1,393,224 | 12,949 | 35 | 2,360 | spec: RIVER-82 -- Fix code quality issues from codebase audit (#83) |
| 05-17 08:09 | 38c37d7a | 24,821 | 327,199 | 15,349,067 | 44,597 | 137 | 662 | impl: RIVER-82 (#84) |
| 05-17 11:32 | 92a9c121 | 211 | 229,692 | 10,179,805 | 93,037 | 167 | 2,899 | docs: update workflow |
| **Total** | — | **51,305** | **15,290,575** | **638,855,357** | **4,690,538** | **8815** | **399,205** | — |

## Weekly Cost

| Week | Input | CacheC | CacheR | Output | Turns | Cost |
|------|------:|-------:|-------:|-------:|------:|-----:|
| 2026-W19 | 15,674 | 6,448,818 | 191,312,718 | 2,438,148 | 2972 | $118.20 |
| 2026-W20 | 35,631 | 8,841,757 | 447,542,639 | 2,252,390 | 5843 | $201.31 |
| **Total** | **51,305** | **15,290,575** | **638,855,357** | **4,690,538** | **8815** | **$319.51** |

## Notes

- Pricing: Sonnet 4.6 — $3.00/1M input, $3.75/1M cache write, $0.30/1M cache read, $15.00/1M output
- **Total estimated cost: $319.5082**
- RTKSaved = tokens removed from tool results before being fed back as context (not billed, but avoided context inflation)
