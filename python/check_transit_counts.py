"""Cross-check our large-ship route cells against NOAA's AIS Vessel Transit Counts 2024.

NOAA OCM builds that raster independently from the same raw AIS (all vessel
groups, 100 m cells, EPSG:3857). This reads its 800 m overview, takes the
maximum transit count in each of our 0.01-degree cells, and reports:
  - the share of our route cells that NOAA also shows traffic in,
  - the rank correlation between our distinct large ships per cell (2024 only
    not separable here, so both years) and NOAA's transits per cell,
  - the share of NOAA's busiest cells that lie on or near our routes.

Usage: python3 python/check_transit_counts.py   (needs data/ref/ais-transit-count-2024.tif)
Writes outputs/<period>/qc/transit_count_check.json.
"""
import json
import os
import sys

import numpy as np
from scipy.spatial import cKDTree
from scipy.stats import spearmanr

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
import ship_viz_products as vp  # noqa: E402

ROOT = os.path.join(HERE, "..")
sys.path.insert(0, HERE)
import ship_period as PER  # noqa: E402  analysis years
import ship_route_rules as rr  # noqa: E402

OUT = os.path.join(ROOT, "outputs", PER.TAG, "qc")


def main():
    z = np.load(os.path.join(ROOT, "outputs", PER.TAG, "viz", "viz_cells.npz"))
    route, bc, bs = z["route_cells"], z["both_cell"], z["both_ships"]
    ncell, nmax = rr.noaa_cells(None)   # max transits per our cell, full 100 m resolution (review CA-63)
    tmap = dict(zip(ncell.tolist(), nmax.tolist()))
    t_route = np.array([tmap.get(int(c), 0) for c in route])
    res = {"route_cells": int(len(route)),
           "route_cells_with_noaa_traffic": float(np.mean(t_route > 0)),
           "noaa_transits_on_route_cells_median": float(np.median(t_route))}
    sh = dict(zip(bc.tolist(), bs.tolist()))
    s_route = np.array([sh.get(int(c), 0) for c in route])
    rho, _ = spearmanr(s_route, t_route)
    res["spearman_ships_vs_transits_route_cells"] = float(rho)
    # NOAA's busiest cells (top 1% of cells with traffic): how many are near our routes?
    thr = np.quantile(nmax, 0.99)
    busy = ncell[nmax >= thr]
    rl, ro = vp.cell_latlon(route)
    tree = cKDTree(vp.ecef(rl, ro))
    bl, bo = vp.cell_latlon(busy)
    d = vp.chord_to_arc(tree.query(vp.ecef(bl, bo))[0])
    res["noaa_top1pct_threshold_transits"] = float(thr)
    res["noaa_top1pct_cells"] = int(len(busy))
    res["noaa_top1pct_within_2km_of_routes"] = float(np.mean(d <= 2))
    res["noaa_top1pct_within_10km_of_routes"] = float(np.mean(d <= 10))
    far = d > 10
    if far.any():   # where NOAA's busy cells sit far from our routes (likely small craft: ferries, fishing)
        h, xe, ye = np.histogram2d(bl[far], bo[far], bins=[np.arange(22, 51, 1), np.arange(-130, -65, 1)])
        top = np.dstack(np.unravel_index(np.argsort(-h.ravel())[:10], h.shape))[0]
        res["far_busy_cells_top_1deg_boxes"] = [{"lat": float(ye[0] * 0 + xe[i]), "lon": float(ye[j]), "cells": int(h[i, j])}
                                                for i, j in top if h[i, j] > 0]
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "transit_count_check.json"), "w") as f:
        json.dump(res, f, indent=1)
    print(json.dumps(res, indent=1))


if __name__ == "__main__":
    main()
