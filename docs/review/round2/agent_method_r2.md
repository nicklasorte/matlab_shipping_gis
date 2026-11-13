DRAFT//PRE-DECISIONAL

## R2MET report: method and code review, round two

### Summary

The changed code mostly does what the paper says. I recomputed the zone land areas geodesically from the shapefiles and they match: 301,147 km² against 301,168 km² for the lower-48 25 km zone, with Hawaii and Puerto Rico matching to within 1 km². Route counts, port distances, the port-approach rule, the route rules, and the charted-lane clip counts all match the run logs. The main problem is how foreign water is handled, which affects the zone files but not the land areas:

- **Ocean waters:** the zones keep foreign water and foreign AIS routes (Canada, Mexico, the Bahamas, Cuba). The paper says each zone is "U.S. land and water."
- **Great Lakes and border rivers:** the Natural Earth country file includes boundary lakes, so removing Canada also removes the Canadian half of the lakes. That includes route cells, so a zone file doesn't always contain its own routes.

Other problems:

- One before/after comparison is attributed to the zone definition alone, but the routes also changed in between.
- One Alaska count is stale.
- The "land" areas include inland water.
- The paper says the charted lanes are downloaded on every run; the code caches them.

### Findings

| ID | Severity | Location | Finding | Evidence | Proposed fix |
|---|---|---|---|---|---|
| R2MET-1 | Zone | Sec. 3 (Table 7 note, Fig. 4 caption and alt text), 3.1 item 1, 1.2 table; shipping_zone_rev1.m:182–193, 257–272, 291 | The zones contain foreign ocean water, and the routes include foreign-port and foreign-water traffic. The equidistance clip applies only to charted lanes, never to AIS cells, and the code removes only foreign *land*. The KML labels say "U.S. water + land." Land areas are unaffected. | Points inside the 25 km zone: Strait of Georgia (49.2, −123.6), Burrard Inlet (49.30, −123.10), off Rosarito, Mexico (32.3, −117.3), Freeport, Bahamas (26.50, −78.77), Bay of Fundy (45.0, −66.5). Route cells sit in Burrard Inlet, off Rosarito, at Freeport, and through the Old Bahama Channel to 22.17° N at 77.5° W. | Pick one: (a) clip the zone water and AIS cells with the same equidistance mask, or with an EEZ layer; or (b) reword to "land and water within D km, with other countries' land removed; includes foreign waters near the border," and say the routes include traffic to Canadian, Mexican, and Bahamian ports. |
| R2MET-2 | Zone | Sec. 3.1 item 1, Sec. 1.5 item 4; load_foreign_land_rev1.m:19–28 | Natural Earth `ne_10m_admin_0_countries` includes boundary lakes in its country polygons. Subtracting Canada therefore removes the Canadian half of the Great Lakes and border rivers, route cells included. In the lakes, the lane clip follows the Natural Earth border, not equidistance, because the foreign mask covers the water (d_foreign = 0). | These route cells lie outside the 25 km zone polygon: Lake Erie (42.555, −81.175), Lake Ontario (43.75, −77.9), Lake Huron (44.435, −82.115), Lake Superior (48.155, −87.195). Canadian lake water 11–22 km from a route is also outside. Natural Earth publishes a separate "without boundary lakes" file: https://openpolar.no/Record/ftdatacite:10.6086%2Fn1kk98tc | Use `ne_10m_admin_0_countries_lakes`, or make treatment of U.S. waters only consistent with R2MET-1 and state it. |
| R2MET-3 | Number | Sec. 3.1 item 2 ("the change makes … 22% … 10% … 4% smaller") | The comparison mixes route sets. "Before" is shore mode on the old routes: 675,763 cells, the 28-feature fairway cache, and the port rule that ran upriver. "After" is ships mode on the new routes. So it isn't the effect of the zone definition alone. | fix_results_rev1.md:33–52; the current log gives 316,855 / 657,203 / 1,284,706 km² of grid cells touching land. | Rerun shore mode on the current routes, or write "Together with the route fixes, …". |
| R2MET-4 | Number | Sec. 5.1, 5.3 ("318,028 … not already route cells" and "not already AIS cells") | Stale. The current run gives 318,210, counted against AIS cells *plus* charted lanes. The 318,028 figure appears to predate the 6,800-cell clip. | outputs/2018_2019/alaska/shipping_zone_alaska_2018_2019_run.log:110 | Use 318,210 and "not already AIS or charted-lane cells" in both places. |
| R2MET-5 | Number | Sec. 3.1 item 4, 3.1 totals, 4.2, 5.2 (Fig. 8 caption: "1,518,386 km² of Census land"), 6.1 | The Census 1:500,000 state polygons include inland water (lakes), so "land" is overstated, by about 3% in Alaska and 9% in Florida. | Alaska polygon area 1,520,595 km² against Census land area (ALAND) of 1,479,017; Florida 150,866 against 138,964. | Say "land and inland water," or remove Census water areas from the polygons. |
| R2MET-6 | Number | Sec. 4.2, 6.1 shares; shipping_zone_rev1.m:256; python/ship_island_routes.py:164–186 | The share numerator uses the land polygon simplified at 0.005° and projected to EPSG:6933. The denominator is unsimplified geodesic area. As a result, zone land can exceed total land, and the Hawaii figure code hides this by capping the share at 1.0. | Puerto Rico 9,278 against 9,275 total; Hawaii 16,717 against 16,715 (fix_results_rev1.md:57–68); ship_hawaii_figures.py:127 `min(1.0, …)`. | Measure the numerator and denominator from the same polygon. |
| R2MET-7 | Wording | Sec. 5.3 last sentence; findings_rev1.md CA-11 | The paper says the lanes are "downloaded from NOAA on each run." The code downloads only when the per-grid cache is missing, then reuses it. | load_shipping_fairways_rev1.m:31, 37, 71–73 | "Downloaded once per grid and cached with NOAA's feature count; delete the cache to refresh." |
| R2MET-8 | Wording | Sec. 1.5 sensitivity paragraph | The paper doesn't say the sensitivity runs leave out charted lanes and racons, or that they measure land on a 0.05° point grid. The tug-barge −12% figure, for example, is measured without the 13,964 lane cells. | python/review_stress.py:5–12; sensitivity baseline 295,750 km² against 301,168 km² in the paper. | Add one sentence saying so. |
| R2MET-9 | Wording (Unverified) | Sec. 1.5 item 4, 5.1 ("6,800 Alaska cells near Russia") | The Alaska grid's foreign mask also contains Canada (Dixon Entrance, Portland Canal). The log gives one total with no split by country. | shipping_zone_rev1.m:183–190; Alaska run log:108 | Split the count by country, or write "near Russia and Canada." |
| R2MET-10 | Wording | README.md:70, 156–166, 212–217; init_shipping_zone_hawaii_rev1.m:14; init_shipping_zone_prusvi_rev1.m:9 | The README is stale: its results heading says "shore mode" over ships-mode numbers; it gives 15,765 lane cells and 686,325 total where the log has 13,964 and 684,524; step 1 says 2023–2024; and the figure links point to the 2023–2024 shore-mode maps. Two init comments also disagree with the paper: Hawaii Jaccard index 0.81 (paper 0.80), Puerto Rico median 61 ships a day (paper 58). | Lower-48 run log against the README | Update the README and the comments. |
| R2MET-11 | Wording | python/word_copy_rev1.py:58–63 | When an alt text isn't matched exactly, the script silently uses the image with the longest shared prefix (at least 40 characters). The alt texts for Figures 9 and 10 share 46 characters, and A-18 and A-19 share 62, so an early edit to one could pull in its sibling's image. No wrong image is in the Word copy now: 54 of 56 images are byte-identical to repo PNGs, Figure 3 is pixel-identical, and Figure 1 differs by 122 pixels. | Prefix check on the paper's 56 alt texts | Log every fallback, and refuse ties. |
| R2MET-12 | Zone (Unverified) | Sec. 5.1 grid, 5.3 | Route cells run to −179.98°, so the lanes continue west of 180°. Lanes there are not zone sources for the U.S. islands east of 180° (the Delarof Islands are at about −179°). The land effect is probably small. | Alaska routes shapefile bounding box | Add a note, or buffer from cells just west of 180°. |

### Checked and found correct

- **Zone land areas:** geodesic recomputation from the land shapefiles matches the logs: lower 48 25 km 301,147 against 301,168 km²; Hawaii 7,868 against 7,869; Puerto Rico 7,211 and 9,278.
- **Table 3:** the counts sum to 684,524. The figures 3,427, 6,800, 19,874 and 16,750 match the logs.
- **Port-approach rule:** matches Sec. 1.5 item 2 (50 km from a port, 25 km from the coastline, 2 ships, 73 ports, 4,100 candidate cells dropped). The Python sensitivity code uses the same rule.
- **Lane download:** paging with `orderByFields`, a hard error when the feature count doesn't match, the corrected traffic separation scheme theme name, and a cache keyed to the grid are all in place.
- **U.S. territories:** they aren't removed as foreign land. Puerto Rico's 50 km zone land (9,278 km²) equals the Census land, which it couldn't if Puerto Rico had been subtracted.
- **Distances:** the distance method (sphere of radius 6,371.0088 km, k-d tree over the edge cells of the route area) matches Sec. 3.1 item 3. All zone files stay inside their grid limits, and the Alaska files don't wrap at the date line.
- **Alaska 51° N edge:** route cells touch the southern edge only between 174.1° W and 169.7° W, more than 100 km from land, so the cut changes no zone land.
- **Hawaii, Alaska, Puerto Rico setup:** route rules, port rule on or off, and grids match Sections 4–6.
- **Port distances:** the figures in Sec. 4.2, 5.2 and 6.1 match the port-check CSVs.
- **Sensitivity numbers:** the figures in Sec. 1.5 match sensitivity_rev1.csv.

Scratch scripts are in /tmp/agent_scratch/R2MET/. The repository was not modified.
