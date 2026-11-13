# Numbers ledger review

Reviewer: ledger. Paper: `docs/review/paper_under_review.md` (Nov 10, 2026 draft).
Ledger: `docs/review/numbers_ledger.csv` (copy of `/tmp/agent_scratch/ledger/numbers_ledger.csv`).
Script: `/tmp/agent_scratch/ledger/build_ledger.py`. It imports the helper modules `extract.py`, `labels.py`, `sources.py`, and `prose_map.py` from the same folder, and it also writes `checks.json`.

## Summary

The script pulled 1,361 numbers from the paper body, tables, captions, and alt text. It ignores numbers in link targets and code spans, such as file names. Each number is either a label or is traced to a field in `outputs/`, a code constant, or a cited outside source. Where no output file stores a value, the script recomputes it from the stored per-cell or per-ship data (`viz_cells.npz`, `viz_offshore.csv`, the Alaska `land_mask`, `wikidata_imo_gt_len.csv`). The paper holds up well. All 8 tables match their source files cell for cell, apart from one internal sum in Table 4. All table totals and percentages recompute. The gross-tonnage, Hawaii, Alaska, Puerto Rico, and Appendix A.20 port-share numbers all match. The problems sit in the prose:

- 3 printed values don't match their source.
- 4 values have no source in an output file.
- 6 cross-section conflicts: the same quantity is printed with two different values.
- 1 table row whose type columns add to more than its total.
- Many figures and tables are never cited by number.

No finding changes a route or a zone.

### Counts by status

| Status | Count |
| --- | ---: |
| match | 964 |
| label | 390 |
| no_source | 4 |
| mismatch | 3 |
| **Total** | **1,361** |

Labels are dates, years, figure, table, and section numbers, MHz band edges, list numbering, regulation numbers, thresholds in phrases such as "1,000 or more", and chart design counts such as "100 squares". Rows count every mention, so a value that is printed three times gets three rows.

## Findings

| ID | Severity | Location | Finding | Evidence | Proposed fix |
| --- | --- | --- | --- | --- | --- |
| ledger-1 | Number | 1.7 (line 125) vs A.4 (line 460) | The two sections give different ends for the Mississippi route. Section 1.7 says the route "continues about 35 km past the city, to 30.77° N". Appendix A.4 says "The route ends about 5 km above Baton Rouge." Both numbers trace to outputs, but to different cell sets. The routes shapefile, which includes the port-approach cells, reaches 30.77° N. The Python cells with 4 or more ships end at 30.485° N. A reader sees a contradiction. | Ledger N0256 and N0257: `shipping_zone_2024_2025_routes.shp` reaches 30.77° N, 36.7 km from Baton Rouge. Ledger N1074: `viz/viz_summary.json` river_km_end − river_km_baton_rouge = 356.47 − 352.02 = 4.4 km; river_end_lat = 30.485. | In A.4, say that the cells with 4 or more ships end about 4 km above Baton Rouge, and that the 2-ship port-approach cells carry the route network on to 30.77° N (Section 1.7). |
| ledger-2 | Number | 1.7 (line 125) vs 1.9 (line 274), Table 6 (line 266), A.4 (line 474), Figure A-31 alt text (line 644) | Both places describe large ships "within 3 km of Baton Rouge", but the counts differ. Section 1.7 gives 263 ships (138 in 2024, 139 in 2025). Table 6 and Section 1.9 give 262 (138 and 138), and Section 1.9 adds "Baton Rouge saw 138 large ships in 2024 and 138 in 2025". The two counts use different methods: a 3 km circle around a point in MATLAB, and 3 km along the corridor path in Python. The paper doesn't say so. | Ledger N0249 and N0253: `shipping_zone_2024_2025_new_orleans_baton_rouge_ship_counts.csv` = 263, 138, 139. `viz/corridor_summary.csv` mississippi: ships_head = 262, y0 = 138, y1 = 138. | Use one count in all places. Or, in Section 1.9, say that corridor counts are measured along the path and can differ by 1 from Section 1.7. |
| ledger-3 | Number | A.13 (line 546) | "New York on the Atlantic (2,199)" names the wrong place. 2,199 is the Atlantic peak in the 39.0–39.5° N bin, which covers Delaware Bay and the upper Chesapeake. The New York bin (40.5–41.0° N) has 2,192 ships. | `viz/geo_profile.csv`: Atlantic, lat 39–39.5 = 2,199; lat 40.5–41 = 2,192. Ledger N1198. | Change the text to "Delaware Bay and upper Chesapeake (2,199), with New York close behind (2,192)", or name the bin by latitude. |
| ledger-4 | Number | 1.9 (line 272) | "On the Delaware, from about 750 ships below Wilmington to about 60 above Philadelphia" doesn't fit the profile. Just above Philadelphia (158.6 km) the reaches still carry 429 to 445 ships. Counts drop to about 60 only from 180 km, about 21 km upstream. | `viz/corridor_profile.csv` delaware: 160–165 km = 429, 165–170 km = 445, 170–175 km = 122, 180–205 km = 56–61. `viz/corridor_marks.csv`: Philadelphia at 158.6 km. Ledger N0738. | Say "to about 60 in the upper river toward Trenton". Or give the drop at each port: about 430 above Philadelphia and about 60 above about 180 km. |
| ledger-5 | Number | Table 4, row 8 (line 150) | South Louisiana's four type columns add to 1,416, which is more than its "Large ships" total of 1,415. The table note says the type columns are part of the total. The same rows appear in the source file, so the cause is probably a ship whose AIS type changed between years and that is counted under two types. | `viz/geo_ports.csv`: ships = 1,415; cargo 932 + tanker 482 + passenger 2 + government 0 = 1,416. Ledger N0327; `checks.json` table4_type_columns_le_total. | Count each ship under one type, for example its most frequent type. Or add a note that a ship that changed type is counted under each type. |
| ledger-6 | Number | Table 3 (line 104) vs A.1 (line 436), A.5, A.6 | Table 3 gives 658,865 AIS cells, from MATLAB. A.1, A.5, and A.6 give 658,867, from Python. A.1 also calls these "route cells", but Table 3 uses that term for 675,763 cells. A reader can't tell which set A.1 counts. | `shipping_zone_2024_2025_run.log`: "AIS source cells (unique_ships rule): 658865". `viz/viz_summary.json` route_cells = 658,867. `viz_matlab/appendix_a_run.log` route_cells = 658,865. Ledger N0211 and N1035. | In Appendix A, say "AIS cells with 4 or more ships (658,867 in Python; 658,865 in MATLAB)". Keep "route cells" for the 675,763 total. |
| ledger-7 | Number | 1.8 (line 243) vs A.3 (line 452) | Section 1.8 says inland river ports sit "about 50 to 700 km" from the routes. A.3 says "48 to 700 km". The file behind Table 5 gives a minimum of 45.1 km (Joliet). | `shipping_zone_2024_2025_principal_port_check.csv`: inland minimum gap = 45.1 km, maximum = 699.1 km. `viz/viz_sites.csv`: inland minimum = 47.9 km. Ledger N0628. | Use one source in both places, for example "45 to 700 km", and say which route set the distance is measured to. |
| ledger-8 | Number | 1.4 (line 57) vs A.7 (line 498) | Section 1.4 says "About 1 ship in 12" passed all four tests. A.7 says "about 1 ship in 11" for the same 2024 day. The 2024 ratio is 1 in 11.3, and the 2025 ratio is 1 in 12.5. | `ais_filter_funnel.csv`: 22,414 / 1,980 = 11.32 (2024-07-10); 23,548 / 1,886 = 12.49 (2025-07-09). Ledger N0098 and N1140. | In Section 1.4, write "About 1 ship in 11 or 12". Or give each day: 1 in 11 in 2024 and 1 in 12 in 2025. |
| ledger-9 | Number | 1.4 (line 69) | "761 of them reached 100 m on July 10, 2024" has no source in an output file. It appears only in a code comment and in the README. | `init_shipping_zone_rev1.m:52`, `README.md:61`. Ledger N0133. | Add a towing row to `ais_filter_by_type.csv` for the length step, or write the count to `funnel.log`. |
| ledger-10 | Number | 1.5 (line 97) | "Without this rule, the routes reached 15 inland river ports" has no source in an output file. It comes from a test run that the README describes. | `README.md:57-58` only. Ledger N0207. | Save that run's principal-port check, or drop the number. |
| ledger-11 | Number | 1.6 (line 117) | "Both produced the same 166,382 cell and ship pairs" has no source in an output file. It appears only in a docstring and in the README. | `ais_cells_py_rev1.py:99`, `README.md:204`. Ledger N0233. | Save the comparison result, for example in `viz_matlab/compare_python.json`. |
| ledger-12 | Number | A.4 (line 460) | "The New Orleans value agrees with the published river mile there (about mile 95)" cites no source for mile 95. Also, 156 river km is 97.0 statute miles, so "agrees" is loose. | `viz/viz_summary.json` river_km_new_orleans = 156.04 km = 97.0 mi. Ledger N1075. | Cite the USACE or NOAA river-mile source. Then say "within about 2 miles of the published river mile 95". |
| ledger-13 | Number | A.6 (line 490) | The paper says 81% of the 2023 cells and 94% of the January–June 2026 cells "are in the 2024–2025 network". These shares were computed against the stability run's base, not the paper network. That base has 661,901 cells and 53 sampled days in 2025, against 658,867 cells and 52 days in the paper. Its Jaccard index against the paper network is 0.762. | `stability/year_stability.json`: lower48.base_cells = 661,901, paper_cells = 661,137, sampled_days 2025 = 53, jaccard_base_vs_paper = 0.762, held_2023.share_inside_base = 0.809, held_2026 = 0.935. Ledger N1122 and N1124. | Rerun the held-out check against the 104-day paper network. Or say that the shares are against a 105-day base. |
| ledger-14 | Wording | Appendix A intro (line 432) | "The entrance and head counts there differ by up to 9%" misstates which counts differ. The head counts are the same in MATLAB and Python. The entrance counts differ by up to 2.2%. The 8.7% gap is in ships_entering, the count behind the continuation curves. | `viz_matlab/compare_python.json` corridor_summary max_rel_diff: ships_head 0.0, ships_entrance 0.022, ships_entering 0.087. Ledger N1033. | Write "the entrance counts differ by up to 2%, and the counts of ships entering the corridor (Figures A-4b and A-4c) by up to 9%". |
| ledger-15 | Wording | Sections 1.4, 1.5, 3 | Tables 2 and 3 and Figure 4 are never cited in the text. Table 7 is first cited in Section 4.2 (line 354), after it appears (line 299). Figure A-2 is first cited in A.12 (line 538), after it appears (line 448). | `checks.json` figure_table_order. | Add the citations, for example "Table 2 gives the kept ships by type", "Table 3 counts the route cells by source", and "(Table 7, Figure 4)" in the Section 3 opening. |
| ledger-16 | Wording | Appendix A | 41 appendix figures are never cited by number: A-1, A-3 to A-17, and A-20 to A-44. The text says only "these figures" or "the map". | `checks.json` figure_table_order (cited_before = false). | Cite each figure in the sentence that makes its point, for example "(Figure A-1)". |
| ledger-17 | Wording | A.18 and A.19 | From A.18 on, figure numbers no longer follow section numbers. Figure A-19 is in section A.18, and section A.19 holds Figures A-20 to A-34. Section 1.9 says "Appendix A.18 shows every corridor's profile, and Appendix A.19 maps each one", which readers may take as figure numbers. | Lines 277, 586–658. | Say "Section A.18 (Figures A-18 and A-19)" and "Section A.19 (Figures A-20 to A-34)". |

## Checked and correct

- **Table 1.** All 20 report and ship counts match `ais_filter_funnel.csv`.
- **Table 2.** All 16 type counts match `ais_filter_by_type.csv`. The totals (1,980 and 1,886) recompute and equal the last funnel step.
- **Table 3.** All four sources match the run log. The total, 675,763, recomputes.
- **Table 4.** All 120 cells match `viz/geo_ports.csv` and the Corps ranks. The rank order follows ship counts. The one internal inconsistency is ledger-5.
- **Table 5.** It lists exactly the 73 deep-draft ports in the source: not type I and at least 1 million foreign tons. Ranks run in ascending order. Every value matches `principal_port_check.csv`: tonnage, distance, "On the route network" (reached and on the network, 69 Yes), and "In 25 km zone".
- **Table 6.** All values match `viz/corridor_summary.csv`. All 15 shares recompute from head/entrance, and the rows are sorted by share. "10 of 15 corridors" recomputes.
- **Table 7.** Matches `band_zones.csv`.
- **Table 8.** Matches `islands/route_rules.json`.
- **Gross-tonnage check.** These recompute from `outputs/2024/gt_proxy_*.csv`: 4,129, 3,873, 3,801, 3,818, 17, 72 (45 cargo, 22 passenger, 5 tankers), 99.6%, 98.1%, 5,674, and the 145 m sweep point. The 0.1 m median recomputes from `data/ais_vessels_2024_4days.csv` and `data/wikidata_imo_gt_len.csv`; no output file stores it.
- **A.1, A.6, and A.11.** These recompute from `viz/viz_cells.npz`: 503 cells with 1,000 or more ships, 344,850 cells with fewer than 10, 6% of cells carrying half the traffic, 85% of traffic in both-year cells, and 25% of busy cells inside the six close-up areas.
- **A.12.** 11%, 24%, and 51% recompute from `viz/viz_offshore.csv`.
- **Alaska.** The 1.53 million km² land total recomputes from the `land_mask` in the Alaska `.mat`, as `python/ship_alaska_figures.py` computes it. The 12%, 17%, and 27% shares, the satellite-lane numbers, and the cutoff sensitivity (4/3/2% and 8/7/6%) all match.
- **Hawaii and Puerto Rico.** The zone areas and shares (70%, 95%, 96%), route-cell counts, port gaps, and the Jaccard index (0.80 and 0.81) all match.
- **Appendix A.20.** These recompute from `viz/port_share.csv` and `port_share_complex.csv`: 39,688 visits, Gulf 48%, top 10 at 43%, 13 and 30 ports, 63%, 16% and 13%, 71% and 57% tankers, 16.5%, the 0.5-point Baltimore shift, and a third of Gulf visits on the lower Mississippi.
- **Repeated values.** These agree everywhere they appear: 99.6%, 98.1%, 4,129, 69 of 73, 7,310, 26,983, 41,237, 2,953, and 2,095.
- **Numbering.** Figures 1–10 and A-1 to A-44, including A-4b and A-4c, and Tables 1–8 are numbered in order.
- **Outside sources.** SOLAS V/19 requires a 3 GHz radar, or a second 9 GHz radar, on ships of 3,000 GT and up (https://www.jrc-world.com/en/regulations/navigation/passenger-and-cargo-ships-3000-9999-gt). USACE announced full restoration of the Fort McHenry channel on June 10, 2024 (https://www.army.mil/article/277129, found by web search; the page itself was not fetched). March 26 to June 10 is 10.9 weeks, which fits "about 11 weeks".

Unverified: the Alaska grid's land total (1.53 million km²) is larger than Alaska's Census land area of about 1.48 million km², even though the grid leaves out the western Aleutians. A 0.01° land mask can overcount coastal cells. If it does, the Alaska shares would fall by less than half a percentage point. I didn't check this against a Census source.
