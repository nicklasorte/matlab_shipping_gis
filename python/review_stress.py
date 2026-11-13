"""Stage 4 stress tests for the review plan: sensitivity, sampling stability, held-out capture.

All three run on the committed day caches (lower 48 unless noted) and measure
two things for each variant:
  route cells   AIS route cells plus port-approach cells (the MATLAB run adds
                charted lanes and racons on top; those don't depend on these
                choices, so they're left out here)
  land in zone  U.S. land within 25, 50, and 100 km of a route cell, on the
                0.05-degree land grid of ship_geo_products.py, by direct
                distance (the paper's zones use the same distance rule but
                clipped land polygons, so absolute areas differ slightly from
                Section 3; the changes between variants are what this measures)
Port approaches follow the fixed rule: within 50 km of a deep-draft port and
25 km of the Census coastline.

1. Sensitivity: each choice moved one step either way, one at a time.
2. Stability: routes rebuilt from 200 random halves of the 104 days.
3. Held-out capture: share of large-ship cell visits on the held-out 2023 and
   2026 days (lower 48, Hawaii, Puerto Rico and USVI) within 25, 50, and
   100 km of the 2024-2025 routes.

4. Length cutoff: the routes rebuilt from day caches at 80 m and 120 m
   (python/build_length_variants.py), compared with 100 m.

Usage: python3 python/review_stress.py [sensitivity|stability|capture|length|all]
Writes docs/review/sensitivity_rev1.csv, stability_rev1.csv,
heldout_capture_rev1.csv, and stress_summary_rev1.json.
"""
import csv
import datetime as dt
import glob
import json
import os
import sys

import numpy as np
import shapefile
from scipy.spatial import cKDTree
from shapely import contains_xy
from shapely.geometry import Polygon
from shapely.ops import unary_union

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, HERE)
sys.path.insert(0, ROOT)
import ais_cells_py_rev1 as cells  # noqa: E402
import ship_viz_products as vp  # noqa: E402
import ship_island_routes as isl  # noqa: E402
import ship_period as PER  # noqa: E402  analysis years

OUT = os.path.join(ROOT, "docs", "review")
DIST = (25, 50, 100)
NR = vp.NR
BASE = {"min_ships": 4, "tow_km": 25.0, "grid": 1, "port_km": 50.0, "port_ships": 2, "port_coast_km": 25.0}


# ---------- data ----------
def load_days(days, grid=None):
    out = []
    for d in days:
        if grid is None:
            m, t = vp.load_pairs(d, "main").reshape(-1, 2), vp.load_pairs(d, "towing").reshape(-1, 2)
        else:
            m, t = isl.load(d, "main", grid), isl.load(d, "towing", grid)
        out.append((d, m, t))
    return out


def tow_distance(day_data, grid=None):
    """Coastline distance (km) of every tug-barge cell, computed once."""
    tc = np.unique(np.concatenate([t[:, 0] for _, _, t in day_data if len(t)]))
    if grid is None:
        coast = vp.coast_cells()
        cl, co = vp.cell_latlon(coast)
        tree = cKDTree(vp.ecef(cl, co))
        la, lo = vp.cell_latlon(tc)
    else:
        tree = isl.coast_tree(grid)
        la, lo = isl.cell_latlon(tc, grid)
    return dict(zip(tc.tolist(), vp.chord_to_arc(tree.query(vp.ecef(la, lo))[0]).tolist()))


def day_sets(day_data, tow_km, tow_d):
    """Per day: unique (cell, mmsi) of main plus tug-barges within tow_km of the coast."""
    res = []
    for d, m, t in day_data:
        if len(t) and tow_km > 0:
            keep = np.array([tow_d[c] <= tow_km for c in t[:, 0].tolist()])
            t = t[keep]
        else:
            t = t[:0]
        both = np.unique(np.vstack([m, t]), axis=0) if len(t) else m
        res.append((d.year, both))
    return res


# ---------- route rule ----------
def coarsen(cell, f):
    r, c = (cell - 1) % NR, (cell - 1) // NR
    return (r // f) + (c // f) * (NR // f) + 1


def expand(coarse, f):
    nr = NR // f
    r, c = (coarse - 1) % nr, (coarse - 1) // nr
    out = [(r * f + i) + (c * f + j) * NR + 1 for i in range(f) for j in range(f)]
    return np.unique(np.concatenate(out))


PORTS = None


def deep_ports():
    global PORTS
    if PORTS is None:
        import pandas as pd
        pp = pd.read_csv(os.path.join(ROOT, "data", "usace_principal_ports.csv"))
        pp = pp[(pp["type"] != "I") & (pp["foreign_tons"] >= 1e6)]
        PORTS = (pp["lat"].to_numpy(), pp["lon"].to_numpy())
    return PORTS


def routes(per_day, p):
    """Route cells (fine grid) for parameters p, with port-approach cells."""
    f = p["grid"]
    max_year = {}
    for y in sorted({y for y, _ in per_day}):
        P = np.vstack([q for yy, q in per_day if yy == y])
        if f > 1:
            P = np.column_stack([coarsen(P[:, 0], f), P[:, 1]])
        P = np.unique(P, axis=0)
        c, n = np.unique(P[:, 0], return_counts=True)
        for cc, nn in zip(c.tolist(), n.tolist()):
            if nn > max_year.get(cc, 0):
                max_year[cc] = nn
    c = np.fromiter(max_year.keys(), np.int64, len(max_year))
    n = np.fromiter(max_year.values(), np.int64, len(max_year))
    src = c[n >= p["min_ships"]]
    if p["port_km"] > 0:
        cand = c[(n >= p["port_ships"]) & (n < p["min_ships"])]
        if len(cand):
            la, lo = vp.cell_latlon(cand) if f == 1 else coarse_latlon(cand, f)
            plat, plon = deep_ports()
            tree = cKDTree(vp.ecef(plat, plon))
            dk = vp.chord_to_arc(tree.query(vp.ecef(la, lo))[0])
            ok = dk <= p["port_km"]
            if p.get("port_coast_km", 0) > 0:
                # Same rule as the MATLAB run (CA-8): port approaches only
                # within port_coast_km of the Census coastline.
                ok &= coast_km(la, lo) <= p["port_coast_km"]
            src = np.concatenate([src, cand[ok]])
    src = np.unique(src)
    return expand(src, f) if f > 1 else src


COAST_TREE = None


def coast_km(la, lo):
    """Great-circle distance (km) to the nearest Census coastline cell."""
    global COAST_TREE
    if COAST_TREE is None:
        cl, co = vp.cell_latlon(vp.coast_cells())
        COAST_TREE = cKDTree(vp.ecef(cl, co))
    return vp.chord_to_arc(COAST_TREE.query(vp.ecef(la, lo))[0])


def coarse_latlon(coarse, f):
    nr = NR // f
    r, c = (coarse - 1) % nr, (coarse - 1) // nr
    fine = (r * f) + (c * f) * NR + 1
    la, lo = vp.cell_latlon(fine)
    return la + (f - 1) * cells.CELL_DEG / 2, lo + (f - 1) * cells.CELL_DEG / 2


# ---------- land metric ----------
LAND = None


def land_grid():
    global LAND
    if LAND is None:
        sf = shapefile.Reader(os.path.join(vp.DATA, "cb_2023_us_state_500k", "cb_2023_us_state_500k.shp"))
        polys = []
        for shp, rec in zip(sf.shapes(), sf.records()):
            if rec["STUSPS"] in ("AK", "HI", "PR", "VI", "GU", "MP", "AS"):
                continue
            pts = shp.points
            parts = list(shp.parts) + [len(pts)]
            for a, b in zip(parts[:-1], parts[1:]):
                if b - a >= 4:
                    polys.append(Polygon(pts[a:b]).buffer(0))
        land = unary_union(polys)
        glat = np.arange(24.0, 49.5, 0.05) + 0.025
        glon = np.arange(-125.0, -66.5, 0.05) + 0.025
        LON, LAT = np.meshgrid(glon, glat)
        on = contains_xy(land, LON, LAT)
        la, lo = LAT[on], LON[on]
        area = (0.05 * 111.195) ** 2 * np.cos(np.radians(la))   # km2 per point
        LAND = (vp.ecef(la, lo), area)
    return LAND


def land_in_zone(route):
    xyz, area = land_grid()
    rl, ro = vp.cell_latlon(route)
    d = vp.chord_to_arc(cKDTree(vp.ecef(rl, ro)).query(xyz)[0])
    return {k: float(area[d <= k].sum()) for k in DIST}


# ---------- 1. sensitivity ----------
def sensitivity(day_data, tow_d):
    variants = [("Baseline", {})]
    # CA-14: threshold sweep from 2 to 8 ships.
    variants += [(f"Ships per cell per year = {v}", {"min_ships": v}) for v in (2, 3, 5, 6, 8)]
    variants += [(f"Tug-barge distance = {v:g} km" if v else "No tug-barges", {"tow_km": v}) for v in (0.0, 50.0)]
    variants += [(f"Port approach radius = {v:g} km", {"port_km": v}) for v in (25.0, 100.0)]
    variants += [("No port approaches", {"port_km": 0.0}), ("Port approach ships = 3", {"port_ships": 3})]
    variants += [("Port approaches without the 25 km coast limit", {"port_coast_km": 0.0})]
    variants += [("Grid cell = 0.02 degree", {"grid": 2})]
    rows, base = [], None
    cache = {}
    for name, ch in variants:
        p = dict(BASE, **ch)
        key = p["tow_km"]
        if key not in cache:
            cache[key] = day_sets(day_data, p["tow_km"], tow_d)
        r = routes(cache[key], p)
        z = land_in_zone(r)
        row = {"variant": name, "route_cells": int(len(r)), **{f"land_{k}km_km2": round(z[k]) for k in DIST}}
        if base is None:
            base = row
        row["route_cells_change_pct"] = round(100 * (row["route_cells"] - base["route_cells"]) / base["route_cells"], 1)
        for k in DIST:
            row[f"land_{k}km_change_pct"] = round(100 * (row[f"land_{k}km_km2"] - base[f"land_{k}km_km2"]) / base[f"land_{k}km_km2"], 1)
        rows.append(row)
        print(json.dumps(row), flush=True)
    write_csv("sensitivity_rev1.csv", rows)
    return rows


# ---------- 2. stability ----------
def stability(day_data, tow_d, n_rep=200, seed=1):
    per_day = day_sets(day_data, BASE["tow_km"], tow_d)
    full = routes(per_day, BASE)
    rng = np.random.default_rng(seed)
    counts = {}
    rows = []
    for k in range(n_rep):
        idx = np.sort(rng.choice(len(per_day), len(per_day) // 2, replace=False))
        r = routes([per_day[i] for i in idx], BASE)
        for c in r.tolist():
            counts[c] = counts.get(c, 0) + 1
        row = {"rep": k, "route_cells": int(len(r)), "share_of_full_in_half": round(len(np.intersect1d(r, full)) / len(full), 4)}
        if k < 40:   # land metric on the first 40 halves (the land query dominates run time)
            z = land_in_zone(r)
            row.update({f"land_{d}km_km2": round(z[d]) for d in DIST})
        rows.append(row)
        if k % 20 == 0:
            print(k, row, flush=True)
    write_csv("stability_rev1.csv", rows)
    freq = np.array([counts.get(c, 0) for c in full.tolist()]) / n_rep
    unstable = full[freq < 0.9]
    np.savetxt(os.path.join(OUT, "stability_unstable_cells_rev1.csv"), unstable, fmt="%d")
    rc = np.array([r["route_cells"] for r in rows])
    return {"full_route_cells": int(len(full)), "half_route_cells_min": int(rc.min()), "half_route_cells_max": int(rc.max()),
            "half_route_cells_median": float(np.median(rc)),
            "full_cells_in_fewer_than_90pct_of_halves": int(len(unstable)),
            "full_cells_in_fewer_than_90pct_share": round(len(unstable) / len(full), 4)}


# ---------- 3. held-out capture ----------
def held_days(year):
    days = sorted({os.path.basename(f).split("_")[2] for f in glob.glob(os.path.join(vp.DATA, f"ais_cells_{year}*_vt0-99*22_50_-130_-66*"))})
    return [dt.date(int(d[:4]), int(d[4:6]), int(d[6:])) for d in days]


def capture():
    areas = {"Lower 48": (None, os.path.join(ROOT, "outputs", PER.TAG, "viz", "viz_cells.npz"), "route_cells"),
             "Hawaii": ("hawaii", os.path.join(ROOT, "outputs", PER.TAG, "islands", "hawaii_rule_cells.npz"), "ship_days_6"),
             "Puerto Rico and USVI": ("prusvi", os.path.join(ROOT, "outputs", PER.TAG, "islands", "prusvi_routes.npz"), "route_cells")}
    rows = []
    for area, (grid, rfile, rkey) in areas.items():
        route = np.load(rfile)[rkey]
        la, lo = vp.cell_latlon(route) if grid is None else isl.cell_latlon(route, grid)
        tree = cKDTree(vp.ecef(la, lo))
        for year in (2023, 2026):
            days = held_days(year)
            visits = []
            for d in days:
                m = vp.load_pairs(d, "main").reshape(-1, 2) if grid is None else isl.load(d, "main", grid)
                visits.append(m[:, 0])
            v = np.concatenate(visits)
            uc, n = np.unique(v, return_counts=True)
            cla, clo = vp.cell_latlon(uc) if grid is None else isl.cell_latlon(uc, grid)
            dk = vp.chord_to_arc(tree.query(vp.ecef(cla, clo))[0])
            row = {"area": area, "year": year, "days": len(days), "cell_visits": int(n.sum()),
                   "share_on_route_cell": round(float(n[np.isin(uc, route)].sum() / n.sum()), 4)}
            for k in DIST:
                row[f"share_within_{k}km"] = round(float(n[dk <= k].sum() / n.sum()), 4)
            far = dk > 100
            row["visits_beyond_100km"] = int(n[far].sum())
            row["cells_beyond_100km"] = int(far.sum())
            if far.any():
                np.savetxt(os.path.join(OUT, f"heldout_beyond100km_{(grid or 'conus')}_{year}.csv"),
                           np.column_stack([uc[far], n[far], np.round(dk[far], 1)]), fmt="%d,%d,%.1f",
                           header="cell,visits,km_to_route", comments="")
            rows.append(row)
            print(json.dumps(row), flush=True)
    write_csv("heldout_capture_rev1.csv", rows)
    return rows


def length_variants():
    """Route cells and land in zone at 80, 100, and 120 m (lower 48)."""
    import scipy.io
    LV = os.path.join(ROOT, "data", "length_variants")
    rows, base = [], None
    for L in (100, 80, 120):
        dd = []
        for d in PER.days():
            if L == 100:
                m, t = vp.load_pairs(d, "main").reshape(-1, 2), vp.load_pairs(d, "towing").reshape(-1, 2)
            else:
                ld = lambda k: scipy.io.loadmat(os.path.join(LV, cells.cache_name(  # noqa: E731
                    d.isoformat(), dict(cells.FILTERS[k], min_length_m=float(L)))))["pairs"].astype(np.int64).reshape(-1, 2)
                m, t = ld("main"), ld("towing")
            dd.append((d, m, t))
        tow_d = tow_distance(dd)
        per_day = day_sets(dd, BASE["tow_km"], tow_d)
        ships = len(np.unique(np.concatenate([q[:, 1] for _, q in per_day])))
        r = routes(per_day, BASE)
        z = land_in_zone(r)
        row = {"length_cutoff_m": L, "distinct_ships": int(ships), "route_cells": int(len(r)),
               **{f"land_{k}km_km2": round(z[k]) for k in DIST}}
        if base is None:
            base = row
        row["ships_change_pct"] = round(100 * (row["distinct_ships"] - base["distinct_ships"]) / base["distinct_ships"], 1)
        row["route_cells_change_pct"] = round(100 * (row["route_cells"] - base["route_cells"]) / base["route_cells"], 1)
        for k in DIST:
            row[f"land_{k}km_change_pct"] = round(100 * (row[f"land_{k}km_km2"] - base[f"land_{k}km_km2"]) / base[f"land_{k}km_km2"], 1)
        rows.append(row)
        print(json.dumps(row), flush=True)
    write_csv("length_sensitivity_rev1.csv", rows)
    return rows


def write_csv(name, rows):
    keys = list(dict.fromkeys(k for r in rows for k in r))
    with open(os.path.join(OUT, name), "w", newline="") as f:
        w = csv.DictWriter(f, keys)
        w.writeheader()
        w.writerows(rows)


def main(what):
    os.makedirs(OUT, exist_ok=True)
    summ_path = os.path.join(OUT, "stress_summary_rev1.json")
    summ = json.load(open(summ_path)) if os.path.isfile(summ_path) else {}
    if what in ("capture", "all"):
        summ["capture"] = capture()
    if what in ("length", "all"):
        summ["length"] = length_variants()
    if what in ("sensitivity", "stability", "all"):
        dd = load_days(PER.days())
        tow_d = tow_distance(dd)
        if what in ("sensitivity", "all"):
            summ["sensitivity"] = sensitivity(dd, tow_d)
        if what in ("stability", "all"):
            summ["stability"] = stability(dd, tow_d)
    json.dump(summ, open(summ_path, "w"), indent=1)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "all")
