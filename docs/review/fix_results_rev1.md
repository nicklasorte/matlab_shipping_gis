# Results after the review fixes

DRAFT//PRE-DECISIONAL

Date: November 12, 2026. Zone runs: Mac, MATLAB R2025b, commit `518ee86` plus
`a7cefb0` (outputs committed in `5c296b3`). These numbers replace the paper's.

## What changed in the method

1. **Charted lanes (CA-1, CA-2).** The NOAA Marine Transportation layer is now
   downloaded in pages and checked against NOAA's feature count (291 features in
   the lower-48 grid), and the theme "Traffic Separation Schemes" is kept. The
   earlier cache held 28 features.
2. **Port approaches (CA-8).** The 2-ship rule near deep-draft ports applies only
   within 25 km of the Census coastline, so it no longer extends routes upriver.
3. **Zone definition (CA-4 to CA-7; decision: recommendation applied).** A zone
   is now all U.S. land and water within D km (great-circle) of a route cell.
   Before, land was measured from the coastline cells within 25 km of a route
   ("shore mode"), so land in a D km zone could be up to D + 25 km from a route.
   The new zones are smaller and mean exactly what their names say.
4. **Foreign land (CA-3).** Land of other countries (Natural Earth 1:10m Admin 0,
   public domain; U.S. territories count as U.S.) is removed from every zone file,
   including the band files.
5. **Land areas (CA-33).** Land in each zone is the area of the clipped land
   polygon in an equal-area projection (EPSG:6933), not the sum of grid cells
   that touch land. Shares use the Census land in each grid, also from polygons.
6. **Other code fixes.** ESRI-style .prj (lon/lat), MATLAB drops reports with no
   readable MMSI (as Python does), racon download retries, year-stability script
   uses 52 days per year.

## Lower 48 (2024–2025)

| Item | Before | After |
| --- | ---: | ---: |
| AIS route cells (4 or more ships in a year) | 658,865 | 658,865 |
| Port-approach cells | 15,782 | 11,682 (4,100 candidates more than 25 km from the coastline dropped) |
| Charted-lane cells (cells crossed) | 4,281 | 48,515 |
| Charted-lane cells not already AIS cells | 1,099 | 15,765 |
| S-band racons in the grid / not already route cells | 17 not already | 24 in the grid / 13 not already |
| Total route cells | 675,763 | 686,325 |
| Deep-draft ports reached (of 73) | 69 | 70 |
| Land in 25 km zone | 404,668 km² | 301,168 km² |
| Land in 50 km zone | 730,157 km² | 638,688 km² |
| Land in 100 km zone | 1,335,776 km² | 1,261,529 km² |
| Mississippi route end above Baton Rouge | 30.77° N | 30.49° N (about 5 km above the city) |

On the same grid-cell basis, the new zone definition alone makes the land
areas 22% smaller at 25 km, 10% smaller at 50 km, and 4% smaller at 100 km
than the shore mode (316,855 / 657,203 / 1,284,706 km² of cells touching land,
against 404,668 / 730,157 / 1,335,776).

The charted lanes now include traffic separation schemes off Cuba in the Old
Bahama Channel (on U.S. charts); their water counts as route water. Clipping
charted lanes to U.S. waters is an open item (no EEZ layer is used).

## Hawaii (2024–2025)

Route cells unchanged (7,310). No charted lanes in the Marine Transportation
layer. Land: 25 km 7,869 km² (47%); 50 km 14,132 km² (85%); 100 km 16,717 km²
(all of the main islands) of 16,715 km² of Census land in the grid. Before:
12,351 (70%), 16,720 (95%), 17,573.

## Puerto Rico and the USVI (2024–2025)

AIS route cells 41,237; port-approach cells 1,564 (1,044 dropped as more than
25 km from the coastline; before 2,608). Land: 25 km 7,211 km² (78%); 50 km and
100 km 9,278 km² (all of the land) of 9,275 km² of Census land. Before: 9,583
(96%), 9,970, 9,970. Ports reached: 7 of 8 (Mayagüez off the routes).

## Alaska east of 180° (2018–2019)

Ship-track cells 26,983; charted-lane cells 26,674 (23,550 not already AIS
cells; before 23,444, the gain is the traffic separation schemes); satellite
cells 334,651 (318,028 not already route cells). Land: 25 km 112,427 km² (7%);
50 km 210,892 km² (14%); 100 km 353,650 km² (23%) of 1,518,386 km² of Census
land east of 180°. Before: 179,047 (12%), 261,953 (17%), 409,521 (27%).

## Year stability (fixed script, 52 days per year)

`outputs/2024_2025/stability/year_stability.json`. Lower 48: base 658,867 AIS
cells; 80.8% of the 2023 network and 93.4% of the January–June 2026 network
fall inside the base network; the 2023 network reproduces 57.2% of the base and
2026 (half a year) 32.9%. Hawaii: 63.3% and 56.0% inside; Puerto Rico and USVI:
81.4% and 92.0% inside. Jaccard index of the base against the 2023–2024 network:
0.764 (lower 48).

## Stress tests

See `findings_rev1.md` (sensitivity, shore link, held-out capture, flagged
reports, sampling stability) and `length_sensitivity_rev1.csv` (80 and 120 m).

## Update: foreign-land clip (rerun 23:07)

Natural Earth's border coast overlapped Census U.S. land at border rivers (Detroit River), so the first fixed run removed slivers of U.S. land; Detroit fell outside every zone. The clip now keeps all Census U.S. land. The numbers above are from the rerun (`034709a`). Hawaii and Puerto Rico didn't change.

## Length cutoff (lower 48)

`length_sensitivity_rev1.csv`: at 120 m, 2.4% fewer ships and 3.6%, 2.2%, and 1.3% less land within 25, 50, and 100 km; at 80 m, 2.4% more ships, 2.5% more route cells, and 11.5%, 10.4%, and 10.6% more land. The added cells are mostly offshore in the Gulf; the added land comes from cells far up the Columbia and Snake Rivers and the Mississippi above Baton Rouge.
