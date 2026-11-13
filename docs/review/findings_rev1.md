# Review findings: 2.7 GHz large-ship routes and zones working paper

DRAFT//PRE-DECISIONAL

Date: November 12, 2026. Reviewed paper: `paper_under_review.md` (doc revision
132). Reviewed code: commit `2419e33` and later review commits on `main`.

This file summarizes the AI-agent review (stages 1 through 5 of
`docs/plans/review_plan_rev1.md`). The confirmed findings are in two tables:

- `findings_method_rev1.md`: method, data, and domain findings (CA-1 to CA-102).
- `findings_paper_rev1.md`: numbers, style, Section 508, data use, and outside
  totals (CB-1 to CB-86).

The fixes were applied on November 13, 2026, and every remaining item was
closed the same day; see "Fixes applied" and "Closing the open items" at the
end of this file.

## Summary

- **The pipeline reproduces.** A clean copy rerun on the Mac gives identical
  outputs in all four areas, a synthetic day with known answers is exact in both
  MATLAB and Python, and an agent that saw only the paper rebuilt the cell and
  ship pairs to within 0.06%. The method is documented well enough to rebuild.
- **But the routes are incomplete in one place that matters.** The lower-48
  charted-lane file is a stale 28-feature cache (NOAA's layer has 291), and a
  misspelled theme name drops every traffic separation scheme. With the live
  layer, about 11,900 charted-lane cells would be added, mostly in the Gulf, where
  the paper reports 1,099 (CA-1, CA-2). This changes routes and zones and should
  be fixed before anything else.
- **The zone definition needs a decision.** In shore mode, land in a D km zone
  can be up to D + 25 km from a route; foreign land counts as ship water in the
  water-and-land files; and some coasts more than 25 km from routes get no
  credit (CA-3 to CA-7). The `_land` files used for the areas are correct, but
  the paper should define the zone exactly or switch modes.
- **Most other findings are text.** 74 of 86 paper findings are confirmed, and
  none changes a zone: stale or conflicting numbers (for example, 166,382 pairs,
  the Mississippi route end, 1 in 11 against 1 in 12), missing sources, acronyms,
  and figure citations.
- **The stress tests show the zones are firm against most choices.** No single
  choice moved the land in the 100 km zone by more than 3%. The 25 km zone is
  most sensitive to the tug-barge rule (−12% without it) and the shore link
  (−13% at 10 km, +11% at 50 km).

## Counts

| Table | Findings | Confirmed | Partly | Not confirmed | Can't check | Zone | Number | Wording |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Method, data, domain (CA) | 102 | 84 | 16 | 0 | 2 | 32 | 33 | 37 |
| Paper and data use (CB) | 86 | 74 | 9 | 2 | 1 | 0 | 24 | 62 |
| **Total** | **188** | **158** | **25** | **2** | **3** | **32** | **57** | **99** |

| Action | CA | CB | Total |
| --- | ---: | ---: | ---: |
| Fix | 59 | 65 | 124 |
| Disclose | 24 | 5 | 29 |
| Nick decides | 19 | 16 | 35 |

Some items appear in both tables (for example, the Mississippi route end and
the 166,382 pair count); the totals count them twice.

## Fix first (changes routes or zones)

| ID | What | Effect |
| --- | --- | --- |
| CA-1 | Re-download the lower-48 charted lanes with paging and a count check; key the cache to the grid | About 8,800 new charted-lane cells in the lower 48 |
| CA-2 | Fix the theme name so traffic separation schemes are kept | About 3,100 more |
| CA-8 | Stop the 2-ship port-approach rule from running upriver of Baton Rouge | Route ends at 30.49° N, not 30.77° N |
| CA-3 | Keep foreign land out of the water-and-land zone files | Vancouver, Toronto, Tijuana, and Havana leave the band files |
| CA-33 | Report land areas from the polygons, not raster counts | Island areas fall by about 5–8% |
| CA-36 | Fix and rerun the year-stability script on the 2024–2025 base | Section 1.3 and 4.1 stability numbers |

After these, rerun the four zone runs, the Python products, and the Word
copy, and rerun stage 1.

## Decisions for Nick (judgment calls)

The full list is in the Action column (35 rows). The main ones:

1. **Zone definition** (CA-4 to CA-7): define shore mode exactly (D + 25 km),
   add ships-mode areas, or set the shore link from the EMC analysis.
2. **Band edges and the 2700–2900 MHz part of the study band** (CA-18, CA-20).
3. **Alaska added lanes** (CA-11): refine the satellite cutoff between 211
   and 659 operating days, and show tracks-only and tracks-plus-charted runs.
4. **Hawaii and Puerto Rico harbor fairways** (CA-10): add ENC harbor-scale
   fairways as route sources, or reword "no fairways."
5. **Public repo contents** (CB data-use rows, flagged for counsel): Nick
   decided on November 12, 2026, to leave the repo public as it is.

## Stress tests (stage 4)

| Test | Result | File |
| --- | --- | --- |
| Clean-room rebuild from the paper alone | 99.94–99.96% of pairs agree on four days; gaps in the paper's description listed | `agent_cleanroom.md`, `cleanroom_comparison_rev1.md` |
| Known-answer synthetic day | Exact in Python and MATLAB | `tests/known_answer/`, `stage1_reproduce_rev1.md` |
| One-at-a-time sensitivity (lower 48) | 100 km zone moves 3% or less for every choice; 25 km zone moves up to 12% | `sensitivity_rev1.csv`, below |
| Shore link 10 and 50 km (MATLAB) | 25 km zone −12.6% and +11.1%; 100 km zone −2.3% and +2.7% | below |
| Alaska satellite cutoff half and double | Land in zone +2–4% and −6–8% | `outputs/2018_2019/alaska/sensitivity/` |
| Held-out capture (2023 and 2026 days) | Lower 48: 98% of large-ship cell visits within 25 km, 99.5% within 100 km. Puerto Rico and USVI: 99.95–100%. Hawaii: 81–82% within 25 km, 94–96% within 100 km | `heldout_capture_rev1.csv` |
| Outside port totals | Top-15 ranks don't match public call counts (Spearman −0.09); all 73 ports 0.66; explained by gateway ports, overlapping 10 km circles, and reference points far from terminals | `agent_totals.md` |
| Sampling stability (200 random halves of the 104 days) | Land in the zones varies little between halves: 25 km 282,536–288,447 km², 50 km 610,576–622,474, 100 km 1,241,067–1,255,948 (a spread of 2% or less), and each half is 1–6% below the full sample. Route cells don't hold up: a half keeps 49–57% of the full set, and 70% of route cells appear in fewer than 90% of halves, because the 4-ship rule is much harder to meet on half the days. The zones are stable to sampling; individual low-traffic cells are not | `stability_rev1.csv`, `stability_unstable_cells_rev1.csv` |
| Flagged reports removed (all 104 days per area) | Lower 48: 4,474 route cells (0.68%) depend only on position jumps or shared ship IDs, mostly far off the Pacific coast; land in the zones falls 0.13–0.19%. Hawaii 0, Puerto Rico and USVI 1, Alaska 11 cells. Rebuilt day pairs match the committed caches exactly on every lower-48, Hawaii, and Puerto Rico day, and to within one pair on 16 Alaska days | `outputs/2024_2025/flagged/flagged_rebuild.json` |

Sensitivity, lower 48 (direct-distance land metric; the changes, not the
absolute areas, are what matter):

| Choice | Route cells | Land 25 km | Land 50 km | Land 100 km |
| --- | ---: | ---: | ---: | ---: |
| 3 ships per cell per year (not 4) | +44.9% | +4.7% | +3.9% | +3.1% |
| 5 ships per cell per year | −25.4% | −2.4% | −1.9% | −0.5% |
| No tug-barges | −1.6% | −11.8% | −5.9% | −2.3% |
| Tug-barge distance 50 km (not 25) | +0.9% | +3.3% | +1.9% | +1.3% |
| Port approach radius 25 km (not 50) | −1.9% | −2.8% | −1.9% | −1.0% |
| Port approach radius 100 km | +6.6% | +6.1% | +4.0% | +2.1% |
| No port approaches | −2.3% | −4.8% | −3.0% | −1.6% |
| Port approach needs 3 ships (not 2) | −1.4% | −3.8% | −2.5% | −1.4% |
| Grid cell 0.02° (not 0.01°) | +107.9% | +4.9% | +2.3% | +1.0% |
| Shore link 10 km (MATLAB, shore mode) | 0 | −12.6% | −6.0% | −2.3% |
| Shore link 50 km (MATLAB, shore mode) | 0 | +11.1% | +7.0% | +2.7% |

Not run: the 80 m and 120 m length cutoffs. The day caches are already cut at
100 m, so these need all 104 raw days downloaded again (about 2 hours).

## Agent calibration

19 of 20 planted errors were caught by at least one agent; the miss was a
projection swap in a data-check script (`agent_calibration.md`). Check
projections by hand.

## Deliverables (stage 5)

See `deliverables_rev1.json`: zone-file validity and KML agreement, hand-off
files, source checksums, and the Word copy check (the marking appears only on
page 1 of the Word copy; CB style findings). The routes shapefiles hold invalid
polygons (orphaned holes; CA-96). The output manifest is `manifest_rev1.csv`.
Links: 0 broken, 2 changed, 16 not checkable from here (`agent_links.md`).

## Mock rebuttal

`mock_rebuttal_rev1.md` (fictional party) and the answer,
`rebuttal_response_rev1.md`: of 20 arguments, 1 rebutted, 13 partly valid, and
6 valid. The valid ones overlap the Fix-first and Decisions lists above.

## Fixes applied (November 13, 2026)

Nick asked to apply the fixes, take the zone-definition recommendation, fix
the text, and run the 80 m and 120 m cutoffs. Results: `fix_results_rev1.md`.

- **Code:** charted lanes downloaded in pages with a count check and the
  traffic separation scheme theme kept (CA-1, CA-2); port approaches limited to
  25 km of the coastline (CA-8); zones measured from the route cells ("ships"
  mode) with foreign land removed (CA-3 to CA-7); land areas from polygons
  (CA-33); ESRI .prj (CA-85); NaN MMSI dropped in MATLAB (CA-79); racon retry
  (CA-90); year-stability day list (CA-36); comments (CA-72, CA-86). 19 of 19
  MATLAB tests pass; Code Analyzer is clean.
- **Reruns:** all four zone runs (Mac, commit `034709a`), island figures,
  year stability, and the Word copy.
- **Zone decision:** zones now mean U.S. land and water within D km of a route
  cell. Lower-48 land in zone: 301,168 / 638,688 / 1,261,529 km² at 25 / 50 /
  100 km (shore mode gave 404,668 / 730,157 / 1,335,776 on a cell basis).
- **Paper:** 133 text edits (all Fix and Disclose rows except those listed
  below), Tables 3, 5, 6, 7, eight captions, eight figures, the A.8 length
  paragraph, and the Figure 6 and 10 caption sentences. The Word copy was
  re-exported with all 56 figures and the marking in its header and footer.
- **Length cutoff:** at 120 m, land in zone changes by −1% to −4%; at 80 m by
  +10% to +12%, from river cruise vessels on the Columbia, Snake, and upper
  Mississippi (`length_sensitivity_rev1.csv`).

Still open after the follow-up on November 13, 2026 (the items below were
done that day: charted lanes kept only on the U.S. side by an equidistance
test, which drops 3,427 lower-48 and 6,800 Alaska charted-lane cells and
changes no land area beyond rounding; fixed QC gate limits (CA-58); transit
counts read at full 100 m resolution, with Table 8's NOAA row now at 8
transits, 18,267 cells, Jaccard 0.40 (CA-63); Table 8 gained the 3-ship row
and marks 1.00 as the reference (CA-12, CA-92); route rings written outer
ring first (CA-96, partly: 149 of 591 lower-48 tiles still hold rings that
touch at a cell corner, which OGC tools call invalid; GIS tools draw them
correctly, and shapely.make_valid repairs them); new Section 1.2 source rows
and A.21 items; MarineCadastre links (CB-40, CB-42); zone figures outlined
for contrast (CB-77); Word copy re-exported):

- Every "Nick decides" row except the zone definition (CA-9 to CA-15, CA-18 to
  CA-20, CA-26, CA-32, CA-37, CA-97, CA-100; CB-15, CB-26, CB-28 to CB-32,
  CB-47, CB-53, CB-60, CB-61, CB-63, CB-64, CB-84 to CB-86).
- CA-84 (check the new zones nest), CA-101 and CA-102 (can't check).
- Figure colors in Appendix A (CB-76, CB-78, CB-81, CB-82) and Word Caption
  styles (CB-73).
- The Appendix A products and the stress tests ran on the network before the
  fixes; the paper quotes only their percentage changes.

## Closing the open items (November 13, 2026, second pass)

Nick asked to close the rest of the open items. Each "Nick decides" row was
decided on the recommendation below and applied; the paper is at doc revision
329 or later.

### Method rows (CA)

| Row | Decision | What changed |
| --- | --- | --- |
| CA-9 | Fix text | Section 1.5: the tug-barge rule drops river towboats more than 25 km from the coastline; Gulf Intracoastal Waterway and tidal-river towboats within 25 km still count. |
| CA-10 | Fix text | Sections 4.1 and 6.1: "no fairways" now applies to the NOAA Marine Transportation and racon layers; harbor-scale charts show local fairways, which aren't used. |
| CA-11 | Disclose | Section 5.3: added lanes make most of the Alaska route water (318,028 satellite and 16,750 charted-lane cells against 26,983 ship-track cells); calibration Jaccard 0.57; the search stepped from 272 to 659. The charted lanes are downloaded on each run with a count check, so no cache is committed. A finer cutoff search wasn't run; the half and double runs bound it. |
| CA-12 | Disclose | Section 4.2: Hawaii year stability (63% and 56% inside, against 81% and 93% in the lower 48). Table 8's 1.00 was already marked as the reference. |
| CA-13 | Fix text | Section 1.3: two years let a one-year route count (the union rule); an unusual year can add routes but not remove them. |
| CA-14 | Analysis and disclose | Threshold sweep from 2 to 8 ships (`sensitivity_rev1.csv`): from 3 to 8 ships the 100 km land changes by +4% to −4%; at 2 ships +35%. Section 1.5 says four ships is a presence test, not an interference criterion. |
| CA-15 | Analysis and disclose | With the 25 km coast limit the rule adds 11,682 cells (MATLAB) and 3% of the 25 km land; Searsport is still not connected. Panama City is now reached. |
| CA-18, CA-19, CA-20 | Disclose | Section 3: the band-distance pairs are illustrative; no interference result supports 25, 50, or 100 km; 3030–3070 MHz is narrower than a 3020–3080 MHz radar channel; the zones cover only 2900–3100 MHz, and the EMC analysis must say whether zones extend below 2900 MHz. The lower-48 areas are now in Section 3. |
| CA-26 | Disclose | Section 1.4: the exactly-100.0 m cluster isn't checked; the 120 m cutoff, which drops it, changes land by 1% to 4%. |
| CA-32 | Disclose | Section 1.3: Wednesday-only sampling can catch or miss a weekly service; the held-out days are also Wednesdays (all 52 in 2023 and 25 in 2026 checked), so they don't test this. |
| CA-37 | Analysis and disclose | Appendix A.2: 40% of Pacific route cells lie south of the U.S.-Mexico border (97,350 of 246,302); without them, the Pacific median is 83 km and the 90th percentile 385 km (with them, 132 and 608 km). |
| CA-84 | Checked | `nesting_check_rev1.json`: the 25 km zone lies inside the 50 km zone and the 50 km inside the 100 km everywhere except open-water slivers at the grid edges (lower 48 17 and 128 km², Puerto Rico 30 km² at 25/50, Alaska 78 and 46 km², Hawaii none), at 22° N, 130° W, 66° W, 16.5° N, and 51° N. No land is involved. The paper's statement that a narrower zone sits inside a wider one holds for land. |
| CA-97 | Disclose | Section 1.5: racons with no band in the chart data aren't added. |
| CA-100 | Fix text | Section 1.2: 33 CFR 164.46 AIS carriage cited. |
| CA-101 | Disclose | Section 4.2: the Hilo gap may be a receiver gap; receiver locations aren't published. |
| CA-102 | Disclose | Section 1.10: other 33 CFR Part 334 areas may lie outside 25 km; not checked one by one. |

### Paper rows (CB)

| Row | Decision | What changed |
| --- | --- | --- |
| CB-15 | Fix text | Section 1.8: nearest-port counting (A.20) changes the ranking (Oakland out of the top 15, Mobile in). |
| CB-26 | Placeholder | Section 2 now holds a bracketed note: the EMC analysis, the decision the zones feed, and its timing are to be written by Nick. |
| CB-28 to CB-32 | Leave as is | Nick's decision: the repository stays public with the caches. |
| CB-47 | Fix text | Sections 5.1 and 6: the rule choice rests on whether the lower-48 rule connects the ports and on how widely the traffic spreads, not on ships a day alone. |
| CB-53 | Reading guide | Introduction: results-only readers can read Section 1.1 and then Sections 3 to 6. The tables stay in place so the method stays with its checks. |
| CB-60 | Keep | Long alt texts describe maps that carry many places; Section 508 doesn't cap length. |
| CB-61 | Keep | The figure images carry takeaway headlines, and each caption's first sentence names the figure. |
| CB-63 | Keep | En dashes in the text; hyphens in alt text and image titles read the same to a screen reader. |
| CB-64 | Keep | NTIA writes frequencies without a thousands separator (2900 MHz). |
| CB-73 | Fixed | `python/word_copy_rev1.py` gives all 64 figure and table captions the Caption style with SEQ fields (A-4b and A-4c style only), so Word can build a list of figures. |
| CB-76, CB-81, CB-82 | Keep | The light fills are the low end of sequential ramps or context marks, and every category that carries a message is labeled directly (WCAG 1.4.11 is met when the information is also given another way). Zone figures were already outlined (CB-77). |
| CB-78 | Keep | The white tile labels are bold; at 4.48:1 they miss 4.5:1 by 0.02 and pass the 3:1 large-text level only above 14 pt. Accepted as a draft-stage item. |
| CB-84 to CB-86 | Closed | Not confirmed or moot (current colors pass; the repository is public; three sites refuse automated requests). |

### Results rerun on the fixed network

- **Appendix A products** use the AIS route cells (`viz_cells.npz`), which the
  fixes didn't change (the fixes changed port approaches, charted lanes, and the
  zone definition). No Appendix A figure needed a rerun.
- **Sensitivity** (`sensitivity_rev1.csv`) and **stability**
  (`stability_rev1.csv`) were rerun with the 25 km coast limit on port
  approaches; the threshold sweep and a no-coast-limit variant were added. The
  baseline is 670,572 cells (AIS plus port approaches; MATLAB 670,547).
- **Held-out capture** measures against the AIS route cells, unchanged.
