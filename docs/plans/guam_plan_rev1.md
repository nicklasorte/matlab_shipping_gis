# Plan: Guam (and the Northern Mariana Islands) routes and zones

DRAFT//PRE-DECISIONAL

Date: November 19, 2026. Adds a fifth region to the paper, built the same way
as Hawaii and Puerto Rico and the U.S. Virgin Islands.

## What we know

- **The AIS data already cover Guam.** MarineCadastre's 2025 metadata gives
  an extent of 141° E eastward across the dateline to 60° W, and 10° N to
  51.5° N (NOAA InPort item 77594). That takes in Guam (13.2° N to 13.7° N)
  and the Northern Mariana Islands (CNMI, to 20.6° N). BOEM has published a
  Guam AIS vessel-count layer for 2017–2023 built from the same NOAA data,
  with the note that the AIS data "may be incomplete" there.
- **NOAA's AIS Vessel Transit Counts include Guam and CNMI** (2025 metadata,
  InPort item 79556: coverage was expanded to them), so the cross-check and the
  NOAA rule used for Hawaii (Table 9) work here too.
- **Census land:** the 2023 cartographic boundary file holds Guam (about
  560 km²) and CNMI (about 470 km²). Rota (CNMI) is 58 km from Guam; Tinian
  and Saipan are 150 km to 190 km away. So a 100 km zone around Guam's routes
  reaches Rota, and the two can't be drawn fully apart.
- **No foreign land nearby,** so the zone-water clip at the equidistance line
  does nothing; only the 200 nautical mile cap applies.
- **Traffic is light and military-heavy.** Apra Harbor holds both the
  commercial Port of Guam and Naval Base Guam. Navy ships often run with AIS
  off (Section 1.10), so the AIS routes undercount Navy radar use.

## Decision

**D13 (decided November 19, 2026): one region, Guam and the Northern Mariana
Islands.** The reasoning: one region,
"Guam and the Northern Mariana Islands," like Puerto Rico and the U.S. Virgin
Islands. The zones overlap at 100 km anyway, Saipan and Tinian have
deep-draft ports, and the same run covers both. The paper can still report
land for each.

## Steps

| Step | Work | Output | Where |
| --- | --- | --- | --- |
| G1 | Count large-ship reports (current filter, 100 m and up) in the box 12.5° N to 21° N, 144° E to 146.5° E in the 104 sampled 2024–2025 days; check the coordinates are east longitudes as expected and see where reception ends | Reports and ships per day; coverage map | Mac |
| G2 | `init_shipping_zone_guam_rev1.m` from the Hawaii one: grid 12.5° N to 21° N, 144° E to 146.5° E at 0.01°; ports Apra Harbor (Guam), Saipan, Tinian, Rota; Census GU and MP land | Init file, run log with commit stamp | Cloud, then Mac |
| G3 | Route rule: compare the lower-48 rule (4 ships a year), ship-days calibrated on the lower 48 (as Hawaii), and NOAA transit counts; check every port connects | `outputs/2024_2025/guam/route_rules.json`, a Table 9-style comparison | Mac and Cloud (`python/ship_route_rules.py` gains a Guam grid) |
| G4 | Run zones (25, 50, 100 km); land areas for Guam and CNMI separately (no population; dropped November 20) | Zone files, areas | Mac |
| G5 | Held-out days (2023 and 2026 Wednesdays): share of large-ship visits within 25 km and 100 km of a route cell | Capture shares | Mac |
| G6 | Figures (routes; land by zone), Python and MATLAB versions agreeing; paper Section 7 (data, rule, routes and zones, limits including Navy traffic) | Figures with alt text; doc section; Word copy | Cloud |
| G7 | Blind review of the new section (numbers, method, style), as in earlier rounds | Findings and dispositions | Cloud |

## Checks

- G1 decides whether the region is feasible: if reports stop close to shore,
  say so and consider the World Bank density layer as a gap-filler, as for
  the St. Lawrence.
- Twins agree on route cells exactly and on land areas within 0.1%.
- Every number in Section 7 traces to a committed output or log.
- D13 is Nick's call.

## Sources

- NOAA InPort, Nationwide Automatic Identification System 2025:
  https://www.fisheries.noaa.gov/inport/item/77594
- NOAA InPort, AIS Vessel Transit Counts 2025:
  https://www.fisheries.noaa.gov/inport/item/79556
- BOEM, Guam AIS Vessel Count 2017 to 2023 Average:
  https://geoseas.boem.gov/server/rest/services/PAC/Guam_AIS_Vessel_Count_2017_to_2023_Average/MapServer
- Census Bureau, cartographic boundary files 2023:
  https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.html
