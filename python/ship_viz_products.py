"""Compute the data behind the ten ship-data figures from the AIS day caches.

The MATLAB twin is viz_products_rev1.m; both read the same per-day cache files
(data/ais_cells_YYYYMMDD_*_rev1.mat) and should give the same tables.

Usage (from the repo root):
  python3 python/ship_viz_products.py

Writes outputs/<period>/viz/:
  viz_cells.npz            per-cell distinct-ship counts (both years,
                           with and without tug-barges) and the coastline distance
  viz_daily.csv            distinct large ships per sampled day: total, by coast,
                           and at Baltimore
  viz_mississippi.csv      distinct ships by river distance from Head of Passes
  viz_offshore.csv         route-cell distance to the coastline, by coast
  viz_sites.csv            distance from each site to the nearest route cell
  viz_summary.json         the numbers the figure headlines quote
"""
import heapq
import json
import os
import sys

import numpy as np
import scipy.io
import shapefile
from scipy.spatial import cKDTree

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ship_period as PER  # noqa: E402  analysis years
import ais_cells_py_rev1 as cells  # noqa: E402  same grid and cache names as the builder

ROOT = os.path.join(os.path.dirname(__file__), "..")
DATA = os.path.join(ROOT, "data")
OUT = os.path.join(ROOT, "outputs", PER.TAG, "viz")

# Must match init_shipping_zone_rev1.m
MIN_SHIPS = 4             # distinct ships per cell in one year
TOWING_COAST_KM = 25.0    # tug-barges count only this close to the coastline
R_EARTH = 6371.0088
NR, NC = cells.NUM_ROW, cells.NUM_COL
LAT0, LON0, D = cells.LATLIM[0], cells.LONLIM[0], cells.CELL_DEG

# Places (approximate public coordinates)
BALTIMORE = (39.235, -76.555)     # Patapsco River below the Key Bridge site, harbor side
BALTIMORE_KM = 8.0
HEAD_OF_PASSES = (29.15, -89.25)  # Mississippi River, where the passes split
NEW_ORLEANS = (29.95, -90.06)
BATON_ROUGE = (30.44, -91.19)
CLOSURE = ("2024-03-26", "2024-06-10")  # Fort McHenry Federal Channel closed to deep draft


def days():
    """Sampled days of the analysis period (python/ship_period.py)."""
    return PER.days()


def load_pairs(day, filt):
    spec = cells.FILTERS[filt] if filt in cells.FILTERS else cells.TYPE_FILTERS[filt]
    f = os.path.join(DATA, cells.cache_name(day.isoformat(), spec))
    if not os.path.isfile(f):
        raise FileNotFoundError(f)
    return scipy.io.loadmat(f)["pairs"].astype(np.int64)


def cell_rc(cell):
    """1-based linear index -> 0-based row (south first), col (west first)."""
    c = cell - 1
    return c % NR, c // NR


def cell_latlon(cell):
    r, c = cell_rc(cell)
    return LAT0 + D * (r + 0.5), LON0 + D * (c + 0.5)


def ecef(lat, lon):
    la, lo = np.radians(lat), np.radians(lon)
    return np.column_stack([np.cos(la) * np.cos(lo), np.cos(la) * np.sin(lo), np.sin(la)]) * R_EARTH


def chord_to_arc(ch):
    return 2 * R_EARTH * np.arcsin(np.clip(ch / (2 * R_EARTH), 0, 1))


def coast_cells():
    """Grid cells crossed by the Census TIGER coastline (sampled every ~100 m)."""
    sf = shapefile.Reader(os.path.join(DATA, "tl_2023_us_coastline", "tl_2023_us_coastline.shp"))
    hit = set()
    for shp in sf.shapes():
        pts = np.array(shp.points)
        parts = list(shp.parts) + [len(pts)]
        for a, b in zip(parts[:-1], parts[1:]):
            seg = pts[a:b]
            for p, q in zip(seg[:-1], seg[1:]):
                n = max(2, int(np.ceil(np.hypot(*(q - p)) / 0.001)))
                lon = np.linspace(p[0], q[0], n)
                lat = np.linspace(p[1], q[1], n)
                r = np.floor((lat - LAT0) / D).astype(int)
                c = np.floor((lon - LON0) / D).astype(int)
                ok = (r >= 0) & (r < NR) & (c >= 0) & (c < NC)
                hit.update((c[ok] * NR + r[ok] + 1).tolist())
    return np.array(sorted(hit), dtype=np.int64)


def coast_region(lat, lon):
    """Pacific, Gulf, Atlantic, Great Lakes by simple boxes (see README)."""
    reg = np.full(lat.shape, "Atlantic", dtype=object)
    reg[lon < -114] = "Pacific"
    reg[(lon >= -98) & (lon < -81) & (lat < 31)] = "Gulf"
    lakes = ((lat > 41) & (lat < 49.5) & (lon > -92.5) & (lon < -75.8)) | \
            ((lat > 43.8) & (lat < 45.5) & (lon >= -76.5) & (lon < -74.3))
    reg[lakes] = "Great Lakes"
    return reg


def near_point(cell, pt, km):
    lat, lon = cell_latlon(cell)
    d = chord_to_arc(np.linalg.norm(ecef(lat, lon) - ecef(np.array([pt[0]]), np.array([pt[1]])), axis=1))
    return d <= km


def main():
    os.makedirs(OUT, exist_ok=True)
    ds = days()

    # Coastline and the tug-barge band
    coast = coast_cells()
    clat, clon = cell_latlon(coast)
    tree = cKDTree(ecef(clat, clon))

    def coast_km(cell):
        lat, lon = cell_latlon(cell)
        return chord_to_arc(tree.query(ecef(lat, lon))[0])

    # Per year, per filter: unique (cell, mmsi)
    per_year = {}
    daily = []
    tow_ok_cache = {}
    for yr in PER.YEARS:
        main_p, tow_p = [], []
        for d in [x for x in ds if x.year == yr]:
            m = load_pairs(d, "main")
            t = load_pairs(d, "towing")
            if len(t):
                key = np.unique(t[:, 0])
                need = np.setdiff1d(key, np.fromiter(tow_ok_cache.keys(), np.int64, len(tow_ok_cache)))
                if len(need):
                    for c_, k_ in zip(need, coast_km(need) <= TOWING_COAST_KM):
                        tow_ok_cache[int(c_)] = bool(k_)
                t = t[np.array([tow_ok_cache[int(c_)] for c_ in t[:, 0]])]
            both = np.unique(np.vstack([m, t]), axis=0) if len(t) else m
            lat, lon = cell_latlon(both[:, 0])
            reg = coast_region(lat, lon)
            row = {"day": d.isoformat(), "year": yr, "ships": int(len(np.unique(both[:, 1])))}
            for name in ("Pacific", "Gulf", "Atlantic", "Great Lakes"):
                row[name] = int(len(np.unique(both[reg == name, 1])))
            row["Baltimore"] = int(len(np.unique(both[near_point(both[:, 0], BALTIMORE, BALTIMORE_KM), 1])))
            daily.append(row)
            main_p.append(m)
            tow_p.append(t)
        main_y = np.unique(np.vstack(main_p), axis=0)
        tow_y = np.unique(np.vstack(tow_p), axis=0)
        per_year[yr] = (main_y, tow_y)
        print(yr, "main pairs", len(main_y), "tow pairs", len(tow_y), flush=True)

    def counts(pairs):
        cell, n = np.unique(pairs[:, 0], return_counts=True)
        return cell, n

    # Distinct ships per cell, per year, with and without tug-barges
    res = {}
    for yr in PER.YEARS:
        m, t = per_year[yr]
        res[f"all_{yr}"] = counts(np.unique(np.vstack([m, t]), axis=0))
        res[f"main_{yr}"] = counts(m)
    all2 = np.unique(np.vstack([per_year[PER.Y0][0], per_year[PER.Y0][1], per_year[PER.Y1][0], per_year[PER.Y1][1]]), axis=0)
    res["all_both"] = counts(all2)

    def route_set(prefix):
        s = set()
        for yr in PER.YEARS:
            c, n = res[f"{prefix}_{yr}"]
            s |= set(c[n >= MIN_SHIPS].tolist())
        return s

    route_all = route_set("all")
    route_main = route_set("main")
    r23 = set(res[f"all_{PER.Y0}"][0][res[f"all_{PER.Y0}"][1] >= MIN_SHIPS].tolist())   # first year
    r24 = set(res[f"all_{PER.Y1}"][0][res[f"all_{PER.Y1}"][1] >= MIN_SHIPS].tolist())   # second year
    both_years = r23 & r24
    only23 = r23 - r24
    only24 = r24 - r23
    tow_only = route_all - route_main

    route_cells = np.array(sorted(route_all), dtype=np.int64)
    np.savez_compressed(
        os.path.join(OUT, "viz_cells.npz"),
        both_cell=res["all_both"][0], both_ships=res["all_both"][1],
        route_cells=route_cells,
        both_years=np.array(sorted(both_years)), only23=np.array(sorted(only23)), only24=np.array(sorted(only24)),
        tow_only=np.array(sorted(tow_only)),
        grid=np.array([LAT0, LON0, D, NR, NC]))

    # Daily table
    with open(os.path.join(OUT, "viz_daily.csv"), "w") as f:
        cols = ["day", "year", "ships", "Pacific", "Gulf", "Atlantic", "Great Lakes", "Baltimore"]
        f.write(",".join(c.replace(" ", "_") for c in cols) + "\n")
        for r in daily:
            f.write(",".join(str(r[c]) for c in cols) + "\n")

    # Offshore distance of route cells, by coast
    lat, lon = cell_latlon(route_cells)
    reg = coast_region(lat, lon)
    dkm = coast_km(route_cells)
    with open(os.path.join(OUT, "viz_offshore.csv"), "w") as f:
        f.write("cell,lat,lon,coast,coast_km\n")
        for c_, a, b, g, k in zip(route_cells, lat, lon, reg, dkm):
            f.write(f"{c_},{a:.3f},{b:.3f},{g},{k:.2f}\n")

    # Mississippi: river distance from Head of Passes through route cells
    box = (lat > 29.1) & (lat < 31.0) & (lon > -91.6) & (lon < -89.2)
    riv = set(route_cells[box].tolist())

    def nbrs(c_):
        r, k = cell_rc(c_)
        for dr in (-1, 0, 1):
            for dk in (-1, 0, 1):
                if dr == 0 and dk == 0:
                    continue
                rr, kk = r + dr, k + dk
                if 0 <= rr < NR and 0 <= kk < NC:
                    n_ = kk * NR + rr + 1
                    if n_ in riv:
                        yield n_

    def nearest(pt):
        arr = np.array(sorted(riv))
        a, b = cell_latlon(arr)
        return int(arr[np.argmin(np.hypot(a - pt[0], (b - pt[1]) * np.cos(np.radians(pt[0]))))])

    src = nearest(HEAD_OF_PASSES)
    dist = {src: 0.0}
    prev = {}
    pq = [(0.0, src)]
    while pq:
        dd, u = heapq.heappop(pq)
        if dd > dist[u]:
            continue
        ua, uo = cell_latlon(np.array([u]))
        for v in nbrs(u):
            va, vo = cell_latlon(np.array([v]))
            w = chord_to_arc(np.linalg.norm(ecef(ua, uo) - ecef(va, vo)))
            nd = dd + float(w)
            if nd < dist.get(v, np.inf):
                dist[v] = nd
                prev[v] = u
                heapq.heappush(pq, (nd, v))
    # The river path: from the northmost reachable cell in the river corridor back to Head of Passes
    corridor = [c_ for c_ in dist if cell_latlon(np.array([c_]))[1][0] < -90.9]
    far = max(corridor, key=lambda c_: cell_latlon(np.array([c_]))[0][0])
    path = [far]
    while path[-1] != src:
        path.append(prev[path[-1]])
    path = path[::-1]
    path_cells = np.array(path)
    pa, po = cell_latlon(path_cells)
    ptree = cKDTree(ecef(pa, po))
    path_km = np.array([dist[c_] for c_ in path])
    # River cells = reachable cells within 2 km of the path; river km = that of the nearest path cell
    reach = np.array(sorted(dist), dtype=np.int64)
    ra, ro = cell_latlon(reach)
    dd, ii = ptree.query(ecef(ra, ro))
    on_river = chord_to_arc(dd) <= 2.0
    river_cell = reach[on_river]
    river_km = path_km[ii[on_river]]
    km_of = dict(zip(river_cell.tolist(), river_km.tolist()))
    bin_km = 5.0
    ships_bins = {}
    for yr in PER.YEARS:
        m, t = per_year[yr]
        p = np.unique(np.vstack([m, t]), axis=0)
        sel = np.isin(p[:, 0], river_cell)
        for c_, s_ in p[sel]:
            b = int(km_of[int(c_)] // bin_km)
            ships_bins.setdefault(b, set()).add(int(s_))

    def km_at(pt):
        return float(path_km[ptree.query(ecef(np.array([pt[0]]), np.array([pt[1]])))[1][0]])

    with open(os.path.join(OUT, "viz_mississippi.csv"), "w") as f:
        f.write("river_km_from,river_km_to,ships\n")
        for b in sorted(ships_bins):
            f.write(f"{b * bin_km:g},{(b + 1) * bin_km:g},{len(ships_bins[b])}\n")

    # Sites: distance to the nearest route cell
    import csv
    rt = cKDTree(ecef(lat, lon))
    rows = []
    with open(os.path.join(ROOT, "outputs", PER.TAG, f"shipping_zone_{PER.TAG}_sites.csv")) as f:
        for r in csv.DictReader(f):
            rows.append(r)
    pp = {}
    with open(os.path.join(ROOT, "outputs", PER.TAG, f"shipping_zone_{PER.TAG}_principal_port_check.csv")) as f:
        for r in csv.DictReader(f):
            pp[r["port"]] = r
    with open(os.path.join(OUT, "viz_sites.csv"), "w") as f:
        f.write("group,name,lat,lon,route_km\n")
        for r in rows:
            g = r["category"]
            if g == "usace_principal_port":
                info = pp.get(r["name"])
                if info is None:
                    continue
                if info["type"] == "I":
                    g = "inland_port"
                elif float(info["foreign_tons"]) >= 1e6:
                    g = "deep_draft_port"
                else:
                    g = "other_coastal_port"
            a, b = float(r["lat"]), float(r["lon"])
            k = chord_to_arc(rt.query(ecef(np.array([a]), np.array([b])))[0])[0]
            f.write(f"{g},\"{r['name']}\",{a},{b},{k:.3f}\n")

    summ = {
        "route_cells": len(route_all),
        "route_cells_main_only": len(route_main),
        "tow_only_cells": len(tow_only),
        "cells_y0": len(r23), "cells_y1": len(r24), "years": list(PER.YEARS),
        "both_years": len(both_years), "only_y0": len(only23), "only_y1": len(only24),
        "share_both_years": len(both_years) / len(r23 | r24),
        "river_km_new_orleans": km_at(NEW_ORLEANS),
        "river_km_baton_rouge": km_at(BATON_ROUGE),
        "river_km_end": float(path_km[-1]),
        "river_end_lat": float(pa[-1]),
    }
    for g in ("Pacific", "Gulf", "Atlantic", "Great Lakes"):
        k = dkm[reg == g]
        summ[f"offshore_median_km_{g}"] = float(np.median(k))
        summ[f"offshore_p90_km_{g}"] = float(np.percentile(k, 90))
        summ[f"tow_only_{g}"] = int(np.sum(coast_region(*cell_latlon(np.array(sorted(tow_only)))) == g))
    with open(os.path.join(OUT, "viz_summary.json"), "w") as f:
        json.dump(summ, f, indent=1)
    print(json.dumps(summ, indent=1))


if __name__ == "__main__":
    main()
