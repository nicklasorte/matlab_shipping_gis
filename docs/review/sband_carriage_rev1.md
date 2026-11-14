# S-band carriage rate: estimator and status (plan step C4)

DRAFT//PRE-DECISIONAL

Date: November 14, 2026.

## Why

Section 1.1 assumes every ship of 3,000 GT or more carries an S-band radar.
SOLAS Chapter V, Regulation 19 lets a second 9 GHz radar stand in for it where
the flag state allows, and no public source gives the share that carry S-band.
The photo coding (`docs/protocols/photo_coding_protocol_rev1.md`) measures that
share for the kept ships.

## Status

| Step | State |
| --- | --- |
| C1 kept-ship list | Built from 104 streamed days; see `data/kept_ships_2024_2025.csv` and the photo frame `data/kept_ships_photo_frame.csv` |
| C2 sample draw | Drawn with `python/photo_sample_draw_rev1.py` (seed 20261114); sheets are kept outside the repo so the coders stay blind |
| C3 coding | **Not started: needs two human coders.** About 300 ships, 20% double-coded |
| C4 estimator | Written and tested on synthetic sheets; waits for C3 |

## Estimator

`python/sband_carriage_rate.py` and its MATLAB twin `sband_carriage_rate_rev1.m`
follow the protocol's "Estimate" steps:

1. Rate by group (cargo, tanker, passenger, other) = ships coded `S` over coded
   ships with a usable photo that aren't `unclear`, with a 95% Wilson interval.
2. Bounds: the rate if every `unclear` ship is `S`, and if none is (both over
   all ships with a photo).
3. Overall rate: each group weighted by its share of the kept ships. Its
   interval combines the group variances with a normal approximation, because
   the Wilson interval has no standard stratified form.

Checks reported with the estimate: Cohen's kappa on the double-coded overlap
(the protocol requires at least 0.7), raw agreement, and the planted research
ships coded `S`. Coder A's codes give the estimate; coder B's are used only for
agreement.

## Tests

- `python/test_sband_carriage_rate.py` (5 tests, all pass): Wilson reference
  values (50 of 100 gives 0.4038 to 0.5962; 0 of 10 gives 0 to 0.2775), a kappa
  reference case (0.40), a hand check of every group rate and the weighted
  overall rate on a synthetic 300-ship sample, and stops on unknown codes and
  missing key rows.
- Python against MATLAB on the same synthetic sheets
  (`python/testdata/carriage/`): every column agrees to within 4.8e-5, the
  rounding of the 4-decimal Python file; kappa 0.904 in both; planted ships 4
  of 5 coded `S` in both.

## What the result will change

If the estimate is well below 100%, Section 1.1 should state the measured rate
with its interval, and the EMC analysis should scale aggregate S-band emitters
by it. The routes themselves don't change: they show where the ships go, not
which radar they run.
