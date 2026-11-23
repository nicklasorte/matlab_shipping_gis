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
    results, D8 Great Lakes layer reported, D9 population (later dropped), D10 kept
    ships at anchor and at the berth (under-way-only run 2% / 1% / 1% less
    land), D11 closed (no 2018–2019 reports west of 180°).
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
| D9 | Report population as well as land | Run R1 | Reversed by Nick on November 20: the paper reports land only; population and PEA coverage are removed |
| D10 | Ships at the berth and at anchor: count as sources or not | Run R4 (done) | Applied: keep them; under-way-only zones are 2% / 1% / 1% smaller |
| D12 | Add large-ship sources in foreign water near U.S. land (St. Lawrence, Chatham Sound, Fundy)? | Plan `foreign_waterways_plan_rev1.md` (steps F1 to F7) | St. Lawrence: added to the lower-48 base (Nick, November 19). Chatham Sound and Fundy: open |
| D13 | Guam alone, or Guam and the Northern Mariana Islands as one region? | Plan `guam_plan_rev1.md` (steps G1 to G7) | Decided: one region, Guam and the Northern Mariana Islands (Nick, November 19) |
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
- Guam plan written (`docs/plans/guam_plan_rev1.md`); first step G1 needs the Mac.
- D13 decided: Guam and CNMI as one region. `init_shipping_zone_guam_rev1.m` written (grid 12 N to 21.5 N, 143.5 E to 147 E; ship-days rule pending G3; port positions for Apra, Tinian, and Rota marked TODO against the World Port Index) and added to the rerun batch.

## Status update, November 20 (rerun started; population dropped)

- Mac link restored. Clone synced to `fc2f4b2` (earlier edits: stash `mac_dirty_20261120`, patch `~/github-runs/mac_dirty_20261120.patch`; 13 untracked files moved to `~/github-runs/mac_untracked_20261120/`). MATLAB tests pass (26 passed, 2 filtered for no parallel pool; 3 water-clip tests pass); `checkcode` has one unused-variable message in `shipping_zone_rev1.m` (`num_cell`, left alone).
- `scripts/run_rerun_batch_rev1.sh` started at 06:59 AM on the Mac; logs in `outputs/rerun_logs_20261120/`.
- Nick: no population. D9 is reversed. The paper (rev 643) no longer reports people or PEA coverage: the Section 3 sentences, the three People columns and note of Table 8, and the people shares for Hawaii, Alaska, and Puerto Rico are removed. One sentence in the Section 1.10 carriage bullet (under-way-only run, "0.8 million fewer people") sits inside a pending suggestion and still needs the words removed. Population runs (R1) are no longer needed; The population scripts, CSVs, and Census inputs were deleted from the repo on November 20 (history stays in git).

## Status update, November 20 (rerun done, paper updated)

- Batch finished at 9:07 AM at commit `fc2f4b2`; logs in `outputs/rerun_logs_20261120/`, decision table rebuilt (`d99f232`, land only).
- Lower-48 base with the St. Lawrence: 301,161 / 638,713 / 1,270,233 km² (25 / 50 / 100 km). `no_st_lawrence` reproduces the old 301,168 / 638,688 / 1,264,979. Hawaii, Puerto Rico and USVI, and Alaska (D2 base and sensitivity runs) match the paper exactly. New by-ship Great Lakes runs: `no_lakers` 274,252 / 593,462 / 1,225,522; `lakers_only` 73,547 / 171,755 / 357,185.
- Guam and CNMI: 531 / 647 / 647 km² of 1,019 km² in the grid; only Apra Harbor connects under the ship-days rule of 6 (Saipan, Tinian, Rota don't). Step G3 (route rule) is Nick's call.
- Paper (rev 655): Figure 4 image, Section 3 land figures, Table 8 (new numbers plus three new rows), Great Lakes layer wording (two boxes), and the St. Lawrence bullet updated. Population removed (see above).
- Still open: Section 1.10 carriage-bullet sentence (blocked by suggestion), Guam G1 in-grid counts and G3, remaining R5 items, Word copy rebuild, MATLAB twins of the St. Lawrence scripts.

## Status update, November 21 (regions rerun)

- Reran Guam, Hawaii, Puerto Rico and USVI, and Alaska (base plus `_all400`, `_nosat`, `_x0.5`, `_x2`) at commit `baea008` (clean). Logs: `outputs/rerun_logs_20261120_regions/`.
- Land matches the paper: Hawaii 14,132 / 16,717 km² (50 / 100 km); Puerto Rico and USVI 9,278 km²; Alaska 181,074 / 319,271 km² (50 / 100 km).
- Guam (new, D13): 531 / 647 / 647 km² at 25 / 50 / 100 km. Only 1 of 4 ports is reached; Saipan, Tinian and Rota have no route. The Guam route rule (G3) is still Nick's call.
- Population code, data and outputs are deleted (`baea008`); the paper reports land only.

## Status update, November 21 (Marianas, Figure 4 caption, Word copy)

- The sampled AIS days hold no Saipan or Tinian lane (5 and 0 cells within 15 km; Rota 116 cells, at most 5 ship-days), so no ship-days threshold connects the Northern Mariana Islands.
- Variant `cnmi_links=true` in `init_shipping_zone_guam_rev1.m` adds straight-line link cells Apra Harbor, Rota, Tinian, Saipan (`python/guam_cnmi_links.py`, 231 cells; a modeling assumption, not AIS). Run at `20ea349`: 4 of 4 ports connect; land in zone 872 km² at 25, 50 and 100 km (Guam only: 531 / 647 / 647). Log: `outputs/rerun_logs_20261121/guam_cnmi_links.log`.
- Open (Nick): accept the link-cell assumption for the paper (G3), confirm harbor positions against the NGA World Port Index (G2), and a MATLAB twin of `guam_cnmi_links.py`.
- Paper rev 659: Figure 4 caption notes the St. Lawrence cells. Word copy rebuilt from the rev 659 export (`docs/2.7GHz_Routes_and_Zones_Sections_DRAFT.docx`, Figure 4 new, 65 SEQ captions, 0 missing images).

## Status update, November 21 (Guam accepted, Section 7 written)

- Nick accepted the link cells (G3). Paper rev 660 adds Section 7, Guam and the Northern Mariana Islands (872 km² at 25, 50, and 100 km; 531 / 647 / 647 without the links), before Appendix A. No map yet (G6).
- Still open: G1 in-grid counts; G2 port positions against the NGA World Port Index; G5 held-out days; G6 map and the Python and MATLAB twins of the link-cell script; Guam and CNMI land split; Word copy rebuild for rev 660; blind review of Section 7 (G7).

- Nov 21 (later): Guam map `python/ship_guam_figures.py` -> `docs/viz_python/guam01_routes_zones.*` (Figure 11, paper rev 662). Grids for the map are in `outputs/guam/*.mat`. Still open: MATLAB twin of the map and of `guam_cnmi_links.py` (G6), Word copy for rev 662, blind review of Section 7 (G7).

## Status update, November 21 (round 6 review of Section 7)

- Blind review of Section 7 done (`docs/review/round6/findings_r6.md`); fixes applied (paper rev 671). Word copy rebuilt at rev 671.
- Open from round 6: threshold sensitivity (ship-days 3, 6, 12, with and without links), MATLAB twin of `guam_cnmi_links.py` and a Guam test, snap link ends to water, a carriage statement for Section 7, NGA World Port Index check, `init_shipping_zone_guam_rev1.m` header grid comment.

## Status update, November 21 (Guam sensitivity run)

- Ran Guam at 2, 3, 4, 6, 8 and 12 ship-days, with and without the links, at `b1333ed` (clean; `outputs/rerun_logs_20261121/guam_sensitivity/`, table in `outputs/guam/guam_sensitivity_rev1.csv`, `python/guam_sensitivity.py`). With the links, land is 872 km² at every threshold and distance; without them the 25 km zone is 474 to 847 km². Port check reads 0 of 4 at 8 and 12 ship-days (the route has under 2,000 cells and doesn't reach the grid edge).
- Paper rev 674: new Section 7.3 and Table 10 (Limits is now 7.4); Word copy rebuilt at rev 674.
- Open: comparison with the lower-48 rule and NOAA transit counts (G3), MATLAB twin of the link script, carriage statement, NGA World Port Index check.

## Status update, November 21 (Guam NOAA comparison)

- `python/guam_route_rules.py` compares the Guam ship-days rule (6) with NOAA AIS Vessel Transit Counts 2025 (the 2024 file stops at 174 W; thresholds K = 6 and T = 8 come from the lower-48 calibration on the 2024 file). Result in `outputs/guam/guam_route_rules_rev1.json`, log `outputs/rerun_logs_20261121/guam_route_rules.log`. Jaccard 0.22 (Hawaii 0.25); NOAA also has no Saipan or Tinian lane. Paper rev 676 (Section 7.3 and 7.4). Word copy not rebuilt since rev 674.
- Open: the lower-48 rule (4 ships in one year) can't be reproduced from the combined-years `unique_ships` grid; MATLAB twin of the link script and a Guam test; carriage statement; NGA World Port Index check; Word copy rebuild.

## Status update, November 21 (Guam land split)

- `python/guam_land_split.py` splits zone land at 13.9 N (total matches the stored area within 0.1 km2): with links Guam 562 / CNMI 310 km2 at 25, 50, and 100 km; without links Guam 531 / 562 / 562 and CNMI 0 / 85 / 85. Output `outputs/guam/guam_land_split_rev1.csv`, log `outputs/rerun_logs_20261121/guam_land_split.log`. Paper rev 679 (Section 7.2 split, 7.4 carriage pointer).
- NGA World Port Index not reachable from the cloud (msi.nga.mil returns 503); needs the Pub 150 CSV attached or run on the Mac.
- Python cross-check of zones needs the Census polygons and the MATLAB buffer method on the Mac; not done.

- Nov 21 (later): `guam_cnmi_links_rev1.m` (MATLAB twin) and `test_guam_links_rev1.m` pass on the Mac and match the Python CSV exactly (231 cells); `checkcode` clean. Paper rev 680. Mac clone merged to the latest main (old sensitivity logs moved to `~/github-runs/mac_logs_20261121_old/`).
- Still open: Python cross-check of zones, held-out days (G5) and G1 in-grid counts, NGA World Port Index check, snap link ends to water (needs rerun and Nick's OK), Word copy rebuild (last at rev 674), header grid comment in `init_shipping_zone_guam_rev1.m`.
- Nov 21 (later): Word copy rebuilt at paper rev 680 (67 SEQ captions, 0 missing images). Nick reviews before it leaves the repo.

## Status update, November 22 (EMC working paper started)

- New working paper (Claude Doc) "2.7 GHz study: NEXRAD and shipborne S-band radar EMC analysis": https://claude.ai/artifact/Dcc1nD6zP3u6KuDejA6B2d. Sections 1-4 and 6 written with public characteristics (NOAA ROC NEXRAD Technical Information; ITU-R M.1849-3; ITU-R M.1460-2). Results pending.
- Plan: `docs/plans/emc_nexrad_ship_plan_rev1.md` (steps E1-E10, MATLAB with matlab_itm area mode; Python twin of FDR and link budget). Decisions for Nick listed there.
- Nov 22: scope set by Nick: NEXRAD assumed to tune 3020-3080 MHz (co-channel with ship radars), ITM area mode only. Plan and paper updated.
- Nov 22: protection-level research done (paper Section 4): NEXRAD pulsed levels from M.1849-3 8.4.2 (+7.2 to +19.8 dB peak for magnetron ship radars, -6.0 to +0.2 dB for solid-state), ship radars -6 dB recommended with no effect to +30/+40 dB measured (M.1460-2 Annex 3). Outputs `outputs/emc/pulsed_in_criteria_rev1.csv`. Base-case choice is Nick's.
- Nov 22: main beam to main beam coupling decided. radar_in simulation run (Mac, code 6694e30, results 509f7a4): supports NEXRAD base +7.2 dB for magnetrons (sim +7.5 dB at the governing case); no ship-radar detection loss to +70 dB from NEXRAD pulses. Paper Section 4.4.
- Nov 22: EMC working paper copies committed under `docs/emc/` (Word and Markdown from doc rev 27), with `docs/emc/README.md` listing the plan, scripts, outputs, and simulation results; CLAUDE.md points to it.
- Nov 22 (evening): EMC co-channel distances done (paper Section 6, doc rev 32). Magnetron and solid-state ship radars as equal cases (Nick). Main beam to main beam, ITM area mode, 3050 MHz, 30 m antennas. 50% of time: ship into NEXRAD 382-606 km (magnetron), 639-872 km (solid state); NEXRAD into ship 840-1,003 km (magnetron), 889-1,125 km (solid state); up to 1,615 km at 0.1%. Code at 736171e, run log `outputs/rerun_logs_20261122/emc_cochannel.log`, matlab_itm a59880a. MATLAB/Python required loss agree to 0.01 dB. Open: ship radar base protection level (-6 dB used; +30 dB halves NEXRAD-into-ship distances) is Nick's call; frequency sweep (E2, E3) next; blind review (E10).
- Nov 22 (late): EMC frequency sweep done (paper Section 6.2, doc rev 40). FDR = OTR + OFR (SM.337-6); emission envelopes (trapezoidal pulse; FM flat with 20 dB/decade skirts) and selectivity (NEXRAD matched filter x ROC front-end points; ship 2-pole IF floored at 60 dB). Both protection levels kept for each victim (Nick): NEXRAD pulsed and -10 dB; ship -6 and +30 dB. At 60 MHz (widest offset in 3020-3080 MHz), 50% of time: magnetron into NEXRAD 91 km (pulsed) / 302 km (-10 dB); solid state into NEXRAD 465 / 564 km; NEXRAD into ship 533 / 166 km (magnetron, -6 / +30 dB) and 433 / 78 km (solid state). Code 8109a4e, log `outputs/rerun_logs_20261122/emc_offset.log`; MATLAB/Python OFR agree to 0.01 dB. Open: blind review (E10); solid-state emission skirts and ship IF skirts are assumptions that drive the large-offset distances.
