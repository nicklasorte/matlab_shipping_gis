# Round-three opposing review: water clip, Alaska satellite lanes, 200-nautical-mile water

DRAFT//PRE-DECISIONAL

Date: November 13, 2026. Reviewer: opposing reader (NOAA and Coast Guard maritime
boundary and navigation view, spectrum-policy skeptic), blind to the drafting.
Paper: `paper_under_review_r3.md`. Decision record: `../round2/foreign_water_decision_rev1.md`
and the "Water clip" and "Mac zone rerun" sections of `../round2/findings_r2.md`.
Also read: `shipping_zone_rev1.m`, `load_foreign_land_rev1.m`,
`python/alaska_satellite_lanes.py`, `outputs/2018_2019/alaska/satellite_lanes*.json`,
`../round2/rerun/clip/foreign_water_after_clip.csv`, and `plot_band_zones_rev1.m`.
Natural Earth and Census outlines were probed locally for small islands (method in
R3OPP-5).

## Summary

- **Calling the clip an equidistance stand-in is fair. The caveat aims at the
  wrong boundaries.** Section 3 lists the Strait of Juan de Fuca and the Gulf of
  Mexico treaty lines as departures, but both are close to equidistance. It leaves
  out the places where equidistance differs most from U.S. jurisdiction: the Gulf
  of Maine (the Hague Line), the U.S.-Russia 1990 line in the Bering Sea (including
  the eastern special areas), and the unresolved areas where equidistance is only
  the U.S. claim (Dixon Entrance, the Bahamas, Machias Seal Island, the Beaufort
  Sea). Because no land changes, these are water-only errors. They matter when a
  reader takes the zone files as a jurisdictional line.
- **The foreign-water rule for zone sources isn't consistent.** AIS route cells,
  S-band racons, and Alaska satellite cells in foreign water stay zone sources.
  Charted-lane cells in foreign water are dropped. The paper gives a physical
  reason for keeping sources ("a ship's radar reaches across the boundary") that
  applies equally to the dropped lanes, and it then calls the water clip "the same
  rule the routes use for charted lanes."
- **The water beyond 200 nautical miles isn't "U.S.-side."** It is high seas. A
  maritime boundary stand-in has no meaning there, and the code marks all water
  more than 2,500 km from both U.S. and foreign land as U.S.-side. Figure 4 crops
  zone water at 100 km from land, so a reader never sees this water. Alaska's water
  beyond 200 nautical miles (11 to 16,187 km²) isn't reported.
- **The Alaska satellite sensitivity is reported correctly, but it hides a method
  problem.** The satellite lanes are described as filling lanes beyond
  shore-receiver range. The code keeps every hexagon above the cutoff, including
  the 110 hexagons inside receiver range, where the paper's own premise is that
  ship tracks are complete. Each coarse 27 km hexagon puts zone sources at the
  shoreline. The 19% of Alaska's 25 km land that depends on satellite cells
  therefore includes land that the in-range hexagons add and the ship tracks don't
  support.
- **No sentence in the text still describes the zones as unclipped or as including
  foreign water.** The leftover problems are labels: the Figure 4 legend calls the
  clipped zone water "large-ship water," and the Section 1.2 data table describes
  Natural Earth as used only to remove land and charted lanes.

## Findings

| ID | Severity | Location | Attack | Evidence | Suggested fix |
| --- | --- | --- | --- | --- | --- |
| R3OPP-1 | High | 5.1 "Satellite lanes"; 5.3 "Satellite cutoff"; Figure 7 alt text | Section 5.1 says the satellite data fill "busy lanes farther out" that shore receivers miss. The code keeps every hexagon at or above the cutoff anywhere in the grid, including hexagons inside the 74 km shore range. That is the same near-shore set the cutoff is calibrated on, where the paper treats ship tracks as complete. Each 27 km hexagon is clipped only to water, so it adds zone sources right up to the shoreline. This puts land in the zone that ship tracks don't support. Satellite cells carry 19%, 14%, and 10% of Alaska's zone land, and the paper doesn't separate the in-range share. | `python/alaska_satellite_lanes.py`: docstring line 1 says "beyond the reach of shore receivers," but line 88 is `keep = in_grid & (kap >= T)`, with no range test. `satellite_lanes.json`: 400 kept, 290 beyond range, so 110 lie inside range. The Figure 7 alt text shows hexagon "patches in Cook Inlet," which is inside receiver range. | Add only hexagons whose centroid is beyond 74 km, or say plainly that in-range hexagons are kept and why. Report the Alaska land at 25, 50, and 100 km without the in-range hexagons. |
| R3OPP-2 | High | 1.5 item 4; 1.2 table, Natural Earth row; 3, paragraph after Table 7; A.3 racon sentence | The paper uses three rules for sources in foreign water. Charted lanes nearer foreign land are dropped as sources. AIS route cells and S-band racons there are kept as sources "because a ship's radar reaches across the boundary." Alaska satellite cells in Canadian water (Dixon Entrance, Hecate Strait) are kept without comment. The radar reason applies equally to a ship in a Canadian traffic separation scheme in Haro Strait or the Strait of Georgia, which is within 25 km of U.S. land at Point Roberts and the San Juan Islands. Section 3 then says the water clip is "the same rule the routes use for charted lanes." The rule is the same in geometry, but it does the opposite job (it drops a source in one case and clips zone water in the other). | `shipping_zone_rev1.m` lines 176–191 (drops lanes) against lines 266–297 (keeps routes and clips only the written zone). The Water clip section of `findings_r2.md` says route cells and racons stay sources. The clip logs record 3,427 lower-48 lane cells and 6,800 Alaska lane cells dropped. | Pick one rule. Option A: keep all charted lanes as sources too, and report the land change (likely small, but Strait of Georgia and Haro Strait lanes are close to Washington). Option B: keep the drop, and justify it as "foreign routing measures aren't evidence of use" instead of a jurisdiction rule. Either way, remove "the same rule." |
| R3OPP-3 | Medium | 3, last sentence of the paragraph after Table 7; 3.1 lead; Figure 4 | "U.S.-side water more than 200 nautical miles from U.S. land" is a contradiction in terms. Beyond 200 nautical miles there is no U.S. EEZ and no boundary to stand in for. The water column is high seas. Even where the United States holds an extended continental shelf (ECS) under the seabed, UNCLOS Article 78 says the shelf doesn't change the status of the water above it. The code labels all water more than 2,500 km from both U.S. and foreign land as U.S.-side. Most of the 0.5 to 0.7 million km² lies in the Pacific out to 130° W and in the Atlantic. Some may lie in the Gulf western and eastern gaps, where the 2000 treaty divides only the shelf and the 2017 eastern-gap treaties with Mexico and Cuba were still before the Senate as of the most recent source checked. Alaska's water beyond 200 nautical miles isn't reported. The paper doesn't say why the decision record's option 4 (cut at 200 nautical miles) was turned down. | `foreign_water_after_clip.csv`: lower 48, 505,106 to 676,473 km² beyond 200 nautical miles; Alaska, 11, 3,372, and 16,187 km²; Hawaii and Puerto Rico, 0. `shipping_zone_rev1.m` line 284. [CRS R47912](https://www.everycrsreport.com/reports/R47912.html) (ECS, Article 78, eastern-gap treaties pending). [Presidential message, December 18, 2023](https://www.presidency.ucsb.edu/documents/message-the-senate-transmitting-two-maritime-boundary-treaties). | Rename it "high-seas water (more than 200 nautical miles from any coast)" and say where it lies. Report the Alaska figure. Either cut the zones at the EEZ outer limit (option 4) or state in one sentence why the files keep this water, for example that ships' radars there still matter. |
| R3OPP-4 | Medium | 3, "Negotiated boundaries… depart from it"; 1.5 Russia parenthetical | The caveat names the wrong departures and leaves out the direction of error. (a) **Gulf of Maine:** the 1984 ICJ chamber rejected Canada's equidistance line. An equidistance clip therefore gives Canada U.S. EEZ water on Georges Bank between the Hague Line and the median. (b) **U.S.-Russia 1990 line:** east of 180° the line runs from 65°30′ N, 168°58′37″ W to 60°11′ N, 179°47′ W. It isn't a median, and it creates an eastern special area (within 200 nautical miles of Russia and beyond 200 nautical miles of the United States) where the United States exercises EEZ jurisdiction. Equidistance gives that water to Russia. The paper quantifies only the lane effect (about 11 km² of land), not the water. (c) **Unresolved areas:** in Dixon Entrance (Canada claims the A–B line), the Bahamas (no treaty), the Beaufort Sea (Canada claims the 141° W meridian), and the Machias Seal Island and North Rock gray zone, equidistance is the U.S. claim or neither party's position, not a boundary. (d) **Lines that are close to equidistance:** the Strait of Juan de Fuca and Haro Strait (1846 treaty, 1872 arbitration), the 1978 U.S.-Mexico Gulf and Pacific lines, the 1977 U.S.-Cuba line, the 1993 U.S.-UK line (British Virgin Islands and Anguilla), and the 1978 U.S.-Venezuela line. The current caveat lists two of these as departures. | [ICJ Gulf of Maine judgment summary](https://icj-cij.org/node/103840). [1990 agreement, Annex and Article 3](https://marineregions.org/documents/USA-RUS1990MB.PDF). [USSR–USA agreement (Russia applies it provisionally and hasn't ratified it)](https://en.wikipedia.org/wiki/USSR%E2%80%93USA_Maritime_Boundary_Agreement). [U.S.-Venezuela treaty points](https://marineregions.org/documents/USA-VEN1978MB.PDF). The decision record says Alaska's foreign-side water is "Russia (Bering Sea)." | Replace the list with: "The largest departures are the Gulf of Maine (the Hague Line), the U.S.-Russia 1990 line and its special areas, and the unresolved boundaries with Canada (Dixon Entrance, the Beaufort Sea, and Machias Seal Island) and the Bahamas, where equidistance is only the U.S. position." Add one sentence that NOAA's U.S. Maritime Limits and Boundaries layer is the authoritative source. |
| R3OPP-5 | Medium | 3.1 item 1; 1.2 table, Natural Earth row | The equidistance line compares 1:500,000 Census U.S. land with Natural Earth "1:10m" foreign land, which is 1:10,000,000, 20 times coarser. Small foreign islands drop out and move the line. Cay Sal Bank (the Bahamas) is missing, which shifts the line toward the Bahamas in the Florida Straits, inside the 100 km zone. Machias Seal Island and North Rock are missing from both files. Foreign distances are measured to outline vertices, not edges, and U.S. distances to a raster mask. In narrow ship channels, the line's error is similar to the channel width: Haro Strait, Boundary Pass, the St. Clair, Detroit, and St. Marys Rivers, and the St. Lawrence Seaway, where the channel crosses the boundary. | Local probe (pyshp): the nearest Bahamas vertex to the Cay Sal Bank box (23.3–24.2° N, 79.6–80.6° W) is outside it, and no Bahamas vertex lies west of 79.59° W. The nearest vertex to Machias Seal Island is 17 km away in both files. Natural Earth does include Isla Aves (3 km), Sombrero, Bermuda, St. Pierre, Big Diomede, and Pelee Island. Census includes Mona, Desecheo, Point Roberts, St. Matthew, and Gambell. `load_foreign_land_rev1.m` returns vertices only. | Write "Natural Earth 1:10,000,000." Add a sentence that small islands such as Cay Sal Bank are missing, and that in narrow boundary channels the clipped water is only approximate. If a jurisdictional reading matters, use option 3 (NOAA limits plus the International Boundary Commission line). |
| R3OPP-6 | Medium | Figure 4 legend, caption, and alt text | The figure fills clipped zone water in pale blue and labels it "large-ship water," which a reader takes as where ships go. The caption mentions only land. The alt text says the panels show "U.S.-side water… water nearer Canada, Mexico, the Bahamas, or Cuba is left out." The figure also crops water at 100 km from land, so the high-seas water the files keep (R3OPP-3) never shows. | `plot_band_zones_rev1.m` lines 54, 66, 85, and 106: the water is `z.poly` minus land, intersected with a 100 km buffer of land, and labeled "Pale blue: large-ship water." | Relabel it "Pale blue: zone water (U.S. side, within 100 km of land shown)." Add the water and the crop to the caption. Make the alt text match. |
| R3OPP-7 | Low | 1.2 table, "Other countries' land" row; 1.5 item 4, last clause | The data table says Natural Earth is used to remove foreign land and to keep charted lanes on the U.S. side. It omits that Natural Earth also sets the water clip, using vertices out to 2,500 km and past the grid edge. "6,800 Alaska cells near Russia and Canada" reads as if Russia and Canada apply to both counts. | `shipping_zone_rev1.m` lines 273–289. | Change the Use cell to "Removed from the zones; sets the equidistance line for zone water and charted lanes." Write "3,427 lower-48 cells (off Cuba, the Bahamas, Mexico, and Canada) and 6,800 Alaska cells (near Russia and Canada)." Confirm the lower-48 list against the logs first. |
| R3OPP-8 | Low | 3, "the same rule the routes use for charted lanes" | The lane clip and the water clip use different implementations. The lane clip uses a raster of in-grid foreign land with distances capped at 400 km. The water clip uses foreign vertices, including land past the grid edge, out to 2,500 km. The two can disagree near grid edges, for example the Dominican Republic past 68.5° W or Russia west of 180°. | `shipping_zone_rev1.m` line 185 (`cap_km=400`, `foreign_land_mask` limited to the grid) against lines 274–280. | Write "the same equidistance idea," or move the lane clip onto the vertex method. |
| R3OPP-9 | Low | A.3 Strait of Georgia racon sentence | "It counts as a zone source, but its own position lies outside the clipped zones" reads as a paradox. The sentence doesn't say why a Canadian aid to navigation feeds a U.S. zone, which is a cross-border coordination question, while Canadian charted lanes don't (R3OPP-2). The findings also record two non-S-band Canadian racons (Strait of Juan de Fuca and Lake Superior) that fall outside the zones, and the paper doesn't mention them. | The Water clip section of `findings_r2.md`. | Rewrite: "One S-band racon, in Canadian waters of the Strait of Georgia, stays a zone source for U.S. land within the zone distance, like route cells in foreign water. The water around it is clipped." State whether it is one of the 13 racon cells in Table 3. |
| R3OPP-10 | Low | 3 caveat; 1.1; A.17; throughout | Since Executive Order 14172 (January 2025), federal agencies and NOAA charts use "Gulf of America" for the U.S. part of the gulf. A hostile reader in an interagency review will flag "Gulf of Mexico" in an NTIA draft. Treaty names keep their original wording. | [NOAA final rule on the name change](https://www.fisheries.noaa.gov/bulletin/noaa-announces-final-rule-implement-gulf-america-name-change). [CRS IF12881](https://www.congress.gov/crs_external_products/IF/PDF/IF12881/IF12881.13.pdf). | Ask NTIA style staff. If it applies, use "Gulf of America" and keep treaty titles as signed. |
| R3OPP-11 | Low | 5.1 and 5.3, satellite cutoff | The paper calls 272 operating days "the best match," but the tested cutoffs jump from 272 to 659. The Jaccard index at half (0.463) and double (0.464) the cutoff is nearly the same, so the true optimum lies somewhere between about 136 and 544 days and isn't pinned down. Section 5.3 states the 659 gap, which is to its credit. | `satellite_lanes*.json`, `jaccard_curve`. | Test cutoffs from 300 to 600 days in steps of 50, or call 272 "the best of the cutoffs tested." |
| R3OPP-12 | Low | 3, "The clip removes 36% to 42%… 20%… 5% to 8%" | These shares come from the decision record's pre-clip Python point sample (cell centers, 0.02°), not from the clipped files. The MATLAB cross-check agrees (37.0% to 42.4%), but the paper doesn't name the source. | The table in `foreign_water_decision_rev1.md`; `foreign_water_after_clip.csv` (residual foreign-side water of 0.4%, 0.8%, and 0.1%). | Add "(estimated on a 0.02° sample before the clip; under 1% of foreign-side water remains in the files, at boundary cells)." |

## What holds up

- **No land area changes.** Every land figure in Sections 3 to 6 matches the Mac
  rerun after the clip (`findings_r2.md`). The claim that the clip doesn't change
  land is true, because the code subtracts the foreign side only from the written
  zone and never from U.S. land (`shipping_zone_rev1.m` line 287).
- **The clip worked.** Foreign-side water left in the files is 0.4% (lower 48),
  0.8% (Puerto Rico and the U.S. Virgin Islands), 0.1% (Alaska), and 0 (Hawaii), at
  boundary cells. The shares removed in Section 3 match the decision record and the
  MATLAB cross-check.
- **No stale wording about unclipped zones.** No sentence in the text still
  describes the zones as unclipped or as including foreign water. Section 3, 3.1
  item 1, the Figure 4 alt text, and the README all describe the clip.
- **"Near Russia, the 1990 boundary line isn't an equidistance line" is correct.**
  North of 65°30′ N the line follows the 168°58′37″ W meridian. South of that it is
  a negotiated line, not a median.
- **Puerto Rico and the U.S. Virgin Islands are close to the real boundaries.**
  Natural Earth includes Isla Aves, and the 1978 U.S.-Venezuela line is mostly an
  equidistance line with full weight for Aves. It reaches 16°44′49″ N, inside the
  grid's southeast corner. The 1993 U.S.-UK line is also close to equidistance.
  Census includes Mona and Desecheo, so the Mona Passage median is sound. There is
  no U.S.-Dominican Republic treaty.
- **Alaska sensitivity numbers are right.** Section 5.1 and 5.3 values (−19%,
  −14%, −10%; +10%, +5%, +4%; −11%, −9%, −7%) match the rerun table in
  `findings_r2.md` and round correctly. 26,674 − 6,800 = 19,874. All five ports stay
  inside the 25 km zone in every case.
- **Keeping foreign route cells as sources is physically right.** A ship's radar
  doesn't stop at a boundary. The problem is consistency (R3OPP-2), not the
  principle.

## Notes for the main session

- Nothing here came from user memory beyond the project context (the repo and its
  review rounds).
