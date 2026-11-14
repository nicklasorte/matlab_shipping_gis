# Next steps: 2.7 GHz large-ship routes and zones

DRAFT//PRE-DECISIONAL

Date: November 14, 2026. Repo state: main at `e53425e`; paper at doc revision 394
(`docs/2.7GHz_Routes_and_Zones_Sections_DRAFT.docx`). Public and cleared sources
only.

This plan lists every item still open in the three review records
(`docs/review/findings_rev1.md`, `docs/review/round2/findings_r2.md`,
`docs/review/round3/findings_r3.md`) and the data plan
(`docs/plans/ship_data_sources_plan_rev1.md`), and adds the work the paper needs
to feed its real purpose: the EMC analysis that sets each frequency range's
zone distance (Section 2, still a placeholder). Each step names an owner, its
inputs and outputs, a check that doesn't rely on the model grading itself, and
a rough effort.

Owners:

- **Cloud:** Claude in the cloud session, using the repo.
- **Mac:** Claude on Nick's Mac (MATLAB R2025b and the AIS downloads), with the
  Mac linked.
- **Nick:** Nick's judgment, review, or access.

## Where things stand

- Routes and zones are built and reviewed for all four regions. Land areas
  haven't changed through three review rounds and two reruns.
- Zone water is clipped at an equidistance line within 200 nautical miles; high
  seas stay in the zones.
- A radar model list (36 models) and a research-ship truth set (18 ships) exist.
  All nine S-band research ships are dropped by the 100 m length test alone,
  and 93% of their underway reports fall inside the 25 km zones.
- Every distance in Sections 3 to 6 is still an example. No EMC result supports
  25, 50, or 100 km yet.

## Decisions for Nick

These block or shape later steps. Each has a recommendation; none is applied
without Nick's answer.

| ID | Decision | Options | Recommendation and why |
| --- | --- | --- | --- |
| D1 | Gulf naming (R3OPP-10) | (a) "Gulf of America" for the U.S. part, per Executive Order 14172 and NOAA charts; (b) keep "Gulf of Mexico" | (a), with treaty names left as written. An interagency reader will flag (b). One edit pass. |
| D2 | Satellite hexagons inside shore-receiver range (R3OPP-1) | (a) keep all 400; (b) keep only the 290 beyond 74 km | Decide after step P8 shows the land change. (b) matches the paper's stated purpose (fill lanes the receivers miss); (a) is more conservative for protection. |
| D3 | Boundary for the water clip (R2MET-1) | (a) keep equidistance (option 2, now applied); (b) NOAA maritime limits plus the U.S.–Canada line in the Great Lakes (option 3) | (a) for the working paper. Move to (b) only if a NOAA or State reviewer will see the zone files; it needs a new input layer and a rerun (step P10). |
| D4 | Band-named zone files (R2OPP-7) | (a) keep `..._band_2900-3000MHz_25km`; (b) rename to distance only until the EMC analysis sets the pairs | (b) if the files will circulate outside the team, because the names read as results. |
| D5 | Scope of Section 2 (CB-26) | (a) leave a placeholder; (b) add an "inputs the EMC analysis needs" section from this repo (workstream E) | (b). It turns the paper's open end into a specified handoff. |
| D6 | Carriage rate (plan A3) | (a) run the photo coding (needs two human coders); (b) state the S-band share as an assumption, as now | (a) if Section 1.1 must defend the "every ship of 3,000 GT or more carries one" assumption; otherwise (b). |

## Status, November 14, 2026 (after running P1 to P10 and C1 to C7)

Decisions applied on the recommendations, all reversible, pending Nick's read:

- **D1 (a)** applied: "Gulf of America" for the U.S. part (doc rev 395).
- **D2** open. P8 shows that the 110 near-shore hexagons supply almost all of
  the satellite lanes' effect on land: with only the 290 beyond 74 km, Alaska
  land is 90,926 / 181,074 / 318,352 km², within 4 km² of no satellite lanes
  at 25 and 50 km. Recommendation now leans (b), since (a) adds land where the
  paper calls ship tracks complete; (a) stays in the paper until Nick decides.
  Both readings are in 5.3.
- **D3 (a)** kept: equidistance. P10 skipped.
- **D4 (a)** kept: file names unchanged.
- **D5** not applied (workstream E waits for Nick).
- **D6 (a)** prepared: sample drawn; coding needs two human coders.

| Step | Result |
| --- | --- |
| P2 | Done (rev 395). |
| P3 | 34 style suggestions laid in the doc for R2STY-6 to 8, 12 to 15, 17, 18, 20 to 23, 25, plus 4 from round four. Not suggestible (image alt text and the byline chips) were fixed as plain edits or left for Nick: byline date chip. |
| P4 | Done: Figure A-18 labels use head-port distance; A.3 range names the program (rev 398). |
| P5 | Done: the 2025 funnel equals the cached counts (1,101,052 reports, 2,017 ships; inside grid 1,059,711 and 1,886). 761 towing ships after the length step is now sourced (`ais_filter_by_type.csv`, both days). "15 inland river ports" and "166,382 pairs" dropped. |
| P6 | Done: shares use the simplified Census polygon in each grid (lower 48 7,804,530; Hawaii 16,725; Puerto Rico and USVI 9,278; Alaska 1,520,713 km²). No share exceeds 100%. Hawaii 50 km changed from 85% to 84%; Figure 6 replaced. |
| P7 | Done in rev 396 (the 0.23 Spearman figure is Alaska's, in 5.3; Hawaii held-out capture is in 4.2). |
| P8 | Done: cutoff sweep flat from 272 to 300 (Jaccard 0.571 to 0.573), 0.45 by 650; beyond-range run as above; added to 5.3. |
| P9 | Done: four blind agents, 72 findings; `docs/review/round4/findings_r4.md`. Open items listed there. |
| P10 | Skipped (D3 a). |
| C1 | Done: `data/kept_ships_2024_2025.csv`, 16,085 ships (equals the cache count); photo frame of 15,110 ships with a valid IMO number. |
| C2 | Done: 300-ship sample, 60 double-coded (seed 20261114). Sheets are on the Mac in `ship_rerun_pack/photo_sample/`, not in the public repo, so coders stay blind. |
| C3 | Waiting for two human coders. |
| C4 | Estimator written and tested (`python/sband_carriage_rate.py`, `sband_carriage_rate_rev1.m`; Python and MATLAB agree to 5e-5); `docs/review/sband_carriage_rev1.md`. Runs once C3 is coded. |
| C5 | PSIX is reachable through its public SOAP service; `python/psix_gt_kept_ships.py` looks up the 789 U.S.-flag kept ships by call sign (`data/psix_gt_kept_ships.csv`). |
| C6 | Blocked: no reachable public page names the radar band for Rainier, Pisces, Nancy Foster, or Hugh R. Sharp (archived NOAA spec pages don't render; current pages omit radar). Corps dredge list still needs Nick's download. |
| C7 | Coast Guard equipment list reached through CGMIX: its 472 mutual-recognition entries hold no radars, so it can't close the model list. EU MED database, Furuno NXT/SSD, and Wärtsilä still need Nick's downloads. |

## Workstream P: finish the paper

| ID | Step | Owner | Inputs | Outputs | Check | Effort |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | Human read of the paper; answer D1 to D6 | Nick | Doc rev 394; this plan | Decisions recorded here | None (human judgment) | 2–3 h |
| P2 | Apply D1 (Gulf naming) and any wording Nick marks | Cloud | P1 | Doc edits; Word copy | Search the doc for every remaining "Gulf of Mexico" outside treaty names | 30 min |
| P3 | Style pass left for Nick: R2STY-4 to 8, 12 to 15, 17, 18, 20 to 23, 25 (alt-text takeaways, byline and table dates, Section 5 intro, splits, acronyms, long sentences, headings, voice) | Cloud drafts as suggestions; Nick accepts | Doc | Suggestions in the doc | Nick accepts or rejects each | 2 h + Nick's review |
| P4 | Figure-level items R2NUM-11 (A.3 range: say which program) and R2NUM-12 (Figure A-18 Mississippi label: head-port distance) | Cloud | `viz/` outputs; `python/ship_corridor_figures.py` | Fixed figure and text | View the regenerated figure | 1 h |
| P5 | R2NUM-6: log the 2025 funnel-to-cache match (2025-07-09) and source or drop 761 towboats, 15 river ports, 166,382 pairs | Mac | One raw 2025 day; `init_filter_funnel_rev1.m` | Funnel log; paper edits | Funnel counts equal the cached counts | 1 h |
| P6 | R2MET-6: use one polygon treatment for land-share numerator and denominator (Puerto Rico 9,278 of 9,275) | Cloud | `census_land_in_grid_rev1.json` method | Shares from one land layer; paper edits | No share above 100% | 1 h |
| P7 | R2OPP-13: add Hawaii's Spearman 0.231 against NOAA transit counts and the Kapsar caveat to 4.2 | Cloud | `outputs/2024_2025/hawaii/` | Doc edit | Number matches its output file | 20 min |
| P8 | R3OPP-11 and D2: test satellite cutoffs 300 to 600 days in steps of 50, and the run without the 110 near-shore hexagons | Cloud (cutoffs, Python); Mac (zone runs) | `python/alaska_satellite_lanes.py`; Kapsar hexagons | Jaccard curve; Alaska land for each run | Base run reproduces 112,426 / 210,895 / 353,639 km² | 2 h |
| P9 | Round-four review on the full paper, not just changes: numbers, method, style and Section 508, and an opposing reader | Cloud (four blind agents) | Doc after P2 to P8 | `docs/review/round4/` with dispositions | Every finding fixed or dispositioned | 3 h |
| P10 | If D3 is (b): clip to NOAA maritime limits and the Great Lakes boundary | Cloud and Mac | NOAA Office of Coast Survey maritime limits (check license and date); International Boundary Commission line | New clip input; rerun of four regions | Land unchanged; water removed within 1% of the boundary | 1 day |

## Workstream C: carriage evidence (who carries S-band)

| ID | Step | Owner | Inputs | Outputs | Check | Effort |
| --- | --- | --- | --- | --- | --- | --- |
| C1 | Build the kept-ship list (IMO, MMSI, name, type group) for 2024–2025. The day caches hold only cell and MMSI pairs, so stream the 104 days again with the length prefilter and keep one row per kept ship | Mac | `ais_prefilter.py`; `ais_vessel_list_rev1.m` | `data/kept_ships_2024_2025.csv` | Ship count equals the distinct MMSI count in the caches | 1 h |
| C2 | Draw the photo sample and hand out sheets (if D6 is a) | Cloud | C1; `python/photo_sample_draw_rev1.py` | `coder_a.csv`, `coder_b.csv`, `key.csv` | Group quotas met; tests pass | 15 min |
| C3 | Code about 300 ships from public photos, 20% double-coded | Nick (two coders) | C2; `docs/protocols/photo_coding_protocol_rev1.md` | Filled sheets | Cohen's kappa of at least 0.7; planted research ships coded S | 2–3 days of coder time |
| C4 | Estimate the carriage rate by group (Wilson intervals, unclear-code bounds) and update 1.1 and 1.10 | Cloud | C3 | `python/sband_carriage_rate.py`, `sband_carriage_rate_rev1.m`, `docs/review/sband_carriage_rev1.md` | Python and MATLAB agree | 2 h |
| C5 | Coast Guard PSIX gross tonnage for U.S.-flag kept ships (plan A6); rerun the length-proxy check with it | Cloud (if the export is reachable) or Nick (download) | PSIX XLSX export | `data/psix_gt_kept_ships.csv`; updated Figure 2 numbers | Spot-check 10 ships against PSIX pages | 2 h |
| C6 | Extend the truth set: Rainier, Pisces, Nancy Foster, Hugh R. Sharp, and Corps hopper dredges | Cloud (pages); Nick (Corps list download) | Operator handbooks | More rows in `data/sband_truth_ships.csv`; rerun the AIS match | Each row quotes its source | 2 h |
| C7 | Close the radar model list: Coast Guard and EU equipment-approval lists, Furuno NXT and SSD frequencies, Wärtsilä power | Nick (downloads blocked here) then Cloud | Approval-list exports; Furuno brochures | Updated `data/ship_radar_models.csv` | Every model on the approval lists for S-band appears in the CSV | 2 h |

## Workstream E: inputs the EMC analysis needs (if D5 is b)

The routes say where ships go. An aggregate interference analysis also needs
how many ships radiate at once, for how long, from what height, and with what
emission. This workstream builds those inputs from public data, so Section 2
can state them.

| ID | Step | Owner | Inputs | Outputs | Check | Effort |
| --- | --- | --- | --- | --- | --- | --- |
| E1 | Agree the input list with Nick: per-cell ship-hours, peak simultaneous ships within a radius of a test point, dwell time near ports, antenna height, radar emission classes | Nick and Cloud | Section 3 text; Nick's EMC method | Input spec in this plan | Nick signs off | 1 h |
| E2 | Compute ship-hours per cell and the distribution of simultaneous large ships within 50 and 100 km of sample sites, streaming the 104 days (one report a minute gives time directly) | Mac | Daily AIS files; kept-ship filter | `outputs/2024_2025/ship_hours_rev1.*`; simultaneity CDFs per site | Ship counts per cell match the route caches; hours bounded by 24 per ship per day | 3 h |
| E3 | Radar emission classes for the analysis: magnetron (30–60 kW, about 0.07% duty) and solid-state (200–250 W, about 2% duty), beam, rotation, and sidelobes, from `data/ship_radar_models.csv` and ITU-R M.1460 | Cloud | Radar CSV | `docs/review/emc_radar_inputs_rev1.md` with value ranges and sources | Every value traces to a cited row | 2 h |
| E4 | Antenna height: a public basis for ship radar mast height by ship type and size (IMO 15 m reference height, photo sample, published ship drawings) | Cloud; C3 coders can record it | MSC.192(79); photos | Height distribution or a bounded assumption | Sources cited; sensitivity range stated | 2 h |
| E5 | Draft a new Section 2 opening, "Inputs for the EMC analysis", from E2 to E4, leaving the interference result to the EMC team | Cloud | E2 to E4 | Doc section | Round-four review covers it | 2 h |

## Workstream Q: keep the record reproducible

| ID | Step | Owner | Check |
| --- | --- | --- | --- |
| Q1 | Run the full MATLAB test suite (`test_shipping_zone_rev1.m`, `test_water_clip_rev1.m`) and the Python tests on the Mac after every code change | Mac | All tests pass |
| Q2 | Keep the Mac clone (`~/github-runs/matlab_shipping_gis`) in step with main by downloading changed files at a commit hash; `git pull` hung there twice | Mac | File content check after each download |
| Q3 | Archive the sources that block direct fetches (fcc.report, Kongsberg, ManualsLib, Radio Holland, researchvessels.org): record the access date and a content hash in the CSV notes, not the files | Cloud | Each cited row has a date |

## Sequence

1. **Now:** P1 (Nick). In parallel, P4, P6, P7 (cloud) and C1, P5 (Mac), which need no decisions.
2. **After P1:** P2, P3, P8, and C2 or E1 depending on D5 and D6.
3. **Then:** E2 to E5 and C3 to C5 in parallel; C6 and C7 when downloads arrive.
4. **Before circulation:** P9 (round-four review), then the Word copy, then Nick's sign-off.

## Risks

- **Mac availability:** P5, P8, C1, and E2 need the Mac awake with the Claude app running.
- **Coder time:** C3 is the only step that can't be automated; without it, the S-band share stays an assumption.
- **Scope creep in workstream E:** it supplies inputs, not an interference result. The EMC analysis itself stays with Nick's team.
- **Boundary scrutiny:** if the zone files go to NOAA or State, D3 option (b) moves from optional to required.
