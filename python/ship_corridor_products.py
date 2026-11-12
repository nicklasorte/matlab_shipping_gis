"""Distinct large ships along each river and ship channel, from the sea to the head.

Generalizes the Mississippi profile (Head of Passes to Baton Rouge) to every
corridor in config/corridors_rev1.csv. The MATLAB twin is corridor_products_rev1.m.

For each corridor:
  1. Take the route cells (>= 4 distinct ships in either year) inside a box
     around the start, end, and marked places and link 8-neighbor cells into a graph weighted by
     great-circle distance.
  2. Run Dijkstra from the route cell nearest the start point, with each edge
     costing km * (1 + 100 / ships) so the path keeps to the busy channel. The path ends
     at the reachable route cell nearest the target point (the end port, or a
     point upstream of it when the routes go past the port).
  3. Route cells within 2 km of the path take the distance of the nearest
     path cell. Distinct ships (both years, main filter plus coastal
     tug-barges) are counted in each distance bin.
  4. Ships at the entrance: distinct ships within 3 km of the start along the
     path. Ships at the head: distinct ships within 3 km (along the path) of
     the end port, or of the end of the routes if they stop short of it.

Usage (from the repo root):
  python3 python/ship_corridor_products.py

Writes outputs/<period>/viz/:
  corridor_profile.csv   corridor, km_from, km_to, ships
  corridor_marks.csv     corridor, role, name, lat, lon, km
  corridor_cells.csv     corridor, cell, lat, lon, km, ships (corridor cells, for maps)
  corridor_path.csv      corridor, km, lat, lon, ships (path cells)
  corridor_summary.csv   corridor, label, length_km, bin_km, ships_entrance,
                         ships_head, ships_head_y0, ships_head_y1, share_head,
                         ships_entering, share_reaching_head
  corridor_continuation.csv  corridor, frac_to_head, ships_beyond, share_beyond:
                         distinct ships seen at or beyond each point (counted from
                         3 km in), and that count over the ships that went at least
                         3 km in (distance scaled so 1 = the head port)
"""
import csv
import os
import sys

import numpy as np
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import dijkstra
from scipy.spatial import cKDTree

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ship_period as PER  # noqa: E402  analysis years
import ship_viz_products as vp  # noqa: E402  same days, grid, coastline, and tug-barge rule

ROOT = os.path.join(HERE, "..")
OUT = os.path.join(ROOT, "outputs", PER.TAG, "viz")
CONFIG = os.path.join(ROOT, "config", "corridors_rev1.csv")
BOX_PAD_DEG = 0.3      # box around start and end points for the graph
COST_K = 100.0         # edge cost = km * (1 + COST_K / ships): the path keeps to the busy channel
PATH_KM = 2.0          # route cells this close to the path belong to the corridor
END_KM = 3.0           # "reached the head": within this distance of the path end
GRID = np.linspace(0, 1, 201)   # continuation curve, share of the distance to the head port
SHORT_KM = 120.0       # corridors shorter than this use 2 km bins, others 5 km


def read_corridors():
    rows = list(csv.DictReader(open(CONFIG)))
    out = {}
    for r in rows:
        c = out.setdefault(r["corridor"], {"label": r["label"], "marks": []})
        pt = (float(r["lat"]), float(r["lon"]))
        if r["role"] in ("start", "end", "target"):
            c[r["role"]] = (r["name"], pt)
        else:
            c["marks"].append((r["name"], pt))
    for c in out.values():
        c.setdefault("target", c["end"])
    return out


def corridor_path(route, ships_of, start, end, marks=()):
    """Dijkstra through route cells in a box around the start, end, and marks.

    Edges cost km * (1 + COST_K / ships), so the path follows the busiest
    channel rather than a shorter, lightly used lane. Returns the box cells,
    the reachable mask, the path (indices into the box cells), the distance
    along the path (km), and the box cell lat/lon."""
    lat, lon = vp.cell_latlon(route)
    pts = np.array([start, end] + list(marks))
    box = ((lat > pts[:, 0].min() - BOX_PAD_DEG) & (lat < pts[:, 0].max() + BOX_PAD_DEG) &
           (lon > pts[:, 1].min() - BOX_PAD_DEG) & (lon < pts[:, 1].max() + BOX_PAD_DEG))
    cells = route[box]
    n = len(cells)
    idx = {int(c): i for i, c in enumerate(cells)}
    r, k = vp.cell_rc(cells)
    xyz = vp.ecef(*vp.cell_latlon(cells))
    src, dst = [], []
    for dr, dk in ((1, -1), (1, 0), (1, 1), (0, 1)):          # each undirected edge once
        rr, kk = r + dr, k + dk
        ok = (rr >= 0) & (rr < vp.NR) & (kk >= 0) & (kk < vp.NC)
        nb = kk * vp.NR + rr + 1
        for i in np.where(ok)[0]:
            j = idx.get(int(nb[i]))
            if j is not None:
                src.append(i)
                dst.append(j)
    src, dst = np.array(src), np.array(dst)
    w = vp.chord_to_arc(np.linalg.norm(xyz[src] - xyz[dst], axis=1))
    sh = ships_of(cells)
    cost = w * (1 + COST_K / np.minimum(sh[src], sh[dst]))
    G = coo_matrix((cost, (src, dst)), shape=(n, n)).tocsr()
    clat, clon = vp.cell_latlon(cells)

    def nearest(pt, among=None):
        d = np.linalg.norm(xyz - vp.ecef(np.array([pt[0]]), np.array([pt[1]])), axis=1)
        if among is not None:
            d = np.where(among, d, np.inf)
        return int(np.argmin(d))

    s0 = nearest(start)
    dist, pred = dijkstra(G, directed=False, indices=s0, return_predecessors=True)
    reach = np.isfinite(dist)
    e0 = nearest(end, reach)
    path = [e0]
    while path[-1] != s0:
        path.append(int(pred[path[-1]]))
    path = np.array(path[::-1])
    step = vp.chord_to_arc(np.linalg.norm(np.diff(xyz[path], axis=0), axis=1))
    path_km = np.concatenate([[0.0], np.cumsum(step)])   # geometric distance along the least-cost path
    return cells, reach, path, path_km, (clat, clon)


def main():
    cor = read_corridors()
    z = np.load(os.path.join(OUT, "viz_cells.npz"))
    route = z["route_cells"]
    ship_map = dict(zip(z["both_cell"].tolist(), z["both_ships"].tolist()))

    def ships_of(c):
        return np.array([ship_map[int(v)] for v in c], dtype=float)

    # Pairs per year, main filter plus tug-barges near the coast (same as the Mississippi profile)
    coast = vp.coast_cells()
    ctree = cKDTree(vp.ecef(*vp.cell_latlon(coast)))
    near = {}

    def tow_ok(c):
        u = np.unique(c)
        need = u[[int(v) not in near for v in u]]
        if len(need):
            km = vp.chord_to_arc(ctree.query(vp.ecef(*vp.cell_latlon(need)))[0])
            for v, kk in zip(need, km <= vp.TOWING_COAST_KM):
                near[int(v)] = bool(kk)
        return np.array([near[int(v)] for v in c], dtype=bool)

    pairs = {}
    for yr in PER.YEARS:
        parts = []
        for d in [x for x in vp.days() if x.year == yr]:
            parts.append(vp.load_pairs(d, "main"))
            t = vp.load_pairs(d, "towing")
            if len(t):
                parts.append(t[tow_ok(t[:, 0])])
        pairs[yr] = np.unique(np.vstack(parts), axis=0)
        print(yr, len(pairs[yr]), flush=True)
    both = np.unique(np.vstack([pairs[2023], pairs[2024]]), axis=0)

    prof_rows, mark_rows, path_rows, summ_rows, cell_rows, surv_rows = [], [], [], [], [], []
    for name, c in cor.items():
        cells, reach, path, pkm, (clat, clon) = corridor_path(route, ships_of, c["start"][1], c["target"][1], [m[1] for m in c["marks"]])
        ptree = cKDTree(vp.ecef(clat[path], clon[path]))
        rc = np.where(reach)[0]
        dd, ii = ptree.query(vp.ecef(clat[rc], clon[rc]))
        on = vp.chord_to_arc(dd) <= PATH_KM
        ccell = cells[rc[on]]
        ckm = pkm[ii[on]]
        length = float(pkm[-1])
        bin_km = 2.0 if length < SHORT_KM else 5.0
        km_of = dict(zip(ccell.tolist(), ckm.tolist()))

        def ships_in(P, keep_km):
            sel = np.isin(P[:, 0], ccell)
            P = P[sel]
            k = np.array([km_of[int(v)] for v in P[:, 0]])
            return P[keep_km(k)]

        # Profile: distinct ships per bin
        P = ships_in(both, lambda k: np.ones(len(k), bool))
        k = np.array([km_of[int(v)] for v in P[:, 0]])
        b = np.floor(k / bin_km).astype(int)
        ub = np.unique(np.column_stack([b, P[:, 1]]), axis=0)
        bins, n = np.unique(ub[:, 0], return_counts=True)
        for bb, nn in zip(bins, n):
            prof_rows.append([name, bb * bin_km, (bb + 1) * bin_km, int(nn)])
        # Path cells with distinct ships (for the maps)
        pc, pn = np.unique(P[:, 0], return_counts=True)
        pn_of = dict(zip(pc.tolist(), pn.tolist()))
        for cc, kk in zip(ccell, ckm):
            la_, lo_ = vp.cell_latlon(np.array([cc]))
            cell_rows.append([name, int(cc), round(float(la_[0]), 4), round(float(lo_[0]), 4),
                              round(float(kk), 2), pn_of.get(int(cc), 0)])
        for j, kk in zip(path, pkm):
            path_rows.append([name, round(float(kk), 2), round(float(clat[j]), 4), round(float(clon[j]), 4),
                              pn_of.get(int(cells[j]), 0)])

        e_km = float(pkm[ptree.query(vp.ecef(np.array([c["end"][1][0]]), np.array([c["end"][1][1]])))[1][0]])

        def ships_near(P, which):
            if which == "head":
                return len(np.unique(ships_in(P, lambda k: abs(k - e_km) <= END_KM)[:, 1]))
            return len(np.unique(ships_in(P, lambda k: k <= END_KM)[:, 1]))

        ent = ships_near(both, "entrance")
        head = ships_near(both, "head")
        # Continuation curve: distinct ships seen at or beyond each point (any day), counting from 3 km in. It can only fall going
        # upstream, so anchorage spikes and lane splits drop out. Distance is scaled so 1 = the head port;
        # at 1 the count is ships seen within 3 km below the head port or above it.
        kP = np.array([km_of[int(v)] for v in P[:, 0]])
        far = {}
        for m_, k_ in zip(P[:, 1].tolist(), kP.tolist()):
            if k_ > far.get(m_, -1.0):
                far[m_] = k_
        far_all = np.array(list(far.values()))
        n_in = int(np.sum(far_all >= END_KM))   # ships that went at least 3 km in (drops passers-by at the entrance)
        for f in GRID:
            thr = min(max(f * e_km, END_KM), e_km - END_KM)
            nb = int(np.sum(far_all >= thr))
            surv_rows.append([name, round(float(f), 3), nb, round(nb / n_in, 4)])
        cont = float(np.sum(far_all >= e_km - END_KM)) / n_in
        summ_rows.append([name, c["label"], round(length, 1), bin_km, ent, head,
                          ships_near(pairs[2023], "head"), ships_near(pairs[2024], "head"),
                          round(head / ent, 3) if ent else "", n_in, round(cont, 3)])
        # Marks
        for role, (mn, pt) in [("start", c["start"])] + [("mark", m) for m in c["marks"]] + [("end", c["end"])] + \
                ([("target", c["target"])] if c["target"] is not c["end"] else []):
            dch, j = ptree.query(vp.ecef(np.array([pt[0]]), np.array([pt[1]])))
            mark_rows.append([name, role, mn, pt[0], pt[1], round(float(pkm[j[0]]), 1),
                              round(float(vp.chord_to_arc(dch[0])), 1)])
        print(f"{name:12s} {length:6.0f} km  entrance {ent:5d}  head {head:5d}", flush=True)

    def write(fn, head, rows):
        with open(os.path.join(OUT, fn), "w", newline="") as f:
            w = csv.writer(f)
            w.writerow(head)
            w.writerows(rows)

    write("corridor_profile.csv", ["corridor", "km_from", "km_to", "ships"], prof_rows)
    write("corridor_marks.csv", ["corridor", "role", "name", "lat", "lon", "km", "off_path_km"], mark_rows)
    write("corridor_cells.csv", ["corridor", "cell", "lat", "lon", "km", "ships"], cell_rows)
    write("corridor_path.csv", ["corridor", "km", "lat", "lon", "ships"], path_rows)
    write("corridor_summary.csv", ["corridor", "label", "length_km", "bin_km", "ships_entrance", "ships_head",
                                   "ships_head_y0", "ships_head_y1", "share_head", "ships_entering", "share_reaching_head"],
          summ_rows)
    write("corridor_continuation.csv", ["corridor", "frac_to_head", "ships_beyond", "share_beyond"], surv_rows)


if __name__ == "__main__":
    main()
