# Plan: add Alaska and Hawaii to the large-ship routes and zones

DRAFT//PRE-DECISIONAL

Last updated: November 12, 2026

This plan extends the large-ship route analysis (2900–3100 MHz S-band
radars, 2.7 GHz study) from the lower 48 states to Hawaii and Alaska. Hawaii
can use the same method and data as the lower 48. Alaska can't: NOAA's
MarineCadastre AIS files, which the whole analysis is built on, leave Alaska
out for 2022–2024. Alaska needs a different AIS source and a decision.

## Summary

| Area | Same data and method as the lower 48? | Recommended path |
| --- | --- | --- |
| Hawaii | Yes | Rebuild the 104 sample days on a separate Hawaii grid. |
| Alaska | No | Choose an AIS source from the options in [AIS data for Alaska](#ais-data-for-alaska), calibrate it against the lower 48, and label it separately. |

## What MarineCadastre covers

| Area | In MarineCadastre 2023–2024? | Evidence |
| --- | --- | --- |
| Hawaii | Yes | The 2023 metadata says coverage includes "the conterminous United States, Hawaii, U.S. Virgin Islands and Puerto Rico." The 2024 bounding box appears to run west across the 180° meridian, which would include Hawaii, but it's written ambiguously. |
| Alaska | No | The 2024 metadata says Alaska records "have been filtered out of our data products" at the request of the Alaska Marine Data Exchange. The 2022 and 2023 bounding boxes stop at about 50–51.5° N, which leaves out all of mainland Alaska. |
| Puerto Rico and U.S. Virgin Islands | Yes | Named in the 2023 coverage statement. |
| Guam | Unclear | Not named in the coverage statements. Check a sample day. |

Phase 1 confirms all of this on sample days before any build.

## AIS data for Alaska

All options below are AIS-derived. They differ in access, age, and whether
they count distinct ships (what our method needs) or positions or hours.

| Source | What it is | Years | Counts distinct ships? | Access | Fit |
| --- | --- | --- | --- | --- | --- |
| [World Bank Global Shipping Traffic Density](https://datacatalog.worldbank.org/search/dataset/0037580) | IMF AIS (terrestrial and satellite), 0.005° grid (about 500 m), layers for commercial, passenger, oil and gas, fishing, and leisure | January 2015 to February 2021 | No: total AIS positions per cell | Public, CC BY 4.0 | **Recommended public option.** Covers the Bering Sea and the route south of the Aleutians. No length filter, so it needs calibration. |
| [MarineCadastre zone files, 2009–2017](https://marinecadastre.gov/ais) | USCG terrestrial AIS, the same records as our data, split by UTM zone | 2009–2017 | Yes: point records with MMSI, length, type, and IMO | Public, if the Alaska zones still hold records | **Best match to our method if Alaska is present.** Older fleet, terrestrial only. One download settles it. |
| [AIS Vessel Traffic Data – Alaska – USCG Terrestrial – Monthly Totals](https://data.amerigeoss.org/it/dataset/ais-vessel-traffic-data-alaska-us-coast-guard-terrestrial-monthly-totals1) (Axiom Data Science) | Heat-map grids from USCG terrestrial AIS, 500 m Albers grid, by region, ship type, and month | 2009–2016 | Unclear | Listed as not open, no license stated | Possible cross-check. Confirm the license and what the values measure before use. |
| [Arctic Oil Spill Risk Assessment vessel density](https://osra.axds.co/) (Axiom, from Marine Exchange of Alaska AIS) | Vessel traffic density regridded to 10 km | Not stated | No | Viewable; downloads not confirmed | Too coarse for routes; useful as a picture check only. |
| [Arctic Ship Traffic Data (ASTD)](https://pame.is/ourwork/arctic-shipping/astd/), Arctic Council PAME | Satellite and terrestrial AIS for the Arctic, with ship identity at Level I | 2013 to present | Yes, at Level I | Government only: free Level I access for national agencies of signatory Arctic states, including the United States | Strong option for Arctic Alaska if NTIA qualifies. **Not public; needs your OK.** Confirm the coverage south of the Bering Strait. |
| USCG Nationwide AIS (NAIS) historical data, by agency request | The full USCG record set, Alaska included | Current | Yes | Government only, by request to the Coast Guard | Matches our method exactly. **Not public; needs your OK and a request.** |
| Marine Exchange of Alaska | Alaska terrestrial and satellite AIS network | Current | Yes | Subscription or agreement | Out of scope under the public-and-cleared rule. |
| Commercial satellite AIS (for example Spire, exactEarth) | Global satellite AIS | Current | Yes | Paid license | Out of scope under the public-and-cleared rule. |

A non-AIS floor, for checks only: IMO-adopted routing measures (the Bering
Strait two-way routes and the Aleutian Areas to Be Avoided) and the Coast
Guard Port Access Route Studies for Alaska. These are charted lines, not
traffic.

### Recommendation for Alaska

1. Test the MarineCadastre 2009–2017 zone files first. If they hold Alaska
   records, they use the same filter, the same distinct-ship counts, and the
   same code, with an age caveat.
2. If they don't, use the World Bank density layers (commercial and
   passenger), calibrated against our lower-48 routes off Washington state.
3. If you can approve government-only data, request ASTD Level I or USCG NAIS
   records for 2023–2024. Either would let Alaska match the lower 48 exactly.

## How to search for more data sources

The table above is a starting list, not a complete one. Before Phase 3,
spend a few hours searching systematically so the Alaska choice is defensible.
Hawaii is covered by MarineCadastre, so this search is mainly for Alaska, plus
a cross-check source for Hawaii.

### Where to search

| Place | What to look for | Example queries or paths |
| --- | --- | --- |
| [Data.gov](https://catalog.data.gov) and [NOAA InPort](https://www.fisheries.noaa.gov/inport/) | Federal AIS, vessel traffic, and transit-count datasets; check each record's "Geographic extent" and access constraints | `AIS Alaska`, `vessel traffic Alaska`, `vessel transit counts`, `AIS Hawaii` |
| [NOAA NCEI](https://www.ncei.noaa.gov) and [BOEM](https://www.boem.gov) | Archived AIS products and environmental studies with traffic layers (Beaufort and Chukchi lease areas, Cook Inlet) | `AIS`, `vessel traffic`, `Cook Inlet vessel`, `Chukchi vessel traffic` |
| U.S. Coast Guard [NAVCEN](https://www.navcen.uscg.gov) and Port Access Route Studies | How agencies request historical NAIS data; PARS reports with traffic summaries for the Bering Strait, Alaska Arctic coast, and Hawaii | `NAIS historical data request`, `Port Access Route Study Alaska`, `PARS Bering Strait` |
| Regional ocean observing systems: [AOOS](https://aoos.org) (Alaska), [PacIOOS](https://www.pacioos.hawaii.edu) (Hawaii), and their ERDDAP and THREDDS servers | AIS heat maps and vessel density layers with download links | Search each portal's catalog for `AIS` and `vessel` |
| Arctic data archives: [Arctic Data Center](https://arcticdata.io), [PAME ASTD](https://pame.is/ourwork/arctic-shipping/astd/) | Arctic ship traffic datasets and access rules | `ship traffic`, `AIS`, `vessel density` |
| Open research repositories: [Zenodo](https://zenodo.org), [Dryad](https://datadryad.org), [figshare](https://figshare.com), and [Google Dataset Search](https://datasetsearch.research.google.com) | AIS-derived grids published with papers, often under open licenses | `AIS Bering Sea`, `vessel traffic Alaska dataset`, `ship density Hawaii` |
| Literature (Google Scholar, Frontiers in Marine Science, Marine Policy) | Papers on Alaska and Bering Strait traffic; their data-availability statements name sources and stewards | `Bering Strait vessel traffic AIS`, `Alaska shipping AIS analysis`, `Aleutian great circle route AIS` |
| International open data: [World Bank](https://datacatalog.worldbank.org), [Global Fishing Watch](https://globalfishingwatch.org/datasets-and-code/), [EMODnet](https://emodnet.ec.europa.eu) (method reference only) | Global gridded AIS products and how others process them | `shipping traffic density`, `vessel presence` |

Also ask data stewards directly. NOAA's Office for Coastal Management runs
MarineCadastre and may know whether an Alaska release exists for federal
users. AOOS and the Alaska Marine Data Exchange can say what they share and
on what terms.

### How to judge a source

Score every candidate on the same points, and record the result:

1. **Access:** public with an open license, government-only, or paid. Only
   public and cleared sources go in the paper without your approval.
2. **Coverage:** Alaska (including the Bering Sea, Aleutians, and Arctic
   coast) and Hawaii, out to at least 100 km from the routes.
3. **Years:** ideally 2023–2024 to match the lower 48; older data needs an
   age caveat.
4. **Measure:** distinct ships (best), ship hours or transits, or position
   counts (needs calibration).
5. **Fields:** MMSI, length, ship type, and IMO number. Without length and
   type, the large-ship filter can't be applied.
6. **Resolution:** 1 km or finer for routes; coarser grids work only as
   checks.
7. **Receiver mix:** terrestrial only, or terrestrial plus satellite.
   Terrestrial-only data misses traffic far from shore.
8. **Reproducibility:** a stable download link and documented processing.

### How to record it

Keep a sources register at `docs/plans/data_sources_register.csv` with one
row per candidate: name, link, steward, access, coverage, years, measure,
fields, resolution, receiver mix, license, date checked, and decision. The
paper's data-sources appendix cites only the sources marked "used".

## Plan

### Phase 1: Confirm coverage (about half a day)

1. Download one 2024 day and one 2023 day. Count large ships by area to
   confirm Hawaii, Puerto Rico, and the U.S. Virgin Islands are present, and
   check whether Guam is.
2. Download one older MarineCadastre UTM zone file for Alaska (zones 3–8) to
   test the 2009–2017 option.
3. Download the World Bank commercial and passenger layers for the Alaska and
   Washington state areas.
4. Report what each source holds before any build.

**Results (November 12, 2026):**

| Area | Large ships, 2024-07-10 | Large ships, 2023-07-12 |
| --- | --- | --- |
| Hawaii | 27 | 16 |
| Puerto Rico and USVI | 63 | 56 |
| Guam and CNMI | 12 | 16 |
| Alaska | 3 (strays near the Washington state line) | 1 |

- 2023–2024 MarineCadastre files hold Hawaii, Puerto Rico, the U.S. Virgin
  Islands, and Guam, but not Alaska.
- The 2015–2017 daily files hold Alaska (366,000–622,000 reports per sampled
  day), but use vessel-type codes 1001–1025 that need the MarineCadastre
  crosswalk, and the IMO field is blank.
- The 2009–2014 files are monthly UTM-zone file geodatabases. Zone 6 for July
  2014 holds 4.1 million reports from 332 vessels, 88 of them 100 m or longer;
  the IMO field is blank.
- The data-source search added the North Pacific and Arctic dataset (Kapsar
  and others, 2022), which counts unique ships per hexagon by type from
  satellite AIS. It's the strongest public Alaska candidate. See
  `data_sources_register.csv`.

### Phase 2: Hawaii, using the lower-48 method (about one day, mostly unattended)

1. Add a separate Hawaii grid: 17–24° N, 162–153° W, 0.01° cells. The cache
   file names already carry the grid limits, so the lower-48 caches don't
   change.
2. Change `ais_cells_py_rev1.py` to fill several grids in one pass over each
   day's file. This needs the 104 sample days downloaded again, because the
   existing caches were clipped to the lower 48. That takes several hours
   unattended; the lower 48 isn't rebuilt.
3. Apply the same filters (length at least 100 m, IMO required except types
   35 and 55) and the same route rule (at least 4 distinct ships in either
   year).
4. Add Hawaii's USACE Principal Ports:
   - Honolulu and Kalaeloa (Barbers Point) clear the 1-million-ton
     foreign-trade bar and get the port-approach rule.
   - Kahului, Hilo, Nawiliwili, and Kawaihae fall below it and are checked
     like the other smaller coastal ports.
5. Keep the 25 km coastal rule for tug-barges, which carry inter-island
   freight. Check that the routes through the Kaiwi and Alenuihaha channels
   don't break mid-channel; widen the rule for Hawaii only if they do.
6. Draw the frequency-dependent zones (25, 50, 100, and 50 km by band), the
   routes map, and the KML and shapefile outputs. Most or all of Hawaii's land
   may fall inside the 50 km and 100 km zones; compute it rather than assume.

**First results (November 12, 2026),** from `python/ship_island_routes.py`
with the lower-48 rules unchanged:

| Measure | Hawaii | Puerto Rico and USVI |
| --- | --- | --- |
| Route cells | 3,882 | 41,057 |
| Distinct large ships, 2023–2024 | 409 | 2,270 |
| Large ships per sampled day (median, range) | 16 (8–28) | 60.5 (37–91) |
| Share of route cells in the biggest connected piece | 81% | 88% |
| Ports more than 2 km from a route | Hilo (8.8 km), Kawaihae (23 km) | Mayaguez (30 km) |

- Honolulu and Kalaeloa sit on one connected network with the trans-Pacific
  lanes. Kahului and Nawiliwili have short approach spurs that don't connect
  to it.
- The inter-island channels break. The likely cause is the rule, not the
  data: a few dedicated ships serve the neighbor islands, so many lane cells
  see traffic but fewer than four distinct ships a year. Inter-island tugs
  are under 100 m, so tug-barges drop out too.
- Options for Hawaii, for Nick to choose: keep the lower-48 rule and report
  the gaps; lower the distinct-ship threshold for Hawaii; or count a cell when
  enough transits cross it, as the NOAA transit counts do. The zones, maps,
  and MATLAB twin wait for that choice.
- Puerto Rico and the U.S. Virgin Islands form wide swaths through the Mona
  and Anegada passages. Mayaguez is a small port and sits off the network,
  like the other smaller coastal ports.

**Route rules compared (November 12, 2026),** from `python/ship_route_rules.py`.
Each threshold for the new rules was set on the lower 48, as the value whose
route set best matches the paper's network (Jaccard index), then used
unchanged on the islands.

| Rule | Lower-48 match | Hawaii route cells | Hawaii ports connected to Honolulu (of 6) | Puerto Rico and USVI ports connected to San Juan (of 7) |
| --- | --- | --- | --- | --- |
| At least 4 distinct ships a year (paper) | 1.00 | 3,882 | 2 | 5 |
| At least 3 | not calibrated | 7,231 | 3 | 5 |
| At least 2 | not calibrated | 18,178 | 4 | 6 |
| At least 1 | not calibrated | 72,757 | 5 | 7 |
| Ship-days: distinct large ships summed over the 104 days, at least 6 | 0.81 | 6,561 | 4 | 5 |
| NOAA 2024 transits, at least 3 (all vessel groups) | 0.37 | 27,144 | 5 | 7 |

- Ship-days fits the lower 48 best of the new rules and draws the cleanest
  Hawaii network: it follows the Honolulu–Kahului–Hilo cargo loop around the
  Big Island, because a few dedicated ships cross the same cells week after
  week.
- Two distinct ships connects the same four ports but adds scattered one-off
  tracks.
- NOAA transits match the lower-48 network poorly, because they count every
  vessel, including ferries, fishing boats, and tour boats around Oahu. Use
  them as a cross-check, not as the rule.
- Hilo stays 2–9 km from every rule's network; ships likely drop out of
  receiver range in the last few kilometers. Kawaihae joins only with rules
  that count small or occasional traffic.

**Decision (November 12, 2026):** Nick chose the ship-days rule (at least 6)
for Hawaii. Built in MATLAB (`init_shipping_zone_hawaii_rev1.m`, outputs in
`outputs/2023_2024/hawaii/`) and checked against Python (same 6,561 cells).
Every Hawaii port lies inside the 25 km zone; the 25, 50, and 100 km zones
cover 70%, 95%, and all of the land. Written up as Section 4 of the working
paper.

**Queued:** 2025 and 2026 AIS for all grids. MarineCadastre has all of 2025
and 2026 through June 30 (checked November 12, 2026). The 78 weekly days
(2025-01-01 to 2026-06-24) are being cached for the lower 48, Hawaii, and
Puerto Rico and the U.S. Virgin Islands.

### Phase 3: Alaska (one to three days, depending on the source)

1. Build an Alaska grid: 51–72° N, from 129° W across the 180° meridian to
   172° E if the western Aleutians are in scope. Split polygons, buffers, and
   KML at 180°, because they break there.
2. If the source counts positions (World Bank), set the route cutoff by
   matching our lower-48 routes off Washington state. Report how much of the
   lower-48 network it reproduces before trusting it in Alaska.
3. Add Alaska's ports:
   - Valdez and the Port of Alaska (Anchorage) clear the deep-draft
     foreign-trade bar and get the port-approach rule.
   - Nikiski, Unalaska (Dutch Harbor), and Kivalina are checked like the
     other smaller coastal ports.
4. Add Cook Inlet (to Anchorage) and Prince William Sound (to Valdez) to the
   river and ship-channel corridor analysis.
5. Label every Alaska figure and table with its source, because the counting
   method differs from the rest of the paper.

### Phase 4: Maps, tables, and paper (about one day)

1. National maps: the lower-48 map with Alaska and Hawaii insets, each in its
   own equal-area projection (EPSG:3338 for Alaska, ESRI:102007 for Hawaii).
2. A full-page routes map and zones map for each of Alaska and Hawaii.
3. Rerun the busiest-ports table, port-share charts, and hexagon maps with the
   new ports.
4. Add an Alaska-and-Hawaii section to Section 1, and update the data-sources
   appendix and the README.
5. Do everything in MATLAB and Python, with the same cross-checks as before.

## Checks

- The lower-48 numbers don't change.
- MATLAB and Python Hawaii results match exactly.
- Every deep-draft port in Alaska and Hawaii sits on the route network.
- Alaska: report how well the calibration reproduces the lower-48 routes, and
  compare the routes with the charted IMO routing measures.

## Status (November 12, 2026)

- **Analysis period:** moved to 2024–2025 for the lower 48, Hawaii, and Puerto
  Rico and the U.S. Virgin Islands (Nick's choice). 2023 and January–June 2026
  are held out: 81% and 94% of their route cells fall inside the 2024–2025
  network. Lower-48 zones grew 0.7–1.9%.
- **Hawaii:** rebuilt on 2024–2025 (7,310 route cells); Section 4 of the paper.
- **Alaska:** MarineCadastre 2018–2019 (Alaska is filtered out from 2021),
  ship-days rule, grid stops at 180° (Nick's choice). 26,983 ship-track cells
  plus 23,444 charted-lane cells. Kapsar satellite check: near-shore routes
  agree; offshore lanes beyond receiver range are missing. Section 5 of the
  paper.
- **Alaska satellite lanes (added, Nick's choice):** 400 Kapsar hexagons at or
  above 272 cargo plus tanker operating days (cutoff matched to the shore
  routes near shore, Jaccard 0.57) added as ship water; zones now 12%, 17%, and
  27% of the land east of 180°.
- **Puerto Rico and the U.S. Virgin Islands (added, Nick's choice):** lower-48
  rule on 2024–2025; Section 6 of the paper.

## Data validity

AIS is self-reported. Transponders broadcast wrong identities, wrong vessel
types, and bad positions, and receivers miss ships. These checks show whether
our counts are good enough for the paper. They run in four tiers, and Alaska
or Hawaii numbers go into the paper only after they pass the gate below.

### Tier 1: Internal consistency and physics

`python/ais_qc_day.py` checks the large ships our filter keeps on one day:

- MMSI is 9 digits with a ship-station country code (201–775).
- The IMO number passes its check digit.
- No implied speed over 50 knots between consecutive reports, and no reported
  speed over 40 knots.
- No MMSI reports two positions more than 50 km apart within 10 minutes
  (shared or spoofed MMSI).
- No reports more than 2 km inland, split into the Great Lakes, route cells
  (narrow rivers the 1:500,000 shoreline closes), and the rest.
- Flagged reports don't create route cells on their own.

| Check (lower 48) | 2024-07-10 | 2023-07-12 |
| --- | --- | --- |
| Large ships checked | 1,743 | 1,663 |
| Ships with a bad MMSI | 1 | 12 |
| IMO numbers failing the check digit | 3 of 1,732 | 7 of 1,662 |
| Ships with a position jump | 120 | 119 |
| Reports over 40 knots | 5 | 1,777 |
| Ships with a possible duplicate MMSI | 99 | 89 |
| Reports inland, off the routes and lakes | 6,389 (19 ships) | 1,705 (9 ships) |
| Cells made only by flagged reports | 803 (288 route cells) | 359 (213 route cells) |

Hawaii passed every check on 2024-07-10.

**What this means:** errors touch a small share of ships, and the route rule
(at least four distinct ships per cell) absorbs most of them, because one bad
transmitter adds one ship to a cell. The 288 route cells made only by flagged
reports are the open item: rerun the route rule with flagged reports removed
and count how many route cells drop out. The duplicate-MMSI ships need a
look, since a shared MMSI makes two ships count as one.

### Tier 2: Independent public references

| Reference | Result | Reading |
| --- | --- | --- |
| NOAA AIS Vessel Transit Counts 2024 (independent processing of the same raw data, all vessel groups, read at 800 m) | 95% of our 661,137 route cells have NOAA traffic. Rank correlation between our ships per cell and NOAA transits per cell is 0.66. 66% of NOAA's busiest 1% of cells lie within 2 km of our routes, 82% within 10 km. | Our pipeline finds the same lanes. NOAA's busy cells far from our routes cluster in Rhode Island and Block Island Sound, Pamlico Sound, Louisiana bayous and the Red and Ouachita rivers, the Florida Keys, coastal Maine, and the Potomac and York rivers: ferries, fishing boats, and towboats, which our 100 m filter excludes by design. |
| USACE Principal Ports tonnage (2022) | Rank correlation 0.74 with foreign tons and 0.67 with total tons, across the 73 deep-draft ports. | Ports that rank higher on ships than tonnage have passing traffic (Galveston, San Francisco, Oxnard, Sabine Pass). Ports that rank lower are Great Lakes ports and Baton Rouge. |

The transit-count check tests our processing, not the raw data, because both
start from the same Coast Guard receivers. For a check on the raw data, use
a different receiver network: World Bank density (terrestrial and satellite)
or the North Pacific and Arctic dataset for Alaska, and PacIOOS for Hawaii.

### Tier 3: Coverage

- Terrestrial receivers typically see about 20–40 nautical miles from shore, so far-
  offshore lanes thin out. Compare our route density with distance from shore
  against World Bank satellite-fed density; if ours drops faster, mark the
  outer edge of the network as a coverage limit, not an absence of ships.
- Check receiver gaps by finding long stretches where ships disappear and
  reappear on the same heading.

### Tier 4: Sampling and filter stability

- Rebuild the routes from 52 of the 104 days (every other week). If most route
  cells hold, the sample is big enough.
- Test the IMO rule on the Great Lakes: count lakers 100 m or longer with no
  IMO number. If many are dropped, the Great Lakes ports undercount.
- Check known events: the Baltimore channel closure (March–June 2024) and the
  Great Lakes winter closure (the Soo Locks shut from mid-January to late
  March) should show up as drops.

### Gate for Alaska and Hawaii numbers

Before any Alaska or Hawaii number goes into the paper:

1. Tier 1 passes on at least two sample days in that area, with the same or
   lower error rates than the lower 48.
2. Every deep-draft port in the area sits on the route network.
3. At least one Tier 2 reference from a different receiver network agrees on
   where the lanes are.
4. MATLAB and Python give identical counts.
5. A separate reviewer who didn't build the results tries to break them.

## Decisions needed

1. **Alaska source:** MarineCadastre 2009–2017 if Alaska is there, World Bank
   density, government-only ASTD or USCG data (needs your approval), or
   charted routes only?
2. **Other territories:** add Puerto Rico and the U.S. Virgin Islands? They're
   in the same files at no extra download cost. Guam needs a check first.
3. **Aleutians west of 180°:** include them, or stop at 180°?

Phases 1 and 2, and the data-source search, don't depend on these answers and can start now.

## Sources

- [Nationwide Automatic Identification System 2024 (NOAA InPort)](https://www.fisheries.noaa.gov/inport/item/73064)
- [AIS Vessel Tracks 2023 (NOAA InPort)](https://www.fisheries.noaa.gov/inport/item/72958)
- [Nationwide Automatic Identification System 2022 (NOAA InPort)](https://www.fisheries.noaa.gov/inport/item/67336)
- [MarineCadastre AIS](https://marinecadastre.gov/ais)
- [Global Shipping Traffic Density (World Bank Data Catalog)](https://datacatalog.worldbank.org/search/dataset/0037580)
- [AIS Vessel Traffic Data – Alaska – USCG Terrestrial – Monthly Totals](https://data.amerigeoss.org/it/dataset/ais-vessel-traffic-data-alaska-us-coast-guard-terrestrial-monthly-totals1)
- [Arctic Oil Spill Risk Assessment products (Axiom Data Science)](https://osra.axds.co/)
- [Arctic Ship Traffic Data (PAME)](https://pame.is/ourwork/arctic-shipping/astd/)
- [Access to ASTD, June 2024 (PAME)](https://pame.is/images/03_Projects/ASTD/Access/Access_to_ASTD_June_2024.pdf)
