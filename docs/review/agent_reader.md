# Decision-reader review: Sections 1 and 3–6

Reviewer: reader (decision reader). Scope: Sections 1, 3, 4, 5, and 6 of `docs/review/paper_under_review.md`, read as a busy, non-technical senior official. I didn't read the code.

## Summary

Section 1 opens well: the first paragraph tells me where large S-band ships go, and the first figure shows it. After that, the paper loses a decision reader in three ways. First, it never says what a "25 km zone" is measured from in plain words. Section 3.1 measures land distance from the coastline next to "ship water," which is itself up to 25 km from the routes. So a port 25 km from the nearest route (Kawaihae) sits inside the 25 km zone, and I can't tell how far from a ship a zone really reaches. Second, several headline claims conflict with the paper's own tables: "every major port" is reached, but Table 5 says Portland, Oregon, and the Chicago port aren't on the network; "most ships drop out at the length step," but Table 1 shows that more drop out at the ship-type step; and the Baton Rouge, Delaware River, and route-end figures change between sections. Third, the zone distances are only examples, and Section 2, which would set the real distances, is blank, so the paper gives me nothing to decide yet. The lower 48 also lacks the land-area figure that Sections 4–6 give for the islands. The number checks I could do by hand (sums, percentages, proxy accuracy) mostly hold.

## How I read each section and figure

| Item | What I understood it to claim (one sentence) | Matches the paper's headline or caption? |
| --- | --- | --- |
| Front matter | These are draft sections; Section 1 maps large-ship routes, Section 3 shows how example zones are drawn, and Sections 4–6 do the same for the islands and Alaska. | Yes. But there is no bottom line for the paper as a whole. |
| Section 1 | Large ships with S-band radars stay on the coasts, the Great Lakes, and a few deep rivers, and they reach every major port. | Matches the headline, but Table 5 contradicts "every major port" (reader-3). |
| Figure 1 | These blue cells are where large ships went in 2024–2025, plus charted lanes and beacons. | Mostly. The caption says cells "that large ships used," but a cell needs 4 or more ships a year to show (reader-10). |
| 1.1 | Ships of 3,000 GT and over must carry a second radar, which in practice is the 3 GHz one. | Yes. "In practice" carries the whole premise and has no source (reader-14). |
| 1.2 | All data are public: AIS positions, NOAA charts, Census boundaries, Corps ports, Wikidata tonnage. | Yes. |
| 1.3 | One day a week for two years (104 days) is enough to catch seasons and avoid one odd year. | Yes. |
| 1.4 | Four tests keep about 1 ship in 12, mostly big cargo ships and tankers, and length 100 m is a good stand-in for 3,000 GT. | Partly. "Most ships drop out at the length step" isn't what Table 1 shows (reader-4). |
| Figure 2 | The 100 m test keeps almost all 3,000 GT ships and almost nothing smaller. | Yes. |
| 1.5 | A 1 km cell is a route if 4 different ships used it in a year (2 near a big port), plus charted lanes and beacons. | Yes. |
| 1.6 | The method was checked three ways, and it reaches 69 of 73 big ports. | Mostly. The heading says "data from outside the analysis," but one check is code against code (reader-19). |
| 1.7 | Large ships go all the way up the Mississippi to Baton Rouge, and the route goes about 35 km past it. | Yes, but Appendix A.4 says 5 km past it (reader-6). |
| Figure 3 | The route on the Mississippi is unbroken from the Gulf to Baton Rouge. | Yes. |
| 1.8 | The busiest ports by ship count are the Gulf ports, LA–Long Beach, and New York; 69 of 73 deep-draft ports are on the network, and all 73 are in the 25 km zone. | Partly. "Reach every major U.S. port" versus four "No" rows (reader-3). |
| 1.9 | On most long rivers, fewer than half the ships at the mouth reach the top port, but every top port still sees ships every year. | Yes. Some numbers inside conflict (reader-5, reader-7). |
| 1.10 | The routes count ships required to carry the radar, miss Navy ships with AIS off, and thin out far offshore. | Yes. |
| Section 3 | Each part of the band can get its own zone width, drawn from the same routes; the widths shown are examples, not results. | Yes. |
| Figure 4 | These four maps show how much land falls in each example zone. | Partly. The caption says "land within that range's distance of large-ship water," and the text says a zone covers water and land, measured from the coastline (reader-1). |
| 3.1 | A zone is the ship water plus the land within the zone distance of the coast that faces that water. | I couldn't tell what "faces ship water" means or how far from a ship the zone edge is (reader-1). |
| Section 4 | Hawaii uses a different route rule, and even a 50 km zone covers 95% of the state's land. | Yes. |
| 4.1 | Hawaii counts ship-days instead of distinct ships, because a few dedicated cargo ships run the inter-island lanes. | Yes, after two readings. |
| Figure 5 | Hawaii routes link the main ports and circle the Big Island. | Yes. |
| Figure 6 | Most of Hawaii is in the 25 km zone and almost all is in the 50 km zone. | Yes. |
| Section 5 | Alaska uses older data, the ship-days rule, and satellite data offshore, and the zones cover 12% to 27% of the land. | Yes. |
| Figure 7 | Alaska routes follow the coast, with charted lanes in the Bering Sea and satellite lanes south of the Aleutians. | Yes. |
| Figure 8 | Only the coastal fringe of Alaska is in any zone. | Yes. |
| 5.3 | The satellite cutoff is the weak point, but halving or doubling it changes the land in the zones by under 10%. | Yes, but I couldn't tell whether "4%" means percent or percentage points (reader-12). |
| Section 6 | Puerto Rico and the U.S. Virgin Islands use the lower-48 rules, and a 25 km zone covers 96% of the land. | Yes. |
| Figure 9 | Routes ring Puerto Rico and reach every port but Mayaguez. | Yes. |
| Figure 10 | Almost all of Puerto Rico and the U.S. Virgin Islands is in the 25 km zone. | Yes. |

## Findings

| ID | Severity | Location | Finding | Evidence | Proposed fix |
| --- | --- | --- | --- | --- | --- |
| reader-1 | Wording (decision-critical) | 3.1; Figure 4 caption; 4.2 | The paper never says in plain words what a "25 km zone" is measured from. 3.1 measures land distance from the coastline "where it faces ship water," and ship water is any water within 25 km of a route cell. So the zone edge can be up to zone distance + 25 km from the nearest route, plus the distance from the route to the coast. Figure 4 says "within that range's distance of large-ship water," and the front matter says zones are drawn "from the Section 1 routes." A reader takes "25 km" to mean 25 km from a ship. Proof that it doesn't: Kawaihae is 25 km from the nearest route cell but is "inside even the 25 km zone." | paper_under_review.md:297, 312, 318–319, 348 | Add one plain sentence and a simple sketch: "A 25 km zone reaches 25 km inland from the shoreline next to waters ships use; ship water is all water within 25 km of a route, so the zone edge can sit up to about 50 km from a route." Define "faces." |
| reader-2 | Wording (decision-critical) | Section 2; Section 3 | Section 2 is blank, and every zone distance is an example. A decision reader has nothing to decide from these sections, and the paper doesn't say what decision they feed or when the EMC distances arrive. | paper_under_review.md:287–297 | Add a two-line note at the top of Section 3: what decision the zones support, and that Section 2 (date or dependency) will set the distances. |
| reader-3 | Number | Section 1 intro; 1.6; 1.8 | "They reach every major port" and "All 24 major ports in the check list are reached," and the list includes Portland, OR, and Chicago, IL. But Table 5 says Port of Portland, OR (5.1 km) and Illinois International Port (Chicago, 12.2 km) are not on the route network. The text explains it as a Corps reference-point offset, but the headline still reads as a contradiction. Table 5 also rates Longview (4.8 km) and Philadelphia (3.8 km) "Yes," while Panama City (0.2 km) is "No," so "Distance to route" doesn't predict "On the route network." | paper_under_review.md:11, 119, 133, 161, 195, 207, 232 | Say "every major port, measured at the berths; two Corps reference points sit 5–12 km from the berths." Add a column note that "on the network" means connected to open water, not distance. |
| reader-4 | Number | 1.4, paragraph after Table 1 | "Most ships drop out at the length step" is wrong by Table 1. The ship-type step removes 14,119 ships (22,414 to 8,295) and the length step removes 5,541 (8,295 to 2,754) on 2024-07-10. Reports: 3,956,063 against 3,785,380. Same on 2025-07-09. | paper_under_review.md:63–65, 69 | "After the ship-type test, most remaining ships drop out at the length step." |
| reader-5 | Number | 1.9, Delaware River | The text says traffic drops "to about 60 above Philadelphia," but Table 6 puts 123 large ships at the head port, Trenton, which is above Philadelphia. Both can't hold. It's also surprising that 100 m ships reach Trenton (Unverified). | paper_under_review.md:265, 272 | Check the Trenton count and head-port choice. Fix whichever number is wrong, or explain the 3 km counting window. |
| reader-6 | Number | 1.7 | 1.7 says the route continues "about 35 km past" Baton Rouge, to 30.77° N. Appendix A.4 says "The route ends about 5 km above Baton Rouge." | paper_under_review.md:125, 460 | Use one figure in both places. |
| reader-7 | Number | 1.7; 1.9; Table 6 | Baton Rouge counts disagree: 1.7 says 263 ships (138 in 2024, 139 in 2025); Table 6 and the 1.9 bullets say 262 (138 and 138). Appendix A.4c says about 300. Mississippi length is 360 km (Table 6), 356 km (1.9 text), and 352 km (A.4). | paper_under_review.md:125, 266, 274, 277, 474 | Use one count and one distance, or state in one place why each differs. |
| reader-8 | Number | 1.4 vs A.7 | 1.4 says "about 1 ship in 12" passed; A.7 says "about 1 ship in 11" for the same day. 1,980 / 22,414 = 1 in 11.3; 1,886 / 23,548 = 1 in 12.5. | paper_under_review.md:57, 498 | Say "about 1 ship in 11 or 12" in both, or give the percentage (8–9%). |
| reader-9 | Number | Table 3 vs Appendix A | Table 3 gives 658,865 AIS cells. Appendix A.1, A.5 (9,130 + 649,737), and A.6 (336,369 + 322,498) all give 658,867. A.1 also calls 658,867 "route cells," but total route cells are 675,763. Section 6.1 then cites "the same one-cell boundary difference seen in the lower 48," which Section 1 never mentions (1.6 says the counts matched exactly). | paper_under_review.md:104, 108, 117, 428, 436, 482, 490 | State the MATLAB–Python cell difference once in 1.6 and use one AIS-cell count throughout. |
| reader-10 | Wording | Figure 1 caption | "Each dark blue mark is a 1 km cell that large ships used" implies any use. A cell needs 4 or more ships in a year (2 near a big port). | paper_under_review.md:15, 95 | "...a 1 km cell used by at least 4 large ships in a year (2 near a major port)..." |
| reader-11 | Number | 4.2, 6.1 land areas | Land totals are grid-cell totals and exceed official land area. Hawaii 100 km total is 17,573 km² against 16,635 km² (Census). Puerto Rico plus USVI is 9,970 km² against 9,216 km² (8,868 + 348). Alaska's 1.53 million km² grid exceeds the 1,477,953 km² for the whole state, even though the grid drops the islands west of 180°. Percentages are fine; the km² figures read as official areas. | https://www.census.gov/geographies/reference-files/2010/geo/state-area.html.html | Label as "land cells (km²)" or scale to official areas. Say once that coastal cells count whole. |
| reader-12 | Number | 5.3 | "The land in the 25, 50, and 100 km zones grows by 4%, 3%, and 2%." I couldn't tell whether that's relative (12% becomes 12.5%) or percentage points (12% becomes 16%). | paper_under_review.md:401 | Give the new shares or areas: "12% becomes 12.5%." |
| reader-13 | Wording | Section 3 | Sections 4–6 each give land area and share per zone; Section 3 gives none for the lower 48, which is the case a decision maker most needs. | paper_under_review.md:295–323 vs 356–358, 388–390, 420–422 | Add land area (and, if available, population) inside each example zone for the lower 48. |
| reader-14 | Wording | 1.1 | "In practice, large merchant ships carry the 3 GHz (S-band) radar" is the premise of the whole paper and has no source. SOLAS allows a second 9 GHz radar instead. | paper_under_review.md:21 | Cite a source for the share of 3,000 GT ships that fit S-band, or soften to "most." |
| reader-15 | Wording | Section 6 vs 5.1 | Puerto Rico at "about 60 large ships a day" is "dense enough for the lower-48 rule," but Alaska at a median of 54 a day is "sparse" and needs ship-days. The reason sounds arbitrary to a reader. | paper_under_review.md:373, 408 | Give the real reason (for example, route connectivity under each rule, as Table 8 shows for Hawaii). |
| reader-16 | Wording | Title; Section 3 | The title says "2.7 GHz Study," but the paper only discusses 2900–3100 MHz. It never says why ships matter only above 2900 MHz or what uses 2700–2900 MHz. | paper_under_review.md:1, 297 | Add one sentence on the 2.7–3.1 GHz study band and why this paper covers 2900–3100 MHz. |
| reader-17 | Wording | 6.1 | Hawaii and Alaska each say all ports lie inside the 25 km zone. Section 6 doesn't say whether Mayaguez (30 km from a route) is inside it. | paper_under_review.md:348, 380, 412 | Add "All eight ports lie inside the 25 km zone" if true. |
| reader-18 | Wording | 6.1 | 50 km zone is "all but a few small cells" and 100 km is the full area, yet both show 9,970 km². | paper_under_review.md:421–422 | Give one more digit or say "rounds to 9,970 km²." |
| reader-19 | Wording | 1.6 | "Three checks test the filter and the routes against data from outside the analysis," but the second check compares the Python and MATLAB code, not outside data. "4,129 of 5,674 ships matched" introduces 5,674, which 1.4 never mentions. | paper_under_review.md:114, 116–117 | "Three checks test the filter, the code, and the routes." State the 5,674 in 1.4. |
| reader-20 | Wording | 1.8, Table 5 | "Ranked by total tonnage," but total tonnage isn't shown, ranks skip (17, 19, 21...), and the foreign-trade column isn't in rank order (Corpus Christi 125.7 sits below South Louisiana 112.7). A reader thinks the table is broken. | paper_under_review.md:163, 169–171, 185 | Add a note: "Rank is the Corps national rank by total tonnage, including inland ports, so ranks skip." Or add the total-tonnage column. |
| reader-21 | Wording | Throughout | Terms and acronyms used before they are defined, or never defined: "S-band" and "racons" (Figure 1 caption, defined in 1.1); "AIS" (1.2 table, defined after it); "deep-draft" (Section 1 intro, defined in 1.5); "ship water" (Figure 4 caption, defined in 3.1). Never defined: SOLAS, IMO, NOAA, MMSI (expanded), "fairways and traffic separation schemes," shapefile/KML/KMZ, "Corps reference point," "Head of Passes," "shore-mode method" (4.2, not used anywhere else), "great-circle," "operating days," "Garden City" (not tied to Savannah), and "ship-days absorbs it." | paper_under_review.md:11, 15, 19, 21, 31, 39, 98, 110, 277, 312, 320, 354, 375, 400 | Define each at first use or add a short glossary. Replace "shore-mode method" with "the Section 3.1 method." |
| reader-22 | Wording | 1.4, 1.8, 1.9, 4.1, 5.1 | Places I would stop reading: Tables 1 and 2 (filter step counts); Table 5 (73 rows); the 1.9 cost formula "(1 + 100 / ships)"; the Jaccard calibration in 4.1; the satellite cutoff paragraph in 5.1. None of them changes a decision; all of them sit before the zone results. | paper_under_review.md:59–83, 165–241, 249, 333, 375 | Move them to the appendix and leave one sentence with the takeaway in each place. |

## Checked and found correct

- 1.4 proxy figures: 3,801 / 3,873 = 98.1%; 3,801 / 3,818 = 99.6%; 3,873 − 3,801 = 72 dropped; 45 + 22 + 5 = 72.
- Table 2 totals: 1,980 and 1,886 match the last row of Table 1.
- Table 3 total: 658,865 + 15,782 + 1,099 + 17 = 675,763.
- Table 4: 15 ports, all with 1,000 or more ships, as the text says. Corps ranks match Table 5.
- Table 5: 73 rows, 4 marked "No," all 73 "Yes" for the 25 km zone.
- 1.9 headline: 10 of 15 corridors have a share under 50%. The smallest yearly head count is 16 (James).
- Hawaii shares: 12,351 / 17,573 = 70%; 16,720 / 17,573 = 95%.
- Alaska shares: 179,047, 261,953, and 409,521 of 1.53 million km² = 11.7%, 17.1%, and 26.8%.
- Puerto Rico and USVI: 9,583 / 9,970 = 96%; 41,237 + 2,608 = 43,845.
- 40 nautical miles = 74 km. A 625 km² hexagon is about 27 km across flats.
- SOLAS V/19 carriage rule (9 GHz at 300 GT; 3 GHz or a second 9 GHz at 3,000 GT) is stated correctly.
- Each section opens with its result first (Sections 1, 4, 5, 6 each lead with the routes and the zone share).

## The three things I'd remember

1. Large ships stay on the coasts, the Great Lakes, and a few deep rivers; the Mississippi up to Baton Rouge is the one long inland reach.
2. The zone distances are only examples; the real ones wait on an EMC analysis that isn't written yet.
3. On the islands, even the smallest zone covers almost everything (Hawaii 70%, Puerto Rico 96%); in Alaska, even the largest covers about a quarter.

Are these the three the paper most wants me to remember? Only partly. The paper seems to want me to remember: (a) the routes are built from public data and checked (the 100 m proxy is right 98–99% of the time, and the routes reach every major port); (b) the routes reach every major port, including Baton Rouge; and (c) zones can differ by frequency and always nest, so the method is ready once Section 2 sets distances. I'd keep (b), and partly (c), but I'd remember that the distances are placeholders more than that the method is ready. I wouldn't keep (a): the checks sit inside dense tables, and the "every major port" claim is undercut by Table 5. The paper also lacks a one-paragraph bottom line for the whole document, which would tell me which three things to keep.
