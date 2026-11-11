# matlab_shipping_gis

DRAFT//PRE-DECISIONAL

This repository builds geographic zones around the waters where large ships
operate in the lower 48 states and extends each zone a set distance inland,
for example 50 km. The zones support the 2.7 GHz study: large ships carry
2.9–3.1 GHz (S-band) maritime radionavigation radars, so the zones mark where
those radars can operate near land.

Each run produces, for every distance you set, polygons as MATLAB
`polyshape` objects, `[lat lon]` vertex arrays, shapefiles (EPSG:4326), and
KML files, plus a map.

## Who uses 2900–3100 MHz maritime radionavigation

NTIA's band summary lists three groups of users of maritime
radionavigation in 2900–3100 MHz:

| User | Where | How this repo covers it |
| --- | --- | --- |
| Commercial ships (cargo, tanker, passenger, many foreign-flagged; fishing vessels) | Wherever they sail | AIS ships, below |
| Coast Guard and Navy ships | U.S. waters, homeports, operating areas | AIS military and law enforcement ships, 100 m and up; ships that don't broadcast AIS are missed |
| Fixed sites: Coast Guard Vessel Traffic Service radars, racons (Coast Guard and private, for example oil platforms) | Busy harbors, channels, coasts, offshore platforms | Racons charted as S-band are zone sources; VTS areas are checked against the zones |

## Which ships carry an S-band radar

SOLAS Chapter V, Regulation 19 requires ships of 3,000 gross tonnage (GT) and
upward to carry a 3 GHz radar or a second 9 GHz radar, in addition to the
9 GHz radar required from 300 GT. In practice, large merchant ships carry the
3 GHz (S-band, 2.9–3.1 GHz) radar.

AIS reports don't include gross tonnage or radar band, so the code uses AIS
fields as a proxy:

| Filter | Default | Why |
| --- | --- | --- |
| AIS ship type | 60–69 passenger, 70–79 cargo, 80–89 tanker, 35 military, 55 law enforcement, 33 dredging, 0 and 90–99 other | Merchant ships plus Navy, Coast Guard, seagoing dredges, and other large ships |
| Length overall | 100 m or longer | Proxy for 3,000 GT, checked against registry tonnage (see Validation) |
| IMO number | Present, except military and law enforcement | IMO numbers go to seagoing ships; Navy and Coast Guard ships have none |
| Speed | Any | Radars often stay on at anchor |

The proxy isn't sensitive to the length cutoff. On 2024-01-01, U.S. AIS had
1,810 passenger, cargo, and tanker ships at 60 m or longer, 1,674 at 80 m,
1,577 at 100 m, and 1,362 at 150 m.

U.S. domestic ships that don't make international voyages, such as Great
Lakes freighters, fall under 33 CFR 164 instead of SOLAS. Many of them carry
S-band radars anyway. The code keeps them when they pass the filter.

Left out on purpose:

- **Towing (AIS types 31, 32, 52), except tug-barges.** Towing ships 100 m
  or longer with an IMO number (ocean-going articulated tug-barges) are kept
  through a separate filter, `p.filt_towing`, but only within
  `p.towing_coast_km` (25 km) of the Census coastline. Some river towboats
  also report IMO numbers and the length of the whole tow (on 2024-07-10,
  COOPERATIVE SPIRIT and AEP MARINER on the Mississippi). Without the coastal
  rule, a test run reached 15 of 36 inland river ports; with it, none. The
  2023 AIS files report the tug's own length, so few towing ships pass the
  100 m test in 2023 (15 on 2023-07-12, 761 on 2024-07-10).
- **Fishing and special craft (30, 34, 36, 37, 50–54, 56–59).** At 100 m and
  up these were also mostly inland river reports, which points to coding
  errors.
- **Other and dredging entries without an IMO number.** Allowing them pulled
  river towboats into the zones up the Mississippi to Memphis, St. Louis,
  and Dubuque.

## Method

1. **Large-ship cells.** The code samples one AIS day per week for 2023 and
   2024 (104 days). It reads each daily MarineCadastre file in chunks,
   applies the filter, and bins positions onto a 0.01° grid (about 1 km). A
   cell becomes a ship cell when at least four distinct ships report in it in
   one calendar year; each year is counted on its own, and a cell that passes
   in either year is kept. Within 50 km of a deep-draft USACE Principal Port
   (coastal or Great Lakes, 1 million tons or more of foreign trade), two
   ships in a year are enough, which keeps thin approaches such as Searsport
   and Coos Bay. With two ships everywhere, the 2024 run kept 903 cells of
   tug and barge traffic on the upper Mississippi; with four, it kept none.
2. **Fairways.** The code adds NOAA shipping fairways, traffic separation
   schemes, precautionary areas, and recommended routes as ship cells.
3. **Distance field.** The code computes the great-circle distance from every
   grid cell to the nearest ship cell (spherical Earth, KD-tree search over
   the edge cells of the ship area).
4. **Zone definition.** Choose one of two modes:
   - `shore` (default): water within `shore_link_km` (25 km) of ship cells is
     ship water. Land is measured from the Census coastline that faces ship
     water. The zone runs from the ship water to X km inland. River ports that
     the coastline layer omits, such as Baton Rouge and Portland, Oregon, are
     covered because the distance to the ships themselves also counts.
   - `ships`: the zone is everything within X km of a ship cell.
5. **Polygons.** The code contours the distance field at each distance with
   sub-cell interpolation, builds a `polyshape`, and clips a land-only copy to
   Census state boundaries.

## Data sources

All sources are public.

| Layer | Source |
| --- | --- |
| AIS positions, 2024+ | `https://noaaocm.blob.core.windows.net/ais/csv2/csv<yyyy>/ais-<yyyy-MM-dd>.csv.zst` |
| AIS positions, 2009–2023 | `https://coast.noaa.gov/htdata/CMSP/AISDataHandler/<yyyy>/AIS_<yyyy_MM_dd>.zip` |
| Fairways and TSS | NOAA ENC Direct, `NavigationChartData/MarineTransportation/FeatureServer/0` |
| Land | Census cartographic boundary states, 1:500,000 (`cb_2023_us_state_500k`) |
| Coastline | Census TIGER/Line national coastline (`tl_2023_us_coastline`) |

AIS covers USCG terrestrial receivers in U.S. waters, including the Great
Lakes and inland waterways, at a 1-minute sample.

## Requirements

- MATLAB R2025b with Mapping Toolbox and Statistics and Machine Learning
  Toolbox. Parallel Computing Toolbox is optional.
- The `zstd` command-line tool for 2024+ AIS files: `brew install zstd`.
- About 2 GB of free disk while a day is processed. Each daily file is about
  200 MB compressed and 750–1,000 MB as CSV. The code deletes each CSV after
  it caches that day's ship cells, which take a few MB.

## Output size

A full run writes about 4.5 MB:

| Setting | Default | Effect |
| --- | --- | --- |
| `p.simplify_deg` | 0.005 | Drops polygon vertices within 0.005° (about 0.5 km, half a grid cell) with `reducem`. Cuts vertices about 6 times; the 50 km land zone moves by under 1% of its area. Use 0 to keep every vertex. |
| `p.kmz` | `true` | Also writes a KMZ (zipped KML, about 5 times smaller) next to each KML. |
| `p.save_grids` | `false` | Leaves the full-size grids out of the `.mat` (1.3 MB instead of 33 MB). `true` saves them in compact types. |
| `p.png_dpi` | 200 | Map resolution. |

## Memory and disk

The code works in pieces so a full year fits on a laptop:

- Each AIS day is read in chunks of `p.ais_read_rows` rows (default
  1,000,000, about 150 MB) with a `tabularTextDatastore`, not loaded whole.
- Each day's result is cached in `p.data_dir` (a few MB) and the day's CSV is
  deleted, so a stopped run resumes where it left off.
- Days are merged one at a time into a running set of cell and ship pairs.
- Distances are computed in blocks of `p.block_rows` grid rows (default 200)
  from 1-D coordinate vectors; intermediate grids are cleared before
  contouring.

## Run

1. Edit the settings at the top of `init_shipping_zone_rev1.m`: distances,
   zone mode, AIS days, and folders. Run it from the repo folder so it uses
   the cached inputs in `data/`.
2. Run `init_shipping_zone_rev1`.

To process days in parallel, start a pool and set `p.parallel_flag=1`. Each
worker needs about 2 GB of disk while it works.

## Results, 2023–2024 (lower 48, `shore` mode)

104 AIS days (every Wednesday in 2023 and 2024).

| Route cells by source | Cells |
| --- | --- |
| AIS cells, 4 or more large ships in a year (tug-barges near the coast included) | 597,138 |
| Port approaches, 2 or more ships within 50 km of 73 deep-draft ports | 14,627 |
| NOAA fairways and traffic separation schemes not already AIS cells | 1,166 |
| S-band racons not already route cells | 16 |
| Total | 612,947 |

| Distance | U.S. land in zone |
| --- | --- |
| 25 km | 396,951 km² |
| 50 km | 721,434 km² |
| 100 km | 1,325,903 km² |

- Named ports: 24 of 24 reached by a continuous route, including Baltimore
  and Baton Rouge.
- USACE Principal Ports: 69 of 73 deep-draft ports reached; 0 of 36 inland
  river ports. Not reached: Portland, Oregon, and Illinois International
  Port (the USACE reference points sit 6 and 13 km from the ship berths),
  and Panama City and Searsport (thin approach traffic). All four are inside
  the 25 km zone.
- Baton Rouge: 267 distinct large ships within 3 km on the sampled days
  (136 in 2023, 138 in 2024).
- Vessel Traffic Service: 9 of 10 VTS areas are inside the 25 km zone;
  VTS Louisville, on the Ohio River, is not.

## Filter attrition

`init_filter_funnel_rev1.m` runs the filter one step at a time on one full
day per year (`outputs/2023_2024/ais_filter_funnel.csv` and
`ais_filter_by_type.csv`). Ship counts:

| Step | 2023-07-12 | 2024-07-10 |
| --- | --- | --- |
| All reports | 22,344 | 22,414 |
| Ship type kept (towing included) | 8,948 | 8,295 |
| and length 100 m or more | 1,844 | 2,754 |
| and IMO number (or military or law enforcement) | 1,805 | 2,184 |
| and inside the lower-48 grid | 1,600 | 1,860 |

Step 4 matches the day caches exactly (1,080,250 and 1,347,288 reports;
1,805 and 2,184 ships), and the caches were built by a separate program
(`ais_cells_py_rev1.py`). That program also reproduces the MATLAB cache for
2024-01-03 cell for cell (166,382 pairs).

## Figures

The 2023–2024 maps are in `docs/`:

- [Large-ship routes, no buffer](docs/shipping_zone_2023_2024_routes_map.png)
- [New Orleans to Baton Rouge routes, no buffer](docs/shipping_zone_2023_2024_new_orleans_baton_rouge_routes_map.png)
- [Example frequency-dependent zones](docs/shipping_zone_2023_2024_band_zones_map.png)
- Land within X km of large-ship water: [25 km](docs/shipping_zone_2023_2024_shore_25km_us_map.png), [50 km](docs/shipping_zone_2023_2024_shore_50km_us_map.png), [100 km](docs/shipping_zone_2023_2024_shore_100km_us_map.png)
- Routes with the X km buffer: [25 km](docs/shipping_zone_2023_2024_shore_25km_routes_buffer_map.png), [50 km](docs/shipping_zone_2023_2024_shore_50km_routes_buffer_map.png), [100 km](docs/shipping_zone_2023_2024_shore_100km_routes_buffer_map.png)
- [Lower Mississippi with the 50 km zone](docs/shipping_zone_2023_2024_lower_mississippi_50km_map.png)
- [Length cutoff check](docs/gt_proxy_check_2024.png)

The 2024-only maps from the earlier run stay in `docs/` under `shipping_zone_2024_*`.

![Large-ship routes, 2023-2024](docs/shipping_zone_2023_2024_routes_map.png)

## Frequency-dependent zones

`p.band_zones` assigns a zone distance to each part of 2900–3100 MHz. The
default is an example, not an EMC result:

| Band | Distance |
| --- | --- |
| 2900–3000 MHz | 25 km |
| 3000–3030 MHz | 50 km |
| 3030–3070 MHz | 100 km |
| 3070–3100 MHz | 50 km |

Each band gets its own shapefile, KML, and KMZ
(`shipping_zone_2023_2024_band_<f1>-<f2>MHz_<X>km`), a row in
`shipping_zone_2023_2024_band_zones.csv`, and a panel in the band map.

## Output files

`outputs/2023_2024/` holds:

- `shipping_zone_2023_2024_routes`: the route cells as polygons (one
  feature per 1° tile), shapefile and KMZ. The KML is 42 MB, so only the KMZ
  (the same KML, zipped, 1.7 MB) is in the repo; a run writes both.
  `..._routes_ais_only` holds the AIS cells without fairways and racons.
- `shipping_zone_2023_2024_shore_<X>km` and `..._land`: the zones for 25,
  50, and 100 km (shapefile, KML, KMZ).
- `shipping_zone_2023_2024_band_*`: the frequency-dependent zones.
- `shipping_zone_2023_2024_sites.csv`: racons, VTS areas, named ports, and
  USACE Principal Ports, with distance to the routes and zone membership.
- Port, principal-port, and VTS checks, Baton Rouge ship counts, the filter
  attrition tables, and the `.mat` result.

The 2024-only outputs from the earlier run stay in `outputs/2024/`.

## Data in the repo

`data/` holds every input the 2023–2024 run uses, so `init_shipping_zone_rev1`
runs without downloading anything:

| File | Content |
| --- | --- |
| `ais_cells_YYYYMMDD_*_rev1.mat` (208 files) | Large-ship grid cells for each of the 104 sampled AIS days: one file for the main filter (`vt0-99-n44`) and one for tug-barges (`vt31-52-n3`). The raw AIS files are 200–300 MB each and aren't stored. `ais_cells_py_rev1.py` rebuilds them without writing the CSV to disk. |
| `racons/` | NOAA chart racon layers (general, coastal, and approach scales) |
| `fairways_rev1.geojson` | NOAA shipping fairways and traffic separation schemes |
| `cb_2023_us_state_500k/` | Census state boundaries, 1:500,000 |
| `tl_2023_us_coastline/` | Census TIGER/Line coastline |
| `wikidata_imo_gt_len.csv` | Wikidata gross tonnage and length by IMO number (queried 2026-11-10) |
| `usace_principal_ports.csv` | USACE Principal Ports: name, type, tonnage, and location (retrieved 2026-11-10) |
| `ais_vessels_2024_4days.csv` | One row per ship from four 2024 AIS days, for the length cutoff check |

## Vessel Traffic Service areas

In the 2023–2024 run, 9 of the 10 Coast Guard VTS areas in the lower 48 are
inside the 25 km zone. VTS Berwick Bay (Morgan City, Louisiana) is within
1 km of a large-ship cell but not on the connected route network. VTS
Louisville, on the Ohio River, serves towboats and is outside every zone.

## Ports the routes must reach

Each run checks two port lists and warns if large-ship routes don't reach a
port.

**Named deep-draft ports (`p.check_ports`, 24 ports).** Baton Rouge (head of
deep-draft navigation on the Mississippi), New Orleans, Houston, Corpus
Christi, Mobile, Tampa, Miami, Savannah, Charleston, Norfolk, Baltimore,
Philadelphia, Newark (New York/New Jersey), Albany, Boston, Los Angeles/Long
Beach, Oakland, Sacramento, Stockton, Portland (Oregon), Seattle, Tacoma,
Duluth, and Chicago. In 2024 all 24 are reached: each is within 1.7 km of a
large-ship cell, on a connected route network, and inside the 25, 50, and
100 km zones. Results: `outputs/2024/shipping_zone_2024_port_check.csv`.

**Every USACE Principal Port in the grid (`p.principal_ports`, 135 ports).**
The run warns only for the 73 coastal and Great Lakes ports with at least
1 million tons of foreign trade. Port locations are USACE district
reference points, so a port counts as reached within 5 km of a ship cell.
Ship cells within 3 cells (about 3 km) of each other count as connected.
Results: `outputs/2024/shipping_zone_2024_principal_port_check.csv`.

| Group | Ports | Reached | In the 25 km zone |
| --- | --- | --- | --- |
| Coastal and Great Lakes, at least 1 million tons foreign | 73 | 65 | 73 |
| Inland river ports (barge traffic) | 36 | 0 | 0 |

The eight deep-draft ports not counted as reached are all inside the 25 km
zone:

- Port of Portland (Oregon) and Illinois International Port (Chicago): the
  USACE reference point sits 6 km and 13 km from the berths. The named
  Portland and Chicago points above are reached.
- Portland (Maine), Portsmouth (New Hampshire), Searsport (Maine), Coos Bay,
  Grays Harbor, and Panama City: large ships reach the port, but few call
  there, so the offshore approach has stretches where fewer than four
  different ships passed in the 52 sampled days. The approach isn't a
  continuous chain of ship cells, though the zone still covers the port.

Inland river ports (St. Louis, Memphis, Pittsburgh, and others) are served by
towboats and barges, not ships of 3,000 GT, so they are correctly left out.

On the Mississippi, large-ship cells run without a break from Head of Passes
to just above Baton Rouge (30.49°N); 251 different large ships used the
Baton Rouge cells in the 52 sampled days.

## Outputs

For each distance `X` in `p.distances_km`, the output folder holds:

| File | Content |
| --- | --- |
| `<name>_<mode>_<X>km.shp`, `.kml`, `.kmz` | Zone: ship water plus land out to X km |
| `<name>_<mode>_<X>km_land.shp`, `.kml`, `.kmz` | The same zone clipped to U.S. land |
| `<name>_port_check.csv` | Distance from each port in `p.check_ports` to the nearest ship cell |
| `<name>_<region>_<X>km_map.png` | Zoomed map for each entry in `p.region_maps` |
| `<name>_<mode>_rev1.mat` | `result` struct: grid, masks, distance field, and zones |
| `<name>_<mode>_map.png` | Diagnostic map: all zones and the ship cells |
| `<name>_<mode>_<X>km_us_map.png` | U.S. map of the land within X km and the large-ship water |
| `<name>_<mode>_<X>km_routes_buffer_map.png` | U.S. map of the large-ship routes and the X km buffer |
| `<name>_routes_map.png` | U.S. map of the large-ship routes |

In `result.zone(k)`, `.poly` and `.poly_land` are planar `polyshape` objects
(x = longitude, y = latitude). `.latlon` and `.latlon_land` are `[lat lon]`
arrays with NaN between rings, ready for `inpolygon` or
`find_points_inside_contour_two_step_rev2`. 

## Validation

- `test_shipping_zone_rev1.m`: URL patterns, the AIS filter on both column
  styles, distances against the Mapping Toolbox `distance` function, the area
  of a 50 km disk (within 1%), polygon rasterization, parallel equals serial,
  and two sessions writing the same cache.
- `zone_bufferm_rev1.m`: an independent check that buffers the ship cells
  with `bufferm`, piece by piece, and unions the pieces. In the Mid-Atlantic
  test box, the `bufferm` zones and the distance-field zones differ by 1.5% of
  area at 25 km and 0.5% at 50 km.

## Length cutoff check

`init_check_gt_proxy_rev1.m` tests the 100 m cutoff against registry gross
tonnage. It takes every passenger, cargo, and tanker ship with an IMO number
seen on four 2024 AIS days (one per season) and matches the IMO numbers to
gross tonnage on Wikidata (81,000 ships with an IMO number, tonnage, and
length, mostly imported from public registers).

- 4,129 of 5,674 AIS ships matched (73%; 68% between 75 and 100 m, 75–84%
  above 100 m).
- At 100 m, 99.6% of the ships the cutoff keeps are 3,000 GT or more
  (3,801 of 3,818), and the cutoff keeps 98.1% of the ships that are
  3,000 GT or more (3,801 of 3,873).
- The 72 ships it misses are mostly 90–99 m cargo ships and ferries;
  12 of them have a wrong AIS length (the register shows 100 m or more).
  Passenger ships have the lowest recall (86%), because many ferries of
  3,000 GT and up are shorter than 100 m.
- The 17 ships it keeps by mistake are 997–2,996 GT, close to the line.
- AIS lengths agree with register lengths: median difference 0.1 m,
  90th percentile 1 m.
- A 90 m cutoff balances the two errors (99.2% and 99.0%).

![Length cutoff check](docs/gt_proxy_check_2024.png)

The tables are in `outputs/2024/gt_proxy_*.csv`.

## Limits

- The 100 m length cutoff stands in for 3,000 GT; the check above found it
  right for about 98% of ships.
- AIS doesn't report radar band or whether the radar is on.
- The grid is 0.01°, so zone edges carry about ±0.5 km of resolution error.
- Alaska, Hawaii, and the territories are outside the default grid.
