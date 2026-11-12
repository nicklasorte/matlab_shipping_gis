"""Alaska route cells from MarineCadastre 2018-2019 (the last full years with Alaska).

MarineCadastre filtered Alaska out of its 2021 and later files; 2018-2020 still
hold it, with IMO numbers and standard vessel-type codes, so the paper's ship
filter applies unchanged. 2020 is left out because pandemic schedules (cruise
ships stopped) make it unrepresentative.

Sample: one Wednesday a week in 2018 and 2019 (104 days), grid 51-72 N, 172 E to
129 W (stored as 172-231 in 0-360 longitude), 0.01 degree cells.

Rules compared (as for Hawaii, python/ship_route_rules.py):
  min_ships_N  at least N distinct large ships in one year (lower-48 rule: N = 4)
  ship_days_6  ship-days of at least 6 over the 104 days (the Hawaii rule; 6 is the
               lower-48 calibration for both 2023-2024 and 2024-2025)
Checks: distance from each USACE Principal Port to the route network, and which
ports connect to Valdez through route cells (ports within 5 km count as reached,
as for the lower-48 principal ports, because USACE points are district references).

Usage: python3 python/ship_alaska_routes.py
Writes outputs/2018_2019/alaska/alaska_rules.json, alaska_rule_cells.npz, alaska_daily.csv.
"""
import csv
import datetime as dt
import json
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ship_viz_products as vp  # noqa: E402
import ship_island_routes as isl  # noqa: E402
import ship_route_rules as rr  # noqa: E402

GRID = "alaska"
OUT = os.path.join(HERE, "..", "outputs", "2018_2019", "alaska")


def days():
    out = []
    for yr, start in ((2018, dt.date(2018, 1, 3)), (2019, dt.date(2019, 1, 2))):
        d = start
        while d.year == yr:
            out.append(d)
            d += dt.timedelta(7)
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    tree = isl.coast_tree(GRID)
    ok_tow, year, day_cells, daily = {}, {}, [], []
    for d in days():
        m, t = isl.load(d, "main", GRID), isl.load(d, "towing", GRID)
        if len(t):
            need = [c for c in np.unique(t[:, 0]).tolist() if c not in ok_tow]
            if need:
                la, lo = isl.cell_latlon(np.array(need), GRID)
                ok_tow.update(zip(need, (vp.chord_to_arc(tree.query(vp.ecef(la, lo))[0]) <= vp.TOWING_COAST_KM).tolist()))
            t = t[np.array([ok_tow[c] for c in t[:, 0].tolist()])]
        both = np.unique(np.vstack([m, t]), axis=0) if len(t) else m
        daily.append({"day": d.isoformat(), "ships": int(len(np.unique(both[:, 1]))) if len(both) else 0})
        if len(both):
            year.setdefault(d.year, []).append(both)
            day_cells.append(both[:, 0])
    yc = {y: np.unique(np.unique(np.vstack(L), axis=0)[:, 0], return_counts=True) for y, L in year.items()}
    c, n = np.unique(np.concatenate(day_cells), return_counts=True)
    allp = np.unique(np.vstack([p for L in year.values() for p in L]), axis=0)
    rules = {f"min_ships_{k}": rr.by_min_ships(yc, k) for k in (4, 3, 2)}
    rules["ship_days_6"] = c[n >= 6]
    res = {"days": len(daily), "distinct_large_ships": int(len(np.unique(allp[:, 1]))),
           "ships_per_day_median": float(np.median([r["ships"] for r in daily])),
           "ships_per_day_range": [int(min(r["ships"] for r in daily)), int(max(r["ships"] for r in daily))],
           "rules": {k: rr.checks(v, GRID, gap_km=5.0) for k, v in rules.items()}}
    np.savez_compressed(os.path.join(OUT, "alaska_rule_cells.npz"), both_cell=c, ship_days=n,
                        both_cell_ships=np.unique(allp[:, 0], return_counts=True)[1], **rules)
    with open(os.path.join(OUT, "alaska_rules.json"), "w") as f:
        json.dump(res, f, indent=1)
    with open(os.path.join(OUT, "alaska_daily.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, ["day", "ships"])
        w.writeheader()
        w.writerows(daily)
    for k, v in res["rules"].items():
        print(k, v["route_cells"], v["ports_within_gap"], v["ports_connected_to_hub"],
              {p: (x["km"], x["connected_to_hub"]) for p, x in v["ports"].items()})
    print({k: v for k, v in res.items() if k != "rules"})


if __name__ == "__main__":
    main()
