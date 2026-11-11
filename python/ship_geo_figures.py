"""Draw the nine geographic figures (Appendix A, maps A-9 to A-17), Python versions.

Run python/ship_viz_products.py and python/ship_geo_products.py first. Writes
PNG, PDF, SVG, and alt text to docs/viz_python/ (geo01 ... geo09). The MATLAB
versions are drawn by init_ship_geo_rev1.m.

Usage (from the repo root):
  MPLBACKEND=Agg python3 python/ship_geo_figures.py
"""
import csv
import json
import os
import sys

import numpy as np
from matplotlib.collections import PolyCollection
from matplotlib.patches import Rectangle
import matplotlib.patheffects as pe

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from onepager import OnePager  # noqa: E402
import ship_viz_figures as vf  # noqa: E402  base map, Albers, cell helpers, products

VIZ = vf.VIZ
OUT = vf.OUT
GS = json.load(open(os.path.join(VIZ, "geo_summary.json")))
HEX_R = 12.5
SRC = vf.SRC_AIS
US = vf.US_EXTENT


def read(name):
    with open(os.path.join(VIZ, name)) as f:
        return list(csv.DictReader(f))


def hex_polys(x, y, r=HEX_R):
    ang = np.radians(np.arange(6) * 60 + 30)   # pointy-top
    return [np.column_stack([xi + r * np.cos(ang), yi + r * np.sin(ang)]) for xi, yi in zip(x, y)]


def ramp_index(v, edges):
    return np.clip(np.searchsorted(edges, v, side="right") - 1, 0, len(edges) - 2)


def ramp_key(page, ax, labels, title, x0=-2850, y0=120, w=420):
    for i, (lab, col) in enumerate(zip(labels, page.theme.ramp)):
        ax.add_patch(Rectangle((x0 + i * w, y0), w - 10, 70, facecolor=col, edgecolor="none", zorder=5))
        ax.text(x0 + i * w + (w - 10) / 2, y0 - 50, lab, ha="center", va="top", fontsize=9, color=page.theme.text)
    ax.text(x0, y0 + 110, title, fontsize=10, fontweight="bold", color=page.theme.text)


def hexes():
    h = read("geo_hex.csv")
    return (np.array([float(r["x_km"]) for r in h]), np.array([float(r["y_km"]) for r in h]),
            np.array([int(r["ships"]) for r in h]))


HX, HY, HN = hexes()
HEX_EDGES = [1, 10, 100, 500, 1000, 1e9]
HEX_LABELS = ["1-9", "10-99", "100-499", "500-999", "1,000+"]


# G1. Hex grid ---------------------------------------------------------------
def geo_hex():
    page = OnePager(
        headline=f"The busiest 5% of hexagons carry {100 * GS['hex_share_top5pct']:.0f}% of large-ship traffic",
        subhead="Distinct large ships per 25 km hexagon on the large-ship routes, 2023 and 2024 together",
        source=SRC + " Hexagons are drawn on an equal-area (Albers) projection.",
        theme="ntia", layout="hero", size=(11, 7.6),
        alt="Hexagon map of the lower 48 states; hexagons along the coasts, Great Lakes, and lower Mississippi "
            "are shaded by the number of distinct large ships, darkest at the major port complexes.")
    ax = page.panel(0, grid=None)
    vf.base_map(page, ax, US)
    o = np.argsort(HN)
    cols = np.array(page.theme.ramp)[ramp_index(HN[o], HEX_EDGES)]
    ax.add_collection(PolyCollection(hex_polys(HX[o], HY[o]), facecolors=cols, edgecolors="white",
                                     linewidths=0.15, zorder=2))
    ramp_key(page, ax, HEX_LABELS, "Distinct ships per hexagon")
    vf.save(page, "geo01_hex_grid")


# G2. Spike map --------------------------------------------------------------
def geo_spikes():
    top = GS["ports_top"]
    page = OnePager(
        headline="Galveston Bay, the lower Mississippi, Los Angeles-Long Beach, and New York tower over the rest of the coast",
        subhead="Spike height = distinct large ships per 25 km hexagon with 10 or more ships, 2023 and 2024 together "
                f"(tallest spike: {GS['hex_max_ships']:,} ships)",
        source=SRC, theme="ntia", layout="hero", size=(11, 7.6),
        alt="Spike map of the lower 48 states with a vertical spike on each hexagon, sized by distinct large "
            "ships; the tallest spikes stand at Galveston Bay, the lower Mississippi, Los Angeles-Long Beach, "
            "and New York.")
    ax = page.panel(0, grid=None)
    vf.base_map(page, ax, (US[0], US[1], US[2], US[3] + 250))
    scale = 420.0 / HN.max()
    o = np.argsort(-HY)   # draw north first so southern spikes overlap them
    o = o[HN[o] >= 10]   # hexagons with 10 or more ships; the rest would be flat specks
    tris = [np.array([[x - 7, y], [x, y + n * scale], [x + 7, y]]) for x, y, n in zip(HX[o], HY[o], HN[o])]
    ax.add_collection(PolyCollection(tris, facecolors=page.theme.accent, edgecolors=page.theme.text,
                                     linewidths=0.25, alpha=0.75, zorder=3))
    for name, (lon, lat), dx, dy, ha in (("Galveston Bay", (-94.8, 29.35), -20, -230, "right"),
                                         ("Lower Mississippi", (-89.4, 29.1), 20, -230, "left"),
                                         ("Los Angeles-Long Beach", (-118.25, 33.7), 40, -40, "left"),
                                         ("New York", (-74.0, 40.5), 60, -20, "left")):
        x, y = vf.alb(lon, lat)
        ax.text(float(x) + dx, float(y) + dy, name, fontsize=9.5, color=page.theme.text, ha=ha, va="top",
                fontweight="bold")
    _ = top
    vf.save(page, "geo02_spike_map")


# G3. Port close-ups ---------------------------------------------------------
AREAS = [("New York-New Jersey", (40.30, 40.95), (-74.35, -73.60)),
         ("Chesapeake and Delaware Bays", (36.80, 39.90), (-77.00, -74.70)),
         ("Houston-Galveston", (29.20, 29.85), (-95.30, -94.50)),
         ("Lower Mississippi", (28.90, 30.60), (-91.30, -89.00)),
         ("Los Angeles-Long Beach", (33.40, 33.90), (-118.55, -117.90)),
         ("Puget Sound", (47.00, 48.60), (-123.30, -122.10))]


def land_lonlat():
    import shapefile
    sf = shapefile.Reader(vf.STATES)
    out = []
    for shp, rec in zip(sf.shapes(), sf.records()):
        pts = np.array(shp.points)
        parts = list(shp.parts) + [len(pts)]
        out += [pts[a:b] for a, b in zip(parts[:-1], parts[1:])]
    return out


def geo_closeups():
    cell, ships = vf.Z["both_cell"], vf.Z["both_ships"]
    keep = np.isin(cell, vf.Z["route_cells"])
    cell, ships = cell[keep], ships[keep]
    lat0, lon0, d, nr, _ = vf.GRID
    c = cell - 1
    lat = lat0 + d * (c % int(nr) + 0.5)
    lon = lon0 + d * (c // int(nr) + 0.5)
    busy = ships >= 200
    inside = np.zeros_like(busy)
    for _, (a, b), (e, f) in AREAS:
        inside |= (lat >= a) & (lat <= b) & (lon >= e) & (lon <= f)
    share = (busy & inside).sum() / busy.sum()
    page = OnePager(
        headline=f"Inside the busiest port areas, large ships keep to narrow channels; these six areas hold "
                 f"{100 * share:.0f}% of the busiest route cells",
        subhead="Distinct large ships per 1 km route cell, 2023 and 2024 together (busiest cells: 200 or more ships)",
        source=SRC, theme="ntia", layout="hero", size=(11, 8.2),
        alt="Six close-up maps of port areas showing large-ship route cells shaded by ship count; traffic runs "
            "in narrow dredged channels in each.")
    host = page.panel(0, grid=None)
    host.set_axis_off()
    host.set_xticks([])
    host.set_yticks([])
    land = land_lonlat()
    cmap_cols = np.array(page.theme.ramp)
    edges = [4, 10, 50, 200, 1000, 1e9]
    for i, (name, (a, b), (e, f)) in enumerate(AREAS):
        ax = host.inset_axes([(i % 3) * 0.34, 0.52 - (i // 3) * 0.52, 0.31, 0.44])
        ax.add_collection(PolyCollection(land, facecolor=page.theme.panel, edgecolor="white", linewidth=0.4))
        m = (lat >= a) & (lat <= b) & (lon >= e) & (lon <= f)
        o = np.argsort(ships[m])
        ax.set_xlim(e, f)
        ax.set_ylim(a, b)
        ax.set_aspect(1 / np.cos(np.radians((a + b) / 2)))
        page.fig.canvas.draw()
        side_pt = ax.get_window_extent().width / page.fig.dpi * 72 * 0.01 / (f - e)   # one 0.01 degree cell
        ax.scatter(lon[m][o], lat[m][o], s=max(side_pt, 0.5) ** 2, marker="s", linewidths=0,
                   c=cmap_cols[ramp_index(ships[m][o], edges)], zorder=2, rasterized=True)
        ax.set_xticks([])
        ax.set_yticks([])
        for sp in ax.spines.values():
            sp.set_color(page.theme.grid)
        ax.set_title(name, fontsize=10.5, color=page.theme.text, loc="left", fontweight="bold")
    vf.save(page, "geo03_port_closeups")


# G4. Offshore distance bands -------------------------------------------------
def geo_offshore_bands():
    o = read("viz_offshore.csv")
    lat = np.array([float(r["lat"]) for r in o])
    lon = np.array([float(r["lon"]) for r in o])
    km = np.array([float(r["coast_km"]) for r in o])
    page = OnePager(
        headline=f"Half of all large-ship route cells are within 100 km of shore; "
                 f"{100 * np.mean(km <= 50):.0f}% are within 50 km",
        subhead="Large-ship route cells colored by distance from the Census coastline",
        source=SRC + " Coastline: Census TIGER/Line 2023.", theme="ntia", layout="hero", size=(11, 7.6),
        alt="Map of large-ship route cells colored by distance from shore: darkest within 25 km at ports and "
            "on the Great Lakes, lighter farther offshore.")
    ax = page.panel(0, grid=None)
    vf.base_map(page, ax, US)
    x, y = vf.alb(lon, lat)
    edges = [0, 25, 50, 100, 1e9]
    cols = np.array(page.theme.ramp[1:][::-1])   # darkest = nearest shore
    idx = ramp_index(km, edges)
    order = np.argsort(-km)
    ax.scatter(x[order], y[order], s=0.3, marker="s", linewidths=0, c=cols[idx[order]], zorder=2, rasterized=True)
    labels = ["0-25 km", "25-50", "50-100", "Over 100"]
    for i, (lab, col) in enumerate(zip(labels, cols)):
        ax.add_patch(Rectangle((-2850 + i * 520, 120), 510, 70, facecolor=col, edgecolor="none", zorder=5))
        ax.text(-2850 + i * 520 + 255, 70, lab, ha="center", va="top", fontsize=9, color=page.theme.text)
    ax.text(-2850, 230, "Distance from shore", fontsize=10, fontweight="bold", color=page.theme.text)
    vf.save(page, "geo04_offshore_bands")


# G5. Near-shore profile ------------------------------------------------------
def geo_profile():
    rows = read("geo_profile.csv")
    page = OnePager(
        headline="Near-shore traffic peaks off Houston-Galveston, New York, and Los Angeles-Long Beach",
        subhead=f"Distinct large ships within {int(50)} km of shore in each half-degree along the coast, 2023 and 2024",
        source=SRC + " Pacific and Atlantic by latitude (south to north); Gulf by longitude (west to east).",
        theme="ntia", layout="hero", size=(11, 8.0),
        alt="Three bar charts of near-shore large-ship traffic along the Pacific, Gulf, and Atlantic coasts; each "
            "has one or two clear peaks at the major port complexes.")
    host = page.panel(0, grid=None)
    host.set_axis_off()
    host.set_xticks([])
    host.set_yticks([])
    peaks = {"Pacific": "Los Angeles-Long Beach", "Gulf": "Houston-Galveston", "Atlantic": "New York"}
    for i, coast in enumerate(["Pacific", "Gulf", "Atlantic"]):
        ax = host.inset_axes([0.07, 0.70 - i * 0.34, 0.92, 0.24])
        rr = [r for r in rows if r["coast"] == coast]
        a = np.array([float(r["from_deg"]) for r in rr])
        n = np.array([int(r["ships"]) for r in rr])
        k = int(np.argmax(n))
        cols = [page.theme.accent if j == k else page.theme.context for j in range(len(n))]
        ax.bar(a + 0.25, n, width=0.45, color=cols)
        ax.set_ylim(0, 4200)
        ax.set_yticks([0, 2000, 4000], ["0", "2,000", "4,000"])
        ax.set_title(coast, loc="left", fontsize=11, fontweight="bold", color=page.theme.text)
        ax.text(a[k] + 0.6, n[k], f"{peaks[coast]} ({n[k]:,})", fontsize=9.5, va="center", color=page.theme.text,
                fontweight="bold")
        ax.set_xlabel("Longitude (degrees)" if coast == "Gulf" else "Latitude (degrees north)", fontsize=9.5)
        ax.tick_params(labelsize=9)
        ax.grid(axis="y", color=page.theme.grid)
        for sp in ("top", "right"):
            ax.spines[sp].set_visible(False)
    vf.save(page, "geo05_coast_profile")


# G6. Port bubbles -----------------------------------------------------------
def geo_ports():
    rows = read("geo_ports.csv")
    lat = np.array([float(r["lat"]) for r in rows])
    lon = np.array([float(r["lon"]) for r in rows])
    n = np.array([int(r["ships"]) for r in rows])
    page = OnePager(
        headline=f"{GS['ports_ge_1000']} deep-draft ports each saw 1,000 or more different large ships within 10 km",
        subhead="Circle area = distinct large ships within 10 km of each deep-draft port, 2023 and 2024 together",
        source=SRC + " Ports: USACE Principal Ports, coastal or Great Lakes, 1 million tons or more of foreign trade.",
        theme="ntia", layout="hero", size=(11, 7.6),
        alt="Bubble map of 73 deep-draft ports sized by the number of large ships nearby; the largest circles are "
            "on the Texas and Louisiana coast, at Los Angeles-Long Beach, and at New York.")
    ax = page.panel(0, grid=None)
    vf.base_map(page, ax, US)
    x, y = vf.alb(lon, lat)
    o = np.argsort(-n)
    ax.scatter(x[o], y[o], s=n[o] / 6, color=page.theme.accent, alpha=0.55, edgecolors=page.theme.text,
               linewidths=0.5, zorder=3)
    for name, nn, (dx, dy) in (("Galveston", 2839, (40, -150)), ("New Orleans", 2413, (70, 110)),
                               ("Long Beach", 1894, (90, -60)), ("New York", 1683, (90, 0)),
                               ("Houston", 1637, (-70, 120))):
        r = [i for i, rr in enumerate(rows) if rr["port"].startswith(name) or rr["port"].startswith("Port of " + name)][0]
        ax.text(x[r] + dx, y[r] + dy, f"{name}\n{n[r]:,}", fontsize=9, color=page.theme.text,
                ha="left" if dx > 0 else "right", zorder=6,
                path_effects=[pe.withStroke(linewidth=2.5, foreground="white")])
    for s_, lab in ((500, "500"), (1500, "1,500"), (3000, "3,000")):
        ax.scatter([], [], s=s_ / 6, color=page.theme.accent, alpha=0.55, edgecolors=page.theme.text, label=lab)
    ax.text(-2850, 330, "Large ships within 10 km", fontsize=10, fontweight="bold", color=page.theme.text)
    for i, s_ in enumerate((500, 1500, 3000)):
        ax.scatter(-2750 + i * 260, 200, s=s_ / 6, color=page.theme.accent, alpha=0.55, edgecolors=page.theme.text)
        ax.text(-2750 + i * 260, 80, f"{s_:,}", ha="center", fontsize=9, color=page.theme.text)
    vf.save(page, "geo06_port_bubbles")


# G7. Ship types -------------------------------------------------------------
def geo_types():
    rows = read("geo_hex_types.csv")
    if not rows:
        print("skip geo07: no ship-type data yet")
        return
    names = [("tanker", "Tankers"), ("cargo", "Cargo and container ships"), ("passenger", "Passenger ships"),
             ("government", "Military and law enforcement")]
    t_share = GS.get("type_share_ships_gulf_tanker", np.nan)
    c_share = GS.get("type_share_ships_gulf_cargo", np.nan)
    page = OnePager(
        headline=f"{100 * t_share:.0f}% of tankers sail in Gulf waters, against {100 * c_share:.0f}% of cargo ships; "
                 "passenger and government ships cluster at a few ports",
        subhead="Distinct ships of each type per 25 km hexagon, 2023 and 2024 together (each map has its own shading)",
        source=SRC + " Types from the AIS ship-type code: tanker 80-89, cargo 70-79, passenger 60-69, "
                     "military 35, law enforcement 55.",
        theme="ntia", layout="grid2x2", size=(11, 8.4),
        alt="Four hexagon maps of where tankers, cargo ships, passenger ships, and military and law enforcement "
            "ships go; tankers concentrate on the Gulf coast, cargo ships on all three coasts.")
    for i, (key, title) in enumerate(names):
        rr = [r for r in rows if r["type"] == key]
        x = np.array([float(r["x_km"]) for r in rr])
        y = np.array([float(r["y_km"]) for r in rr])
        n = np.array([int(r["ships"]) for r in rr])
        nt = GS.get(f"type_ships_{key}", 0)
        ax = page.panel(i, title=f"{title} ({nt:,} ships)", grid=None)
        vf.base_map(page, ax, US)
        q = np.quantile(n, [0, 0.5, 0.8, 0.95, 0.99])
        edges = list(np.unique(q)) + [1e9]
        cols = np.array(page.theme.ramp)[-len(edges) + 1:] if len(edges) - 1 < 5 else np.array(page.theme.ramp)
        o = np.argsort(n)
        ax.add_collection(PolyCollection(hex_polys(x[o], y[o]), facecolors=cols[ramp_index(n[o], edges)],
                                         edgecolors="none", zorder=2))
    vf.save(page, "geo07_ship_types")


# G8. Land distance to the nearest route ----------------------------------------
def geo_land_distance():
    d = np.load(os.path.join(VIZ, "geo_land_distance.npz"))
    lat, lon, km = d["lat"], d["lon"], d["dist_km"]
    LON, LAT = np.meshgrid(lon, lat)
    x, y = vf.alb(LON.ravel(), LAT.ravel())
    x, y = x.reshape(LAT.shape), y.reshape(LAT.shape)
    page = OnePager(
        headline="Away from the coasts, only the Great Lakes and a few deep rivers bring large-ship routes inland",
        subhead="Distance from each point of U.S. land to the nearest large-ship route cell",
        source=SRC + " Land: Census cartographic boundary states, 2023 (0.05 degree grid).",
        theme="ntia", layout="hero", size=(11, 7.6),
        alt="Map of the lower 48 states shaded by distance to the nearest large-ship route: dark bands along the "
            "coasts, the Great Lakes, the Hudson, Columbia, Sacramento, and lower Mississippi rivers; light in "
            "the interior.")
    ax = page.panel(0, grid=None)
    ax.set_aspect("equal")
    ax.set_axis_off()
    edges = [0, 25, 50, 100, 200, 1e9]
    cols = np.array(page.theme.ramp[::-1])
    idx = np.where(np.isnan(km), -1, ramp_index(np.nan_to_num(km), edges))
    for i, col in enumerate(cols):
        m = idx == i
        ax.scatter(x[m] / 1, y[m] / 1, s=1.1, marker="s", linewidths=0, color=col, rasterized=True)
    ax.set_xlim(US[0], US[1])
    ax.set_ylim(US[2], US[3])
    labels = ["0-25 km", "25-50", "50-100", "100-200", "Over 200"]
    for i, (lab, col) in enumerate(zip(labels, cols)):
        ax.add_patch(Rectangle((-2850 + i * 500, 120), 490, 70, facecolor=col, edgecolor="none", zorder=5))
        ax.text(-2850 + i * 500 + 245, 70, lab, ha="center", va="top", fontsize=9, color=page.theme.text)
    ax.text(-2850, 230, "Distance to the nearest large-ship route", fontsize=10, fontweight="bold",
            color=page.theme.text)
    vf.save(page, "geo08_land_distance")


# G9. Fixed S-band sites over the hex grid --------------------------------------
def geo_sites():
    sites = read("viz_sites.csv")
    raw = list(csv.DictReader(open(os.path.join(vf.ROOT, "outputs", "2023_2024",
                                                "shipping_zone_2023_2024_sites.csv"))))
    rac = [(s, r) for s, r in zip(sites, raw) if r["category"] == "racon"]
    sb = np.array([float(s["route_km"]) for s, r in rac if r["sband_source"] == "1"])
    page = OnePager(
        headline=f"{int((sb <= 5).sum())} of {len(sb)} charted S-band racons and 9 of 10 VTS areas sit within 5 km "
                 "of a large-ship route",
        subhead="Racons and Coast Guard Vessel Traffic Service areas over the large-ship hexagon grid",
        source=SRC + " Racons: NOAA ENC Direct (S-band = charted wavelength 0.10 m). VTS: U.S. Coast Guard.",
        theme="ntia", layout="hero", size=(11, 7.6),
        alt="Map of large-ship hexagons in light blue with racons and VTS areas marked; the S-band racons and VTS "
            "areas sit on the busiest lanes, except VTS Louisville on the Ohio River.")
    ax = page.panel(0, grid=None)
    vf.base_map(page, ax, US)
    ax.add_collection(PolyCollection(hex_polys(HX, HY), facecolors=page.theme.ramp[1], edgecolors="none", zorder=2))
    for s, r in rac:
        x, y = vf.alb(float(r["lon"]), float(r["lat"]))
        is_s = r["sband_source"] == "1"
        ax.scatter(x, y, s=28 if is_s else 14, marker="o", color=page.theme.text if is_s else page.theme.context,
                   edgecolors="white", linewidths=0.6, zorder=4)
    for r in raw:
        if r["category"] == "vts_area":
            x, y = vf.alb(float(r["lon"]), float(r["lat"]))
            ax.scatter(x, y, s=60, marker="^", color=page.theme.accent2, edgecolors="white", linewidths=0.6, zorder=5)
    ax.scatter(-2800, 330, s=28, color=page.theme.text, edgecolors="white")
    ax.text(-2760, 330, "Charted S-band racon", va="center", fontsize=9.5, color=page.theme.text)
    ax.scatter(-2800, 230, s=14, color=page.theme.context, edgecolors="white")
    ax.text(-2760, 230, "Other racon (X-band or not charted)", va="center", fontsize=9.5, color=page.theme.text)
    ax.scatter(-2800, 130, s=60, marker="^", color=page.theme.accent2, edgecolors="white")
    ax.text(-2760, 130, "VTS area", va="center", fontsize=9.5, color=page.theme.text)
    vf.save(page, "geo09_sband_sites")


if __name__ == "__main__":
    geo_hex()
    geo_spikes()
    geo_closeups()
    geo_offshore_bands()
    geo_profile()
    geo_ports()
    geo_types()
    geo_land_distance()
    geo_sites()
