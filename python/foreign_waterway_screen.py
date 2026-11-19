"""Screen foreign ship channels near U.S. land for gaps in the route cells (planning screen).

For hand-placed waypoints along the main foreign ship channels within reach of U.S.
land, this samples the channel every ~5 km and reports each point's distance to U.S.
land (Natural Earth 1:10m) and to the nearest AIS route cell (lower 48 2024-2025,
Alaska 2018-2019). It then estimates the U.S. land that a zone around the uncovered
reach would add beyond the current zones. Screening only: waypoints are approximate
and Natural Earth is coarser than the Census layers the zones use. MATLAB twin: pending
(docs/plans/foreign_waterways_plan_rev1.md, step F1).

Usage: python3 python/foreign_waterway_screen.py <natural_earth_dir>
Writes outputs/foreign_waterways/channel_screen_rev1.csv and added_land_rev1.csv.
"""
import os
import sys
import warnings

import geopandas as gpd
import numpy as np
import pandas as pd
from pyproj import CRS, Geod, Transformer
from shapely.geometry import LineString, Point
from shapely.ops import transform, unary_union

warnings.filterwarnings("ignore")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "outputs", "foreign_waterways")
G = Geod(ellps="WGS84")
STEP_KM = 5
# (lat, lon) waypoints along each channel, read from charts by eye; screening only.
WATERWAYS = {
    "St. Lawrence (Montreal to Sept-Iles)": [(45.50, -73.55), (46.04, -73.11), (46.34, -72.54), (46.81, -71.20),
        (46.98, -70.80), (47.45, -70.20), (47.95, -69.65), (48.55, -68.55), (49.05, -67.70), (49.35, -67.20), (50.15, -66.40)],
    "Bay of Fundy to Saint John": [(44.40, -66.60), (44.90, -66.30), (45.20, -66.05), (45.26, -66.06)],
    "Chatham Sound to Prince Rupert and Portland Canal to Stewart": [(54.40, -130.85), (54.30, -130.45), (54.70, -130.60),
        (55.10, -130.15), (55.60, -130.05), (55.92, -130.00)],
    "Gulf of California north (Puerto Penasco)": [(31.0, -113.8), (31.3, -113.55)],
    "Ensenada approach": [(31.6, -117.0), (31.85, -116.63)],
}
ZONES = {  # waterway prefix -> zone land file pattern
    "St.": "2024_2025/shipping_zone_2024_2025_ships_{km}km_land.shp",
    "Bay": "2024_2025/shipping_zone_2024_2025_ships_{km}km_land.shp",
    "Cha": "2018_2019/alaska/shipping_zone_alaska_2018_2019_ships_{km}km_land.shp",
}


def dist_km(pt, geom):
    crs = CRS.from_proj4(f"+proj=aeqd +lat_0={pt.y} +lon_0={pt.x}")
    t = Transformer.from_crs(4326, crs, always_xy=True)
    near = geom.intersection(pt.buffer(5))
    return np.inf if near.is_empty else Point(0, 0).distance(transform(t.transform, near)) / 1000


def main(ne_dir):
    c = gpd.read_file(os.path.join(ne_dir, "ne_10m_admin_0_countries_lakes.shp"))
    us = unary_union(c[c.ADMIN == "United States of America"].geometry)
    routes = [os.path.join(ROOT, "outputs", p) for p in (
        "2024_2025/shipping_zone_2024_2025_routes_ais_only.shp",
        "2018_2019/alaska/shipping_zone_alaska_2018_2019_routes_ais_only.shp")]
    for f in routes:
        if not os.path.exists(f):
            raise FileNotFoundError(f)
    rt = unary_union([unary_union(gpd.read_file(f).to_crs(4326).geometry) for f in routes])
    rows = []
    for name, wp in WATERWAYS.items():
        pts = []
        for (la0, lo0), (la1, lo1) in zip(wp[:-1], wp[1:]):
            n = max(2, int(G.inv(lo0, la0, lo1, la1)[2] / (STEP_KM * 1000)))
            pts += [(lo0, la0)] + G.npts(lo0, la0, lo1, la1, n)
        pts.append((wp[-1][1], wp[-1][0]))
        for x, y in pts:
            p = Point(x, y)
            rows.append((name, y, x, dist_km(p, us), dist_km(p, rt), bool((22 <= y <= 50) and (-130 <= x <= -66))))
    d = pd.DataFrame(rows, columns=["waterway", "lat", "lon", "us_km", "route_km", "in_lower48_grid"])
    os.makedirs(OUT, exist_ok=True)
    d.round(3).to_csv(os.path.join(OUT, "channel_screen_rev1.csv"), index=False)
    usa = c[c.ADMIN == "United States of America"].to_crs(6933).geometry.union_all()
    added = []
    for name, g in d.groupby("waterway", sort=False):
        gap = g[g.route_km > 5]
        rec = dict(waterway=name, min_us_km=round(g.us_km.min(), 1))
        for km in (25, 50, 100):
            rec[f"gap_channel_km_within_{km}"] = STEP_KM * int((gap.us_km <= km).sum())
        pat = ZONES.get(name[:3])
        if pat and len(gap) > 1:
            lat0, lon0 = gap.lat.mean(), gap.lon.mean()
            line = gpd.GeoSeries([LineString(list(zip(gap.lon, gap.lat)))], crs=4326).to_crs(
                f"+proj=aeqd +lat_0={lat0} +lon_0={lon0}")
            for km in (25, 50, 100):
                z = gpd.read_file(os.path.join(ROOT, "outputs", pat.format(km=km))).to_crs(6933).geometry.union_all()
                buf = line.buffer(km * 1000).to_crs(6933).iloc[0].intersection(usa)
                rec[f"new_us_land_km2_{km}"] = round(buf.difference(z).area / 1e6)
        added.append(rec)
    a = pd.DataFrame(added)
    a.to_csv(os.path.join(OUT, "added_land_rev1.csv"), index=False)
    print(a.to_string(index=False))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: python3 python/foreign_waterway_screen.py <natural_earth_dir>")
    main(sys.argv[1])
