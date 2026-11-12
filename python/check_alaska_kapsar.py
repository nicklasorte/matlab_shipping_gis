"""Cross-check the Alaska routes (MarineCadastre 2018-2019, terrestrial AIS) against an
independent satellite-AIS source: the North Pacific and Arctic Marine Vessel Traffic
Dataset (Kapsar and others, 2022; Arctic Data Center doi:10.18739/A2XG9FC41; CC BY 4.0).

Kapsar gives, per 625 km2 hexagon (Alaska Albers, EPSG:3338) and month, the distinct
ships (nMMSI) and operating days (nOprD) by type. Cargo (C) and tanker (T) are the
closest match to our large-ship filter (Kapsar has no 100 m length cut). The dataset
covers 160 E to 145 W, 50-74 N, so Southeast Alaska and the eastern Gulf of Alaska
are outside it.

For hexagons inside Kapsar's coverage it reports:
  - rank correlation between our ship-days per hexagon and Kapsar cargo + tanker
    operating days per hexagon (24 months summed);
  - share of Kapsar's busiest hexagons (top 10% by cargo + tanker operating days)
    that hold at least one of our route cells, and how far from shore the ones that
    don't lie (terrestrial receivers reach about 40 nautical miles);
  - share of our route cells inside hexagons where Kapsar sees cargo or tanker traffic.

Usage: python3 python/check_alaska_kapsar.py [rule]   (rule from alaska_rule_cells.npz; default ship_days_6)
Writes outputs/2018_2019/alaska/kapsar_check.json.
"""
import glob
import io
import json
import os
import sys
import zipfile

import numpy as np
import shapefile
from matplotlib.path import Path
from pyproj import Transformer
from scipy.spatial import cKDTree
from scipy.stats import spearmanr

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, HERE)
import ship_viz_products as vp  # noqa: E402
import ship_island_routes as isl  # noqa: E402

AK = os.path.join(ROOT, "outputs", "2018_2019", "alaska")
HEX = os.path.join(ROOT, "data", "ref", "kapsar_hex")
TO = Transformer.from_crs(4326, 3338, always_xy=True)


def read_hex():
    polys, ops, ships = {}, {}, {}
    for zf in sorted(glob.glob(os.path.join(HEX, "SpeedHex_201[89]_*.zip"))):
        z = zipfile.ZipFile(zf)
        stem = [n[:-4] for n in z.namelist() if n.endswith(".shp")][0]
        sf = shapefile.Reader(shp=io.BytesIO(z.read(stem + ".shp")), dbf=io.BytesIO(z.read(stem + ".dbf")),
                              shx=io.BytesIO(z.read(stem + ".shx")))
        names = [f[0] for f in sf.fields[1:]]
        for shp, rec in zip(sf.shapes(), sf.records()):
            r = dict(zip(names, rec))
            h = r["hexID"]
            polys.setdefault(h, np.array(shp.points))
            ops[h] = ops.get(h, 0) + (r["nOprD_C"] or 0) + (r["nOprD_T"] or 0)
            ships[h] = max(ships.get(h, 0), (r["nMMSI_C"] or 0) + (r["nMMSI_T"] or 0))
    return polys, ops, ships


def main(rule):
    z = np.load(os.path.join(AK, "alaska_rule_cells.npz"))
    route, cell, sdays = z[rule], z["both_cell"], z["ship_days"]
    polys, ops, mships = read_hex()
    hid = list(polys)
    cent = np.array([polys[h].mean(axis=0) for h in hid])
    tree = cKDTree(cent)
    rad = max(np.max(np.hypot(*(polys[h] - polys[h].mean(axis=0)).T)) for h in hid[:50]) * 1.01

    def hex_of(cells_):
        la, lo = isl.cell_latlon(cells_, "alaska180")
        x, y = TO.transform(np.where(lo > 180, lo - 360, lo), la)
        xy = np.column_stack([x, y])
        out = np.full(len(xy), -1)
        d, i = tree.query(xy, k=3)
        for j in range(3):   # nearest candidate centers, confirm by point in polygon
            todo = (out < 0) & (d[:, j] <= rad)
            for k in np.unique(i[todo, j]):
                m = todo & (i[:, j] == k)
                inside = Path(polys[hid[k]]).contains_points(xy[m])
                out[np.nonzero(m)[0][inside]] = k
        return out

    hc = hex_of(cell)
    ours = np.zeros(len(hid))
    np.add.at(ours, hc[hc >= 0], sdays[hc >= 0])
    kap = np.array([ops[h] for h in hid], float)
    both = (kap > 0) | (ours > 0)
    rho, _ = spearmanr(ours[both], kap[both])
    hr = hex_of(route)
    has_route = np.zeros(len(hid), bool)
    has_route[hr[hr >= 0]] = True
    top = kap >= np.quantile(kap[kap > 0], 0.9)
    # Distance from shore of Kapsar's busiest hexagons that hold no route cell
    ct = isl.coast_tree("alaska")   # whole Alaska coastline, both sides of 180
    lon_c, lat_c = Transformer.from_crs(3338, 4326, always_xy=True).transform(cent[:, 0], cent[:, 1])
    lon_c = np.where(lon_c < 0, lon_c + 360, lon_c)
    shore_km = vp.chord_to_arc(ct.query(vp.ecef(lat_c, lon_c))[0])
    miss = top & ~has_route
    res = {"rule": rule, "hexagons_in_kapsar": len(hid),
           "hexagons_with_traffic_either": int(both.sum()),
           "spearman_our_shipdays_vs_kapsar_cargo_tanker_opdays": round(float(rho), 3),
           "kapsar_top10pct_hexagons": int(top.sum()),
           "kapsar_top10pct_with_our_route": round(float(np.mean(has_route[top])), 3),
           "kapsar_top10pct_without_route_median_km_from_shore": round(float(np.median(shore_km[miss])), 1) if miss.any() else None,
           "kapsar_top10pct_without_route_share_beyond_74km": round(float(np.mean(shore_km[miss] > 74)), 3) if miss.any() else None,
           "our_route_cells_in_kapsar_area": int(np.sum(hr >= 0)),
           "share_of_those_in_hex_with_kapsar_cargo_tanker": round(float(np.mean(kap[hr[hr >= 0]] > 0)), 3)}
    with open(os.path.join(AK, "kapsar_check.json"), "w") as f:
        json.dump(res, f, indent=1)
    print(json.dumps(res, indent=1))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "ship_days_6")
