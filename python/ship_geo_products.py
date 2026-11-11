"""Compute the data behind the nine geographic figures (Appendix A, maps A-9 to A-17).

The MATLAB twin is geo_products_rev1.m. Both read the AIS day caches built by
ais_cells_py_rev1.py (main, tug-barge, and ship-type filters).

Usage (from the repo root):
  python3 python/ship_geo_products.py

Writes outputs/2023_2024/viz/:
  geo_hex.csv            distinct large ships per 25 km hexagon (Albers), all types
  geo_hex_types.csv      distinct ships per hexagon for cargo, tanker, passenger, government
  geo_ports.csv          distinct large ships within 10 km of each deep-draft port
  geo_profile.csv        distinct large ships within 50 km of shore, by 0.5 degree along each coast
  geo_land_distance.npz  distance from land to the nearest route cell, 0.05 degree grid
  geo_summary.json       the numbers the figure headlines quote
"""
import csv
import json
import os
import sys

import numpy as np
import shapefile
from pyproj import Transformer
from scipy.spatial import cKDTree
from shapely import contains_xy
from shapely.geometry import Polygon
from shapely.ops import unary_union

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
import ship_viz_products as vp  # noqa: E402  same days, grid, coastline, and tug-barge rule

ROOT = os.path.join(HERE, "..")
OUT = os.path.join(ROOT, "outputs", "2023_2024", "viz")
HEX_R_KM = 12.5           # hexagon circumradius; 25 km corner to corner
PORT_KM = 10.0
NEAR_SHORE_KM = 50.0
TO_ALB = Transformer.from_crs(4326, 5070, always_xy=True)
TYPES = ["cargo", "tanker", "passenger", "government"]


def hex_index(x, y, r=HEX_R_KM):
    """Pointy-top axial hex index (q, r) for Albers km coordinates (cube rounding)."""
    q = (np.sqrt(3) / 3 * x - y / 3) / r
    rr = (2 / 3 * y) / r
    xc, zc = q, rr
    yc = -xc - zc
    rx, ry, rz = np.round(xc), np.round(yc), np.round(zc)
    dx, dy, dz = abs(rx - xc), abs(ry - yc), abs(rz - zc)
    fix_x = (dx > dy) & (dx > dz)
    fix_z = ~fix_x & (dy <= dz)
    rx = np.where(fix_x, -ry - rz, rx)
    rz = np.where(fix_z, -rx - ry, rz)
    return rx.astype(np.int64), rz.astype(np.int64)


def hex_center(q, rr, r=HEX_R_KM):
    return r * np.sqrt(3) * (q + rr / 2), r * 1.5 * rr


def cell_alb(cell):
    lat, lon = vp.cell_latlon(cell)
    x, y = TO_ALB.transform(lon, lat)
    return np.asarray(x) / 1e3, np.asarray(y) / 1e3


def load_year_pairs(filt_names, tow_ok=None):
    """Unique (cell, mmsi) over both years for the named filters."""
    parts = []
    for d in vp.days():
        for f in filt_names:
            p = vp.load_pairs(d, f)
            if f == "towing" and len(p):
                p = p[tow_ok(p[:, 0])]
            parts.append(p)
    return np.unique(np.vstack(parts), axis=0)


def hex_counts(pairs, route_set=None):
    """Distinct ships per hexagon: returns q, r, ships."""
    if route_set is not None:
        pairs = pairs[np.isin(pairs[:, 0], route_set)]
    ucell, inv = np.unique(pairs[:, 0], return_inverse=True)
    x, y = cell_alb(ucell)
    q, r = hex_index(x, y)
    hp = np.unique(np.column_stack([q[inv], r[inv], pairs[:, 1]]), axis=0)
    h, n = np.unique(hp[:, :2], axis=0, return_counts=True)
    return h[:, 0], h[:, 1], n


def main():
    os.makedirs(OUT, exist_ok=True)
    summ = {}

    # Coastline searcher and the tug-barge rule (same as ship_viz_products.py)
    coast = vp.coast_cells()
    clat, clon = vp.cell_latlon(coast)
    tree = cKDTree(vp.ecef(clat, clon))

    def coast_km(c):
        lat, lon = vp.cell_latlon(c)
        return vp.chord_to_arc(tree.query(vp.ecef(lat, lon))[0])

    near = {}

    def tow_ok(c):
        u = np.unique(c)
        need = u[[int(v) not in near for v in u]]
        if len(need):
            for v, k in zip(need, coast_km(need) <= vp.TOWING_COAST_KM):
                near[int(v)] = bool(k)
        return np.array([near[int(v)] for v in c])

    z = np.load(os.path.join(OUT, "viz_cells.npz"))
    route = z["route_cells"]

    allp = load_year_pairs(["main", "towing"], tow_ok)
    print("pairs", len(allp), flush=True)

    # 1. Hex counts, all large ships, route cells only
    q, r, n = hex_counts(allp, route)
    with open(os.path.join(OUT, "geo_hex.csv"), "w") as f:
        f.write("q,r,x_km,y_km,ships\n")
        hx, hy = hex_center(q, r)
        for a, b, c, d, e in zip(q, r, hx, hy, n):
            f.write(f"{a},{b},{c:.2f},{d:.2f},{e}\n")
    order = np.sort(n)[::-1]
    summ["hex_count"] = int(len(n))
    summ["hex_max_ships"] = int(order[0])
    summ["hex_share_top5pct"] = float(order[:max(1, len(order) // 20)].sum() / order.sum())
    summ["hex_ge_1000"] = int((n >= 1000).sum())

    # 7. Hex counts by ship type (route cells of any large ship)
    type_pairs = {}
    types = [] if os.environ.get("SKIP_TYPES") else TYPES   # SKIP_TYPES=1 while the type caches build
    with open(os.path.join(OUT, "geo_hex_types.csv"), "w") as f:
        f.write("type,q,r,x_km,y_km,ships\n")
        for t in types:
            pt = load_year_pairs([t])
            type_pairs[t] = pt
            tq, tr, tn = hex_counts(pt)
            tx, ty = hex_center(tq, tr)
            for a, b, c, d, e in zip(tq, tr, tx, ty, tn):
                f.write(f"{t},{a},{b},{c:.2f},{d:.2f},{e}\n")
            summ[f"type_ships_{t}"] = int(len(np.unique(pt[:, 1])))
            # share of this type's distinct ships seen in the Gulf box at least once
            ucell = np.unique(pt[:, 0])
            reg = vp.coast_region(*vp.cell_latlon(ucell))
            gulf_cells = ucell[reg == "Gulf"]
            summ[f"type_share_ships_gulf_{t}"] = float(len(np.unique(pt[np.isin(pt[:, 0], gulf_cells), 1])) /
                                                      len(np.unique(pt[:, 1])))
            print("type", t, len(pt), flush=True)

    # 6. Ports: distinct ships within 10 km of each deep-draft port
    pp = [r_ for r_ in csv.DictReader(open(os.path.join(ROOT, "outputs", "2023_2024",
                                                       "shipping_zone_2023_2024_principal_port_check.csv")))
          if r_["type"] != "I" and float(r_["foreign_tons"]) >= 1e6]
    plat = np.array([float(r_["lat"]) for r_ in pp])
    plon = np.array([float(r_["lon"]) for r_ in pp])
    ptree = cKDTree(vp.ecef(plat, plon))
    ucell, inv = np.unique(allp[:, 0], return_inverse=True)
    ulat, ulon = vp.cell_latlon(ucell)
    chord = 2 * vp.R_EARTH * np.sin(PORT_KM / (2 * vp.R_EARTH))

    def port_ship_counts(pairs):
        """Distinct ships within PORT_KM of each port, for a [cell, mmsi] pair list."""
        uc, iv = np.unique(pairs[:, 0], return_inverse=True)
        la, lo = vp.cell_latlon(uc)
        hits = ptree.query_ball_point(vp.ecef(la, lo), chord)
        cell_ports = {ci: lst for ci, lst in enumerate(hits) if lst}
        sets = [set() for _ in pp]
        sel = np.isin(iv, np.fromiter(cell_ports.keys(), np.int64))
        for ci, m in zip(iv[sel], pairs[sel, 1]):
            for pi in cell_ports[int(ci)]:
                sets[pi].add(int(m))
        return np.array([len(x) for x in sets])

    port_n = port_ship_counts(allp)
    port_t = {t: port_ship_counts(tp) for t, tp in type_pairs.items()}
    with open(os.path.join(OUT, "geo_ports.csv"), "w") as f:
        f.write("port,lat,lon,rank,ships" + "".join("," + t for t in port_t) + "\n")
        for i, r_ in enumerate(pp):
            f.write(f"\"{r_['port']}\",{r_['lat']},{r_['lon']},{r_['rank']},{port_n[i]}"
                    + "".join(f",{port_t[t][i]}" for t in port_t) + "\n")
    sets = [range(n_) for n_ in port_n]   # only the counts are used below
    pn = sorted(((len(s_), r_["port"]) for r_, s_ in zip(pp, sets)), reverse=True)
    summ["ports_top"] = [[p_, n_] for n_, p_ in pn[:10]]
    summ["ports_ge_1000"] = int(sum(1 for n_, _ in pn if n_ >= 1000))

    # 5. Near-shore profile along each coast
    ck = coast_km(ucell)
    reg = vp.coast_region(ulat, ulon)
    nearc = ck <= NEAR_SHORE_KM
    rows = []
    for coast_name, coord, lo, hi in (("Pacific", "lat", 32.0, 49.0), ("Gulf", "lon", -97.5, -81.0),
                                      ("Atlantic", "lat", 24.5, 45.0)):
        m_cell = nearc & (reg == coast_name)
        v = ulat if coord == "lat" else ulon
        b = np.floor((v - lo) / 0.5).astype(int)
        okc = m_cell & (v >= lo) & (v < hi)
        keep = okc[inv]
        bp = np.unique(np.column_stack([b[inv][keep], allp[keep, 1]]), axis=0)
        bb, bn = np.unique(bp[:, 0], return_counts=True)
        for k, c in zip(bb, bn):
            rows.append((coast_name, coord, lo + 0.5 * k, lo + 0.5 * (k + 1), int(c)))
    with open(os.path.join(OUT, "geo_profile.csv"), "w") as f:
        f.write("coast,axis,from_deg,to_deg,ships\n")
        for r_ in rows:
            f.write(f"{r_[0]},{r_[1]},{r_[2]:g},{r_[3]:g},{r_[4]}\n")
    for cname in ("Pacific", "Gulf", "Atlantic"):
        rr_ = [r_ for r_ in rows if r_[0] == cname]
        top = max(rr_, key=lambda t: t[4])
        summ[f"profile_peak_{cname}"] = [top[2], top[3], top[4]]

    # 8. Land distance to the nearest route cell, 0.05 degree grid
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
    on_land = contains_xy(land, LON, LAT)
    rlat, rlon = vp.cell_latlon(route)
    rtree = cKDTree(vp.ecef(rlat, rlon))
    dist = np.full(LAT.shape, np.nan)
    dist[on_land] = vp.chord_to_arc(rtree.query(vp.ecef(LAT[on_land], LON[on_land]))[0])
    np.savez_compressed(os.path.join(OUT, "geo_land_distance.npz"), lat=glat, lon=glon, dist_km=dist)
    dl = dist[on_land]
    for k in (25, 50, 100):
        summ[f"land_share_within_{k}km"] = float(np.mean(dl <= k))
    summ["land_max_km"] = float(np.nanmax(dist))

    old = os.path.join(OUT, "geo_summary.json")
    if types == [] and os.path.isfile(old):   # keep type numbers from a full run
        prev = json.load(open(old))
        summ.update({k: v for k, v in prev.items() if k.startswith("type_")})
    with open(os.path.join(OUT, "geo_summary.json"), "w") as f:
        json.dump(summ, f, indent=1)
    print(json.dumps(summ, indent=1))


if __name__ == "__main__":
    main()
