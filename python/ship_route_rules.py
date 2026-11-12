"""Compare three route rules for the island grids, each calibrated on the lower 48.

Rules (a cell is a route cell when ...):
  A. min_ships  - at least N distinct large ships cross it in either year of the analysis period
                  (the paper's rule uses N = 4; sweep N = 1..4).
  B. ship_days  - our own transit count: the sum over the 104 sampled days of the
                  distinct large ships in the cell that day is at least K.
  C. noaa       - NOAA AIS Vessel Transit Counts 2024 (all vessel groups, read at
                  800 m) is at least T in the cell.
K and T are calibrated on the lower 48: the value whose route set best matches the
paper's lower-48 network (highest Jaccard index) is used unchanged on the islands.

Checks for each rule: route cells, distance from each port to the nearest route
cell, and whether each port connects to Honolulu (or San Juan) through route cells
(8-neighbor, with one-cell gaps bridged).

Usage: python3 python/ship_route_rules.py
Writes outputs/<period>/islands/route_rules.json and <grid>_rule_cells.npz.
"""
import json
import os
import sys

import numpy as np
import rasterio
from pyproj import Transformer
from rasterio.windows import from_bounds
from scipy import ndimage
from scipy.spatial import cKDTree

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, ROOT)
sys.path.insert(0, HERE)
import ais_cells_py_rev1 as cells  # noqa: E402
import ship_viz_products as vp  # noqa: E402
import ship_period as PER  # noqa: E402  analysis years
import ship_island_routes as isl  # noqa: E402

OUT = os.path.join(ROOT, "outputs", PER.TAG, "islands")
TIF = os.path.join(ROOT, "data", "ref", "ais-transit-count-2024.tif")
HUB = {"hawaii": "Honolulu", "prusvi": "San Juan", "alaska": "Valdez"}
TO_LL = Transformer.from_crs(3857, 4326, always_xy=True)
TO_M = Transformer.from_crs(4326, 3857, always_xy=True)


def noaa_cells(grid):
    """Max NOAA transits per 0.01-degree cell of the grid (None = lower 48)."""
    (la0, la1), (lo0, lo1) = cells.GRIDS[grid] if grid else (cells.LATLIM, cells.LONLIM)
    x0, y0 = TO_M.transform(lo0, la0)
    x1, y1 = TO_M.transform(lo1, la1)
    with rasterio.open(TIF, overview_level=2) as r:   # factor 8 = 800 m
        w = from_bounds(x0, y0, x1, y1, r.transform).round_offsets().round_lengths()
        a = r.read(1, window=w)
        tr = r.window_transform(w)
    rows, cols = np.nonzero(a)
    v = a[rows, cols].astype(np.int64)
    lon, lat = TO_LL.transform(tr.c + (cols + 0.5) * tr.a, tr.f + (rows + 0.5) * tr.e)
    row, col, ok = cells.discrete(lat, lon, grid)
    nr = cells.grid_size(grid)[0]
    cell = (row[ok] + (col[ok] - 1) * nr).astype(np.int64)
    v = v[ok]
    out = np.zeros(cell.max() + 1 if len(cell) else 1, np.int64)
    np.maximum.at(out, cell, v)
    c = np.nonzero(out)[0]
    return c, out[c]


def jaccard(a, b):
    a, b = set(a), set(b)
    return len(a & b) / max(1, len(a | b))


def conus_counts():
    """Lower 48: distinct ships per cell per year, and ship-days per cell (main + coastal tug-barges)."""
    coast = vp.coast_cells()
    cl, co = vp.cell_latlon(coast)
    tree = cKDTree(vp.ecef(cl, co))
    ok_tow, days_acc, year = {}, [], {y: [] for y in PER.YEARS}
    for d in vp.days():
        m, t = vp.load_pairs(d, "main"), vp.load_pairs(d, "towing")
        if len(t):
            need = [c for c in np.unique(t[:, 0]).tolist() if c not in ok_tow]
            if need:
                la, lo = vp.cell_latlon(np.array(need))
                ok_tow.update(zip(need, (vp.chord_to_arc(tree.query(vp.ecef(la, lo))[0]) <= vp.TOWING_COAST_KM).tolist()))
            t = t[np.array([ok_tow[c] for c in t[:, 0].tolist()])]
        both = np.unique(np.vstack([m, t]), axis=0) if len(t) else m
        days_acc.append(both[:, 0])
        year[d.year].append(both)
    sd_c, sd_n = np.unique(np.concatenate(days_acc), return_counts=True)
    yr = {}
    for y, L in year.items():
        p = np.unique(np.vstack(L), axis=0)
        yr[y] = np.unique(p[:, 0], return_counts=True)
    return yr, (sd_c, sd_n)


def island_counts(grid):
    tree = isl.coast_tree(grid)
    ok_tow, days_acc, year = {}, [], {y: [] for y in PER.YEARS}
    for d in vp.days():
        m, t = isl.load(d, "main", grid), isl.load(d, "towing", grid)
        if len(t):
            need = [c for c in np.unique(t[:, 0]).tolist() if c not in ok_tow]
            if need:
                la, lo = isl.cell_latlon(np.array(need), grid)
                ok_tow.update(zip(need, (vp.chord_to_arc(tree.query(vp.ecef(la, lo))[0]) <= vp.TOWING_COAST_KM).tolist()))
            t = t[np.array([ok_tow[c] for c in t[:, 0].tolist()])]
        both = np.unique(np.vstack([m, t]), axis=0) if len(t) else m
        if len(both):
            days_acc.append(both[:, 0])
            year[d.year].append(both)
    sd = np.unique(np.concatenate(days_acc), return_counts=True)
    yr = {y: np.unique(np.unique(np.vstack(L), axis=0)[:, 0], return_counts=True) for y, L in year.items()}
    return yr, sd


def by_min_ships(yr, n):
    s = set()
    for c, k in yr.values():
        s |= set(c[k >= n].tolist())
    return np.array(sorted(s), dtype=np.int64)


def checks(route, grid):
    la0, lo0, nr, nc = isl.grid_ref(grid)
    mask = np.zeros((nr, nc), bool)
    mask[(route - 1) % nr, (route - 1) // nr] = True
    bridged = ndimage.binary_closing(mask, structure=np.ones((3, 3))) | mask   # bridge one-cell gaps
    lab, _ = ndimage.label(bridged, structure=np.ones((3, 3)))
    rl, ro = isl.cell_latlon(route, grid)
    tree = cKDTree(vp.ecef(rl, ro))
    out, hub_lab = {}, None
    for name, (pla, plo) in isl.PORTS[grid].items():
        dch, i = tree.query(vp.ecef(np.array([pla]), np.array([plo])))
        c = route[i[0]]
        L = lab[(c - 1) % nr, (c - 1) // nr]
        out[name] = {"km": round(float(vp.chord_to_arc(dch)[0]), 1), "label": int(L)}
        if name == HUB[grid]:
            hub_lab = L
    for v in out.values():
        v["connected_to_hub"] = bool(v.pop("label") == hub_lab and v["km"] <= 2)
    return {"route_cells": int(len(route)),
            "ports_within_2km": int(sum(v["km"] <= 2 for v in out.values())),
            "ports_connected_to_hub": int(sum(v["connected_to_hub"] for v in out.values())),
            "ports": out}


def main():
    res = {"calibration": {}}
    yr48, (sdc, sdn) = conus_counts()
    paper = by_min_ships(yr48, vp.MIN_SHIPS)
    ks = [2, 3, 4, 5, 6, 8, 10, 12, 15, 20, 25, 30]
    jk = {k: jaccard(paper, sdc[sdn >= k]) for k in ks}
    K = max(jk, key=jk.get)
    nc_, nv = noaa_cells(None)
    ts = [1, 2, 3, 5, 8, 10, 15, 20, 30, 40, 50, 75, 100]
    jt = {t: jaccard(paper, nc_[nv >= t]) for t in ts}
    T = max(jt, key=jt.get)
    res["calibration"] = {"paper_route_cells": int(len(paper)),
                          "ship_days_jaccard": {str(k): round(v, 3) for k, v in jk.items()}, "K": K,
                          "noaa_jaccard": {str(t): round(v, 3) for t, v in jt.items()}, "T": T}
    print(json.dumps(res["calibration"]), flush=True)
    for grid in ("hawaii", "prusvi"):
        yr, (c, n) = island_counts(grid)
        ncc, nvv = noaa_cells(grid)
        rules = {f"min_ships_{m}": by_min_ships(yr, m) for m in (4, 3, 2, 1)}
        rules[f"ship_days_{K}"] = c[n >= K]
        rules[f"noaa_{T}"] = ncc[nvv >= T]
        res[grid] = {k: checks(v, grid) for k, v in rules.items()}
        np.savez_compressed(os.path.join(OUT, f"{grid}_rule_cells.npz"), **rules)
        for k, v in res[grid].items():
            print(grid, k, v["route_cells"], v["ports_within_2km"], v["ports_connected_to_hub"], flush=True)
    with open(os.path.join(OUT, "route_rules.json"), "w") as f:
        json.dump(res, f, indent=1)


if __name__ == "__main__":
    main()
