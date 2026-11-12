"""Route cells for the Hawaii and Puerto Rico/USVI grids, with the lower-48 rules.

Same rules as ship_viz_products.py: a cell is on the route network when at least
MIN_SHIPS distinct large ships (main filter, plus tug-barges within
TOWING_COAST_KM of the Census coastline) cross it in 2023 or in 2024.

Checks reported for the gate in docs/plans/alaska_hawaii_plan_rev1.md:
  - distance from each USACE port in the area to the nearest route cell,
  - number of connected route pieces (8-neighbor) and the size of the biggest,
  - distinct large ships per sampled day.

Usage: python3 python/ship_island_routes.py [hawaii] [prusvi]
Writes outputs/2023_2024/islands/<grid>_routes.npz, <grid>_summary.json, <grid>_daily.csv.
"""
import csv
import json
import os
import sys

import numpy as np
import scipy.io
import shapefile
from scipy import ndimage
from scipy.spatial import cKDTree

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, ROOT)
sys.path.insert(0, HERE)
import ais_cells_py_rev1 as cells  # noqa: E402
import ship_viz_products as vp  # noqa: E402  same days(), MIN_SHIPS, TOWING_COAST_KM

OUT = os.path.join(ROOT, "outputs", "2023_2024", "islands")
# USACE Principal Ports in each area (approximate public coordinates of the harbor)
PORTS = {
    "hawaii": {"Honolulu": (21.305, -157.870), "Kalaeloa (Barbers Point)": (21.320, -158.120),
               "Kahului": (20.898, -156.472), "Hilo": (19.731, -155.065),
               "Nawiliwili": (21.955, -159.355), "Kawaihae": (20.035, -155.830)},
    "prusvi": {"San Juan": (18.455, -66.105), "Ponce": (17.975, -66.615),
               "Guayanilla and Penuelas": (17.990, -66.760), "Yabucoa": (18.040, -65.830),
               "Mayaguez": (18.205, -67.160), "St. Croix (Limetree Bay)": (17.690, -64.750),
               "Charlotte Amalie (St. Thomas)": (18.335, -64.930)},
}


def grid_ref(grid):
    (la0, _), (lo0, _) = cells.GRIDS[grid]
    nr, nc = cells.grid_size(grid)
    return la0, lo0, nr, nc


def cell_latlon(cell, grid):
    la0, lo0, nr, _ = grid_ref(grid)
    c = cell - 1
    return la0 + cells.CELL_DEG * (c % nr + 0.5), lo0 + cells.CELL_DEG * (c // nr + 0.5)


def coast_tree(grid):
    """KD-tree of Census coastline points inside the grid (about 100 m spacing)."""
    (la0, la1), (lo0, lo1) = cells.GRIDS[grid]
    sf = shapefile.Reader(os.path.join(ROOT, "data", "tl_2023_us_coastline", "tl_2023_us_coastline.shp"))
    pts = []
    for shp in sf.shapes():
        b = shp.bbox
        if b[2] < lo0 or b[0] > lo1 or b[3] < la0 or b[1] > la1:
            continue
        p = np.array(shp.points)
        parts = list(shp.parts) + [len(p)]
        for a, e in zip(parts[:-1], parts[1:]):
            for q0, q1 in zip(p[a:e - 1], p[a + 1:e]):
                n = max(2, int(np.ceil(np.hypot(*(q1 - q0)) / 0.001)))
                pts.append(np.column_stack([np.linspace(q0[0], q1[0], n), np.linspace(q0[1], q1[1], n)]))
    pts = np.vstack(pts)
    return cKDTree(vp.ecef(pts[:, 1], pts[:, 0]))


def load(day, filt, grid):
    spec = cells.FILTERS[filt]
    m = scipy.io.loadmat(os.path.join(ROOT, "data", cells.cache_name(day.isoformat(), spec, grid)))
    return m["pairs"].astype(np.int64).reshape(-1, 2)


def run(grid):
    tree = coast_tree(grid)
    tow_ok = {}
    per_year, daily = {}, []
    for yr in (2023, 2024):
        acc = []
        for d in [x for x in vp.days() if x.year == yr]:
            m, t = load(d, "main", grid), load(d, "towing", grid)
            if len(t):
                need = [c for c in np.unique(t[:, 0]).tolist() if c not in tow_ok]
                if need:
                    la, lo = cell_latlon(np.array(need), grid)
                    km = vp.chord_to_arc(tree.query(vp.ecef(la, lo))[0])
                    tow_ok.update(zip(need, (km <= vp.TOWING_COAST_KM).tolist()))
                t = t[np.array([tow_ok[c] for c in t[:, 0].tolist()])]
            both = np.unique(np.vstack([m, t]), axis=0) if len(t) else m
            daily.append({"day": d.isoformat(), "ships": int(len(np.unique(both[:, 1]))) if len(both) else 0})
            acc.append(both)
        per_year[yr] = np.unique(np.vstack(acc), axis=0)
    route, n_year = set(), {}
    for yr, p in per_year.items():
        c, n = np.unique(p[:, 0], return_counts=True)
        r = set(c[n >= vp.MIN_SHIPS].tolist())
        n_year[yr] = len(r)
        route |= r
    route = np.array(sorted(route), dtype=np.int64)
    allp = np.unique(np.vstack(list(per_year.values())), axis=0)
    bc, bs = np.unique(allp[:, 0], return_counts=True)
    # Connected pieces of the route network (8-neighbor)
    la0, lo0, nr, nc = grid_ref(grid)
    mask = np.zeros((nr, nc), bool)
    mask[(route - 1) % nr, (route - 1) // nr] = True
    lab, npieces = ndimage.label(mask, structure=np.ones((3, 3)))
    sizes = np.bincount(lab.ravel())[1:]
    # Ports
    rl, ro = cell_latlon(route, grid)
    rtree = cKDTree(vp.ecef(rl, ro))
    ports = {}
    for name, (pla, plo) in PORTS[grid].items():
        dch, i = rtree.query(vp.ecef(np.array([pla]), np.array([plo])))
        ports[name] = {"km_to_route": round(float(vp.chord_to_arc(dch)[0]), 2),
                       "on_main_piece": bool(lab[(route[i[0]] - 1) % nr, (route[i[0]] - 1) // nr] == np.argmax(sizes) + 1)}
    ships_day = np.array([r["ships"] for r in daily])
    summ = {"grid": grid, "limits": cells.GRIDS[grid], "days": len(daily),
            "route_cells": int(len(route)), "route_cells_2023": n_year[2023], "route_cells_2024": n_year[2024],
            "route_area_km2_approx": round(float(np.sum(np.cos(np.radians(rl)) * (111.32 * cells.CELL_DEG) ** 2)), 0),
            "distinct_ships_both_years": int(len(np.unique(allp[:, 1]))),
            "ships_per_day_median": float(np.median(ships_day)), "ships_per_day_min": int(ships_day.min()),
            "ships_per_day_max": int(ships_day.max()),
            "route_pieces": int(npieces), "largest_piece_share": round(float(sizes.max() / sizes.sum()), 3),
            "pieces_over_20_cells": int(np.sum(sizes > 20)), "ports": ports}
    os.makedirs(OUT, exist_ok=True)
    np.savez_compressed(os.path.join(OUT, f"{grid}_routes.npz"), route_cells=route, both_cell=bc, both_ships=bs,
                        grid=np.array([la0, lo0, cells.CELL_DEG, nr, nc]))
    with open(os.path.join(OUT, f"{grid}_summary.json"), "w") as f:
        json.dump(summ, f, indent=1)
    with open(os.path.join(OUT, f"{grid}_daily.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, ["day", "ships"])
        w.writeheader()
        w.writerows(daily)
    print(json.dumps(summ, indent=1))


if __name__ == "__main__":
    for g in sys.argv[1:] or ["hawaii", "prusvi"]:
        run(g)
