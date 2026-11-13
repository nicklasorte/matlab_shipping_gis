# Stage 1: reproduction from a clean copy

DRAFT//PRE-DECISIONAL

Date: November 12, 2026

## MATLAB zone runs

A clean download of commit `64653fe` was run on the Mac (MATLAB R2025b) with
the four committed entry scripts, from the committed day caches.

| Area | Script | CSV outputs identical to the committed copy | Key run-log lines identical |
| --- | --- | --- | --- |
| Lower 48 | `init_shipping_zone_rev1.m` | 8 of 8 | 6 of 6 |
| Hawaii | `init_shipping_zone_hawaii_rev1.m` | 5 of 5 | 5 of 5 |
| Puerto Rico and USVI | `init_shipping_zone_prusvi_rev1.m` | 5 of 5 | 6 of 6 |
| Alaska | `init_shipping_zone_alaska_rev1.m` | 5 of 5 | 6 of 6 |

The key run-log lines are the AIS source cells, port-approach cells, fairway
cells, satellite (extra) cells, and the land in each zone. Every one matched.

## Known-answer test

A synthetic day with ten made-up ships and hand-computed cells
(`python/test_known_answer.py`, `check_known_answer_rev1.m`,
`tests/known_answer/`) gives an exact match in both pipelines: 37 lower-48
pairs and 2 Alaska pairs, including grid-edge reports and the report west of
180 degrees that must be dropped. The planted position jump is flagged.

## MATLAB test suite

18 of 18 tests pass with a two-worker pool (`outputs/2024_2025/viz_matlab/test_suite_run.log`).

## MATLAB and Python

Appendix A tables agree within one grid cell except two corridors
(`outputs/2024_2025/viz_matlab/compare_python.json`).
