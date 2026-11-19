# Next steps, phase 2: 2.7 GHz large-ship routes and zones

DRAFT//PRE-DECISIONAL

Date: November 17, 2026. Repo state: main at `5b036b8`; paper at doc revision
520. Public and cleared sources only. This plan follows
`docs/plans/next_steps_rev1.md` (phase 1, steps P1 to P10 and C1 to C7, done
except where noted) and works alongside
`docs/plans/technical_review_plan_2026_11_14.md` (Nick's review plan, here
called workstream V).

## Where things stand

- Routes and zones are built for four regions and have passed four review
  rounds. Land areas didn't change on the November 14 rerun.
- Round four left 12 open items (`docs/review/round4/findings_r4.md`). Most are
  questions of the form "how much does choice X move the land?", and each
  needs one run.
- 38 style suggestions wait in the doc for Nick.
- New evidence since phase 1: none of 159 U.S.-flag towing vessels in the kept
  set is 3,000 GT or more (`docs/review/psix_gt_check_rev1.md`), and the 110
  near-shore satellite hexagons supply almost all of the satellite lanes'
  effect on Alaska land.
- Every distance is still an example. Section 2 (EMC analysis) is a
  placeholder.

## Status, November 17 (end of session)

Nick asked to run this plan (except Section 2, D5, on hold) and to apply the
recommendations. Decisions applied are recorded in
`docs/plans/decision_memo_rev1.md`; Nick can reverse any of them, since each
option has its own run and zone files.

- **Done.**
  - R0: 100 km boundary fix; lower 48 100 km land 1,264,979 km² (+0.27%);
    25 and 50 km unchanged in every region.
  - R1 to R4 and R8 runs, all in `outputs/rerun_logs_20261117/`, with zone
    files in `outputs/2024_2025/decision/` and the summary in
    `outputs/decision_table_rev1.csv`.
  - D2 applied (Alaska 90,926 / 181,074 / 319,271 km²), D7 kept with both
    results, D8 Great Lakes layer reported, D9 population reported, D10 kept
    ships at anchor and at the berth (under-way-only run 2% / 1% / 1% less
    land), D11 closed (no 2018–2019 reports west of 180°).
  - Population (`outputs/zone_population_rev1.csv`, Python and MATLAB agree on
    the base rows) and PEA coverage (`outputs/zone_population_pea_rev1.csv`).
  - T: `test_route_rules_rev1.m` and `python/test_route_rules.py`.
  - S: Appendix B (S-band equipment), receiver coverage (R7), PSIX carriage
    numbers (C8), population text, Alaska D2 text, Table 8 (decision table) in
    Section 3.1; the Hawaii table is now Table 9. Paper at doc revision 616.
  - V1 baseline manifest: `docs/review/round5/v1_baseline/`.
  - Round-four dispositions updated in `docs/review/round4/findings_r4.md`.
  - Word copy rebuilt from doc revision 616 with the regenerated share figures
    (A-35 to A-44).
- **Open.**
  - D5 (Section 2) on hold.
  - V2 claims ledger; V3 to V5 blind review of the frozen state.
  - Style items R4STY-18, 22, 23, 24, and 26; 38 style suggestions and the
    November 17 suggestions wait in the doc for Nick.
  - R4OPP-6 (reach from a satellite lane centerline), R4OPP-15 and 16 (Navy
    and VTS radar-site layers), R4MET-5 port-connectivity test.
  - The MATLAB twin of `decision_table.py` isn't written; the table only
    parses logs and the population CSV, which MATLAB already checks.
- **Round five (November 17, afternoon).** Four blind agents reviewed doc
  revision 616 (`docs/review/round5/`). Exact fixes went in at revisions 617
  to 629, including a deep-draft ports column in Table 8, the Great Lakes
  layer definition, and the PEA denominator. Dispositions, Nick's calls, and
  the open rerun and code list are in `docs/review/round5/findings_r5.md`.
- **Running.** Nothing.

## The goal of this phase

Turn the paper's open choices into a decision table: for each contested
method choice, one row with the land (and population) under each option, so
Nick can decide and an opposing filer finds the answer already printed. Then
freeze the method, run Nick's technical review (workstream V) on the frozen
state, and hand the EMC team a specified set of inputs.

## Decisions for Nick

| ID | Decision | What will inform it | Recommendation today |
| --- | --- | --- | --- |
| D2 | Alaska near-shore satellite hexagons: keep all 400 or only the 290 beyond 74 km | Done (5.3): 90,926 / 181,074 / 318,352 km² without them | Keep only the 290; it matches the stated purpose and the paper's premise |
| D5 | Section 2: placeholder or "inputs the EMC analysis needs" | Workstream E | Write the inputs section |
| D7 | Tug-barge rule: keep, drop, or keep as a labeled sensitivity | PSIX result; run R3 | Report both; make the no-tug-barge zones the base case only if the EMC team agrees tugs don't carry S-band |
| D8 | Great Lakes: in the base zones or a separately labeled layer | Run R2 | Separate layer, since no carriage rule supports it |
| D9 | Report population as well as land | Run R1 | Yes; land area alone invites attack from both sides |
| D10 | Ships at the berth and at anchor: count as sources or not | Run R4 (done) | Applied: keep them; under-way-only zones are 2% / 1% / 1% smaller |
| D12 | Add large-ship sources in foreign water near U.S. land (St. Lawrence, Chatham Sound, Fundy)? | Plan `foreign_waterways_plan_rev1.md` (steps F1 to F7) | St. Lawrence: added to the lower-48 base (Nick, November 19). Chatham Sound and Fundy: open |
| D11 | Extend Alaska west of 180° | Run R8 (done) | Closed: the 2018–2019 files hold no reports west of 180° |

D1, D3, D4, and D6 stand as recorded in the phase 1 plan.

## Workstream R: runs that answer round four

Each run writes a CSV row to one new file,
`outputs/decision_table_rev1.csv` (run, region, land at 25, 50, and 100 km,
change against the base, source log), and commits its log. MATLAB and Python
both, where a Python twin exists. Owner "Mac" means Claude Code on Nick's Mac
(MATLAB R2025b and the AIS files); "Cloud" means a cloud session.

| ID | Run | Finding | Owner | Outside check | Effort |
| --- | --- | --- | --- | --- | --- |
| R0 | Fix the 100 km distance field (compute a few cells past the largest zone distance), rerun all four regions | R4MET-1 | Mac | 25 and 50 km land unchanged to the km²; 100 km land rises by no more than about 0.5%; a known-answer test with one route cell gives a disk of radius 100 km within one cell | 2 h |
| R1 | Population in each zone, by region and distance, from 2020 Census block centroids | R4OPP-3 | Cloud | Zone population at "all land" equals the Census state totals in the grid; spot-check one county by hand | 3 h |
| R2 | Great Lakes share: zones from routes outside the Great Lakes only | R4OPP-2 | Mac | Lakes-only plus non-lakes land is at least the base land (overlap only where both reach) | 1 h |
| R3 | Tug-barge rule off, on current code (the 12% figure predates the clip and polygon areas) | R4OPP-1 | Mac | Route cells equal base minus the 9,130 tug-barge-only cells in A.5 | 30 min |
| R4 | Underway only: rebuild the day caches keeping reports over 3 knots, then routes and zones | R4OPP-4 | Mac | Cell and ship pairs are a subset of the base caches on every day | 3 h (streams 104 days) |
| R5 | Both-year cells only | R4OPP-7 | Mac | Route cells equal 336,369 (A.6) | 30 min |
| R6 | Satellite hexagons as centerlines: distance from hexagon centers, not edges | R4OPP-6 | Cloud (Python), Mac (zones) | Land is no larger than the base in every zone | 2 h |
| R7 | AIS source check: read the MarineCadastre 2024 and 2025 metadata for satellite or long-range sources; map reports by distance offshore per year | R4OPP-12 | Cloud | The metadata text is quoted with its URL and date; the offshore share matches A.2 | 1 h |
| R8 | Alaska on a 0–360° grid, 172° E to 129° W | R4OPP-13 | Mac | East of 180°, route cells and land equal the current run exactly | 4 h |
| R9 | Full-sample bias: zones from every other sampled day against all 104, extrapolated; and one full month of daily data for one coast as a direct test | R4OPP-9 | Mac | The half-sample result reproduces `docs/review/stability_rev1.csv` | 3 h |
| R10 | Jacksonville coast label in the port-share products; regenerate A.20 | R4NUM-6 | Cloud | Gulf share stays 48% after rounding | 30 min |

Order: R0 first, because every later run should use the fixed distance field.
Then R3, R5, R2 (cheap, same caches), then R1 and R7 in the cloud in parallel,
then R4, R6, R8, R9.

**Stop rule.** If R0 moves any 25 or 50 km land area, stop and find out why
before running anything else.

## Workstream T: tests before the method freezes

| ID | Step | Finding | Check |
| --- | --- | --- | --- |
| T1 | Unit tests for the port-approach rule, the tug-barge band, the per-year union, port connectivity, and satellite selection, in MATLAB (`test_route_rules_rev1.m`) and pytest | R4MET-5 | Each test uses a hand-built grid with a known answer; a deliberate one-line bug makes at least one test fail |
| T2 | Make pytest collect `python/test_known_answer.py`; run the funnel cross-check in code, not by hand | R4MET-14 | `python3 -m pytest -q python/` runs every test |
| T3 | Write the values the paper cites but no file holds: the 0.1 m median length difference, "half are 87–99 m", the A.6 speck shares, the head-port distance in `corridor_summary.csv` | R4NUM-11, 13, 14 | Each paper number greps to an output file |
| T4 | Update the README and remove or label archived 2023–2024 products that the review plan flags as stale | Review plan, "Repository context" | README period matches `period_rev1.m` |

## Workstream S: paper

| ID | Step | Owner |
| --- | --- | --- |
| S1 | Accept or reject the 38 pending suggestions; fix the byline date | Nick |
| S2 | Second style pass as suggestions: R4STY-8 and 10 to 26 (link text, the 87 long sentences, jargon, duplicate headings, table headers, Table 5 names, marking placement) | Cloud, then Nick |
| S3 | Add a decision table to Section 3 from `outputs/decision_table_rev1.csv`, and population next to land in Sections 3 to 6 if D9 is yes | Cloud |
| S4 | Apply D2, D7, D8, D10, and D11 once Nick decides; rerun, regenerate figures, rebuild the Word copy | Mac and Cloud |

## Workstream V: Nick's technical review plan

Run `technical_review_plan_2026_11_14.md` after R0 and T1 to T4, on a frozen
commit, so the claim-to-source table is built once. Its steps 1 and 2 (freeze
and inventory; claim-to-source traceability) can start now, because they don't
depend on the runs. Findings keep the existing ID scheme (R5...).

## Workstream E: inputs for the EMC analysis (if D5 is yes)

Unchanged from the phase 1 plan (E1 to E5), with two additions from this
phase:

- E2 uses the R4 underway split, so ship-hours come separately for ships
  moving and ships at the berth.
- E6: a one-page handoff listing, for each EMC input, the file, the units, the
  known bias, and the round-four finding that bounds it.

## Workstream C: carriage (carried over)

| ID | Step | Owner | State |
| --- | --- | --- | --- |
| C3 | Code 300 ships from photos, 60 double-coded | Nick (two coders) | Sheets in `ship_rerun_pack/photo_sample/` on the Mac |
| C4 | Run the estimator on the coded sheets | Cloud | Ready |
| C6, C7 | Truth-set and radar-model sources that are blocked from the cloud (archived NOAA specification pages, Corps dredge list, EU equipment database, Furuno and Wärtsilä documents) | Nick downloads; or try from Claude Code on the Mac, whose network may reach them | Blocked |
| C8 | Extend the PSIX tonnage check: look up the 126 unmatched and ambiguous U.S.-flag ships by name; rerun the Figure 2 length check against PSIX tonnage | Cloud | New |

## Sequence

1. **This week, no decisions needed:** R0, T1, T2 (Mac); R1, R7, R10, C8, V
   steps 1 and 2 (Cloud); S1 (Nick).
2. **Next:** R3, R5, R2, then R4, R6, R8, R9; T3, T4; S2.
3. **Decision meeting with the table in hand:** D2, D5, D7 to D11.
4. **Freeze:** S3, S4; workstream V on the frozen commit; round-five blind
   review of changes only; Word copy; Nick's sign-off.
5. **In parallel throughout:** C3 (coders), then C4; workstream E after D5.

## Checks on this plan

- Every open round-four finding maps to a step here (R4MET-1, 5; R4NUM-6, 11,
  13, 14; R4STY-8, 10 to 26; R4OPP-2, 3, 4, 6, 7, 9, 12, 13, 15, 16).
  R4OPP-15 and 16 (public Navy and Vessel Traffic Service radar-site layers)
  are deferred to workstream E, because they are EMC victims and sources, not
  ship routes.
- The reviewer's estimates quoted above (Great Lakes about a quarter of the
  land; both-year cells 6%, 6%, 3% smaller; the 100 km shortfall 0.3% to 0.5%)
  are estimates, not results. Runs R0, R2, and R5 replace them.
- Policy calls (D2, D5, D7 to D11) and anything that leaves the organization
  need Nick's review.

## Risks

- **Rerun churn:** five decisions could each trigger a rerun. S4 applies them
  in one pass after the decision meeting, not one at a time.
- **Mac time:** R4 and R9 stream AIS again (about 30 minutes per 104 days per
  pass, plus zone runs).
- **Scope:** R1 adds population but not auction value or household counts;
  those belong to the wider study.

## Status update, November 17 (rerun setup)

- Code for the round-five reruns is committed: commit stamp in every run log (`git_commit_stamp_rev1.m`), two-box Great Lakes mask reaching Montreal (`box_mask_rev1.m`), by-ship Great Lakes split (`ship_split_by_box_rev1.m`; `decision_variant` `lakers_only` and `no_lakers`), tests (MATLAB and Python twin `python/ship_split.py`). Python tests pass (15).
- Batch driver: `scripts/run_rerun_batch_rev1.sh` (base, all variants, Hawaii, Puerto Rico, Alaska five suffixes). Not yet run: the Mac did not answer on November 17. Still to add after the zone runs: foreign-water split, stress outputs to `outputs/`, GT check, sites check.
- Open: MATLAB tests and `checkcode` on the Mac; the Mac clone is behind and has modified tracked files that need checking before checkout.
- Note: the `no_great_lakes` and `great_lakes_only` variants now use the two-box constant, so Table 8 rows change on rerun.

## Status update, November 19 (foreign waterways)

- New plan `docs/plans/foreign_waterways_plan_rev1.md` (D12, steps F1 to F7) for ships in foreign water near U.S. land. Screen committed (`python/foreign_waterway_screen.py`, `outputs/foreign_waterways/`): the St. Lawrence below Sorel would add about 5,100 km² of Maine to the 100 km zone; Chatham Sound and Portland Canal about 2,300 km² to the Alaska 25 km zone; Fundy under 100 km².
- The rerun batch (November 17) has still not run; the Mac was unreachable.

## Status update, November 19 (St. Lawrence added)

- Nick: add the St. Lawrence data and show it on the lower-48 figure. `init_shipping_zone_rev1.m` now sets `p.extra_source_csv` to `outputs/foreign_waterways/st_lawrence_lower48_cells_rev1.csv` (12,403 DFO and World Bank cells inside the grid); `decision_variant='no_st_lawrence'` reproduces the old zones. Added to the rerun batch.
- Paper (rev 631): Figure 1 replaced with `docs/viz_python/fig01_routes_lower48_rev1.png` (`python/fig01_routes_lower48.py`, the whole route to Cabot Strait); caption, Section 1.10 bullet, and two Section 1.2 data rows added. Section 3, Table 8, Figure 4, and the land areas in CLAUDE.md change after the Mac rerun.
- To do: `python/decision_table.py` RUNS entry for `no_st_lawrence`; MATLAB twin of the St. Lawrence scripts; Word copy rebuild; intro sentence in Section 1 (blocked by a pending suggestion).
