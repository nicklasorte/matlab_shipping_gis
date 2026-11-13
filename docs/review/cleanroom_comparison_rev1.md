# Clean-room pairs compared with the repo caches

DRAFT//PRE-DECISIONAL

The clean-room agent (`agent_cleanroom.md`) built (cell, MMSI) pairs from the
paper's text alone. Its pairs include tug-barges, so they're compared here with
the repo's day caches for the main filter plus the tug-barge filter (before the
25 km coastline rule), on the same four days.

| Day | Clean-room pairs | Repo pairs (main + tug-barge) | In both | Only clean-room | Only repo | Agreement |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 2024-01-03 | 195,951 | 195,952 | 195,865 | 86 | 87 | 99.96% |
| 2024-07-10 | 299,316 | 299,294 | 299,148 | 168 | 146 | 99.94% |
| 2025-01-08 | 174,638 | 174,633 | 174,561 | 77 | 72 | 99.96% |
| 2025-07-09 | 267,415 | 267,393 | 267,305 | 110 | 88 | 99.95% |

Agreement is pairs in both divided by pairs in either. The differences are
reports on cell boundaries, where the clean-room program's rounding differs
from the repo's (the paper doesn't state the rounding rule; see the gaps in
`agent_cleanroom.md`).

The paper's figure of 166,382 pairs on 2024-01-03 (Section 1.6) doesn't match
either program: the repo's main-filter cache for that day holds 176,087 pairs
(195,952 with tug-barges). The number in Section 1.6 is stale and should be
updated, with the pair file defined.

Computed by comparing `/tmp/agent_scratch/cleanroom/pairs_<day>.npz` with
`data/ais_cells_<day>_*` (main and towing filters, lower-48 grid), November 12,
2026.
