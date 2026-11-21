# Round 6 review: Section 7 (Guam and the Northern Mariana Islands)

DRAFT//PRE-DECISIONAL

Four blind agents reviewed `section7_under_review.md` at paper rev 662: numbers, method and code, style and Section 508, and an opposing reader.

## Numbers
Every number reproduced (1,468 AIS cells; 231 links, 229 new; 257 / 318, 116 / 5, 5 / 2, 0 cells at the ports; 872 / 531 / 647 km²; 1,019 km² land; 341 and 225 km² gains; 147 km² outside, all north of 16° N). Fixed: zones merge at 50 km, not 100 km (R6NUM-1). Open: stale grid comment in `init_shipping_zone_guam_rev1.m` header (R6NUM-3); MarineCadastre "may be incomplete" quote traces only to the Guam plan (R6NUM-4).

## Method and code
| ID | Finding | Disposition |
| --- | --- | --- |
| R6MET-1 | "All 4 ports reach a route" is true by construction (links start at the port positions) | Text now says so |
| R6MET-2 | Ship-days 6 not compared with the lower-48 rule or NOAA counts for Guam (G3) | Threshold sensitivity run done (Table 10, Section 7.3): with the links the zones are 872 km² at every threshold; without them 474 to 847 km² at 25 km. NOAA comparison done Nov 21 (`python/guam_route_rules.py`, Section 7.3): Jaccard 0.22 at K=6, T=8 (Hawaii 0.25); NOAA also shows no Saipan or Tinian lane. Lower-48 rule itself (4 ships in one year) not reproducible from the combined-years `unique_ships` grid; open |
| R6MET-3 | No MATLAB twin of the link script; no Guam test | In 7.3; open |
| R6MET-4 | 35 link cells lie on land (harbor ends) | In 7.3; snapping the ends to water open (areas unaffected: that land is within 25 km of a route anyway; not verified by rerun) |
| R6MET-5 | Links join networks through the 3-cell link rule | Open |
| R6MET-6 | Straight lines in latitude and longitude | In 7.3 |
| R6MET-7 | Figure script asserted exact counts | Fixed: reads counts from the log |

## Style and Section 508
Fixed: CNMI defined as the Commonwealth; "lies among them"; "200-nautical-mile"; hyphen and unit wording; Figure 11 cited in 7.1; caption notes polygons versus cells; alt text corrected (cells fan west and northwest of Guam); legend swatches, larger AIS cells, white halo under the link, Apra label moved, 50 km scale bar, nonbreaking space in the headline. Open: number style for "6 ship-days" and "4 ports" (kept as numerals with units; check against Section 4.1); marking appears at the top of the figure only.

## Opposing reader
Critical: the straight-line links drive the result (+64% at 25 km, +35% at 50 and 100 km). Disclosed; text now leads with both numbers and the uplift. Major: ship-days rule borrowed from Hawaii; AIS reception; carriage of S-band radar not mentioned in Section 7. Open: sensitivity run over ship-days 3, 6, 12 with and without links; independent traffic source for Saipan and Tinian; carriage statement.
