"""Draw the Alaska route and zone maps (Python), NTIA style, Alaska Albers (EPSG:3338).

Inputs: outputs/2018_2019/alaska/alaska_rule_cells.npz (ship_alaska_routes.py) and the
MATLAB zone shapefiles in outputs/2018_2019/alaska/ (init_shipping_zone_alaska_rev1.m),
plus the Kapsar check (check_alaska_kapsar.py) for the coverage note.

Usage (from the repo root):
  MPLBACKEND=Agg python3 python/ship_alaska_figures.py
Writes docs/viz_python/ak01_routes and ak02_zones (PNG, PDF, SVG, alt text).
"""
import csv
import os
import sys

import matplotlib.patheffects as pe
import numpy as np
import scipy.io
import shapefile
from matplotlib.collections import PolyCollection
from matplotlib.patches import Rectangle
from pyproj import Transformer

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, HERE)
from onepager import OnePager  # noqa: E402
import ship_island_routes as isl  # noqa: E402
import ship_viz_figures as vf  # noqa: E402

AK = os.path.join(ROOT, "outputs", "2018_2019", "alaska")
STEM = "shipping_zone_alaska_2018_2019"
GRID = "alaska180"
TO = Transformer.from_crs(4326, 3338, always_xy=True)
SRC = ("Source: NTIA analysis of MarineCadastre AIS (Coast Guard shore receivers), 104 sampled days in 2018 and 2019, "
       "route cells crossed by large ships on at least 6 ship-days; NOAA charted lanes; satellite-AIS cargo and tanker "
       "hexagons from Kapsar and others (2022), CC BY 4.0; Census 1:500,000 state outline. Analysis stops at 180 degrees.")
SHORT = {"Valdez, AK": "Valdez", "Port of Alaska, AK": "Anchorage", "Nikiski, AK": "Nikiski",
         "Unalaska Island, AK": "Dutch Harbor", "Kivalina, AK": "Kivalina"}
OFFSET = {"Valdez": (8, -2), "Anchorage": (6, 6), "Nikiski": (-58, -4), "Dutch Harbor": (8, -10), "Kivalina": (8, -2)}


def km(lon, lat):
    x, y = TO.transform(lon, lat)
    return np.asarray(x) / 1000, np.asarray(y) / 1000


def rings(path, state=None):
    sf = shapefile.Reader(path)
    recs = sf.records() if state else [None] * len(sf)
    out = []
    for shp, rec in zip(sf.shapes(), recs):
        if state and rec["STUSPS"] != state:
            continue
        p = np.array(shp.points)
        parts = list(shp.parts) + [len(p)]
        for a, b in zip(parts[:-1], parts[1:]):
            q = p[a:b]
            if state and q[:, 0].max() > 0:   # Aleutian pieces west of 180: outside the analysis
                continue
            x, y = km(q[:, 0], q[:, 1])
            out.append(np.column_stack([x, y]))
    return out


def frame(page, ax):
    ax.set_xlim(-1050, 1550)
    ax.set_ylim(350, 2450)
    ax.set_aspect(1)
    ax.set_xticks([])
    ax.set_yticks([])
    for sp in ax.spines.values():
        sp.set_visible(False)
    ax.plot([1250, 1450], [420, 420], color=page.theme.text, lw=2)
    ax.text(1350, 445, "200 km", ha="center", fontsize=9, color=page.theme.text)


def ports(page, ax, hollow=False):
    with open(os.path.join(AK, f"{STEM}_principal_port_check.csv")) as f:
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
    la, lo = isl.cell_latlon(cell, GRID)
    return km(lo, la)


def ak_routes():
    z = np.load(os.path.join(AK, "alaska_rule_cells.npz"))
    ais, allc = z["ship_days_6"], z["both_cell"]
    # MATLAB route cells: AIS (ship-days) cells plus NOAA charted fairways and routing measures
    m = scipy.io.loadmat(os.path.join(AK, f"{STEM}_shore_rev1.mat"), squeeze_me=True, struct_as_record=False)
    r_, c_ = m["source_mask"].nonzero()
    nr = m["source_mask"].shape[0]
    route = np.sort(r_ + 1 + c_ * nr).astype(np.int64)
    sat = np.loadtxt(os.path.join(AK, "satellite_lane_cells.csv"), dtype=np.int64)
    charted = np.setdiff1d(np.setdiff1d(route, ais), sat)
    sat = np.setdiff1d(sat, ais)
    page = OnePager(
        headline="Large-ship routes in Alaska run the Inside Passage, Cook Inlet, Prince William Sound, and Unimak "
                 "Pass; satellite data add the great-circle lanes far offshore",
        subhead=f"Route cells east of 180°, 2018–2019: {len(ais):,} cells of about 1 km from shore-received ship tracks "
                f"(ship-days rule, blue), {len(charted):,} from NOAA charted lanes (light blue), and {len(sat):,} from "
                "satellite-AIS hexagons (purple)",
        source=SRC, theme="ntia", layout="hero", size=(11, 8.2),
        alt="Map of Alaska. Blue route cells follow the Inside Passage in Southeast Alaska, Cook Inlet to Anchorage, "
            "Prince William Sound to Valdez, and Unimak Pass near Dutch Harbor; purple satellite-AIS hexagons add a wide "
            "band of lanes along and south of the Aleutians and patches in the Bering Sea.")
    ax = page.panel(0, grid=None)
    ax.add_collection(PolyCollection(rings(vf.STATES, "AK"), facecolor=page.theme.panel, edgecolor="white", lw=0.4))
    x, y = cells_xy(allc)
    ax.scatter(x, y, s=0.3, marker="s", lw=0, c=page.theme.grid, rasterized=True, zorder=1)
    x, y = cells_xy(charted)
    ax.scatter(x, y, s=0.9, marker="s", lw=0, c=page.theme.ramp[1], rasterized=True, zorder=2)
    x, y = cells_xy(sat)
    ax.scatter(x, y, s=0.9, marker="s", lw=0, c=page.theme.accent2, alpha=0.35, rasterized=True, zorder=2)
    x, y = cells_xy(ais)
    ax.scatter(x, y, s=0.9, marker="s", lw=0, c=page.theme.accent, rasterized=True, zorder=3)
    frame(page, ax)
    ports(page, ax)
    page.note(ax, "Purple: busy satellite-AIS hexagons\n(Kapsar and others, 2022), beyond\nshore-receiver range",
              (250, 520), coords="data")
    vf.save(page, "ak01_routes")


def ak_zones():
    m = scipy.io.loadmat(os.path.join(AK, f"{STEM}_shore_rev1.mat"), squeeze_me=True, struct_as_record=False)
    zs = {int(z.distance_km): float(z.land_area_km2) for z in m["zone"]}
    R = m["R"]
    land = m["land_mask"].astype(bool)
    # Total U.S. land in the grid from the same cells (spherical cell areas, as the zone areas)
    nr, nc = land.shape
    lat = 51 + 0.01 * (np.arange(nr) + 0.5)
    cell_km2 = (np.pi / 180 * 6371.0088) ** 2 * 0.01 * 0.01 * np.cos(np.radians(lat))
    total = float((land * cell_km2[:, None]).sum())
    del R
    page = OnePager(
        headline=f"A 25 km zone would cover {100 * zs[25] / total:.0f}% of Alaska's land east of 180°, a 50 km "
                 f"zone {100 * zs[50] / total:.0f}%, and a 100 km zone {100 * zs[100] / total:.0f}%",
        subhead="Land within each distance of large-ship water (shore mode, same method as the lower 48), 2018–2019 "
                "routes; the interior stays outside every zone",
        source=SRC, theme="ntia", layout="hero", size=(11, 8.2),
        alt=f"Map of Alaska with land near the coast shaded by zone: {100 * zs[25] / total:.0f}% within 25 km, "
            f"{100 * zs[50] / total:.0f}% within 50 km, and {100 * zs[100] / total:.0f}% within 100 km of large-ship "
            "water, concentrated in Southeast Alaska, Southcentral Alaska, and the Alaska Peninsula.")
    ax = page.panel(0, grid=None)
    ramp = page.theme.ramp
    cols = {100: ramp[0], 50: ramp[len(ramp) // 2], 25: ramp[-1]}
    ax.add_collection(PolyCollection(rings(vf.STATES, "AK"), facecolor="white", edgecolor=page.theme.text, lw=0.4))
    for d in (100, 50, 25):
        ax.add_collection(PolyCollection(rings(os.path.join(AK, f"{STEM}_shore_{d}km_land.shp")),
                                         facecolor=cols[d], edgecolor="none", zorder=2))
    frame(page, ax)
    ports(page, ax, hollow=True)
    for i, d in enumerate((25, 50, 100)):
        yy = 700 - i * 70
        ax.add_patch(Rectangle((300, yy), 50, 40, color=cols[d]))
        ax.text(370, yy + 20, f"Within {d} km: {zs[d]:,.0f} km² ({100 * zs[d] / total:.0f}%)",
                va="center", fontsize=10, color=page.theme.text)
    vf.save(page, "ak02_zones")
    return zs, total


if __name__ == "__main__":
    ak_routes()
    print(ak_zones())
