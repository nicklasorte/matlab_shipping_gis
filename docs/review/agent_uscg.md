# Coast Guard reviewer: routing measures, VTS areas, and AIS

DRAFT//PRE-DECISIONAL

**Role note.** This review checks the paper against what the U.S. Coast Guard
has published: Port Access Route Studies (PARS), 33 CFR Part 161 (VTS),
33 CFR 164.46 (AIS carriage), and Navigation Center (NAVCEN) and acquisition
material on the Nationwide AIS (NAIS). The reviewer doesn't speak for the
Coast Guard.

## Summary

The routes match the main routing measures the Coast Guard recommends where
the paper has data. Route cells lie inside the Pacific Coast PARS Offshore
Fairway on every transect from 34.75° N to 47.25° N. The charted Bering
Strait two-way route is covered from 58.75° N north. All Alaska passages and
VTS areas tested are within about 3 km of a route cell. Four problems stand
out. First, the cached NOAA routing-measure file holds 28 features from three
Mid-Atlantic port approaches. The live NOAA layer holds 291 features in the
same box, including the Gulf of Mexico shipping safety fairways. About 7,400
charted cells are left out of the routes, against the 1,099 fairway cells the
paper reports. Second, the Alaska routes stop near Red Dog (about 67.7° N), so
the Alaskan Arctic Coast PARS route from the Bering Strait to the Canadian
border has no route cells. Third, the paper gives shore-receiver range as
40 nmi. The Coast Guard gives 50 nmi for receiving, and the shore data miss
the Bering Strait lanes even close to shore. This weakens the premise behind
the Alaska satellite cutoff. Fourth, the VTS check lists 10 areas, but
33 CFR 161.12 lists 12, including Buzzards Bay and Prince William Sound. Both
are covered by routes. The AIS description also needs fixes: AIS reporting
rate, the U.S. Official Number in the IMO field, and data clipped at the EEZ.

## Findings

| ID | Severity | Location | Finding | Evidence | Proposed fix |
| --- | --- | --- | --- | --- | --- |
| uscg-1 | Zone | Sec. 1.5 item 4, Table 3, Sec. 1.10 "Not for navigation"; `data/fairways_rev1.geojson`; `load_shipping_fairways_rev1.m:33-46` | The cached NOAA routing-measure file is incomplete. It holds 28 features, all between 36.8° and 40.6° N and 76° and 73° W (New York, Delaware Bay, Chesapeake approaches). After the theme filter, 17 are kept. No "Shipping Fairways Lanes and Zones" features are in it, so the Gulf of Mexico shipping safety fairways are missing, along with the Pacific, New England, Florida, and Great Lakes TSS and precautionary areas. The paper says charted fairways and TSS are added everywhere. | A live query of the same ENC Direct layer (MapServer/0, envelope -130,22,-66,50) on 2026-11-12 returned 291 features. 192 have the kept themes: 101 TSS lanes, 48 precautionary areas, 35 fairways, and 8 recommended routes. Rasterized to the 0.01° grid, they cover 36,280 cells. 7,372 of these are not route cells now (3,310 in the Gulf, 366 Pacific, 1,246 south of 24.5° N). The paper reports 1,099. 22 features have parts more than 5 km from any route cell. Most are Gulf fairways off Louisiana (for example, near 29.09° N 90.96° W, up to 53 km), plus one near 26.26° N 83.03° W (70 km). Run log: `outputs/2024_2025/shipping_zone_2024_2025_run.log:109` ("Fairway cells: 4281"). Service: https://encdirect.noaa.gov/arcgis/rest/services/NavigationChartData/MarineTransportation/MapServer/0. The Galveston-Sabine PARS (final report March 2026) found the existing Gulf safety fairways "adequate": https://www.govinfo.gov/content/pkg/FR-2026-08-07/html/2026-16119.htm | Download the layer again with paging and a feature-count check against `returnCountOnly`. Fail the run if the count is far below the layer total. Rerun and update Table 3. Clip to the U.S. EEZ so non-U.S. TSS (for example, Yucatán) don't count. |
| uscg-2 | Zone | Sec. 5 intro, Sec. 5.2, Figures 7 and 8 | The Alaska routes stop near Red Dog and Kivalina (about 67.7° N). Nothing on the Chukchi or Beaufort coast north of Point Hope is a route cell. The Coast Guard's Alaskan Arctic Coast PARS (docket USCG-2018-1058) proposes a 4 nmi two-way route from the Bering Strait to the U.S.-Canada border. The paper doesn't say this coast is left out. | Distance to the nearest Alaska route cell (`outputs/2018_2019/alaska/shipping_zone_alaska_2018_2019_routes.shp`): offshore Point Hope 202 km, Point Lay 240 km, Wainwright 382 km, Point Barrow 535 km, Prudhoe Bay 1,037 km. The PARS route is described in the Marine Mammal Commission comment letter of 2020-11-10: https://www.mmc.gov/wp-content/uploads/20-11-10-Newell-USCG-Alaskan-Arctic-Coast-PARS-with-appendices_reduced.pdf. Study notice: https://www.govinfo.gov/content/pkg/FR-2018-12-21/html/2018-27604.htm | State that the Arctic coast north of Point Hope has no route cells and why: seasonal traffic below the ship-days cutoff, and sparse shore receivers. Then decide whether to add the proposed Arctic route as ship water, as the paper already does for charted lanes. Or call it out of scope in Sec. 5.3. |
| uscg-3 | Zone | Sec. 5.1 "Charted lanes", Figure 7 | The southern part of the PARS-recommended Bering Sea two-way route has no route cells. This is the part from Unimak Pass north (54.7° to 58.7° N), part of the preferred Alternative 1 and of Alternative 2. The charted lanes start at about 58.75° N. No land lies within 100 km of the gap, so the land zones likely don't change, but the routes don't match the PARS route there. | Sampled along the Alternative 2 waypoints (Bering Strait PARS conclusions): distance to route cells is 40, 99, 167, 215, 169, 110, and 51 km between 55.2° and 58.25° N, and 0 km from 58.75° N to 66.1° N. https://navcen.uscg.gov/sites/default/files/pdf/PARS/Bering_Strait_PARS_Conclusions.pdf | Say in Sec. 5.1 that the charted lanes cover the Bering Strait part only and that the PARS route south to Unimak Pass isn't charted or in the routes. Or add it as ship water. |
| uscg-4 | Number | Sec. 5.1 "Satellite lanes", Sec. 5.3; `python/alaska_satellite_lanes.py:52`; `python/check_alaska_kapsar.py:16` | The paper says Coast Guard shore receivers "reach about 40 nautical miles (74 km)" and that routes are complete inside 74 km. The Coast Guard gives a different number, and the data show coverage isn't uniform. Shore-only AIS routes miss the Bering Strait lanes even about 30 km from Cape Prince of Wales. The satellite cutoff (272 operating days, Jaccard 0.57) is tuned on hexagons inside 74 km, so this premise matters. | Coast Guard: NAIS Increment 2 "transmits and receives data up to 24 nautical miles" and "receives data up to 50 nautical miles": https://www.dcms.uscg.mil/Our-Organization/Assistant-Commandant-for-Acquisitions-CG-9/Newsroom/Latest-Acquisition-News/Article/1664712/coast-guard-nais-transitions-to-sustainment/. Computed: AIS-only route cells (`..._routes_ais_only.shp`) are 119 to 138 km from the charted Bering Strait route at 65.4° to 66.1° N, and 72 to 264 km along the whole charted route. | Cite the Coast Guard figure (24 nmi two-way, 50 nmi receive). Say that coverage depends on where receivers are and is sparse in western and northern Alaska. Tune the cutoff only where receiver coverage is shown, for example Southeast and Southcentral Alaska. Or report how the cutoff changes with a 50 nmi (93 km) range. |
| uscg-5 | Number | Sec. 1.2, paragraph after the table; Sec. 1.4 item 4 | The paper says "AIS ... reports give each ship's position about once a minute." Class A transponders report every 2 to 10 s underway and every 3 min at anchor. The one-minute rate comes from MarineCadastre thinning the data. The paper also says the grid takes in waters "several hundred kilometers offshore" and the Florida Straits, but MarineCadastre clips its data to the U.S. EEZ. | NAVCEN: "every 2 to 10 seconds while underway, and every 3 minutes while at anchor": https://navcen.uscg.gov/node/84. NOAA metadata for the MarineCadastre NAIS files: "filtered to a one-minute frequency rate", data "subset to ... vessels broadcasting within the Exclusive Economic Zone", from "all U.S. Coast Guard NAIS terrestrial receivers": https://www.fisheries.noaa.gov/inport/item/70162 | Write: "Ships transmit AIS positions every few seconds; MarineCadastre thins the data to one report per ship per minute and keeps only the U.S. EEZ." Say that grid cells outside the EEZ have no AIS data. |
| uscg-6 | Number | Appendix A.3, A.17, Figure A-17; `init_shipping_zone_rev1.m:114-120`; `init_shipping_zone_alaska_rev1.m:90` | The paper checks "10 Vessel Traffic Service areas." 33 CFR 161.12, Table 1 lists 12 VTS and VMRS areas: 11 in the lower 48 (Buzzards Bay is missing from the check) and Prince William Sound in Alaska (Alaska checks no VTS). Los Angeles-Long Beach, which the paper includes, is a VMRS, like Buzzards Bay. Both missing areas have route cells. | Table 1 to § 161.12(c): https://www.law.cornell.edu/cfr/text/33/161.12. Computed distance to the nearest route cell: Buzzards Bay Entrance Light 1.0 km, Cape Cod Canal (both ends) 0 km; Hinchinbrook Entrance 0 km, Valdez Arm 0 km, Valdez Narrows 0 km. | Add Buzzards Bay and Prince William Sound. Report "10 of 11 lower-48 VTS and VMRS areas, and Prince William Sound." Label Los Angeles-Long Beach and Buzzards Bay as VMRS areas. |
| uscg-7 | Wording | Appendix A.3, A.17; `outputs/2024_2025/shipping_zone_2024_2025_vts_check.csv:7`; `check_ports_rev1.m:70-71` | The VTS check tests one "approximate center" point per area. VTS areas are large: Lower Mississippi runs up to Port Hudson Light (mile 254.5 AHP), Puget Sound reaches west of 124°40′ W, and San Francisco covers 38 nmi from Mount Tamalpais. Also, `on_route_network` is 1 for VTS Louisville, which is 393 km from any route cell. The column reports the network of the nearest cell, not of the site. | 33 CFR 161.12 area descriptions (URL above). Computed at area ends: Port Hudson 1.1 km, Puget Sound west entrance 0 km, Rosario and Haro Straits 0 km, De Tour Reef and Ile Parisienne (St. Marys River) 0 km, Sabine Bank 3.3 km, San Francisco sub-area (ii) 0 km, 25 nmi south of Point Fermin 0 km. | Say "approximate center" in the text, or test against the VTS area boundaries in § 161.12. Set `on_route_network` to false when `reached` is false. |
| uscg-8 | Wording | Sec. 1.4 item 3, Sec. 1.5 item 3, Sec. 1.4 paragraph after Table 1; `ais_cells_py_rev1.py:153`; `ais_large_ship_cells_rev1.m:75` | The paper says the IMO number "is issued to seagoing ships." The Coast Guard encoding guide tells U.S. vessels without an IMO number to enter their U.S. Official Number in that field. This explains the "river towboats [that] also report IMO numbers." The guide also tells push vessels to report dimensions that include the tow and to use ship type 86. Type 86 falls in the 80–89 tanker range, which the filter keeps without the 25 km tug-barge rule. The code tests only that the field isn't empty. | USCG AIS Encoding Guide: "should reflect the vessel's assigned IMO or U.S. Official number, if it lacks an IMO assigned number"; "Push vessels ABCD values should reflect its dimension with its tow ... AIS Ship Code should be 86 (Integrated / Articulated / Push Tug-Barge)": https://www.navcen.uscg.gov/sites/default/files/pdf/AIS/USCG_Encoding_Guide.pdf. The repo's QC finds only 3 to 5 ships with a bad IMO check digit among about 1,480 to 1,730 kept main-filter ships per day (`outputs/2024_2025/qc/ais_qc_2024-01-10.json`, `ais_qc_2024-07-10.json`), so the effect on the main set is small. The towing set isn't checked (Unverified). | Reword: "The IMO field holds an IMO number or, for U.S. ships without one, a U.S. Official Number." Add a 7-digit IMO check-digit test to the filter, or report how many kept ships fail it, including type 86 and the towing set. |
| uscg-9 | Wording | Sec. 1.10 "Ships without AIS" | The limit is stated only for Navy ships. It would be stronger with the carriage rule. 33 CFR 164.46 requires Class A AIS on self-propelled commercial vessels of 65 ft or more. AIS must stay on underway and at anchor, and a ship may switch it off only for safety or security and must log it. So nearly all 100 m merchant ships in U.S. waters broadcast. This also supports keeping ships at any speed. | 33 CFR 164.46(b) and (d): https://www.law.cornell.edu/cfr/text/33/164.46 and https://www.ecfr.gov/current/title-33/chapter-I/subchapter-P/part-164/section-164.46 | Add one sentence citing 33 CFR 164.46, and keep the Navy caveat. |

## Checked and found correct

- **Pacific Coast PARS Offshore Fairway.** Route cells lie inside the
  15 nmi fairway (PAC-PARS 2023 Appendix coordinates, points 1–14 and 39–51)
  on every 0.5° transect from 34.75° to 47.25° N. Route cells fill 13% to
  100% of each transect. The weakest stretch is off central Oregon (44.25° to
  45.25° N, 13% to 27%, largest gap 14 km), which is inside the 25 km ship-water
  link. PAC-PARS reports coastwise cargo ships 25 to 40 nmi offshore and tankers
  at 50 nmi or more, which fits route cells running far offshore on the
  Pacific (Appendix A.2). Source:
  https://www.navcen.uscg.gov/sites/default/files/pdf/PARS/PAC_PARS_FINAL_2023.pdf
- **Atlantic PARS fairways.** The fairways that grew out of the Atlantic Coast
  PARS are still proposed: NPRM USCG-2019-0279, comment period reopened
  2026-05-05. So they aren't charted, and their absence from the ENC layer is
  expected. On transects from 28° to 43.5° N, AIS route cells run 30 to 150 km
  offshore, where the Consolidated Port Approaches PARS puts the coastwise
  fairways. This is a qualitative check: the PARS text gives no coordinates.
  Sources: https://www.federalregister.gov/documents/2026/05/05/2026-08699/shipping-safety-fairways-along-the-atlantic-coast,
  https://WWW.NAVCEN.USCG.GOV/sites/default/files/pdf/PARS/Consolidated_Port_Approaches_PARS_Updated_Mar2023.pdf
- **Charted Bering Strait route** (58.75° to 66.1° N): every sampled point is
  inside route cells. King Island, Little Diomede, and Nunivak are 11 to 15 km
  from routes, which fits the Areas To Be Avoided around them.
- **Alaska passages and ports.** Unimak Pass, Akutan, Dutch Harbor,
  Hinchinbrook Entrance, Valdez Narrows, Kennedy Entrance, Anchorage,
  Whittier, Seward, Kodiak, Dixon Entrance, Chatham Strait, Juneau, Skagway,
  Ketchikan, Sitka, Nome, and Red Dog are each within 1.3 km of a route cell.
- **VTS areas in 33 CFR 161.12.** Every lower-48 area except Louisville (a
  towboat area at McAlpine Locks, 390 km away) has route cells at its center
  and at the ends tested (uscg-7). Leaving out Louisville is correct.
- **Hawaii and Puerto Rico/USVI.** A live ENC Direct query returned 0
  routing-measure features for both grids, so "NOAA charts show no fairways"
  is correct. 33 CFR 161.12 lists no VTS area in either place. I found no PARS
  for Hawaii or Puerto Rico/USVI (Unverified that none exists).
- **Data source (Sec. 1.2).** MarineCadastre files come from Coast Guard NAIS
  terrestrial receivers and are thinned to one minute (NOAA InPort item
  70162). The 2023 metadata extent stops at 51.5° N, which fits the paper's
  statement that Alaska is left out after 2020.
- **Towing-vessel length (Sec. 1.4).** The Coast Guard encoding guide tells
  push vessels to report dimensions that include the tow. That supports the
  paper's explanation of why so many towing vessels pass the 100 m test.
- **Satellite-lane count.** 318,134 added cells (Sec. 5.1) matches
  `outputs/2018_2019/alaska/shipping_zone_alaska_2018_2019_run.log:109`
  (334,651 extra cells, 318,134 not already route cells).

Scratch scripts used for the distance checks are in `/tmp/agent_scratch/uscg/`.
