# Clean-room test of the large-ship filter

**DRAFT//PRE-DECISIONAL**

This report tests whether Sections 1.2 to 1.5 of the draft paper, `paper_under_review.md`, describe the method fully enough to rebuild it. The test used only the paper's text. No repository code or output was read.

## Summary

- The paper's four filter tests can be reproduced from the text. On both days in Table 1, the clean-room program matches every report count and ship count exactly, at every step.
- The grid can't be fully rebuilt from the text. The paper doesn't say how a position maps to a cell, how cells are numbered, or which grid edges are inside. These choices move pair counts by up to 0.2%.
- The paper's one published pair count doesn't reproduce. Section 1.6 reports 166,382 cell and ship pairs on 2024-01-03. The clean-room program gets 195,951, which is 18% more. No choice tested explains the difference (see [Unresolved difference](#unresolved-difference)).

## Method

The program, `/tmp/agent_scratch/cleanroom/cleanroom_pairs.py`, does the following steps:

1. It reads one MarineCadastre day file (`ais-<YYYY-MM-DD>.csv.zst`) in chunks of 1 million rows. It uses six fields: `mmsi`, `latitude`, `longitude`, `imo`, `vessel_type`, and `length`. Peak memory was about 670 MB.
1. It applies the four Section 1.4 tests to each report: ship type, length of 100 m or more, IMO number, and location in the grid.
1. It maps each report it keeps to a 0.01-degree cell and saves the distinct (cell, MMSI) pairs.

The output for each day is `/tmp/agent_scratch/cleanroom/pairs_<day>.npz`. It holds `lat_row` (0-based row from 22° N), `lon_col` (0-based column from 130° W), and `mmsi`. `summary_<day>.json` holds the step counts and the results of the sensitivity runs.

## Gaps in the paper's description

| # | Gap | Choice made | Effect on pairs, 2024-07-10 |
| --- | --- | --- | --- |
| 1 | "Carries an IMO number" isn't defined: non-empty, non-zero, or a valid check digit. | Any non-empty `imo` field passes. | Check digit required: -1.2%. Non-zero required: no change. |
| 2 | Missing length isn't covered. Test per report or per ship isn't stated. | Per report. A blank length fails. | None. Table 1 matches. |
| 3 | The type ranges don't say whether they include both ends. | 0, 31, 32, 33, 35, 52, 55, and 60–99, both ends included. | None. Table 1 matches. |
| 4 | It's unstated whether a blank ship type counts as unknown (0). | A blank type fails. | Blank counted as unknown: +0.2%. |
| 5 | The paper doesn't say how a position maps to a cell or how cells are numbered. | row = floor((lat - 22) / 0.01), col = floor((lon + 130) / 0.01). The grid is 2,800 by 6,400, with a small offset to absorb floating-point error. | Cells centered on the 0.01-degree lines instead: -0.2%. |
| 6 | The grid edges' inclusion isn't stated. The paper writes west longitudes as positive; the file stores them as negative. | 22 <= lat < 50 and -130 <= lon < -66. | Edges counted as inside: no change. |
| 7 | It's unstated whether military and law enforcement ships also need 100 m. | They need the length and type tests. They skip only the IMO test. | None. Table 1 matches. |
| 8 | For the lower 48, the paper doesn't cover invalid MMSI, position, or speed, or duplicate reports. | No MMSI or speed checks. Bad positions fail the grid test. Duplicates collapse. | None found in the four files. |
| 9 | It's unstated whether daily pairs apply the Section 1.5 tug-barge rule. | Not applied. Daily pairs keep every ship that passes Section 1.4. | Towing ships give 21,757 pairs (7.3%). |
| 10 | The day boundary isn't stated. | One published file is one day. | Not tested. |

The full list, with notes, is in `/tmp/agent_scratch/cleanroom/gaps.md`.

## Results

| Day | Distinct cells | Distinct ships | Pairs |
| --- | --- | --- | --- |
| 2024-01-03 | 115,256 | 1,722 | 195,951 |
| 2024-07-10 | 211,635 | 1,980 | 299,316 |
| 2025-01-08 | 108,629 | 1,741 | 174,638 |
| 2025-07-09 | 179,260 | 1,886 | 267,415 |

### Check against Table 1

The clean-room step counts equal Table 1 at every step on both days:

| Step | Reports, 2024-07-10 | Ships, 2024-07-10 | Reports, 2025-07-09 | Ships, 2025-07-09 |
| --- | --- | --- | --- | --- |
| All reports | 9,626,350 | 22,414 | 9,186,207 | 23,548 |
| Ship type kept | 5,670,287 | 8,295 | 5,022,885 | 8,214 |
| and length 100 m or more | 1,884,907 | 2,754 | 1,580,824 | 2,583 |
| and IMO number (or military or law enforcement) | 1,347,288 | 2,184 | 1,101,052 | 2,017 |
| and inside the analysis grid | 1,237,989 | 1,980 | 1,059,711 | 1,886 |

Because these counts match, the Section 1.4 text is enough to rebuild the report filter.

### Unresolved difference

Section 1.6 reports 166,382 cell and ship pairs on 2024-01-03. The clean-room count is 195,951. The difference is too big for the grid choices, which change counts by 0.2% or less. The difference is also too big for the tug-barge rule: removing every towing pair still leaves 176,084. The paper doesn't define "cell and ship pairs" closely enough to find the cause. Possible causes include the following:

- The pairs were built on a different grid.
- Another rule removed reports before the pairs were built.
- The file was a different version.

We recommend that the paper define the daily pair file in Section 1.5 or 1.6, so that a reader can rebuild the 166,382 figure.

### Other notes

- Section 1.4 says that about 1 ship in 12 passed all four tests. Appendix A.7 says about 1 in 11. The data give 1,980 of 22,414 ships, which is 1 in 11.3.
- In the 2024 and 2025 files, `length` is blank in about 2% to 4% of reports. `vessel_type` is blank in about 0.5% to 1.4%. The paper doesn't mention either.
