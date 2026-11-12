"""Share of large-ship traffic at each deep-draft port, for the port-share figures.

The MATLAB twin is port_share_products_rev1.m. Both read the AIS day caches.

Port areas: route-network cells within 10 km of a deep-draft port (USACE
Principal Port, coastal or Great Lakes, at least 1 million tons of foreign
trade), each cell assigned to its nearest port so areas don't overlap.
Traffic at a port = distinct large ships seen in its area over the 104
sampled days. A ship that calls at several ports counts once at each, so
the shares are shares of port visits: port ships / sum over all ports.

Usage (from the repo root):
  python3 python/ship_port_share_products.py

Writes outputs/<period>/viz/port_share.csv:
  port, short, complex, coast, lat, lon, rank, ships, ships_y0, ships_y1,
  share, cargo, tanker, passenger, government
and port_share_complex.csv: complex, coast, ships (distinct ships in the
union of its port areas), visits (sum of its ports), share.
"""
import csv
import os
import sys

import numpy as np
from scipy.spatial import cKDTree

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ship_period as PER  # noqa: E402  analysis years
import ship_viz_products as vp  # noqa: E402

ROOT = os.path.join(HERE, "..")
OUT = os.path.join(ROOT, "outputs", PER.TAG, "viz")
PORT_KM = 10.0
TYPES = ["cargo", "tanker", "passenger", "government"]


def main():
    pp = [r for r in csv.DictReader(open(os.path.join(ROOT, "outputs", PER.TAG,
                                                       f"shipping_zone_{PER.TAG}_principal_port_check.csv")))
          if r["type"] != "I" and int(r["foreign_tons"]) >= 1e6]
    short = {r["port"]: r["short"] for r in csv.DictReader(open(os.path.join(ROOT, "config",
                                                                           "port_short_names_rev1.csv")))}
    cx = {r["port"]: r["complex"] for r in csv.DictReader(open(os.path.join(ROOT, "config",
                                                                             "port_complexes_rev1.csv")))}
    plat = np.array([float(r["lat"]) for r in pp])
    plon = np.array([float(r["lon"]) for r in pp])
    coast = vp.coast_region(plat, plon)
    coast = np.where(np.array([r["type"] == "L" for r in pp]), "Great Lakes", coast)
    ptree = cKDTree(vp.ecef(plat, plon))
    chord = 2 * vp.R_EARTH * np.sin(PORT_KM / (2 * vp.R_EARTH))

    # Tug-barge coastal rule, as in the other products
    coast_cells = vp.coast_cells()
    ctree = cKDTree(vp.ecef(*vp.cell_latlon(coast_cells)))
    near = {}

    def tow_ok(c):
        u = np.unique(c)
        need = u[[int(v) not in near for v in u]]
        if len(need):
            km = vp.chord_to_arc(ctree.query(vp.ecef(*vp.cell_latlon(need)))[0])
            for v, kk in zip(need, km <= vp.TOWING_COAST_KM):
                near[int(v)] = bool(kk)
        return np.array([near[int(v)] for v in c], dtype=bool)

    def load(filts, years=PER.YEARS):
        parts = []
        for d in vp.days():
            if d.year not in years:
                continue
            for f in filts:
                p = vp.load_pairs(d, f)
                if f == "towing" and len(p):
                    p = p[tow_ok(p[:, 0])]
                parts.append(p)
        return np.unique(np.vstack(parts), axis=0)

    port_of = {}

    def port_counts(P):
        """Distinct ships per port area; each cell goes to its nearest port within 10 km."""
        uc = np.unique(P[:, 0])
        need = uc[[int(v) not in port_of for v in uc]]
        if len(need):
            dd, ii = ptree.query(vp.ecef(*vp.cell_latlon(need)))
            for v, d_, i_ in zip(need, dd, ii):
                port_of[int(v)] = int(i_) if d_ <= chord else -1
        pi = np.array([port_of[int(v)] for v in P[:, 0]])
        keep = pi >= 0
        u = np.unique(np.column_stack([pi[keep], P[keep, 1]]), axis=0)
        return np.bincount(u[:, 0], minlength=len(pp)), u

    y23 = load(["main", "towing"], (PER.Y0,))
    y24 = load(["main", "towing"], (PER.Y1,))
    both = np.unique(np.vstack([y23, y24]), axis=0)
    n_all, pm = port_counts(both)
    n23, _ = port_counts(y23)
    n24, _ = port_counts(y24)
    n_type = {t: port_counts(load([t]))[0] for t in TYPES}
    total = n_all.sum()

    rows = []
    for i, r in enumerate(pp):
        rows.append([r["port"], short[r["port"]], cx.get(r["port"], short[r["port"]]), coast[i], plat[i], plon[i], int(r["rank"]),
                     int(n_all[i]), int(n23[i]), int(n24[i]), round(n_all[i] / total, 5)] +
                    [int(n_type[t][i]) for t in TYPES])
    rows.sort(key=lambda x: -x[7])
    with open(os.path.join(OUT, "port_share.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["port", "short", "complex", "coast", "lat", "lon", "rank", "ships", "ships_y0", "ships_y1", "share"]
                   + TYPES)
        w.writerows(rows)

    # Complexes: distinct ships in the union of the member port areas
    comp = np.array([cx.get(r["port"], short[r["port"]]) for r in pp])
    crow = []
    for c in np.unique(comp):
        idx = np.where(comp == c)[0]
        ships = len(np.unique(pm[np.isin(pm[:, 0], idx), 1]))
        visits = int(n_all[idx].sum())
        crow.append([c, coast[idx[0]], ships, visits, round(visits / total, 5)])
    crow.sort(key=lambda x: -x[3])
    with open(os.path.join(OUT, "port_share_complex.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["complex", "coast", "ships", "visits", "share"])
        w.writerows(crow)
    print("ports", len(pp), "visits", total)
    for r in rows[:12]:
        print(r[1:4], r[7], r[10])


if __name__ == "__main__":
    main()
