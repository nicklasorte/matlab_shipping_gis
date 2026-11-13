"""Draw the Puerto Rico and U.S. Virgin Islands route and zone maps (Python), NTIA style.

Inputs: outputs/<period>/islands/prusvi_rule_cells.npz (route cells, from
ship_route_rules.py), outputs/<period>/islands/prusvi_routes.npz (all large-ship
cells), and the MATLAB zone shapefiles in outputs/<period>/prusvi/ (from
init_shipping_zone_prusvi_rev1.m). Maps use NAD83 / Puerto Rico and Virgin Islands (EPSG:32161).

Usage (from the repo root):
  MPLBACKEND=Agg python3 python/ship_prusvi_figures.py
Writes docs/viz_python/pr01_routes and pr02_zones (PNG, PDF, SVG, alt text).
"""
import csv
import os
import sys

import numpy as np
import scipy.io
import shapefile
import matplotlib.patheffects as pe
from matplotlib.collections import PolyCollection
from matplotlib.patches import Rectangle
from pyproj import Transformer

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, HERE)
from onepager import OnePager  # noqa: E402
import ship_island_routes as isl  # noqa: E402
import ship_viz_figures as vf  # noqa: E402
import ship_period as PER  # noqa: E402  analysis years

ISL = os.path.join(ROOT, "outputs", PER.TAG, "islands")
HAW = os.path.join(ROOT, "outputs", PER.TAG, "prusvi")
STEM = f"shipping_zone_prusvi_{PER.TAG}"
TO = Transformer.from_crs(4326, 32161, always_xy=True)
EXT = (-68.0, -64.3, 17.3, 18.95)   # lon, lat limits drawn
SRC = (f"Source: NTIA analysis of MarineCadastre AIS, 104 sampled days in {PER.AND}; route cells with 4 or more large "
       "ships in a year (2 near deep-draft ports), NOAA charted lanes, and S-band racons; Census 1:500,000 outlines.")
SHORT = {"San Juan, PR": "San Juan", "Ponce, PR": "Ponce", "Guaynabo, PR": "Guaynabo", "Yabucoa, PR": "Yabucoa",
         "Mayaguez, PR": "Mayaguez", "Charlotte Amalie (St. Thomas), VI": "Charlotte Amalie",
         "Limetree Bay (St. Croix), VI": "Limetree Bay", "Frederiksted (St. Croix), VI": "Frederiksted"}
OFFSET = {"San Juan": (6, 8), "Ponce": (-10, -16), "Guaynabo": (-62, 8), "Yabucoa": (8, -6), "Mayaguez": (-72, 0),
          "Charlotte Amalie": (6, 8), "Limetree Bay": (8, -12), "Frederiksted": (-84, -4)}


def km(lon, lat):
    x, y = TO.transform(lon, lat)
    return np.asarray(x) / 1000, np.asarray(y) / 1000


def rings(path, lim=None):
    sf = shapefile.Reader(path)
    out = []
    for shp, rec in zip(sf.shapes(), sf.records() if lim else [None] * len(sf)):
        if lim and rec["STUSPS"] != lim:
            continue
        p = np.array(shp.points)
        parts = list(shp.parts) + [len(p)]
        for a, b in zip(parts[:-1], parts[1:]):
            x, y = km(p[a:b, 0], p[a:b, 1])
            out.append(np.column_stack([x, y]))
    return out


def frame(page, ax):
    x0, y0 = km(EXT[0], EXT[2])
    x1, y1 = km(EXT[1], EXT[3])
    ax.set_xlim(float(x0), float(x1))
    ax.set_ylim(float(y0), float(y1))
    ax.set_aspect(1)
    ax.set_xticks([])
    ax.set_yticks([])
    for sp in ax.spines.values():
        sp.set_visible(False)
    # 50 km scale bar
    xb, yb = float(x1) - 75, float(y0) + 12
    ax.plot([xb, xb + 50], [yb, yb], color=page.theme.text, lw=2)
    ax.text(xb + 25, yb + 8, "50 km", ha="center", fontsize=9, color=page.theme.text)


def ports(page, ax, hollow=False):
    with open(os.path.join(HAW, f"{STEM}_port_check.csv")) as f:
        rows = list(csv.DictReader(f))
    for r in rows:
        x, y = km(float(r["lon"]), float(r["lat"]))
        name = SHORT.get(r["port"], r["port"])
        on = r["reached"] == "1" and r["on_route_network"] == "1"
        ax.plot(x, y, marker="o", ms=5, color=page.theme.text, mfc="white" if (hollow or not on) else page.theme.text,
                mec=page.theme.text, zorder=5)
        ax.annotate(name + ("" if on else " (off routes)"), (x, y), xytext=OFFSET.get(name, (6, 0)),
                    textcoords="offset points", fontsize=9, color=page.theme.text, zorder=6,
                    path_effects=[pe.withStroke(linewidth=3, foreground="white")])
    return rows


def cells_xy(cell):
    lat, lon = isl.cell_latlon(cell, "prusvi")
    return km(lon, lat)


def land_rings():
    return rings(vf.STATES, "PR") + rings(vf.STATES, "VI")


def pr_routes():
    m = scipy.io.loadmat(os.path.join(HAW, f"{STEM}_ships_rev1.mat"), squeeze_me=True, struct_as_record=False)
    r_, c_ = m["source_mask"].nonzero()
    route = (r_ + 1 + c_ * m["source_mask"].shape[0]).astype(np.int64)
    allc = np.load(os.path.join(ISL, "prusvi_routes.npz"))["both_cell"]
    with open(os.path.join(HAW, f"{STEM}_port_check.csv")) as f:
        pc = list(csv.DictReader(f))
    on = [SHORT[r["port"]] for r in pc if r["reached"] == "1" and r["on_route_network"] == "1"]
    off = [SHORT[r["port"]] for r in pc if not (r["reached"] == "1" and r["on_route_network"] == "1")]
    page = OnePager(
        headline=f"Large-ship routes ring Puerto Rico and run through the Mona and Anegada passages; {len(on)} of "
                 f"{len(pc)} ports sit on them",
        subhead=f"Route cells around Puerto Rico and the U.S. Virgin Islands, {PER.RANGE}, {len(route):,} cells of about 1 km "
                f"(same rule as the lower 48); gray shows every cell a large ship crossed. Off the routes: {', '.join(off) or 'none'}",
        source=SRC, theme="ntia", layout="hero", size=(11, 7.4),
        alt=f"Map of Puerto Rico and the U.S. Virgin Islands. Blue route cells ring Puerto Rico, cross the Mona Passage to "
            f"the west and the Anegada Passage to the east, and reach {', '.join(on)}.")
    ax = page.panel(0, grid=None)
    ax.add_collection(PolyCollection(land_rings(), facecolor=page.theme.panel, edgecolor="white", lw=0.5))
    x, y = cells_xy(allc)
    ax.scatter(x, y, s=0.4, marker="s", lw=0, c=page.theme.grid, rasterized=True, zorder=1)
    x, y = cells_xy(route)
    ax.scatter(x, y, s=1.0, marker="s", lw=0, c=page.theme.accent, rasterized=True, zorder=2)
    frame(page, ax)
    ports(page, ax)
    vf.save(page, "pr01_routes")
    return len(route), on, off


def pr_zones():
    m = scipy.io.loadmat(os.path.join(HAW, f"{STEM}_ships_rev1.mat"), squeeze_me=True, struct_as_record=False)
    zs = {int(z.distance_km): float(z.land_area_km2) for z in m["zone"]}
    total = isl.land_total_km2("prusvi")   # polygon land, same footing as the zone areas (review CA-33)
    sh = {d: min(1.0, zs[d] / total) for d in zs}   # simplified zone outlines can exceed the total by a hair
    page = OnePager(
        headline=f"A 25 km zone would cover {100 * sh[25]:.0f}% of the land of Puerto Rico and the U.S. Virgin Islands, and "
                 f"a 50 km zone {100 * sh[50]:.0f}%",
        subhead="Land within each distance of the route cells (same method as the lower 48); "
                f"the 100 km zone covers {100 * sh[100]:.0f}%",
        source=SRC, theme="ntia", layout="hero", size=(11, 7.4),
        alt=f"Map of Puerto Rico and the U.S. Virgin Islands with land shaded by zone: {100 * sh[25]:.0f}% within 25 km, "
            f"{100 * sh[50]:.0f}% within 50 km, and {100 * sh[100]:.0f}% within 100 km of large-ship water.")
    ax = page.panel(0, grid=None)
    ramp = page.theme.ramp
    cols = {100: ramp[0], 50: ramp[len(ramp) // 2], 25: ramp[-1]}
    ax.add_collection(PolyCollection(land_rings(), facecolor="white", edgecolor=page.theme.text, lw=0.5))
    for d in (100, 50, 25):
        ax.add_collection(PolyCollection(rings(os.path.join(HAW, f"{STEM}_ships_{d}km_land.shp")),
                                         facecolor=cols[d], edgecolor="none", zorder=2))
    frame(page, ax)
    ports(page, ax, hollow=True)
    x0, y0 = km(-67.9, 17.75)
    for i, d in enumerate((25, 50, 100)):
        yy = float(y0) - i * 12
        ax.add_patch(Rectangle((float(x0), yy), 9, 7, color=cols[d]))
        ax.text(float(x0) + 13, yy + 3.5, f"Within {d} km: {zs[d]:,.0f} km\u00b2 ({100 * sh[d]:.0f}%)",
                va="center", fontsize=10, color=page.theme.text)
    vf.save(page, "pr02_zones")
    return zs, total


if __name__ == "__main__":
    print(pr_routes())
    print(pr_zones())
