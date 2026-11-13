"""How much of each zone is foreign water (review R2MET-1). Python twin of
init_foreign_water_split_rev1.m / foreign_water_split_rev1.m, same method:

Sample each zone (ships mode, 25, 50, 100 km) on a 0.02 deg grid; a point is
land if inside the zone's *_land.shp polygon, else water. Water nearer U.S. land
(Census cb_2023 states) than foreign land (Natural Earth 1:10m countries without
boundary lakes, the United States and its territories removed) is U.S.-side; the rest is foreign-side. Water more
than 370.4 km (200 nmi) from U.S. land is also flagged. The equidistance line
stands in for the maritime boundary, as in the zone code's charted-lane rule.

Usage: python3 python/foreign_water_split.py [ne_countries_lakes.shp]
Writes outputs/foreign_water_split_py.csv.
"""
import csv
import os
import sys

import numpy as np
import shapefile
from scipy.spatial import cKDTree
from shapely import contains_xy
from shapely.geometry import Polygon, shape
from shapely.ops import unary_union

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
R = 6371.0088
STEP = 0.02
PAD_KM = 800
# Natural Earth gives U.S. territories their own ADM0 codes; none is foreign.
US_ADM0 = ("USA", "PRI", "VIR", "GUM", "ASM", "MNP", "UMI")
REGIONS = [
    ("Lower 48", "outputs/2024_2025", "shipping_zone_2024_2025"),
    ("Hawaii", "outputs/2024_2025/hawaii", "shipping_zone_hawaii_2024_2025"),
    ("Puerto Rico and USVI", "outputs/2024_2025/prusvi", "shipping_zone_prusvi_2024_2025"),
    ("Alaska", "outputs/2018_2019/alaska", "shipping_zone_alaska_2018_2019"),
]


def polygon(path):
    return unary_union([shape(s.__geo_interface__).buffer(0) for s in shapefile.Reader(path).shapes()])


def verts(path, field, drop, latlim):
    sf = shapefile.Reader(path)
    names = [f[0] for f in sf.fields[1:]]
    i = names.index(field)
    pts = [np.asarray(s.points) for s, rec in zip(sf.shapes(), sf.records()) if rec[i] not in drop and s.points]
    p = np.vstack(pts)
    pad = PAD_KM / 111.195
    k = (p[:, 1] >= latlim[0] - pad) & (p[:, 1] <= latlim[1] + pad)
    return p[k, 0], p[k, 1]


def xyz(lon, lat):
    lo, la = np.radians(lon), np.radians(lat)
    return np.column_stack([np.cos(la) * np.cos(lo), np.cos(la) * np.sin(lo), np.sin(la)])


def split(zone_shp, land_shp, ne):
    Z, L = polygon(zone_shp), polygon(land_shp)
    x0, y0, x1, y1 = Z.bounds
    lon = np.arange(np.floor(x0 / STEP) * STEP + STEP / 2, x1, STEP)
    lat = np.arange(np.floor(y0 / STEP) * STEP + STEP / 2, y1, STEP)
    LON, LAT = np.meshgrid(lon, lat)
    inz = contains_xy(Z, LON.ravel(), LAT.ravel())
    plon, plat = LON.ravel()[inz], LAT.ravel()[inz]
    a = (np.radians(STEP) * R) ** 2 * np.cos(np.radians(plat))
    land = contains_xy(L, plon, plat)
    ulon, ulat = verts(os.path.join(ROOT, "data", "cb_2023_us_state_500k", "cb_2023_us_state_500k.shp"), "STUSPS", (), (y0, y1))
    flon, flat = verts(ne, "ADM0_A3", US_ADM0, (y0, y1))
    P = xyz(plon[~land], plat[~land])
    du = 2 * R * np.arcsin(np.minimum(cKDTree(xyz(ulon, ulat)).query(P)[0] / 2, 1))
    df = 2 * R * np.arcsin(np.minimum(cKDTree(xyz(flon, flat)).query(P)[0] / 2, 1)) if len(flon) else np.full(len(du), np.inf)
    aw = a[~land]
    us, fo = aw[du <= df].sum(), aw[du > df].sum()
    return dict(total_km2=a.sum(), land_km2=a[land].sum(), us_water_km2=us, foreign_water_km2=fo,
                beyond_200nmi_km2=aw[du > 370.4].sum(), foreign_share_of_water=fo / (us + fo))


def main(ne=os.path.join(ROOT, "data", "ne_10m_admin_0_countries_lakes", "ne_10m_admin_0_countries_lakes.shp")):
    rows = []
    for region, d, stem in REGIONS:
        for km in (25, 50, 100):
            z = os.path.join(ROOT, d, f"{stem}_ships_{km}km.shp")
            r = split(z, z.replace(".shp", "_land.shp"), ne)
            rows.append(dict(region=region, distance_km=km, **{k: round(v, 4) if k.endswith("share_of_water") else round(v) for k, v in r.items()}))
            print(rows[-1], flush=True)
    out = os.path.join(ROOT, "outputs", "foreign_water_split_py.csv")
    with open(out, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)


if __name__ == "__main__":
    main(*sys.argv[1:2])
