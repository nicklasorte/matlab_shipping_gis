"""Rebuild the route networks on 2024-2025 and check them against 2023 and 2026.

Base years: 2024 and 2025 (the two most recent full years). 2023 (52 sampled days)
and 2026 (26 sampled days, January-June) are held out to check how stable the
routes are from year to year.

Rules (as in the paper):
  - Lower 48 and Puerto Rico/USVI: at least MIN_SHIPS distinct large ships in one
    year, either base year (main filter plus tug-barges within 25 km of the coast).
  - Hawaii: ship-days (distinct ships per sampled day, summed over the base days) of
    at least K, with K recalibrated on the lower 48 for 2024-2025.

Reports, per grid: base network vs the paper's 2023-2024 network (Jaccard, cells
added and dropped), the share of each held-out year's network inside the base
network (and of the base network it reproduces), deep-draft ports within 5 km, and
median large ships per sampled day by year.

Usage: python3 python/ship_year_stability.py
Writes outputs/2024_2025/stability/year_stability.json and <grid>_routes_2024_2025.npz.
"""
import csv
import datetime as dt
import json
import os
import sys

import numpy as np
import scipy.io
from scipy.spatial import cKDTree

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, ROOT)
sys.path.insert(0, HERE)
import ais_cells_py_rev1 as cells  # noqa: E402
import ship_viz_products as vp  # noqa: E402
import ship_island_routes as isl  # noqa: E402

OUT = os.path.join(ROOT, "outputs", "2024_2025", "stability")
BASE = (2024, 2025)
HELD = (2023, 2026)


def all_days():
    """The 52 sampled Wednesdays of 2023, of each base year (ship_period.py), and January-June 2026.

    Fixed in the November 2026 review (CA-36): the earlier version appended
    2025-01-01 onward to vp.days(), which by then already held 2025, so 2025 got
    53 days and the base network 661,901 cells.
    """
    def wednesdays(start, n=None, end=None):
        out, d = [], start
        while (n is None or len(out) < n) and (end is None or d <= end):
            out.append(d)
            d += dt.timedelta(7)
        return out
    out = wednesdays(dt.date(2023, 1, 4), n=52) + list(vp.days()) + wednesdays(dt.date(2026, 1, 7), end=dt.date(2026, 6, 30))
    assert len(out) == len(set(out)), "duplicate sample days"
    return out


def load(day, filt, grid):
    m = scipy.io.loadmat(os.path.join(ROOT, "data", cells.cache_name(day.isoformat(), cells.FILTERS[filt], grid)))
    return m["pairs"].astype(np.int64).reshape(-1, 2)


def latlon(cell, grid):
    return vp.cell_latlon(cell) if grid is None else isl.cell_latlon(cell, grid)


def coast_tree(grid):
    if grid is None:
        c = vp.coast_cells()
        la, lo = vp.cell_latlon(c)
        return cKDTree(vp.ecef(la, lo))
    return isl.coast_tree(grid)


def counts_by_year(grid):
    """Per year: distinct ships per cell; per day: the day's (cell, mmsi) pairs' cells; ships per day."""
    tree = coast_tree(grid)
    ok_tow, years, days_cells, per_day = {}, {}, {}, {}
    for d in all_days():
        m, t = load(d, "main", grid), load(d, "towing", grid)
        if len(t):
            need = [c for c in np.unique(t[:, 0]).tolist() if c not in ok_tow]
            if need:
                la, lo = latlon(np.array(need), grid)
                ok_tow.update(zip(need, (vp.chord_to_arc(tree.query(vp.ecef(la, lo))[0]) <= vp.TOWING_COAST_KM).tolist()))
            t = t[np.array([ok_tow[c] for c in t[:, 0].tolist()])]
        both = np.unique(np.vstack([m, t]), axis=0) if len(t) else m
        years.setdefault(d.year, []).append(both)
        days_cells.setdefault(d.year, []).append(both[:, 0])
        per_day.setdefault(d.year, []).append(len(np.unique(both[:, 1])) if len(both) else 0)
    yc = {}
    for y, L in years.items():
        p = np.unique(np.vstack(L), axis=0)
        yc[y] = np.unique(p[:, 0], return_counts=True)
    sd = {y: np.unique(np.concatenate(L), return_counts=True) for y, L in days_cells.items()}
    return yc, sd, per_day


def net_min_ships(yc, years, n=vp.MIN_SHIPS):
    s = set()
    for y in years:
        c, k = yc[y]
        s |= set(c[k >= n].tolist())
    return s


def net_ship_days(sd, years, k):
    tot = {}
    for y in years:
        for c, n in zip(*sd[y]):
            tot[c] = tot.get(c, 0) + n
    return {c for c, n in tot.items() if n >= k}


def jac(a, b):
    return len(a & b) / max(1, len(a | b))


def ports_reached(net, grid):
    if not net:
        return 0, 0
    (la0, la1), (lo0, lo1) = cells.GRIDS[grid] if grid else (cells.LATLIM, cells.LONLIM)
    with open(os.path.join(ROOT, "data", "usace_principal_ports.csv")) as f:
        pp = [r for r in csv.DictReader(f) if r["type"] != "I" and float(r["foreign_tons"]) >= 1e6
              and la0 <= float(r["lat"]) <= la1 and lo0 <= float(r["lon"]) <= lo1]
    c = np.fromiter(net, np.int64, len(net))
    la, lo = latlon(c, grid)
    tree = cKDTree(vp.ecef(la, lo))
    d = vp.chord_to_arc(tree.query(vp.ecef(np.array([float(r["lat"]) for r in pp]),
                                           np.array([float(r["lon"]) for r in pp])))[0])
    return int(np.sum(d <= 5)), len(pp)


def compare(base, paper, yc, sd, per_day, grid, rule):
    res = {"rule": rule, "base_cells": len(base), "paper_cells": len(paper),
           "jaccard_base_vs_paper": round(jac(base, paper), 3),
           "cells_added": len(base - paper), "cells_dropped": len(paper - base),
           "ships_per_day_median": {str(y): float(np.median(v)) for y, v in sorted(per_day.items())},
           "sampled_days": {str(y): len(v) for y, v in sorted(per_day.items())}}
    for y in HELD:
        held = net_min_ships(yc, [y]) if rule.startswith("min") else net_ship_days(sd, [y], K_HELD[y])
        res[f"held_{y}"] = {"cells": len(held), "share_inside_base": round(len(held & base) / max(1, len(held)), 3),
                            "share_of_base_reproduced": round(len(held & base) / max(1, len(base)), 3)}
    r, n = ports_reached(base, grid)
    rp, _ = ports_reached(paper, grid)
    res["deep_draft_ports_within_5km"] = {"base": r, "paper": rp, "of": n}
    return res


def main():
    global K_HELD
    os.makedirs(OUT, exist_ok=True)
    yc, sd, pdays = counts_by_year(None)
    paper = net_min_ships(yc, (2023, 2024))
    base = net_min_ships(yc, BASE)
    # Recalibrate ship-days K on the lower 48, base years
    jk = {k: jac(base, net_ship_days(sd, BASE, k)) for k in (3, 4, 5, 6, 7, 8, 10)}
    K = max(jk, key=jk.get)
    # Held-out ship-days cutoffs scale with the number of days (52 base days per year)
    K_HELD = {2023: max(1, round(K / 2)), 2026: max(1, round(K / 4))}
    res = {"base_years": BASE, "held_out": HELD,
           "ship_days_calibration_2024_2025": {"jaccard": {str(k): round(v, 3) for k, v in jk.items()}, "K": K}}
    res["lower48"] = compare(base, paper, yc, sd, pdays, None, "min_ships_4")
    np.savez_compressed(os.path.join(OUT, "lower48_routes_2024_2025.npz"), route_cells=np.array(sorted(base)))
    print(json.dumps(res["lower48"]), flush=True)
    for grid in ("hawaii", "prusvi"):
        yc, sd, pdays = counts_by_year(grid)
        if grid == "hawaii":
            base, paper = net_ship_days(sd, BASE, K), net_ship_days(sd, (2023, 2024), 6)
            rule = f"ship_days_{K}"
        else:
            base, paper = net_min_ships(yc, BASE), net_min_ships(yc, (2023, 2024))
            rule = "min_ships_4"
        res[grid] = compare(base, paper, yc, sd, pdays, grid, rule)
        np.savez_compressed(os.path.join(OUT, f"{grid}_routes_2024_2025.npz"), route_cells=np.array(sorted(base)))
        print(grid, json.dumps(res[grid]), flush=True)
    with open(os.path.join(OUT, "year_stability.json"), "w") as f:
        json.dump(res, f, indent=1)


K_HELD = {}
if __name__ == "__main__":
    main()
