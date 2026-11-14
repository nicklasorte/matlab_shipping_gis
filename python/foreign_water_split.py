"""How much of each zone is foreign water (review R2MET-1). Python twin of
init_foreign_water_split_rev1.m / foreign_water_split_rev1.m, same method:

Sample each zone (ships mode, 25, 50, 100 km) on a 0.02 deg grid; a point is
land if inside the zone's *_land.shp polygon, else water. Water nearer U.S. land
(Census cb_2023 states) than foreign land (Natural Earth 1:10m countries without
boundary lakes, the United States and its territories removed) is U.S.-side; the rest is foreign-side. Water more
than 370.4 km (200 nmi) from U.S. land is also flagged. The equidistance line
stands in for the maritime boundary, as in the zone code's water clip. Water
more than 200 nmi from every coast is high seas, a class of its own (as in the
zone code, it is never foreign-side). foreign_share_of_water is foreign-side
water over all water.

Usage: python3 python/foreign_water_split.py [ne_countries_lakes.shp] [committed|run] [out_stem]
"committed" (default) reads the zone files in outputs/; "run" reads output*/.
Writes outputs/<out_stem>.csv (default foreign_water_split_py) and
outputs/<out_stem>_by_country.csv (foreign-side water by nearest foreign country).
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
HIGH_SEAS_KM = 370.4   # 200 nautical miles
# Natural Earth gives U.S. territories their own ADM0 codes; none is foreign.
US_ADM0 = ("USA", "PRI", "VIR", "GUM", "ASM", "MNP", "UMI")
RUN_DIRS = {"Lower 48": "output", "Hawaii": "output_hawaii",
            "Puerto Rico and USVI": "output_prusvi", "Alaska": "output_alaska"}
REGIONS = [
    ("Lower 48", "outputs/2024_2025", "shipping_zone_2024_2025"),
    ("Hawaii", "outputs/2024_2025/hawaii", "shipping_zone_hawaii_2024_2025"),
    ("Puerto Rico and USVI", "outputs/2024_2025/prusvi", "shipping_zone_prusvi_2024_2025"),
    ("Alaska", "outputs/2018_2019/alaska", "shipping_zone_alaska_2018_2019"),
]


def polygon(path):
    return unary_union([shape(s.__geo_interface__).buffer(0) for s in shapefile.Reader(path).shapes()])


def verts(path, field, drop, latlim, codes=False):
    sf = shapefile.Reader(path)
    names = [f[0] for f in sf.fields[1:]]
    i = names.index(field)
    pts, code = [], []
    for s, rec in zip(sf.shapes(), sf.records()):
        if rec[i] in drop or not s.points:
            continue
        pts.append(np.asarray(s.points))
        code += [rec[i]] * len(s.points)
    p = np.vstack(pts)
    code = np.asarray(code)
    pad = PAD_KM / 111.195
    k = (p[:, 1] >= latlim[0] - pad) & (p[:, 1] <= latlim[1] + pad)
    return (p[k, 0], p[k, 1], code[k]) if codes else (p[k, 0], p[k, 1])


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
    flon, flat, fcode = verts(ne, "ADM0_A3", US_ADM0, (y0, y1), codes=True)
    P = xyz(plon[~land], plat[~land])
    du = 2 * R * np.arcsin(np.minimum(cKDTree(xyz(ulon, ulat)).query(P)[0] / 2, 1))
    if len(flon):
        dfc, j = cKDTree(xyz(flon, flat)).query(P)
        df = 2 * R * np.arcsin(np.minimum(dfc / 2, 1))
    else:
        df, j = np.full(len(du), np.inf), np.zeros(len(du), int)
    aw = a[~land]
    high = (du > HIGH_SEAS_KM) & (df > HIGH_SEAS_KM)       # beyond 200 nmi of every coast
    fo_mask = (du > df) & ~high
    us, fo = aw[~fo_mask & ~high].sum(), aw[fo_mask].sum()
    by_country = {}
    if fo_mask.any():
        cc = fcode[j[fo_mask]]
        for c in np.unique(cc):
            by_country[str(c)] = float(aw[fo_mask][cc == c].sum())
    return dict(total_km2=a.sum(), land_km2=a[land].sum(), us_water_km2=us, foreign_water_km2=fo,
                high_seas_km2=aw[high].sum(), beyond_200nmi_km2=aw[du > HIGH_SEAS_KM].sum(),
                foreign_share_of_water=fo / aw.sum() if aw.sum() else 0.0), by_country


def main(ne=os.path.join(ROOT, "data", "ne_10m_admin_0_countries_lakes", "ne_10m_admin_0_countries_lakes.shp"),
         zone_set="committed", out_stem="foreign_water_split_py"):
    if zone_set not in ("committed", "run"):
        raise ValueError("zone_set must be 'committed' or 'run'")
    rows, crow = [], []
    for region, d, stem in REGIONS:
        if zone_set == "run":
            d = RUN_DIRS[region]
        for km in (25, 50, 100):
            z = os.path.join(ROOT, d, f"{stem}_ships_{km}km.shp")
            r, byc = split(z, z.replace(".shp", "_land.shp"), ne)
            rows.append(dict(region=region, distance_km=km, **{k: round(v, 4) if k.endswith("share_of_water") else round(v) for k, v in r.items()}))
            tot = sum(byc.values())
            for c, v in sorted(byc.items(), key=lambda kv: -kv[1]):
                crow.append(dict(region=region, distance_km=km, country=c, foreign_water_km2=round(v), share_of_foreign=round(v / tot, 4)))
            print(rows[-1], flush=True)
    for name, data in ((out_stem, rows), (out_stem + "_by_country", crow)):
        with open(os.path.join(ROOT, "outputs", name + ".csv"), "w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(data[0]))
            w.writeheader()
            w.writerows(data)


if __name__ == "__main__":
    main(*sys.argv[1:4])
