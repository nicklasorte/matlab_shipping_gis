DRAFT//PRE-DECISIONAL

**R2NUM: numbers audit of paper_under_review_r2.md (rev 329)**

## Summary

Most of the paper's numbers trace to a repo output and agree with it. I checked them against the latest zone-run logs (lower 48, Hawaii, Puerto Rico and the U.S. Virgin Islands, Alaska), the funnel files, the viz, corridor and port_share outputs, the Wikidata proxy files, year_stability.json, heldout_capture_rev1.csv, flagged_rebuild.json and the Alaska satellite and sensitivity outputs. I also reran the derived arithmetic from viz_cells.npz and viz_offshore.csv. One count is stale: the Alaska figure for satellite cells not already route cells comes from an earlier run. Both sensitivity tables, and every percentage drawn from them, use baselines that are not the network the paper presents, and the 80 m length result was run with the port-approach rule that the coast limit later fixed. Several distances and land changes trace only to first-round review notes, not to any output. The rest are small rounding and range slips. I left out the Section 1.10 "200 random halves" sentence, as the brief asked. The 291-feature and 26,674-cell counts trace only to fix_results_rev1.md. NAME = R2NUM.

## Findings

| ID | Severity | Location | Finding | Evidence | Proposed fix |
|---|---|---|---|---|---|
| R2NUM-1 | Number | Sec. 5.1 (satellite lanes); Sec. 5.3 (satellite cutoff) | The paper gives "318,028" satellite cells not already route cells, in both places. The latest Alaska run gives 318,210. The 318,028 is from the earlier run, before 6,800 charted-lane cells nearer Russia were dropped. | `outputs/2018_2019/alaska/shipping_zone_alaska_2018_2019_run.log`: "Extra source cells: 334651 (318210 not already route cells)"; `fix_results_rev1.md:72-73` gives 318,028 | Change both places to 318,210. |
| R2NUM-2 | Number | Sec. 1.4 (length test, "1% to 4%"); App. A.8 (all 80 m and 120 m figures) | The length runs don't use the current network. Their baseline (674,685 route cells; 300,406 / 639,699 / 1,266,625 km²) is exactly the "Port approaches without the 25 km coast limit" variant. That is the pre-fix rule, which carried routes above Baton Rouge. So A.8's statement that 80 m adds land "on the Mississippi above Baton Rouge" may partly come from that rule. | `length_sensitivity_rev1.csv` row 100; `sensitivity_rev1.csv` row "Port approaches without the 25 km coast limit" | Rerun 80 m and 120 m on the current network. If you don't rerun, say which baseline was used. |
| R2NUM-3 | Number | Sec. 1.5 (sensitivity paragraph; rule 2, "3% smaller") | The one-step sensitivity baseline is 670,572 cells and 295,750 / 631,505 / 1,254,018 km². That is AIS cells plus port approaches only, with no charted lanes or racons. The paper's network is 684,524 cells and 301,168 / 638,688 / 1,261,529 km². The percentages are correct for that baseline, but the paper doesn't name it. | `sensitivity_rev1.csv` Baseline row; `findings_rev1.md:244`; run log | Add one clause: "on the AIS and port-approach cells, without charted lanes". |
| R2NUM-4 | Number | Sec. 4.2 (Lahaina 18.9 km, Port Allen 25.3 km); Sec. 6.1 (Sonda de Vieques 19.5 km); Sec. 5.2 (Red Dog pier 0.2 km) | Unverified: no source found in any output. These four distances appear only in reviewer notes. One of them drives a zone statement: Port Allen "falls just outside the 25 km zone". | `findings_method_rev1.md:70, 71, 104`. None of them is in the hawaii, prusvi or alaska `*_sites.csv` or `*port_check.csv` | Add the four sites to the site checks and cite the output. |
| R2NUM-5 | Number | Sec. 1.6 ("reduces the land in the zones by 0.13–0.19%") | Unverified: no source found. flagged_rebuild.json has cell counts only; its 4,474 cells (0.679%) and the 0, 1 and 11 counts match the paper. The land change appears only in the review summary. | `outputs/2024_2025/flagged/flagged_rebuild.json`; `findings_rev1.md:102` | Write the land areas to the rebuild output, or drop the range. |
| R2NUM-6 | Number | Sec. 1.4 (761 towing ships); Sec. 1.5 (15 inland river ports); Sec. 1.6 (166,382 pairs; 2025 funnel match) | Unverified: no source found. 761 and 15 are earlier-run numbers with no output, and 166,382 appears only in the README; the ledger marks all three as having no source. The README records the exact funnel-to-cache match for 2023-07-12 and 2024-07-10. It doesn't record one for 2025-07-09 (1,101,052 reports, 2,017 ships). | `numbers_ledger.csv` rows N0133, N0207, N0233; `README.md:203-206` | Log the 2025 comparison. Cite or drop the earlier-run numbers. |
| R2NUM-7 | Number | Sec. 1.4 (Wikidata match rate "77% to 84%" above 100 m) | The six bins above 100 m match at 77.4, 84.4, 77.8, 75.5, 79.1 and 80.2%. The 200–250 m bin rounds to 76%. | `outputs/2024/gt_proxy_coverage_2024.csv` | "76% to 84%". |
| R2NUM-8 | Number | App. A intro ("entrance counts differ by up to 2%") | For the Calcasieu, Python gives 409 at the entrance and MATLAB gives 400: a 2.25% difference. | `viz/corridor_summary.csv` and `viz_matlab/corridor_summary.csv` | "by about 2%" or "by up to 2.3%". |
| R2NUM-9 | Number | Sec. 1.10 (held-out days) | Lower 48: the paper says 99.5% within 100 km; the outputs give 99.62% for 2023 and 99.48% for 2026. Puerto Rico and USVI: the paper says "99.95% to 100%" within 25 km; the outputs give 99.95% and 99.98%. The 100% is the 50 km value. | `heldout_capture_rev1.csv` | "99.5% to 99.6%"; "99.95% to 99.98%". |
| R2NUM-10 | Wording | Sec. 5.1 ("54"), Sec. 6 ("Alaska's 54"), Sec. 5.3 ("53.5") | The same quantity is printed two ways. | `alaska_rules.json` ships_per_day_median = 53.5 | Use one value throughout. |
| R2NUM-11 | Number | Table 5 note and App. A.3 ("45 to 700 km" to inland ports) | 45.1 km is the MATLAB value. Figure A-3 uses the Python values, whose nearest inland port is 47.9 km, and Appendix A says its figures report Python values. | `shipping_zone_2024_2025_principal_port_check.csv`; `viz/viz_sites.csv` | In A.3, give "48 to 700 km", or say which program the range comes from. |
| R2NUM-12 | Wording (Unverified on the figure itself) | Table 6 / Sec. 1.9 (Mississippi 356 km); Fig. A-18 | Table 6 uses the Baton Rouge mark (355.9 km). corridor_summary.csv gives length_km = 360.3, the path to the "Upstream limit" target. The Figure A-18 labels are built from length_km, so the figure likely reads 360 km. I didn't view the image. | `viz/corridor_marks.csv`; `python/ship_corridor_figures.py:95` | Label the figure with the head-port distance. |

## Checked and correct

- **Tables 1 and 2:** every cell matches `ais_filter_funnel.csv` and `ais_filter_by_type.csv`. Both type columns sum to 1,980 and 1,886.
- **Filter ratios:** 22,414 / 1,980 is about 1 in 11 (11.3), and 23,548 / 1,886 is about 1 in 12 (12.5). The length step drops two-thirds of ships (33.2% kept). 309 of 1,980 ships (15.6%) weren't tested.
- **Wikidata proxy:** I rebuilt it from the data files. The counts 4,129, 5,674, 3,873, 3,801, 3,818, 17 and 72 (45 / 22 / 5) all match, as do 98.1%, 99.6% and 86%. Half of the dropped ships are 87–99 m, and the median length difference is 0.1 m. The 90 m cutoff makes 70 errors against 89 at 100 m, and recall falls below 0.9 at 145 m.
- **Table 3:** the rows sum to 684,524.
- **Run-log values:** the port approaches (11,682), charted lanes (13,964), racons (13), dropped cells (3,427 and 6,800), 70 of 73 deep-draft ports, 24 of 24 named ports, 0 of 36 inland ports, the three zone areas and the Baton Rouge counts 138 / 139 / 263 all match the run log.
- **Island zones:** Hawaii is 7,310 cells; 47%, 85% and the port distances check. Table 8 matches route_rules.json, and Jaccard 0.80 / 0.81 checks. Puerto Rico and USVI: 41,237 + 1,564 = 42,801 cells, 78% of the land, Mayaguez 29.7 km, and the median of 58 ships a day all check.
- **Alaska:** 26,983 and 19,142 cells and 26,674 − 6,800 = 19,874 check, as do 16,750, the 400 and 290 hexagons, cutoffs 272 / 136 / 544 and 633 / 304 hexagons, Jaccard 0.57 and the next cutoff of 659. The +4/3/2% and −8/7/6% changes and all port distances check. The land shares 7 / 14 / 23% are of 1,518,386 km², and the daily counts are 1 and 18.
- **Tables 4 and 5:** Table 4 matches `geo_ports.csv` cell for cell. All 73 rows of Table 5 match, including the Yes/No columns, and 71 of 73 ports are within 5 km.
- **Table 6 and A.4b/A.4c:** Table 6 shares, lengths, counts and per-year counts check except item 12; 10 of 15 corridors are below half. The A.4b/A.4c numbers check: 74%, 13%, 7%, 5%, 4,610, 3,871 and 300.
- **Appendix A:**
  - **A.1:** 6.3% of cells carry half the traffic; 503 cells saw 1,000 or more ships, and 344,850 saw fewer than 10.
  - **A.2:** offshore medians and 90th percentiles; the Baja share is 39.5%; without Baja, 83 and 385 km.
  - **A.5:** 9,130 tug-barge cells and the split by coast.
  - **A.6:** 336,369 and 322,498 cells; 85.4% of traffic; 6.5% and 34.9% (8-connected groups); 81, 93, 57 and 33%; Jaccard 0.764.
  - **A.9 to A.13:** 7,678 hexagons, 42%, 140 hexagons, 3,206 ships, 25.3%, 11 / 24 / 51%, and the coast peaks.
  - **A.14 and A.15:** port counts and type counts.
  - **A.20:** 39,688 visits and every share and ranking.
- **Section 3.1:** the 22 / 10 / 4% reductions recompute from the fix_results areas.
- **Sampling dates and Key Bridge:** the sampling dates are correct. The Key Bridge dates (May 21 and June 10, 2024) match the [Army article](https://www.army.mil/article/277129).
- **River mile:** USGS has a "Mississippi River at Mile 95.8" site at New Orleans ([USGS 295611090032500](https://nwis.waterdata.usgs.gov/monitoring-location/295611090032500)).

Sources:
- https://www.army.mil/article/277129
- https://nwis.waterdata.usgs.gov/monitoring-location/295611090032500
