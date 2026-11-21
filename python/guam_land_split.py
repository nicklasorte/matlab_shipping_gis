"""Split the Guam-region zone land into Guam and the Northern Mariana Islands (CNMI).

Reads the zone land polygons (zone(i).latlon_land, NaN-separated rings, even-odd fill) from the two
zone files in outputs/guam, projects to EPSG:6933, and cuts at 13.9 N (Guam's north tip is 13.7 N;
Rota, the southernmost CNMI island, is at 14.1 N). Checks that the total equals the stored
land_area_km2 within 0.1 km2 (fails loudly otherwise). Writes outputs/guam/guam_land_split_rev1.csv.
"""
import csv
import os

import numpy as np
import scipy.io as sio
from pyproj import Transformer
from shapely.geometry import Polygon, box
from shapely.ops import transform

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "outputs", "guam")
CUT_LAT = 13.9
PROJ = Transformer.from_crs(4326, 6933, always_xy=True).transform
RUNS = {"with_links": "shipping_zone_guam_cnmi_links_2024_2025_ships_rev1.mat",
        "without_links": "shipping_zone_guam_2024_2025_ships_rev1.mat"}


def land_geom(ll):
    nan = np.isnan(ll[:, 0])
    parts = np.split(np.arange(len(ll)), np.nonzero(nan)[0])
    rings = [ll[i[~np.isnan(ll[i, 0])]] for i in parts]
    g = None
    for r in rings:
        if len(r) < 3:
            continue
        p = Polygon(r[:, ::-1])
        g = p if g is None else g.symmetric_difference(p)
    return g.buffer(0)


def main():
    rows = []
    for run, f in RUNS.items():
        m = sio.loadmat(os.path.join(OUT, f), struct_as_record=False, squeeze_me=True)
        for z in m["zone"]:
            g = land_geom(z.latlon_land)
            tot = transform(PROJ, g).area / 1e6
            if abs(tot - z.land_area_km2) > 0.1:
                raise RuntimeError(f"guam_land_split:total: {run} {z.distance_km} km {tot:.2f} vs {z.land_area_km2:.2f}")
            guam = transform(PROJ, g.intersection(box(140, 10, 150, CUT_LAT))).area / 1e6
            rows.append([run, int(z.distance_km), round(tot, 1), round(guam, 1), round(tot - guam, 1)])
    with open(os.path.join(OUT, "guam_land_split_rev1.csv"), "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["run", "distance_km", "total_km2", "guam_km2", "cnmi_km2"])
        w.writerows(rows)
    for r in rows:
        print(*r)


if __name__ == "__main__":
    main()
