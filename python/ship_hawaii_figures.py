"""Draw the Hawaii route and zone maps (Python), NTIA style.

Inputs: outputs/<period>/islands/hawaii_rule_cells.npz (ship-days route cells, from
ship_route_rules.py), outputs/<period>/islands/hawaii_routes.npz (all large-ship
cells), and the MATLAB zone shapefiles in outputs/<period>/hawaii/ (from
init_shipping_zone_hawaii_rev1.m). Maps use Hawaii Albers equal area (ESRI:102007).

Usage (from the repo root):
  MPLBACKEND=Agg python3 python/ship_hawaii_figures.py
Writes docs/viz_python/haw01_routes and haw02_zones (PNG, PDF, SVG, alt text).
"""
import csv
import os
import sys

import numpy as np
import shapefile
import matplotlib.patheffects as pe
from matplotlib.collections import PolyCollection
from pyproj import Transformer

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, HERE)
from onepager import OnePager  # noqa: E402
import ship_island_routes as isl  # noqa: E402
import ship_viz_figures as vf  # noqa: E402
import ship_period as PER  # noqa: E402  analysis years

ISL = os.path.join(ROOT, "outputs", PER.TAG, "islands")
HAW = os.path.join(ROOT, "outputs", PER.TAG, "hawaii")
STEM = f"shipping_zone_hawaii_{PER.TAG}"
TO = Transformer.from_crs(4326, "ESRI:102007", always_xy=True)
EXT = (-160.6, -154.6, 18.8, 22.4)   # lon, lat limits drawn
SRC = (f"Source: NTIA analysis of MarineCadastre AIS, 104 sampled days in {PER.AND}; route cells crossed by "
       "large ships on at least 6 ship-days (ship-days rule); Census 1:500,000 state outline.")
SHORT = {"Honolulu, O'ahu, HI": "Honolulu", "Kalaeloa Barbers Point, HI": "Kalaeloa", "Kahului, Maui, HI": "Kahului",
         "Kawaihae, Hawai'i, HI": "Kawaihae", "Hilo, Hawai'i, HI": "Hilo", "Nawiliwili, Kaua'i, HI": "Nawiliwili"}
OFFSET = {"Honolulu": (8, -14), "Kalaeloa": (-62, -14), "Kahului": (8, 6), "Kawaihae": (-118, 12),
          "Hilo": (8, -4), "Nawiliwili": (8, -10)}


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
    xb, yb = float(x0) + 20, float(y0) + 20
    ax.plot([xb, xb + 50], [yb, yb], color=page.theme.text, lw=2)
    ax.text(xb + 25, yb + 8, "50 km", ha="center", fontsize=9, color=page.theme.text)


def ports(page, ax, hollow=False):
    with open(os.path.join(HAW, f"{STEM}_principal_port_check.csv")) as f:
        rows = list(csv.DictReader(f))
    for r in rows:
        x, y = km(float(r["lon"]), float(r["lat"]))
        name = SHORT[r["port"]]
        on = r["on_route_network"] == "1"
        ax.plot(x, y, marker="o", ms=5, color=page.theme.text, mfc="white" if (hollow or not on) else page.theme.text, mec=page.theme.text, zorder=5)
        ax.annotate(name + ("" if on else " (off routes)"), (x, y), xytext=OFFSET[name], textcoords="offset points",
                    fontsize=9, color=page.theme.text, zorder=6,
                    path_effects=[pe.withStroke(linewidth=3, foreground="white")])
    return rows


def cells_xy(cell):
    lat, lon = isl.cell_latlon(cell, "hawaii")
    return km(lon, lat)


def haw_routes():
    route = np.load(os.path.join(ISL, "hawaii_rule_cells.npz"))["ship_days_6"]
    allc = np.load(os.path.join(ISL, "hawaii_routes.npz"))["both_cell"]
    page = OnePager(
        headline="Large-ship routes link Honolulu with Kahului, Nawiliwili, and Hilo, and run northeast to the "
                 "U.S. mainland",
        subhead=f"Route cells around the main Hawaiian Islands (ship-days rule), {len(route):,} cells of about 1 km; "
                "gray shows every cell a large ship crossed",
        source=SRC, theme="ntia", layout="hero", size=(11, 8.2),
        alt="Map of the main Hawaiian Islands. Gray dots show every cell a large ship crossed; blue route cells "
            "connect Honolulu and Kalaeloa with Kahului, Nawiliwili, and Hilo and run northeast toward the "
            "mainland. Kawaihae is off the routes.")
    ax = page.panel(0, grid=None)
    ax.add_collection(PolyCollection(rings(vf.STATES, "HI"), facecolor=page.theme.panel, edgecolor="white", lw=0.5))
    x, y = cells_xy(allc)
    ax.scatter(x, y, s=0.4, marker="s", lw=0, c=page.theme.grid, rasterized=True, zorder=1)
    x, y = cells_xy(route)
    ax.scatter(x, y, s=1.2, marker="s", lw=0, c=page.theme.accent, rasterized=True, zorder=2)
    frame(page, ax)
    ports(page, ax)
    vf.save(page, "haw01_routes")


def haw_zones():
    shares = {}
    import scipy.io
    m = scipy.io.loadmat(os.path.join(HAW, f"{STEM}_shore_rev1.mat"), squeeze_me=True, struct_as_record=False)
    zs = m["zone"]
    land_total = float(next(z.land_area_km2 for z in zs if z.distance_km == 100))
    for z in zs:
        shares[int(z.distance_km)] = (float(z.land_area_km2), float(z.land_area_km2) / land_total)
    page = OnePager(
        headline=f"A 50 km zone would cover {100 * shares[50][1]:.0f}% of Hawaii's land, and a 25 km zone "
                 f"{100 * shares[25][1]:.0f}%",
        subhead="Land within each distance of large-ship water (shore mode, same method as the lower 48); the 100 km "
                "zone covers all of the main islands",
        source=SRC, theme="ntia", layout="hero", size=(11, 8.2),
        alt=f"Map of the main Hawaiian Islands with land shaded by zone: the 25 km zone covers "
            f"{100 * shares[25][1]:.0f}% of the land, the 50 km zone {100 * shares[50][1]:.0f}%, and the 100 km zone "
            "all of it. The interior of the Big Island and parts of Maui fall outside 25 km.")
    ax = page.panel(0, grid=None)
    ramp = page.theme.ramp
    cols = {100: ramp[0], 50: ramp[len(ramp) // 2], 25: ramp[-1]}
    ax.add_collection(PolyCollection(rings(vf.STATES, "HI"), facecolor="white", edgecolor=page.theme.text, lw=0.5))
    for d in (100, 50, 25):
        ax.add_collection(PolyCollection(rings(os.path.join(HAW, f"{STEM}_shore_{d}km_land.shp")),
                                         facecolor=cols[d], edgecolor="none", zorder=2))
    frame(page, ax)
    ports(page, ax, hollow=True)
    # Direct key in the open ocean, southwest
    x0, y0 = km(-160.3, 19.6)
    for i, d in enumerate((25, 50, 100)):
        yy = float(y0) - i * 22
        ax.add_patch(__import__("matplotlib").patches.Rectangle((float(x0), yy), 16, 12, color=cols[d]))
        ax.text(float(x0) + 22, yy + 6, f"Within {d} km: {shares[d][0]:,.0f} km² ({100 * shares[d][1]:.0f}%)",
                va="center", fontsize=10, color=page.theme.text)
    vf.save(page, "haw02_zones")


if __name__ == "__main__":
    haw_routes()
    haw_zones()
