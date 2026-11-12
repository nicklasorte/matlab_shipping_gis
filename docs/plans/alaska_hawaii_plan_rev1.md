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

## Decisions needed

1. **Alaska source:** MarineCadastre 2009–2017 if Alaska is there, World Bank
   density, government-only ASTD or USCG data (needs your approval), or
   charted routes only?
2. **Other territories:** add Puerto Rico and the U.S. Virgin Islands? They're
   in the same files at no extra download cost. Guam needs a check first.
3. **Aleutians west of 180°:** include them, or stop at 180°?

Phases 1 and 2 don't depend on these answers and can start now.

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
