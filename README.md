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

## Which ships carry an S-band radar

SOLAS Chapter V, Regulation 19 requires ships of 3,000 gross tonnage (GT) and
upward to carry a 3 GHz radar or a second 9 GHz radar, in addition to the
9 GHz radar required from 300 GT. In practice, large merchant ships carry the
3 GHz (S-band, 2.9–3.1 GHz) radar.

AIS reports don't include gross tonnage or radar band, so the code uses AIS
fields as a proxy:

| Filter | Default | Why |
| --- | --- | --- |
| AIS ship type | 60–69 passenger, 70–79 cargo, 80–89 tanker | Container ships, bulkers, car carriers, tankers, and cruise ships |
| Length overall | 100 m or longer | Proxy for 3,000 GT. **TODO:** validate against a registry with GT. |
| IMO number | Present | IMO numbers go to seagoing SOLAS ships |
| Speed | Any | Radars often stay on at anchor |

The proxy isn't sensitive to the length cutoff. On 2024-01-01, U.S. AIS had
1,810 passenger, cargo, and tanker ships at 60 m or longer, 1,674 at 80 m,
1,577 at 100 m, and 1,362 at 150 m.

U.S. domestic ships that don't make international voyages, such as Great
Lakes freighters, fall under 33 CFR 164 instead of SOLAS. Many of them carry
S-band radars anyway. The code keeps them when they pass the filter.

## Method

1. **Large-ship cells.** The code samples one AIS day per week for a year
   (52 days by default). It reads each daily MarineCadastre file in chunks,
   applies the filter, and bins positions onto a 0.01° grid (about 1 km). A
   cell becomes a ship cell when at least four distinct ships report in it
   over the sampled days. With two, the 2024 run kept 903 cells of tug and
   barge traffic on the upper Mississippi that passed the type and length
   filter; with four, it kept none, while the Columbia, Sacramento, Hudson,
   St. Lawrence, and lower Mississippi ports stay in.
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
   zone mode, AIS days, and folders.
2. Run `init_shipping_zone_rev1`.

To process days in parallel, start a pool and set `p.parallel_flag=1`. Each
worker needs about 2 GB of disk while it works.

## 2024 results (lower 48, `shore` mode)

52 AIS days (one a week in 2024), 1,580–2,090 large ships a day, 468,246 ship
cells plus 1,499 fairway-only cells, 20,476 coastline cells that face ship
water.

| Distance | U.S. land in the zone |
| --- | --- |
| 25 km | 356,183 km² |
| 50 km | 673,235 km² |
| 100 km | 1,284,704 km² |

Spot checks at 50 km: Chicago, Duluth, Houston, Baton Rouge, Portland
(Oregon), Sacramento, Seattle, Albany, and Washington, D.C. are in the zone;
Denver, Memphis, St. Louis, Nashville, Atlanta, Pittsburgh, and Jackson
(Mississippi) are not.

## Outputs

For each distance `X` in `p.distances_km`, the output folder holds:

| File | Content |
| --- | --- |
| `<name>_<mode>_<X>km.shp`, `.kml` | Zone: ship water plus land out to X km |
| `<name>_<mode>_<X>km_land.shp`, `.kml` | The same zone clipped to U.S. land |
| `<name>_<mode>_rev1.mat` | `result` struct: grid, masks, distance field, and zones |
| `<name>_<mode>_map.png` | Map of the zones and the ship cells |

In `result.zone(k)`, `.poly` and `.poly_land` are planar `polyshape` objects
(x = longitude, y = latitude). `.latlon` and `.latlon_land` are `[lat lon]`
arrays with NaN between rings, ready for `inpolygon` or
`find_points_inside_contour_two_step_rev2`. `.land_area_km2` is the U.S. land
area in the zone.

## Validation

- `test_shipping_zone_rev1.m`: URL patterns, the AIS filter on both column
  styles, distances against the Mapping Toolbox `distance` function, the area
  of a 50 km disk (within 1%), polygon rasterization, parallel equals serial,
  and two sessions writing the same cache.
- `zone_bufferm_rev1.m`: an independent check that buffers the ship cells
  with `bufferm`, piece by piece, and unions the pieces. In the Mid-Atlantic
  test box, the `bufferm` zones and the distance-field zones differ by 1.5% of
  area at 25 km and 0.5% at 50 km.

## Limits

- The 100 m length cutoff is a proxy for 3,000 GT; a registry check would
  confirm it.
- AIS doesn't report radar band or whether the radar is on.
- The grid is 0.01°, so zone edges carry about ±0.5 km of resolution error.
- Alaska, Hawaii, and the territories are outside the default grid.
