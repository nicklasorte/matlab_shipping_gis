"""Draw the ten ship-data figures (Python versions) from the viz products.

Run python/ship_viz_products.py first. Uses the vendored one-page toolkit
(python/onepager.py, NTIA theme) and writes PNG, PDF, SVG, and alt text to
docs/viz_python/. The MATLAB versions are drawn by init_ship_viz_rev1.m.

Usage (from the repo root):
  MPLBACKEND=Agg python3 python/ship_viz_figures.py
"""
import csv
import datetime as dt
import json
import os
import sys

import matplotlib.dates as mdates
import numpy as np
import shapefile
from matplotlib.collections import PolyCollection
from matplotlib.colors import BoundaryNorm, ListedColormap
from pyproj import Transformer

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ship_period as PER  # noqa: E402  analysis years
from onepager import OnePager  # noqa: E402

ROOT = os.path.join(HERE, "..")
VIZ = os.path.join(ROOT, "outputs", PER.TAG, "viz")
OUT = os.path.join(ROOT, "docs", "viz_python")
STATES = os.path.join(ROOT, "data", "cb_2023_us_state_500k", "cb_2023_us_state_500k.shp")
SRC_AIS = (f"Source: NTIA analysis of MarineCadastre AIS, 104 sampled days in {PER.AND}; "
           "large ships = cargo, tanker, passenger, military, and other seagoing ships 100 m or longer, "
           "plus tug-barges near the coast.")
TO_ALB = Transformer.from_crs(4326, 5070, always_xy=True)
os.makedirs(OUT, exist_ok=True)


def alb(lon, lat):
    x, y = TO_ALB.transform(lon, lat)
    return np.asarray(x) / 1e3, np.asarray(y) / 1e3


def states_polys():
    sf = shapefile.Reader(STATES)
    polys = []
    for shp, rec in zip(sf.shapes(), sf.records()):
        if rec["STUSPS"] in ("AK", "HI", "PR", "VI", "GU", "MP", "AS"):
            continue
        pts = np.array(shp.points)
        parts = list(shp.parts) + [len(pts)]
        for a, b in zip(parts[:-1], parts[1:]):
            x, y = alb(pts[a:b, 0], pts[a:b, 1])
            polys.append(np.column_stack([x, y]))
    return polys


_STATES = None


def base_map(page, ax, extent=None):
    global _STATES
    if _STATES is None:
        _STATES = states_polys()
    t = page.theme
    ax.add_collection(PolyCollection(_STATES, facecolor=t.panel, edgecolor="#FFFFFF", linewidth=0.4, zorder=1))
    ax.set_aspect("equal")
    ax.set_axis_off()
    if extent:
        ax.set_xlim(extent[0], extent[1])
        ax.set_ylim(extent[2], extent[3])


def cells_xy(cells, grid):
    lat0, lon0, d, nr, _ = grid
    c = cells.astype(np.int64) - 1
    lat = lat0 + d * (c % int(nr) + 0.5)
    lon = lon0 + d * (c // int(nr) + 0.5)
    return alb(lon, lat)


def read_csv(name):
    with open(os.path.join(VIZ, name)) as f:
        return list(csv.DictReader(f))


Z = np.load(os.path.join(VIZ, "viz_cells.npz"))
GRID = Z["grid"]
SUMM = json.load(open(os.path.join(VIZ, "viz_summary.json")))
DAILY = read_csv("viz_daily.csv")
DATES = np.array([np.datetime64(r["day"]) for r in DAILY])
YEAR = np.array([int(r["year"]) for r in DAILY])
US_EXTENT = (-2950, 2550, -150, 3300)


def save(page, name):
    page.save(os.path.join(OUT, name))
    print("saved", name)


# 1. Traffic density -----------------------------------------------------------
def fig_density():
    cell, ships = Z["both_cell"], Z["both_ships"]
    keep = np.isin(cell, Z["route_cells"])
    cell, ships = cell[keep], ships[keep]
    order = np.argsort(-ships)
    cs = np.cumsum(ships[order]) / ships.sum()
    half_share = np.searchsorted(cs, 0.5) / len(ships)
    page = OnePager(
        headline=f"The busiest {100 * half_share:.0f}% of route cells carry half of all large-ship traffic",
        subhead=f"Distinct large ships per 1 km route cell, {PER.AND} together",
        source=SRC_AIS, theme="ntia", layout="hero", size=(11, 7.6),
        alt="Map of the lower 48 states with each large-ship route cell colored by how many distinct ships "
            "used it; the darkest cells are the main coastal lanes and port approaches.")
    ax = page.panel(0, grid=None)
    base_map(page, ax, US_EXTENT)
    x, y = cells_xy(cell, GRID)
    bounds = [4, 10, 50, 200, 1000, 1e6]
    cmap = ListedColormap(page.theme.ramp)
    o = np.argsort(ships)
    ax.scatter(x[o], y[o], c=ships[o], s=0.25, marker="s", linewidths=0, cmap=cmap,
               norm=BoundaryNorm(bounds, cmap.N), zorder=2, rasterized=True)
    labels = ["4-9", "10-49", "50-199", "200-999", "1,000+"]
    for i, (lab, col) in enumerate(zip(labels, page.theme.ramp)):
        ax.add_patch(__import__("matplotlib").patches.Rectangle((-2850 + i * 320, 120), 310, 70,
                     facecolor=col, edgecolor="none", zorder=3))
        ax.text(-2850 + i * 320 + 155, 70, lab, ha="center", va="top", fontsize=9, color=page.theme.text)
    ax.text(-2850, 230, "Distinct ships per cell", fontsize=10, fontweight="bold", color=page.theme.text)
    save(page, "fig01_traffic_density")
    return half_share


# 2. Baltimore and the Key Bridge closure ---------------------------------------
def fig_baltimore():
    b = np.array([int(r["Baltimore"]) for r in DAILY])
    doy = np.array([(dt.date.fromisoformat(r["day"]) - dt.date(int(r["year"]), 1, 1)).days for r in DAILY])
    c0, c1 = (dt.date(2024, 3, 26) - dt.date(2024, 1, 1)).days, (dt.date(2024, 6, 10) - dt.date(2024, 1, 1)).days
    other = [y for y in PER.YEARS if y != PER.CLOSURE_YEAR][0]   # the year without the closure
    in24 = (YEAR == PER.CLOSURE_YEAR) & (doy >= c0) & (doy <= c1)
    in23 = (YEAR == other) & (doy >= c0 - 3) & (doy <= c1 + 3)
    drop = 1 - b[in24].mean() / b[in23].mean()
    page = OnePager(
        headline=f"Large ships in Baltimore harbor fell {100 * drop:.0f}% during the 2024 Key Bridge closure",
        subhead="Distinct large ships within 8 km of the Patapsco River harbor on each sampled Wednesday",
        source=SRC_AIS + " Closure: Fort McHenry Federal Channel, March 26 to June 10, 2024 (USACE).",
        theme="ntia", layout="hero", size=(11, 6.8), margin_right=0.8,
        alt=f"Line chart of large ships in Baltimore harbor each sampled week in {other} (gray) and 2024 (blue); "
            "the 2024 line drops during the shaded closure and recovers by June.")
    ax = page.panel(0)
    x = doy / 7.0 + 1
    ax.axvspan(c0 / 7 + 1, c1 / 7 + 1, color=page.theme.panel, zorder=0)
    ax.text((c0 + c1) / 14 + 1, 30, "Key Bridge closure", ha="center", fontsize=10.5, color=page.theme.text)
    page.lines(ax, None, {}, end_labels=False) if False else None
    for yr, col, lw in ((other, page.theme.context, 1.5), (PER.CLOSURE_YEAR, page.theme.accent, 2.4)):
        m = YEAR == yr
        ax.plot(x[m], b[m], color=col, lw=lw, zorder=3)
        ax.text(x[m][-1] + 0.6, b[m][-1], str(yr), color=page.theme.text,
                fontsize=11, fontweight="bold", va="center")
    ax.set_xlim(1, 53)
    ax.set_ylim(0, 34)
    ax.set_xlabel("Week of the year")
    ax.set_ylabel("Large ships")
    save(page, "fig02_baltimore_key_bridge")
    return drop


# 3. Seasons by coast ----------------------------------------------------------
def fig_seasons():
    names = [("Great Lakes", "Great_Lakes"), ("Atlantic", "Atlantic"), ("Gulf", "Gulf"), ("Pacific", "Pacific")]
    mon = np.array([int(r["day"][5:7]) for r in DAILY])
    gl = np.array([int(r["Great_Lakes"]) for r in DAILY])
    winter, summer = gl[np.isin(mon, [1, 2, 3])].mean(), gl[np.isin(mon, [6, 7, 8, 9])].mean()
    page = OnePager(
        headline="Great Lakes traffic falls by half in winter; the ocean coasts barely change",
        subhead=f"Distinct large ships on each sampled Wednesday, {PER.AND}",
        source=SRC_AIS + " Coasts are split by simple latitude and longitude boxes.",
        theme="ntia", layout="grid2x2", size=(11, 8.0),
        alt="Four line charts of large ships per sampled day for the Great Lakes, Atlantic, Gulf, and Pacific; "
            "only the Great Lakes line dips sharply each winter.")
    for i, (title, col) in enumerate(names):
        v = np.array([int(r[col]) for r in DAILY])
        ax = page.panel(i, title=title)
        color = page.theme.accent if title == "Great Lakes" else page.theme.context
        ax.plot(DATES, v, color=color, lw=2.2 if title == "Great Lakes" else 1.6)
        ax.set_ylim(0, max(v) * 1.15)
        ax.xaxis.set_major_locator(mdates.MonthLocator(bymonth=[1, 7]))
        ax.xaxis.set_major_formatter(mdates.DateFormatter("%b %Y"))
    save(page, "fig03_seasons_by_coast")
    return winter, summer


# 4. Length cutoff sweep -------------------------------------------------------
def fig_sweep():
    rows = list(csv.DictReader(open(os.path.join(ROOT, "outputs", "2024", "gt_proxy_sweep_2024.csv"))))
    cut = np.array([float(r["cutoff_m"]) for r in rows])
    prec = np.array([float(r["precision"]) for r in rows]) * 100
    rec = np.array([float(r["recall"]) for r in rows]) * 100
    i100 = int(np.argmin(abs(cut - 100)))
    page = OnePager(
        headline=f"At 100 m, {prec[i100]:.1f}% of kept ships are 3,000 GT or more, and {rec[i100]:.1f}% of those ships are kept",
        subhead="Length cutoff tested against Wikidata gross tonnage (3,000 GT, the SOLAS size for a 3 GHz radar), "
                "4,129 cargo, tanker, and passenger ships",
        source="Source: NTIA analysis of MarineCadastre AIS (four days in 2024) matched by IMO number to Wikidata gross tonnage.",
        theme="ntia", layout="hero", size=(11, 6.8),
        alt="Line chart of two measures against the length cutoff from 50 to 200 m: the share of kept ships "
            "that are 3,000 GT or more rises, the share of 3,000 GT ships kept falls, and they cross near 90 m; at 100 m "
            "the shares are 99.6% and 98.1%.")
    ax = page.panel(0)
    ax.plot(cut, prec, color=page.theme.context, lw=2)
    ax.plot(cut, rec, color=page.theme.accent, lw=2.4)
    ax.axvline(100, color=page.theme.text, lw=1, ls="--")
    ax.text(101.5, 60, "100 m cutoff", fontsize=10.5, color=page.theme.text)
    ax.text(150, prec[np.argmin(abs(cut - 150))] + 1.2, "Kept ships that are 3,000 GT or more", fontsize=10.5,
            ha="center", va="bottom", color=page.theme.text)
    ax.text(103, 88, "3,000 GT ships the test keeps", fontsize=10.5,
            ha="left", va="top", color=page.theme.accent, fontweight="bold")
    ax.set_xlim(50, 200)
    ax.set_ylim(np.floor(min(rec.min(), prec.min()) / 5) * 5 - 5, 101)
    ax.set_xlabel("Length cutoff (m)")
    ax.set_ylabel("Percent")
    save(page, "fig04_length_cutoff_sweep")
    return prec[i100], rec[i100]


# 5. Filter funnel -------------------------------------------------------------
def fig_funnel():
    rows = list(csv.DictReader(open(os.path.join(ROOT, "outputs", "2023_2024", "ais_filter_funnel.csv"))))  # one day: July 10, 2024
    r24 = [r for r in rows if r["day"].startswith("10-Jul-2024") or r["day"].startswith("2024-07-10")]
    steps = ["All ships reporting", "Ship type kept", "Length 100 m or more", "IMO number", "Inside the analysis grid"]
    ships = [int(float(r["ships"])) for r in r24]
    page = OnePager(
        headline=f"About 1 ship in {round(ships[0] / ships[-1])} reporting on AIS passes the large-ship filter",
        subhead="Distinct ships left after each filter step on July 10, 2024 (each step keeps only ships that passed the steps above it)",
        source="Source: NTIA analysis of the full MarineCadastre AIS file for July 10, 2024.",
        theme="ntia", layout="hero", size=(11, 6.4), margin_right=0.4,
        alt=f"Horizontal bar chart of ships after each filter step on July 10, 2024: {ships[0]:,} reporting, "
            f"{ships[-1]:,} kept.")
    ax = page.panel(0, grid=None)
    y = np.arange(len(steps))[::-1]
    cols = [page.theme.context] * (len(steps) - 1) + [page.theme.accent]
    ax.barh(y, ships, color=cols, height=0.62)
    for yi, s, lab in zip(y, ships, steps):
        ax.text(s + 250, yi, f"{s:,}", va="center", fontsize=11, color=page.theme.text,
                fontweight="bold" if lab == steps[-1] else "normal")
    ax.set_yticks(y, steps)
    ax.set_xticks([])
    for sp in ax.spines.values():
        sp.set_visible(False)
    ax.set_xlim(0, ships[0] * 1.12)
    save(page, "fig05_filter_funnel")
    return ships


# 6. Stability between years ---------------------------------------------------
def fig_stability():
    cell, ships = Z["both_cell"], Z["both_ships"]
    r = np.isin(cell, Z["route_cells"])
    both = np.isin(cell, Z["both_years"])
    share_visits = ships[r & both].sum() / ships[r].sum()
    page = OnePager(
        headline=f"{100 * share_visits:.0f}% of large-ship traffic is in cells that pass the threshold in both years",
        subhead=f"Route cells with 4 or more ships in both {PER.AND} ({SUMM['both_years']:,} cells, blue) "
                f"or in only one year ({SUMM['only_y0'] + SUMM['only_y1']:,} cells, gray)",
        source=SRC_AIS, theme="ntia", layout="hero", size=(11, 7.6),
        alt="Map of route cells: cells that pass the ship threshold in both years form the main lanes in blue; "
            "cells that pass in only one year are scattered gray cells around them.")
    ax = page.panel(0, grid=None)
    base_map(page, ax, US_EXTENT)
    one = np.concatenate([Z["only23"], Z["only24"]])
    x, y = cells_xy(one, GRID)
    ax.scatter(x, y, s=0.2, marker="s", linewidths=0, color=page.theme.context, zorder=2, rasterized=True)
    x, y = cells_xy(Z["both_years"], GRID)
    ax.scatter(x, y, s=0.2, marker="s", linewidths=0, color=page.theme.accent, zorder=3, rasterized=True)
    save(page, "fig06_stability_between_years")
    return share_visits


# 7. Tug-barge cells -----------------------------------------------------------
def fig_tugs():
    total = SUMM["route_cells"]
    add = SUMM["tow_only_cells"]
    page = OnePager(
        headline=f"Tug-barges add {100 * add / SUMM['route_cells_main_only']:.0f}% more route cells, "
                 "mostly near Atlantic, Gulf, and Great Lakes ports",
        subhead=f"Route cells that only tug-barges put over the threshold ({add:,} cells, blue) "
                f"on the other large-ship routes (gray)",
        source=SRC_AIS, theme="ntia", layout="hero", size=(11, 7.6),
        alt="Map of large-ship routes in gray with the few cells that only tug-barges add shown in blue, "
            "mostly along the Northeast, Gulf, and Great Lakes coasts.")
    ax = page.panel(0, grid=None)
    base_map(page, ax, US_EXTENT)
    x, y = cells_xy(Z["route_cells"], GRID)
    ax.scatter(x, y, s=0.15, marker="s", linewidths=0, color="#C9CBCE", zorder=2, rasterized=True)
    x, y = cells_xy(Z["tow_only"], GRID)
    ax.scatter(x, y, s=1.6, marker="s", linewidths=0, color=page.theme.accent, zorder=3, rasterized=True)
    for g, (lx, ly) in {"Atlantic": (1950, 1250), "Gulf": (650, 120), "Great Lakes": (250, 2450), "Pacific": (-2700, 1500)}.items():
        ax.text(lx, ly, f"{g}\n{SUMM['tow_only_' + g]:,} cells", fontsize=10, color=page.theme.text, ha="center")
    save(page, "fig07_tug_barge_cells")
    return add, total


# 8. Mississippi profile -------------------------------------------------------
def fig_mississippi():
    rows = read_csv("viz_mississippi.csv")
    km = np.array([(float(r["river_km_from"]) + float(r["river_km_to"])) / 2 for r in rows])
    ships = np.array([int(r["ships"]) for r in rows])
    no, br, end = SUMM["river_km_new_orleans"], SUMM["river_km_baton_rouge"], SUMM["river_km_end"]
    at_br = ships[np.argmin(abs(km - br))]
    page = OnePager(
        headline=f"Traffic thins above New Orleans, but large ships still reach Baton Rouge, {br:.0f} river km upstream",
        subhead=f"Distinct large ships in each 5 km reach of the Mississippi River, 104 sampled days in {PER.AND}",
        source=SRC_AIS + " River distance is measured through the route cells from Head of Passes.",
        theme="ntia", layout="hero", size=(11, 6.6),
        alt="Line chart of distinct large ships along the Mississippi from Head of Passes to Baton Rouge; "
            "traffic is highest below New Orleans, stays in the hundreds up to Baton Rouge, and ends just above it.")
    ax = page.panel(0)
    ax.fill_between(km, ships, step="mid", color=page.theme.ramp[1], lw=0)
    ax.step(km, ships, where="mid", color=page.theme.accent, lw=2)
    for k, lab, ha, dx in ((no, "New Orleans", "left", 3), (br, "Baton Rouge", "right", -3)):
        ax.axvline(k, color=page.theme.text, lw=1, ls="--")
        ax.text(k + dx, ships.max() * 1.03, lab, fontsize=10.5, color=page.theme.text, ha=ha)
    ax.set_xlim(0, end + 15)
    ax.set_ylim(0, ships.max() * 1.12)
    ax.set_xlabel("River distance above Head of Passes (km)")
    ax.set_ylabel("Distinct large ships")
    save(page, "fig08_mississippi_profile")
    return at_br


# 9. Sites near routes ---------------------------------------------------------
def fig_sites():
    rows = read_csv("viz_sites.csv")
    groups = [("named_port", "Named major ports"), ("deep_draft_port", "Deep-draft ports"),
              ("other_coastal_port", "Other coastal ports"), ("racon", "S-band racons"),
              ("vts_area", "VTS areas"), ("inland_port", "Inland river ports")]
    dd = np.array([float(r["route_km"]) for r in rows if r["group"] == "deep_draft_port"])
    page = OnePager(
        headline=f"Every named major port and {100 * np.mean(dd <= 5):.0f}% of deep-draft ports sit within 5 km "
                 "of a large-ship route; inland river ports do not",
        subhead="Distance from each site to the nearest large-ship route cell (log scale); each dot is one site",
        source=SRC_AIS + " Ports: USACE Principal Ports (deep-draft = coastal or Great Lakes, 1 million tons "
                         "or more of foreign trade). Racons: NOAA ENC Direct. VTS: U.S. Coast Guard.",
        theme="ntia", layout="hero", size=(11, 6.8), margin_right=0.2,
        alt="Strip plot of distance to the nearest large-ship route for six kinds of site; ports, racons, and "
            "VTS areas cluster under 5 km, while inland river ports sit hundreds of kilometers away.")
    ax = page.panel(0, grid="x")
    rng = np.random.default_rng(1)
    for k, (key, lab) in enumerate(groups):
        d = np.array([float(r["route_km"]) for r in rows if r["group"] == key])
        y = len(groups) - 1 - k + rng.uniform(-0.18, 0.18, len(d))
        hl = key in ("named_port", "deep_draft_port")
        ax.scatter(np.maximum(d, 0.1), y, s=26, color=page.theme.accent if hl else page.theme.context,
                   alpha=0.85, linewidths=0, zorder=3)
        ax.text(0.11, len(groups) - 1 - k + 0.24, f"{lab} ({len(d)})", ha="left", va="bottom", fontsize=10.5,
                color=page.theme.text, fontweight="bold" if hl else "normal")
    ax.axvline(5, color=page.theme.text, lw=1, ls="--")
    ax.text(5.4, len(groups) - 0.45, "5 km", fontsize=10.5, color=page.theme.text)
    ax.set_xscale("log")
    ax.set_xlim(0.1, 1000)
    ax.set_xticks([0.1, 1, 10, 100, 1000], ["0.1", "1", "10", "100", "1,000"])
    ax.set_yticks([])
    ax.set_ylim(-0.4, len(groups) - 0.1)
    ax.set_xlabel("Distance to the nearest large-ship route cell (km)")
    for sp in ("left", "top", "right"):
        ax.spines[sp].set_visible(False)
    save(page, "fig09_sites_near_routes")


# 10. Offshore distance --------------------------------------------------------
def fig_offshore():
    rows = read_csv("viz_offshore.csv")
    coasts = ["Great Lakes", "Atlantic", "Pacific", "Gulf"]
    page = OnePager(
        headline=f"Half of Pacific and Gulf route cells lie more than {min(SUMM['offshore_median_km_Pacific'], SUMM['offshore_median_km_Gulf']) // 10 * 10:.0f} km "
                 f"offshore; 90% of Great Lakes route cells are within {SUMM['offshore_p90_km_Great Lakes']:.0f} km of shore",
        subhead="Share of large-ship route cells within a given distance of the Census coastline, by coast",
        source=SRC_AIS + " Coastline: Census TIGER/Line 2023. The analysis grid ends at 130 W and 22 N.",
        theme="ntia", layout="hero", size=(11, 6.8), margin_right=1.3,
        alt="Cumulative distribution of route-cell distance to the coastline for four coasts; the Great Lakes "
            "curve rises fastest, the Atlantic next, and the Pacific and Gulf curves extend hundreds of kilometers.")
    ax = page.panel(0)
    for g in coasts:
        d = np.sort([float(r["coast_km"]) for r in rows if r["coast"] == g])
        y = np.arange(1, len(d) + 1) / len(d) * 100
        hl = g == "Pacific"
        ax.plot(d, y, color=page.theme.accent if hl else page.theme.context, lw=2.4 if hl else 1.5)
        x_end = min(d[-1], 600)
        ax.text(x_end + 8, y[np.searchsorted(d, x_end) - 1] if x_end < d[-1] else 100, g, fontsize=10.5,
                va="center", color=page.theme.text, fontweight="bold" if hl else "normal")
    ax.axhline(50, color=page.theme.grid, lw=1)
    ax.set_xlim(0, 600)
    ax.set_ylim(0, 103)
    ax.set_xlabel("Distance from the coastline (km)")
    ax.set_ylabel("Percent of route cells")
    save(page, "fig10_offshore_distance")


if __name__ == "__main__":
    out = {
        "density_half_share": fig_density(),
        "baltimore_drop": fig_baltimore(),
        "great_lakes_winter_summer": fig_seasons(),
        "sweep_at_100": fig_sweep(),
        "funnel_ships": fig_funnel(),
        "stability_visits_share": fig_stability(),
        "tugs": fig_tugs(),
        "mississippi_at_baton_rouge": int(fig_mississippi()),
    }
    fig_sites()
    fig_offshore()
    print(json.dumps({k: (list(map(float, v)) if isinstance(v, (tuple, list)) else float(v)) for k, v in out.items()}, indent=1))
