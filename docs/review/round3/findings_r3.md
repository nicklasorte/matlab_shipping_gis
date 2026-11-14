# Round-three review findings and dispositions

DRAFT//PRE-DECISIONAL

Date: November 13, 2026. Reviewed: the work since commit 82ed1a5 (radar model
list, research-ship truth set, Mac zone reruns, foreign-water split, and the
equidistance water clip) and the paper at doc revision 379
(`paper_under_review_r3.md`). Four AI agents, each blind to the drafting:
numbers (`agent_numbers_r3.md`, R3NUM), code (`agent_code_r3.md`, R3COD), data
sources (`agent_data_r3.md`, R3DAT), and an opposing maritime reader
(`agent_opposing_r3.md`, R3OPP). Fixes are in the repo through this commit and
in the doc through revision 393.

## Summary

- **No land area changes.** Every land area in Sections 3 to 6 matches the
  rerun logs, before and after the clip, and after the fixes below.
- **The biggest change is the 200 nautical mile cap.** The clip had given open
  ocean to whichever coast was nearer (R3COD-1, R3OPP-3). Distances now stop at
  200 nautical miles, so high seas stay in the zones. The clip now removes 32%
  to 34% of lower-48 zone water (was reported as 36% to 42%), 20% in Puerto Rico
  and the U.S. Virgin Islands, and 5% to 8% in Alaska
  (`outputs/foreign_water_clip_effect_rev1.csv`). The zones keep 0.7 to 1.1
  million km² of high seas in the lower 48. Python and MATLAB agree
  (`foreign_water_split_postclip_py.csv`, `foreign_water_split_postclip_rev1.csv`).
- **The paper's boundary caveat now names the real departures** (Gulf of Maine,
  the 1990 U.S.–Russia line, unresolved areas) and explains why charted lanes in
  foreign water are dropped while observed tracks and racons stay sources
  (R3OPP-2, R3OPP-4).
- **Data corrections:** the photo-coding rule is now 12 ft or longer for S-band
  and 8 to 11.9 ft unclear (a 10 ft X-band antenna exists, R3DAT-1); two truth-set
  tonnage values were displacement (R3DAT-19, R3DAT-20); Sally Ride's length
  makes all nine S-band ships under 100 m (R3DAT-26).

## Dispositions

| ID | Disposition |
| --- | --- |
| R3NUM-1, R3NUM-2, R3NUM-3, R3OPP-12 | Fixed with new numbers after the cap: 32%–34%, 20%, 5%–8%; country order by share; source named (`foreign_water_clip_effect_rev1.csv`). |
| R3NUM-4 | Fixed in the decision note: within 0.2% in the lower 48 and 0.8% elsewhere. |
| R3NUM-5 | Fixed: stale table removed; the Python split now writes `*_by_country.csv`. |
| R3NUM-6 | Fixed: old-definition sensitivity files removed; `alaska_satellite_sensitivity_rev1.csv` and the rerun port checks for half, double, and no satellite lanes committed. |
| R3NUM-7, R3OPP-9 | Fixed: six Canadian racons (five Salish Sea, one Lake Superior) in the findings and paper A.3. |
| R3NUM-8 | Fixed: paper uses the rerun distances and explains Port Allen (grid tracing and 0.5 km simplification). |
| R3NUM-9 | Fixed: `outputs/2024_2025/census_land_in_grid_rev1.json` (7,803,930 km²; 3.9%, 8.2%, 16.2%). |
| R3NUM-10 | Fixed: "measured on the AIS route cells". |
| R3NUM-11 | Superseded by the cap: the paper now reports high seas, 0.7 to 1.1 million km². |
| R3NUM-12, R3NUM-13, R3NUM-14, R3DAT-19 to R3DAT-30 | Fixed in `data/sband_truth_ships.csv` and `sband_truth_ships_rev1.md` (tonnage sources, Kilo Moana radar, Healy call sign, Sally Ride specs, IMO numbers marked secondary, source dates, fleet wording). R3DAT-28 (IRVSI moved) disclosed. |
| R3NUM-15 | Fixed: `outputs/zone_nesting_check_rev1.json`; largest sliver now 78 km² (Alaska), land nesting holds; paper says "none larger than 80 km²". The 11 km² Russia figure is labelled as an earlier check. |
| R3COD-1, R3OPP-3 | Fixed: `clip_water_cap_km` 370.4 (200 nautical miles); high seas reported as their own class in both splits. |
| R3COD-2, R3OPP-4 | Fixed: zone-code comment and paper name the Gulf of Maine and U.S.–Russia departures (about 5,000 and 2,000 km², from the code reviewer's approximate lines) and unresolved areas. Not implemented as boundaries; that is option 3. |
| R3COD-3, R3COD-4, R3COD-15 | Fixed in `photo_sample_draw_rev1.py`; tests in `python/test_photo_sample_draw.py` (4 pass); protocol updated. |
| R3COD-5 | Fixed: clip logic moved to `foreign_side_polygon_rev1.m`; `test_water_clip_rev1.m` (3 tests pass on the Mac, MATLAB R2025b). |
| R3COD-6, R3COD-7, R3COD-12, R3COD-13, R3COD-14, R3COD-16 | Fixed (messages, warning, argument check, lane_suffix check and clear, zone_set switch, variable rename). |
| R3COD-8, R3OPP-8 | Partly: paper no longer calls the two rules "the same"; the charted-lane filter keeps its 400 km raster rule so routes don't change. |
| R3COD-9, R3COD-10, R3COD-11 | Accepted as limits (in-grid U.S. land only, vertex distances, simplification); no cell found flipped. |
| R3OPP-1 | Fixed in 5.1: the 110 hexagons within shore range also add near-shore sources. Whether to drop them is a method choice for Nick. |
| R3OPP-2 | Fixed in 1.5 and 3: charted lanes are routing measures, not traffic; tracks and racons stay sources. |
| R3OPP-5 | Fixed: "1:10 million" and the Cay Sal Bank omission stated. |
| R3OPP-6, R3OPP-7 | Fixed: Figure 4 legend, caption, and alt text; 1.2 table row. |
| R3OPP-10 | Nick decides: federal usage since Executive Order 14172 is "Gulf of America"; not changed. |
| R3OPP-11 | Open: cutoffs between 300 and 600 days not tested; 5.3 already states the 272-to-659 gap. |
| R3DAT-1 to R3DAT-17 | Fixed in `data/ship_radar_models.csv` and `sband_radar_models_rev1.md` (photo rule, FAR-2268DS 60 kW row, PRR, CAT 2/3, rpm, sidelobes, labelled inferences, SharpEye wording, sector-blanking wording, row count). R3DAT-8 (swing circle) noted in the guide, no new column. R3DAT-18 (hosts block direct fetch) noted. |
