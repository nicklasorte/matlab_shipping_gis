# Plan: large-ship routes in foreign waters near U.S. land

DRAFT//PRE-DECISIONAL

Date: November 19, 2026. Answers review item R5MET-4 (St. Lawrence below
Montreal has no route cells) and the wider question: which foreign waterways
carry large ships close enough to U.S. land to put U.S. land inside a zone?

## The gap and why it exists

The routes come from MarineCadastre AIS, which is built from U.S. Coast Guard
terrestrial receivers (NAIS). A ship in foreign water shows up only when a U.S.
receiver hears it. The zone method already handles foreign sources correctly:
route cells in foreign water are sources, and only zone *water* nearer foreign
land is clipped. The problem is missing input, not method.

## Screening result

`python/foreign_waterway_screen.py` samples hand-placed waypoints along each
main foreign ship channel every 5 km and measures the distance to U.S. land
(Natural Earth 1:10m) and to the nearest AIS route cell. It then estimates the
U.S. land a zone around the uncovered reach would add beyond the current
zones. Outputs: `outputs/foreign_waterways/channel_screen_rev1.csv` and
`added_land_rev1.csv`.

| Waterway | Closest to U.S. land | Uncovered channel within 25 / 50 / 100 km of U.S. land | New U.S. land, 25 / 50 / 100 km zones (km²) |
| --- | --- | --- | --- |
| St. Lawrence, Montreal to Sept-Îles | 55 km | 0 / 0 / 270 km | 0 / 0 / 5,058 |
| Chatham Sound (Prince Rupert) and Portland Canal (Stewart) | 0 km (the canal is the border) | 165 / 195 / 205 km | 2,331 / 748 / 108 |
| Bay of Fundy to Saint John | 46 km | 0 / 40 / 50 km | 0 / 3 / 88 |
| Northern Gulf of California (Puerto Peñasco) | 84 km | 0 / 0 / 20 km | not computed (minor port) |
| Ensenada approach | 79 km | covered | 0 |

What this shows:

- **St. Lawrence:** route cells stop near Sorel, about 50 km below Montreal.
  From Québec City to about Rimouski the channel runs 57 km to 100 km from
  northern Maine, so it matters only for the 100 km zone (3030–3070 MHz). It
  would add about 5,100 km² of Maine, 0.4% of the lower-48 100 km land area
  (1,264,979 km²). Every ship below Montreal is ocean-going, so the S-band
  carriage case is strong (unlike the Great Lakes lakers).
- **Prince Rupert and Stewart:** the largest effect per kilometer. Portland
  Canal is the Alaska–British Columbia border and Chatham Sound is next to
  U.S. islands, so the gap adds about 2,300 km² to the Alaska 25 km zone.
  Prince Rupert is a major container, coal, and grain port.
- **Bay of Fundy:** already covered except about 40 km near Saint John; adds
  under 100 km².
- **Already covered:** Detroit and St. Clair rivers, Toronto and Hamilton,
  Juan de Fuca and Haro Strait, Vancouver, Ensenada, Freeport (Bahamas).

Screening limits: waypoints are read from charts by eye; Natural Earth is
coarser than the Census layers the zones use; added areas are for a buffer of
the uncovered reach, not a rerun. Still to screen: British Virgin Islands
(next to the U.S. Virgin Islands), the Russian side of the Bering Strait, and
the Canadian Beaufort Sea.

## Public data sources

| Source | What it gives | Fit |
| --- | --- | --- |
| DFO, *Vessel Density Mapping of AIS Data in the Northwest Atlantic*, 2013–2024 (Open Government Licence – Canada) | Canadian Coast Guard terrestrial plus satellite AIS, 1 km cells, vessels per day per km² from track counts, classes Cargo, Tanker, Fishing, Passenger, Other (DFO Tech. Rep. 3520) | **First choice for the St. Lawrence and Fundy.** 2024 matches our years. The extent (38° N to 62° N) overlaps our U.S. East Coast routes, so it can be calibrated. No length filter; how far upriver it goes needs checking. |
| World Bank / IMF *Global Shipping Traffic Density*, 2015–2021 (CC BY 4.0) | AIS position counts in 0.005° cells, "Commercial" layer | **First choice for Chatham Sound,** and a cross-check everywhere. Older years, positions not ships, no length filter. |
| MarineCadastre raw AIS we already have | Any below-threshold reports in the gaps | Check first: it shows where U.S. reception ends. |
| Laurentian Pilotage Authority, Port of Québec, Prince Rupert Port Authority annual statistics | Vessel calls and pilot assignments | Corroboration of traffic volume, not geometry. |
| Commercial AIS (Spire, MarineTraffic, and others) | Full coverage | Out of scope: not public. |

## Method

Treat a calibrated density layer as an extra source layer, in the same way
the islands analysis calibrated the NOAA transit counts (rule C in
`python/ship_route_rules.py`):

1. In the overlap with our AIS (U.S. waters from Chesapeake Bay to Maine, and
   the St. Lawrence from Montreal to Sorel), find the DFO Cargo + Tanker
   density threshold whose cells best match our route cells (highest Jaccard
   index).
2. Hold out a test area (Gulf of Maine) and report the match there before
   using the threshold anywhere new.
3. Apply the threshold only in foreign water outside our AIS coverage, so no
   U.S. cell changes source.
4. Feed the result to `shipping_zone_rev1` as a new optional input
   `p.external_source_mask` (like fairways and racons), logged and counted
   separately so Table 8 can show it as its own row.

## Steps

| Step | Work | Output | Where |
| --- | --- | --- | --- |
| F1 | Commit the screen (done, Python); add the MATLAB twin; screen the BVI, Bering Strait, and Beaufort | `outputs/foreign_waterways/`; twin agrees exactly on route distances and to 1% on areas | Cloud, then Mac |
| F2 | Count our raw 2024–2025 large-ship reports below the threshold in the St. Lawrence, Fundy, and Chatham Sound boxes | Where U.S. reception ends, by reach | Mac |
| F3 | Download DFO 2024 (GeoTIFF) and the World Bank Commercial layer; check DFO's upriver extent | `data/external/` with a source README | Mac (large files) |
| F4 | Calibrate and hold-out test the density threshold (Python and MATLAB) | Threshold, Jaccard on calibration and test areas | Cloud and Mac |
| F5 | Add `p.external_source_mask` to `shipping_zone_rev1` with a test; a `decision_variant` `foreign_sources` (lower 48) and an Alaska equivalent | Code, tests | Cloud |
| F6 | Run the variant on the commit stamped by the batch; zone areas, population, deep-draft ports | New Table 8 row; Alaska row | Mac |
| F7 | Paper: Section 3.1 coverage edge sentence (closes R5MET-4 either way), the new row, sources | Doc edits (sourced content as plain edits) | Cloud |

## Decision for Nick

**D12: add foreign-water sources?** Options:

- **A. Add them to the base** (St. Lawrence to Rimouski, Chatham Sound,
  Portland Canal, Fundy). For: these are ocean-going SOLAS ships with S-band
  radar, close to U.S. land. Against: a second data source with a different
  method; DFO counts aren't distinct large ships.
- **B. Report them as a Table 8 row only.** For: keeps one source in the
  base. Against: the base then knowingly omits ships near Maine and southeast
  Alaska.
- **C. State the coverage edge only.** Cheapest; closes R5MET-4 as a
  disclosure.

## Checks

- F4 hold-out Jaccard reported before use; the threshold must not be tuned on
  the test area.
- Python and MATLAB twins agree (stated tolerance per step).
- A rerun that changes land areas needs a reason and a paper update
  (CLAUDE.md); this one would change the lower-48 100 km and Alaska figures.
- Human review: D12 is Nick's call.

## Sources

- Veinot, Nicoll, Rozalska, and Coffen-Smout, *Vessel Density Mapping of 2019
  AIS Data in the Northwest Atlantic*, Can. Tech. Rep. Fish. Aquat. Sci. 3520
  (2023): https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41105163.pdf
- DFO, *Vessel Density Mapping of 2024 AIS Data in the Northwest Atlantic*:
  https://donnees.iriu.ca/dataset/27b450d8-3a9a-460a-8f71-587737b2cdf4
- World Bank, *Global Shipping Traffic Density*:
  https://datacatalog.worldbank.org/search/dataset/0037580
- NOAA, *Nationwide Automatic Identification System 2025*:
  https://www.fisheries.noaa.gov/inport/item/77594
