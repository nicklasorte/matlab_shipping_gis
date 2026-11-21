"""Draw the Guam and Northern Mariana Islands route and zone map (Python), NTIA style.

Inputs: outputs/guam/shipping_zone_guam_cnmi_links_2024_2025_ships_rev1.mat (from
init_shipping_zone_guam_rev1.m with cnmi_links=true), outputs/guam/shipping_zone_guam_2024_2025_ships_rev1.mat
(the Guam-only run), and the run log for the zone areas. Grid: 12 to 21.5 N, 143.5 to 147 E, 0.01 deg,
row 1 = southernmost row, as in the MATLAB grid.

Usage (from the repo root):
  MPLBACKEND=Agg python3 python/ship_guam_figures.py
Writes docs/viz_python/guam01_routes_zones (PNG, PDF, SVG, alt text).
"""
import os
import re
import sys

import numpy as np
import scipy.io
import matplotlib.patheffects as pe

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, HERE)
from onepager import OnePager  # noqa: E402
import ship_viz_figures as vf  # noqa: E402
import ship_period as PER  # noqa: E402

LAT0, LON0, STEP = 12.0, 143.5, 0.01
G = os.path.join(ROOT, "outputs", "guam")
LOG = os.path.join(ROOT, "outputs", "rerun_logs_20261121", "guam_cnmi_links.log")
PORTS = {"Apra Harbor": (13.4437, 144.6667), "Rota": (14.1400, 145.1380),
         "Tinian": (14.9580, 145.6200), "Saipan": (15.2258, 145.7349)}
SRC = (f"Source: NTIA analysis of MarineCadastre AIS, 104 sampled days in {PER.AND}; AIS route cells = large ships on "
       "at least 6 ship-days; link cells are straight lines between harbors (an assumption); Census 2023 land.")


def load(name):
    m = scipy.io.loadmat(os.path.join(G, name), squeeze_me=True, struct_as_record=False)
    return (np.asarray(m["source_mask"].todense() if hasattr(m["source_mask"], "todense") else m["source_mask"]) > 0,
            np.asarray(m["land_mask"].todense() if hasattr(m["land_mask"], "todense") else m["land_mask"]) > 0,
            np.asarray(m["dist_field_km"], dtype=float))


def areas():
    txt = open(LOG).read()
    a = {int(d): float(v) for d, v in re.findall(r"(\d+) km: \d+ regions, U.S. land in zone (\d+) km", txt)}
    tot = float(re.search(r"U.S. land in the grid: (\d+) km", txt).group(1))
    return a, tot


def xy(mask):
    r, c = np.nonzero(mask)
    return LON0 + STEP * (c + 0.5), LAT0 + STEP * (r + 0.5)


def main():
    src_l, land, dist = load("shipping_zone_guam_cnmi_links_2024_2025_ships_rev1.mat")
    src_g, _, _ = load("shipping_zone_guam_2024_2025_ships_rev1.mat")
    link = src_l & ~src_g
    a, tot = areas()
    assert int(src_g.sum()) == 1468 and int(link.sum()) == 229, (src_g.sum(), link.sum())
    in25 = land & (dist <= 25)
    page = OnePager(
        headline=f"With assumed links, the zones cover {a[25]:,.0f} km² of land in Guam and the Northern Mariana "
                 f"Islands, {100 * a[25] / tot:.0f}% of the total",
        subhead="Large-ship route cells and land within 25 km of them; the 50 and 100 km zones cover the same land",
        source=SRC, theme="ntia", layout="hero", size=(8.5, 10.2),
        alt=f"Map of Guam and the Northern Mariana Islands. Blue AIS route cells surround Guam and reach Apra Harbor; "
            f"purple link cells run in straight lines from Apra Harbor to Rota, Tinian, and Saipan. Land within 25 km "
            f"of a route cell is dark: {a[25]:,.0f} of {tot:,.0f} km² ({100 * a[25] / tot:.0f}%). Land outside the zone, "
            f"{tot - a[25]:,.0f} km², lies on islands north of 16 degrees north, which the map does not show.")
    ax = page.panel(0, grid=None)
    th = page.theme
    x, y = xy(land & ~in25)
    ax.scatter(x, y, s=1.6, marker="s", lw=0, c="#8A8D91", rasterized=True, zorder=1)
    x, y = xy(in25)
    ax.scatter(x, y, s=1.6, marker="s", lw=0, c="#163353", rasterized=True, zorder=2)
    x, y = xy(src_g)
    ax.scatter(x, y, s=0.6, marker="s", lw=0, c=th.accent, rasterized=True, zorder=3)
    x, y = xy(link)
    ax.scatter(x, y, s=4, marker="s", lw=0, c="#7B3FA0", zorder=4)
    for n, (la, lo) in PORTS.items():
        ax.plot(lo, la, marker="o", ms=5, color=th.text, mfc="white", mec=th.text, zorder=6)
        ax.annotate(n, (lo, la), xytext=(8, -3), textcoords="offset points", fontsize=9, color=th.text,
                    path_effects=[pe.withStroke(linewidth=3, foreground="white")], zorder=7)
    ax.set_xlim(143.6, 146.3)
    ax.set_ylim(12.6, 15.9)
    ax.set_aspect(1 / np.cos(np.radians(14.2)))
    ax.set_xticks([])
    ax.set_yticks([])
    for sp in ax.spines.values():
        sp.set_visible(False)
    ax.text(143.7, 15.75, "AIS route cells", color=th.accent, fontsize=10, fontweight="bold", ha="left")
    ax.text(143.7, 15.55, "Link cells (assumed)", color="#7B3FA0", fontsize=10, fontweight="bold", ha="left")
    ax.text(143.7, 15.35, f"Land within 25 km: {a[25]:,.0f} km²", color="#163353", fontsize=10, ha="left")
    ax.text(143.7, 15.15, f"Land outside (north of 16° N, not shown): {tot - a[25]:,.0f} km²", color=th.text, fontsize=10, ha="left")
    vf.save(page, "guam01_routes_zones")


if __name__ == "__main__":
    main()
