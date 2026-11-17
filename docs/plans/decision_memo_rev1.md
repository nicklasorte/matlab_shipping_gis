# Decision memo: method choices for the large-ship routes and zones

DRAFT//PRE-DECISIONAL

Date: November 17, 2026. For: Nick LaSorte. Data: `outputs/decision_table_rev1.csv`,
`outputs/zone_population_rev1.csv`, `outputs/zone_population_pea_rev1.csv`, and the
run logs in `outputs/rerun_logs_20261117/`. Plan: `docs/plans/next_steps_rev2.md`.

Nick asked on November 17 to apply the recommendations in the phase 2 plan.
This memo records each decision, what the runs showed, and what the paper now
says. Every choice is reversible: each option has its own run and zone files.
The EMC section (decision D5) is on hold at Nick's request.

## Summary

| ID | Decision | Applied | Effect on the zones (25 / 50 / 100 km) |
| --- | --- | --- | --- |
| D2 | Alaska satellite hexagons | Keep only the 290 beyond 74 km | Land 90,926 / 181,074 / 319,271 km², against 112,426 / 210,895 / 354,593 with all 400; people in the 25 km zone 438,787 against 481,884 |
| D7 | Tug-barge rule | Keep in the base; report the run without it | Without it: land -10% / -4% / -2%; 2.2 million fewer people at 25 km |
| D8 | Great Lakes | Report as a separate layer | Routes outside the Great Lakes give 227,267 / 469,257 / 921,475 km²; the Great Lakes add the rest of the base land (24% / 27% / 27%) |
| D9 | Population | Report people next to land | Lower 48: 100.3 / 138.8 / 175.9 million (30% / 42% / 53%) |
| D10 | Ships at the berth and at anchor | Decide after the underway-only run | See D10 below |
| D11 | Western Aleutians | Add as a separate grid, 172 E to 180 | See D11 below |
| D5 | Section 2, inputs for the EMC analysis | On hold | None |

## D2: Alaska satellite hexagons

- **Question.** The 400 satellite hexagons at or above the cutoff include 110
  within 74 km of shore, where the paper takes ship tracks as complete. Keep
  them or not?
- **What the runs show.** The 110 near-shore hexagons supply almost all of the
  satellite lanes' effect on land. Without any satellite lanes, the land is
  90,923 / 181,070 / 317,670 km², within 4 km² of the 290-hexagon base at 25
  and 50 km.
- **For keeping all 400.** Larger zones, the more protective reading. A
  calibration match of 0.57 near shore says the tracks may miss traffic there.
- **For keeping only 290.** It's what the satellite lanes are for: lanes the
  shore receivers miss. Keeping the 110 adds land where the paper says it has
  complete data, which an opposing filer would attack.
- **Applied:** 290. The paper reports the 400-hexagon result as the protective
  alternative (Section 5.3).

## D7: Tug-barge rule

- **Question.** Towing vessels report the length of the whole tow, so the 100 m
  test admits them; does that belong in the base?
- **What the runs show.** No U.S.-flag towing vessel in the kept set that PSIX
  matches by name is 3,000 GT or more (0 of 164; median 497 GT), so the rule has
  no SOLAS carriage basis. Without it, the land falls 10% / 4% / 2% and the
  25 km zone holds 98.0 million people instead of 100.3 million.
- **For keeping it.** Ocean tug-barges are large, carry marine radar under
  33 CFR 164.72, and sail the same coastal lanes; some may carry S-band.
- **For dropping it.** No carriage rule supports it, and it is the single
  largest choice in the 25 km zone.
- **Applied:** kept in the base, with the no-tug-barge result printed next to
  it (Section 1.5 and Table 9). Moving it out of the base waits on the EMC
  team's view of what towing vessels transmit.

## D8: Great Lakes

- **Question.** SOLAS leaves out ships that sail only on the Great Lakes, so the
  paper's carriage assumption has no rule behind it there. How should the zones
  show that?
- **What the runs show.** The Great Lakes and St. Lawrence routes account for
  about a quarter of the lower-48 zone land and 15% of its people at 25 km
  (100.3 million in the base against 84.9 million without them).
- **Applied:** the paper reports the lower-48 zones in two layers, routes
  outside the Great Lakes and the Great Lakes layer, with the combined zones as
  the total (Section 3, Table 9). The zone files keep the combined zones; the
  Great Lakes layer has its own files.

## D9: Population

- **Applied:** population next to land in Sections 3 to 6, from 2020 Census
  block-group centers of population. Python and MATLAB agree on all 12 base
  rows. By license area, the 25 km zone reaches 85 of the 412 Partial
  Economic Areas (PEAs) and covers more than half the people in 44; at 100 km,
  131 and 92 (`outputs/zone_population_pea_rev1.csv`).

## D10: Ships at the berth and at anchor

Pending the underway-only run (reports over 3 knots). See the decision table
when the run finishes.

## D11: Western Aleutians

Pending the 172 E to 180 run. See the decision table when the run finishes.

## Checks

- The 100 km boundary fix (R0) left every 25 km and 50 km land area unchanged
  to the km² and raised the 100 km land by 0.27% in the lower 48 and Alaska.
- The both-years run found 336,367 route cells against 336,369 in Appendix A.6
  (the known two-cell difference between the MATLAB and Python readers).
- Nick decides; this memo records the recommendations he asked to apply.
