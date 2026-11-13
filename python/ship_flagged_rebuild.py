"""Rebuild the AIS route cells without flagged reports (review plan, gap 4).

For each area, the route rule runs twice on the same day caches: once as
committed, and once with the (cell, MMSI) pairs that come only from flagged
reports removed (python/flagged_pairs_day.py: position jumps and possible
duplicate MMSIs). The difference is the set of route cells that depend on
flagged reports.

Rules (AIS cells only, before port approaches, charted lanes, and satellite
lanes):
  lower 48, Puerto Rico and USVI  at least 4 distinct ships in one year
  Hawaii, Alaska                  at least 6 ship-days over the 104 days

Usage: python3 python/ship_flagged_rebuild.py
Writes outputs/<period>/flagged/flagged_rebuild.json (and the 2018_2019
Alaska result into the same file) and dropped-cell lists per area.
"""
import datetime as dt
import json
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, HERE)
sys.path.insert(0, ROOT)
import ship_viz_products as vp  # noqa: E402
import ship_island_routes as isl  # noqa: E402
import ship_alaska_routes as akr  # noqa: E402
import ship_period as PER  # noqa: E402  analysis years

FLAG = os.path.join(ROOT, "data", "flagged")
OUT = os.path.join(ROOT, "outputs", PER.TAG, "flagged")
AREAS = {  # name: (grid, rule, days, committed route file and key)
    "Lower 48": (None, "unique_ships", PER.days,
                 (os.path.join(ROOT, "outputs", PER.TAG, "viz", "viz_cells.npz"), "route_cells")),
    "Hawaii": ("hawaii", "ship_days", PER.days,
               (os.path.join(ROOT, "outputs", PER.TAG, "islands", "hawaii_rule_cells.npz"), "ship_days_6")),
    "Puerto Rico and USVI": ("prusvi", "unique_ships", PER.days,
                             (os.path.join(ROOT, "outputs", PER.TAG, "islands", "prusvi_routes.npz"), "route_cells")),
    "Alaska to 180": ("alaska180", "ship_days", akr.days,
                      (os.path.join(ROOT, "outputs", "2018_2019", "alaska", "alaska_rule_cells.npz"), "ship_days_6")),
}
KEY = 1 << 31   # MMSI < 2**31


def loader(grid):
    if grid is None:
        coast = vp.coast_cells()
        cl, co = vp.cell_latlon(coast)
        from scipy.spatial import cKDTree
        tree = cKDTree(vp.ecef(cl, co))
        return (lambda d, f: vp.load_pairs(d, f).reshape(-1, 2)), (lambda c: vp.cell_latlon(c)), tree
    return (lambda d, f: isl.load(d, f, grid)), (lambda c: isl.cell_latlon(c, grid)), isl.coast_tree(grid)


def day_pairs(grid, days):
    """Per day: main pairs, coastal tug-barge pairs (as in the route scripts)."""
    load, latlon, tree = loader(grid)
    ok_tow = {}
    for d in days():
        m, t = load(d, "main"), load(d, "towing")
        if len(t):
            need = [c for c in np.unique(t[:, 0]).tolist() if c not in ok_tow]
            if need:
                la, lo = latlon(np.array(need))
                ok_tow.update(zip(need, (vp.chord_to_arc(tree.query(vp.ecef(la, lo))[0]) <= vp.TOWING_COAST_KM).tolist()))
            t = t[np.array([ok_tow[c] for c in t[:, 0].tolist()])]
        yield d, m, t


def rule_cells(per_day, rule):
    """per_day: list of (year, unique pairs n x 2). Returns sorted route cells."""
    if rule == "ship_days":
        c, n = np.unique(np.concatenate([p[:, 0] for _, p in per_day]), return_counts=True)
        return c[n >= 6]
    route = set()
    for y in sorted({y for y, _ in per_day}):
        p = np.unique(np.vstack([q for yy, q in per_day if yy == y]), axis=0)
        c, n = np.unique(p[:, 0], return_counts=True)
        route |= set(c[n >= 4].tolist())
    return np.array(sorted(route), dtype=np.int64)


def main():
    os.makedirs(OUT, exist_ok=True)
    res = {}
    for area, (grid, rule, days, (rfile, rkey)) in AREAS.items():
        name = grid or "conus"
        full, clean, removed, missing = [], [], 0, []
        for d, m, t in day_pairs(grid, days):
            both = np.unique(np.vstack([m, t]), axis=0) if len(t) else m
            full.append((d.year, both))
            f = os.path.join(FLAG, f"flag_pairs_{d.isoformat()}.npz")
            if not os.path.isfile(f):
                missing.append(d.isoformat())
                clean.append((d.year, both))
                continue
            fo = np.load(f)[name].reshape(-1, 2)
            keep_m = ~np.isin(m[:, 0] * KEY + m[:, 1], fo[:, 0] * KEY + fo[:, 1]) if len(fo) and len(m) else np.ones(len(m), bool)
            removed += int((~keep_m).sum())
            mc = m[keep_m]
            cb = np.unique(np.vstack([mc, t]), axis=0) if len(t) else mc
            clean.append((d.year, cb))
        r_full, r_clean = rule_cells(full, rule), rule_cells(clean, rule)
        committed = np.load(rfile)[rkey]
        dropped = np.setdiff1d(r_full, r_clean)
        np.savetxt(os.path.join(OUT, f"dropped_cells_{name}.csv"), dropped, fmt="%d")
        res[area] = {"rule": rule, "days": len(full), "days_without_flag_file": missing,
                     "pairs_removed": removed,
                     "route_cells_committed": int(len(committed)),
                     "route_cells_rebuilt_all_reports": int(len(r_full)),
                     "rebuilt_matches_committed": bool(np.array_equal(np.sort(committed), r_full)),
                     "route_cells_without_flagged": int(len(r_clean)),
                     "route_cells_dropped": int(len(dropped)),
                     "route_cells_dropped_pct": round(100 * len(dropped) / max(1, len(r_full)), 4),
                     "route_cells_gained": int(len(np.setdiff1d(r_clean, r_full)))}
        print(area, json.dumps({k: (len(v) if k == "days_without_flag_file" else v) for k, v in res[area].items()}))
    res["generated"] = dt.date.today().isoformat()
    with open(os.path.join(OUT, "flagged_rebuild.json"), "w") as f:
        json.dump(res, f, indent=1)


if __name__ == "__main__":
    main()
