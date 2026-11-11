"""Draw the river and ship-channel figures: how far up each corridor large ships go.

Run python/ship_viz_products.py and python/ship_corridor_products.py first.
Writes PNG, PDF, SVG, and alt text to docs/viz_python/:
  corr01_reach_by_corridor   ships at the entrance and at the head port, every corridor
  corr02_profiles            small multiples: distinct ships along each corridor
  corr03_normalized_profiles all corridors on one chart, distance and ships normalized
  corr_<name>                one page per corridor: route map and profile
The MATLAB versions are drawn by init_ship_corridors_rev1.m.

Usage (from the repo root):
  MPLBACKEND=Agg python3 python/ship_corridor_figures.py
"""
import csv
import os
import sys

import numpy as np
from matplotlib.collections import PolyCollection
import matplotlib.patheffects as pe

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from onepager import OnePager  # noqa: E402
import ship_viz_figures as vf  # noqa: E402

VIZ = vf.VIZ
SRC = vf.SRC_AIS + " Distance is measured along the large-ship route cells from the entrance."
EDGES = [1, 10, 50, 200, 500, 1e9]
LABELS = ["1-9", "10-49", "50-199", "200-499", "500+"]


def read(name):
    with open(os.path.join(VIZ, name)) as f:
        return list(csv.DictReader(f))


SUMM = {r["corridor"]: r for r in read("corridor_summary.csv")}
ORDER = list(SUMM)                       # file order = config order
PROF, MARKS, CELLS, PATH = {}, {}, {}, {}
for r in read("corridor_profile.csv"):
    PROF.setdefault(r["corridor"], []).append(((float(r["km_from"]) + float(r["km_to"])) / 2, int(r["ships"])))
for r in read("corridor_marks.csv"):
    MARKS.setdefault(r["corridor"], []).append(r)
for r in read("corridor_cells.csv"):
    CELLS.setdefault(r["corridor"], []).append((float(r["lat"]), float(r["lon"]), int(r["ships"])))
for r in read("corridor_path.csv"):
    PATH.setdefault(r["corridor"], []).append((float(r["lat"]), float(r["lon"])))


def share(c):
    s = SUMM[c]
    return int(s["ships_head"]) / int(s["ships_entrance"])


def end_mark(c):
    return [m for m in MARKS[c] if m["role"] == "end"][0]


def short_of(c):
    """km by which the route cells stop short of the end port (0 if they reach it)."""
    m = end_mark(c)
    return float(m["off_path_km"]) if float(m["off_path_km"]) > 5 else 0.0


# C1. Reach by corridor ---------------------------------------------------------
def corr_reach():
    order = sorted(ORDER, key=share)
    n_half = sum(share(c) < 0.5 for c in ORDER)
    page = OnePager(
        headline=f"On {n_half} of {len(ORDER)} rivers and ship channels, fewer than half of the large ships "
                 "at the entrance reach the head port",
        subhead="Distinct large ships within 3 km of the entrance and of the head port, 104 sampled days in 2023 and 2024",
        source=SRC + " Entrance counts include ships bound for other ports near the entrance.",
        theme="ntia", layout="hero", size=(11, 7.8),
        alt="Dot chart with one row per river or ship channel, showing distinct large ships at the entrance (gray) "
            "and at the head port (blue); the gap is largest on the James, Hudson, Sacramento, Mississippi, "
            "Delaware, and Houston corridors.")
    ax = page.panel(0, grid="x")
    y = np.arange(len(order))
    ent = np.array([int(SUMM[c]["ships_entrance"]) for c in order])
    head = np.array([int(SUMM[c]["ships_head"]) for c in order])
    ax.hlines(y, head, ent, color=page.theme.grid, lw=3, zorder=1)
    ax.scatter(ent, y, s=60, color=page.theme.context, zorder=2)
    ax.scatter(head, y, s=60, color=page.theme.accent, zorder=3)
    labs = []
    for c in order:
        s = SUMM[c]
        end = end_mark(c)["name"]
        extra = f" (routes end {short_of(c):.0f} km short)" if short_of(c) else ""
        to = "" if end in s["label"] else f" to {end}"
        labs.append(f"{s['label']}{to}{extra}, {float(s['length_km']):.0f} km")
    ax.set_yticks(y, labs, fontsize=9.5)
    for yi, h, e, c in zip(y, head, ent, order):
        ax.text(e + 40, yi, f"{100 * share(c):.0f}% reach the head", va="center", fontsize=9, color=page.theme.text)
    ax.set_xlim(0, ent.max() * 1.32)
    ax.set_ylim(-0.7, len(order) - 0.3)
    ax.set_xlabel("Distinct large ships")
    i = int(np.argmax(ent - head))   # widest gap has room for the two labels
    ax.text(ent[i], y[i] + 0.42, "At the entrance", ha="center", va="center", fontsize=9.5, color=page.theme.text)
    ax.text(head[i], y[i] + 0.42, "At the head port", ha="center", va="center", fontsize=9.5,
            color=page.theme.accent, fontweight="bold")
    vf.save(page, "corr01_reach_by_corridor")
    return n_half


# C2. Small multiples --------------------------------------------------------------
def corr_profiles():
    order = sorted(ORDER, key=lambda c: -float(SUMM[c]["length_km"]))
    page = OnePager(
        headline="Large-ship traffic falls off step by step as each river or channel passes its ports",
        subhead="Distinct large ships (vertical axis) in each reach of each corridor (2 km reaches under 120 km long, 5 km otherwise), "
                "2023 and 2024 together; each panel has its own scale",
        source=SRC, theme="ntia", layout="hero", size=(11, 8.6),
        alt="Fifteen small step charts, one per river or ship channel, each showing distinct large ships against "
            "distance from the entrance; every profile steps down past the ports along the way.")
    host = page.panel(0, grid=None)
    host.set_axis_off()
    nc, nr = 5, 3
    for i, c in enumerate(order):
        ax = host.inset_axes([(i % nc) * 0.205, 0.69 - (i // nc) * 0.345, 0.175, 0.23])
        km, n = map(np.array, zip(*PROF[c]))
        ax.fill_between(km, n, step="mid", color=page.theme.ramp[1], lw=0)
        ax.step(km, n, where="mid", color=page.theme.accent, lw=1.4)
        ax.set_ylim(0, n.max() * 1.15)
        yt = ax.get_yticks()
        ax.set_yticks([t for t in yt if 0 < t <= n.max() * 1.15])
        xt = ax.get_xticks()
        ax.set_xticks([t for t in xt if 0 < t <= float(SUMM[c]["length_km"]) * 1.03])
        ax.set_xlim(0, float(SUMM[c]["length_km"]) * 1.03)
        ax.set_title(SUMM[c]["label"], fontsize=9.5, loc="left", color=page.theme.text, fontweight="bold")
        ax.tick_params(labelsize=8, colors=page.theme.text, length=0)
        for sp in ("top", "right"):
            ax.spines[sp].set_visible(False)
        for sp in ("left", "bottom"):
            ax.spines[sp].set_color(page.theme.grid)
        if i // nc == nr - 1:
            ax.set_xlabel("km from entrance", fontsize=8.5, color=page.theme.text)
    vf.save(page, "corr02_profiles")


# C2b. All corridors on one normalized chart ---------------------------------------
def corr_normalized():
    """Distance as a share of corridor length, ships as a share of ships at the entrance."""
    tiers = [(0.5, "Most ships reach the head (over 50%)", "#5674C4"),
             (0.15, "Some reach the head (15-50%)", "#6E4F92"),
             (0.0, "Few reach the head (under 15%)", "#163353")]

    def tier(v):
        return next(t for t in tiers if v > t[0] or t[0] == 0.0)

    page = OnePager(
        headline="Mobile and Savannah keep 9 in 10 large ships to the head port; the Hudson and James keep fewer than 1 in 15",
        subhead="Distinct large ships in each reach as a share of ships at the entrance, against distance as a share "
                "of corridor length, 15 rivers and ship channels, 2023 and 2024 together",
        source=SRC + " Entrance counts include ships bound for other ports near the entrance.",
        theme="ntia", layout="hero", size=(11, 7.8), margin_right=2.3,
        alt="Fifteen step lines, one per river or ship channel, of large ships as a share of entrance traffic "
            "against distance as a share of corridor length, colored by how many reach the head port; Mobile and "
            "Savannah stay near 1 to the head, while the James, Hudson, Sacramento, and Mississippi fall to about "
            "0.1 or less.")
    ax = page.panel(0)
    ends = []
    for c in ORDER:
        L = float(SUMM[c]["length_km"])
        ent = int(SUMM[c]["ships_entrance"])
        km, n = map(np.array, zip(*PROF[c]))
        b = float(SUMM[c]["bin_km"])
        x = np.clip(np.append(km - b / 2, km[-1] + b / 2) / L, 0, 1)
        y = np.append(n, n[-1]) / ent
        v = int(SUMM[c]["ships_head"]) / ent
        col = tier(v)[2]
        ax.step(x, y, where="post", color=col, lw=1.4, alpha=0.85, zorder=2)
        ends.append((v, SUMM[c]["label"], col))
    ends.sort()
    gap = 0.058
    pos = []
    for v, _, _ in ends:
        pos.append(max(v, pos[-1] + gap) if pos else v)
    for (v, lab, col), py in zip(ends, pos):
        ax.plot([1.0, 1.03, 1.06], [v, v, py], color=col, lw=0.6, alpha=0.6, clip_on=False)
        ax.text(1.07, py, f"{lab} ({100 * v:.0f}%)", va="center", fontsize=9, clip_on=False, color=col, fontweight="bold")
    for i, (_, lab, col) in enumerate(tiers):
        ax.plot([0.02, 0.06], [1.58 - i * 0.07] * 2, color=col, lw=2.5)
        ax.text(0.075, 1.58 - i * 0.07, lab, va="center", fontsize=9.5, color=col, fontweight="bold")
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1.65)
    ax.set_yticks([0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.2])
    ax.set_xlabel("Distance from the entrance, as a share of the corridor length (0 = entrance, 1 = head port)")
    ax.set_ylabel("Large ships, as a share of ships at the entrance")
    vf.save(page, "corr03_normalized_profiles")


# C3. One page per corridor ---------------------------------------------------------
def corr_page(c):
    s = SUMM[c]
    km, n = map(np.array, zip(*PROF[c]))
    marks = MARKS[c]
    end = end_mark(c)
    pct = 100 * share(c)
    stop = short_of(c)
    if stop:
        head = (f"Large-ship routes on the {s['label']} stop {stop:.0f} km short of {end['name']}; "
                f"{int(s['ships_head']):,} ships reach the end of the routes")
    else:
        head = (f"{int(s['ships_head']):,} large ships reach {end['name']}, {float(end['km']):.0f} km from the "
                f"entrance: {pct:.0f}% of the {int(s['ships_entrance']):,} seen at the entrance")
    page = OnePager(
        headline=head,
        subhead=f"{s['label']}: distinct large ships per route cell (map) and per {float(s['bin_km']):g} km reach "
                f"(chart), 2023 and 2024 together ({int(s['ships_head_2023'])} at the head in 2023, "
                f"{int(s['ships_head_2024'])} in 2024)",
        source=SRC, theme="ntia", layout="map-left", size=(11, 6.4),
        alt=f"Map of the {s['label']} route cells shaded by distinct large ships, and a step chart of ships against "
            f"distance from the entrance; {int(s['ships_entrance']):,} ships at the entrance and "
            f"{int(s['ships_head']):,} at {end['name']}.")
    # Map
    ax = page.panel(0, grid=None)
    la, lo, sh = map(np.array, zip(*CELLS[c]))
    pts = np.array([[float(m["lat"]), float(m["lon"])] for m in marks])
    a0, a1 = min(la.min(), pts[:, 0].min()), max(la.max(), pts[:, 0].max())
    o0, o1 = min(lo.min(), pts[:, 1].min()), max(lo.max(), pts[:, 1].max())
    pad = 0.12 * max(a1 - a0, (o1 - o0) * np.cos(np.radians(a0)))
    a0, a1, o0, o1 = a0 - pad, a1 + pad, o0 - pad / np.cos(np.radians(a0)), o1 + pad / np.cos(np.radians(a0))
    land = LAND
    ax.add_collection(PolyCollection(land, facecolor=page.theme.panel, edgecolor="white", linewidth=0.5))
    ax.set_xlim(o0, o1)
    ax.set_ylim(a0, a1)
    ax.set_aspect(1 / np.cos(np.radians((a0 + a1) / 2)))
    ax.set_xticks([])
    ax.set_yticks([])
    for sp in ax.spines.values():
        sp.set_color(page.theme.grid)
    # context: all route cells in view
    rc = vf.Z["route_cells"]
    lat0, lon0, d, nr, _ = vf.GRID
    rl = lat0 + d * ((rc - 1) % int(nr) + 0.5)
    ro = lon0 + d * ((rc - 1) // int(nr) + 0.5)
    v = (rl > a0) & (rl < a1) & (ro > o0) & (ro < o1)
    page.fig.canvas.draw()
    side = max(ax.get_window_extent().width / page.fig.dpi * 72 * d / (o1 - o0), 1.2)
    ax.scatter(ro[v], rl[v], s=side ** 2, marker="s", linewidths=0, color="#D5D7DA", zorder=2, rasterized=True)
    cols = np.array(page.theme.ramp)[np.clip(np.searchsorted(EDGES, sh, side="right") - 1, 0, 4)]
    oo = np.argsort(sh)
    ax.scatter(lo[oo], la[oo], s=side ** 2, marker="s", linewidths=0, c=cols[oo], zorder=3, rasterized=True)
    placed = []
    for m in marks:
        if m["role"] == "target":
            continue
        ml, mo = float(m["lat"]), float(m["lon"])
        clash = any(abs(ml - pl) < 0.06 * (a1 - a0) and abs(mo - po) < 0.5 * (o1 - o0) for pl, po in placed)
        placed.append((ml, mo))
        ax.plot(float(m["lon"]), float(m["lat"]), "o", ms=5, mfc="white", mec=page.theme.text, zorder=4)
        right = float(m["lon"]) > (o0 + o1) / 2
        ax.text(mo, ml - (0.12 * (a1 - a0) if clash else 0), (m["name"] + "  ") if right else ("  " + m["name"]), fontsize=9,
                color=page.theme.text, zorder=5, va="center", ha="right" if right else "left",
                path_effects=[pe.withStroke(linewidth=3, foreground="white")])
    for i, (lab, col) in enumerate(zip(LABELS, page.theme.ramp)):
        ax.scatter([], [], s=40, marker="s", color=col, label=lab)
    ax.legend(title="Distinct ships per cell (gray: other large-ship routes)", fontsize=8.5, title_fontsize=9,
              loc="upper left", bbox_to_anchor=(0, -0.01), ncol=5, frameon=False, handletextpad=0.2,
              columnspacing=0.8, alignment="left")
    # Profile
    ax = page.panel(1)
    ax.fill_between(km, n, step="mid", color=page.theme.ramp[1], lw=0)
    ax.step(km, n, where="mid", color=page.theme.accent, lw=2)
    top = n.max()
    for m in marks:
        if m["role"] in ("start", "target") or (m["role"] == "end" and stop):
            continue
        k = float(m["km"])
        ax.axvline(k, color=page.theme.text, lw=0.9, ls="--")
        ax.text(k, top * 1.04, m["name"], rotation=90, fontsize=9, color=page.theme.text, ha="right", va="bottom")
    ax.set_xlim(0, float(s["length_km"]) * 1.04)
    ax.set_ylim(0, top * 1.35)
    ax.set_xlabel("Distance from the entrance along the route (km)")
    ax.set_ylabel("Distinct large ships")
    vf.save(page, f"corr_{c}")


def main():
    global LAND
    import shapefile
    sf = shapefile.Reader(vf.STATES)
    LAND = []
    for shp in sf.shapes():
        pts = np.array(shp.points)
        parts = list(shp.parts) + [len(pts)]
        LAND += [pts[a:b] for a, b in zip(parts[:-1], parts[1:])]
    corr_reach()
    corr_profiles()
    corr_normalized()
    for c in ORDER:
        corr_page(c)


LAND = []
if __name__ == "__main__":
    main()
