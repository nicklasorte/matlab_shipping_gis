"""Ten figures on how large-ship port visits split among the deep-draft ports.

Run python/ship_port_share_products.py first. Writes PNG, PDF, SVG, and alt
text to docs/viz_python/ (share01 ... share10). The MATLAB versions are drawn
by init_port_share_rev1.m.

  share01_treemap          treemap: coast, then port, area = share of visits
  share02_circle_pack      packed circles, one per port, area = visits
  share03_pareto           top 25 ports, bars plus running total
  share04_concentration    cumulative share against number of ports
  share05_waffle           100 squares, each 1% of visits, by port complex
  share06_marimekko        top 12 complexes: width = share, height = ship-type mix
  share07_sunburst         rings: coast, complex, port
  share08_dorling          Dorling map: non-overlapping circles at the ports
  share09_coast_bars       100% bars: how each coast's visits split among its ports
  share10_years            share in 2023 against 2024, top 15 ports (dumbbell)

Usage (from the repo root):
  MPLBACKEND=Agg python3 python/ship_port_share_figures.py
"""
import csv
import os
import sys

import numpy as np
import matplotlib.patheffects as pe
from matplotlib.patches import Circle, Rectangle, Wedge

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from onepager import OnePager  # noqa: E402
import ship_viz_figures as vf  # noqa: E402

VIZ = vf.VIZ
SRC = (vf.SRC_AIS + " Port visits = distinct large ships seen within 10 km of a deep-draft port (each 1 km "
       "cell assigned to its nearest port); a ship that calls at two ports counts at both.")
COAST_COLOR = {"Gulf": "#163353", "Atlantic": "#5674C4", "Pacific": "#6E4F92", "Great Lakes": "#9A6B00"}
COASTS = ["Gulf", "Atlantic", "Pacific", "Great Lakes"]
TYPES = ["tanker", "cargo", "passenger", "government"]
TYPE_LABEL = {"tanker": "Tankers", "cargo": "Cargo and container", "passenger": "Passenger",
              "government": "Military and law enforcement", "other": "Other large ships and tug-barges"}
TYPE_COLOR = {"tanker": "#163353", "cargo": "#5674C4", "passenger": "#6E4F92", "government": "#9A6B00",
              "other": "#C9CBCE"}


def read(name):
    with open(os.path.join(VIZ, name)) as f:
        return list(csv.DictReader(f))


P = read("port_share.csv")
for r in P:
    for k in ("ships", "ships_2023", "ships_2024", "cargo", "tanker", "passenger", "government", "rank"):
        r[k] = int(r[k])
    for k in ("share", "lat", "lon"):
        r[k] = float(r[k])
CX = read("port_share_complex.csv")
for r in CX:
    r["visits"] = int(r["visits"])
    r["share"] = float(r["share"])
TOTAL = sum(r["ships"] for r in P)
COAST_SHARE = {c: sum(r["ships"] for r in P if r["coast"] == c) / TOTAL for c in COASTS}
HALO = [pe.withStroke(linewidth=2.5, foreground="white")]


def pct(v, d=0):
    return f"{100 * v:.{d}f}%"


def text_color(fill):
    return "white" if fill in ("#163353", "#5674C4", "#6E4F92", "#9A6B00", "#3F5FA8") else "#163353"


def coast_key(page, ax, x0, y0, dy, transform=None, fs=9.5):
    tr = transform or ax.transAxes
    for i, c in enumerate(COASTS):
        ax.add_patch(Rectangle((x0, y0 - i * dy - 0.012), 0.02, 0.024, transform=tr, color=COAST_COLOR[c],
                               clip_on=False))
        ax.text(x0 + 0.028, y0 - i * dy, f"{c} ({pct(COAST_SHARE[c])})", transform=tr, va="center", fontsize=fs,
                color=COAST_COLOR[c], fontweight="bold")


# Squarified treemap (Bruls, Huizing, and van Wijk 2000) ------------------------------
def squarify(values, x, y, w, h):
    """Rectangles (x, y, w, h) for values (sorted descending) filling the box."""
    vals = list(values)
    total = sum(vals)
    vals = [v * w * h / total for v in vals]
    out = []

    def worst(row, side):
        s = sum(row)
        return max(max(side * side * r / (s * s), (s * s) / (side * side * r)) for r in row)

    def layout(row, x, y, w, h):
        s = sum(row)
        rects = []
        if w >= h:   # column on the left
            cw = s / h
            yy = y
            for r in row:
                rh = r / cw
                rects.append((x, yy, cw, rh))
                yy += rh
            return rects, (x + cw, y, w - cw, h)
        rh = s / w   # row on the bottom
        xx = x
        for r in row:
            rw = r / rh
            rects.append((xx, y, rw, rh))
            xx += rw
        return rects, (x, y + rh, w, h - rh)

    row = []
    while vals:
        side = min(w, h)
        v = vals[0]
        if not row or worst(row + [v], side) <= worst(row, side):
            row.append(v)
            vals.pop(0)
        else:
            rects, (x, y, w, h) = layout(row, x, y, w, h)
            out += rects
            row = []
    if row:
        rects, _ = layout(row, x, y, w, h)
        out += rects
    return out


def share_treemap():
    top = P[0]
    page = OnePager(
        headline=f"Gulf ports take {pct(COAST_SHARE['Gulf'])} of large-ship port visits; Galveston alone takes "
                 f"{pct(top['share'])}",
        subhead="Share of large-ship port visits at the 73 deep-draft ports, grouped by coast, 2023 and 2024 "
                "together (area = share)",
        source=SRC, theme="ntia", layout="hero", size=(11, 7.8),
        alt="Treemap of the 73 deep-draft ports grouped into Gulf, Atlantic, Pacific, and Great Lakes blocks, each "
            "rectangle sized by its share of large-ship port visits; the Gulf block covers about half the area, "
            "led by Galveston, New Orleans, and Plaquemines.")
    ax = page.panel(0, grid=None)
    ax.set_axis_off()
    W, H = 1.6, 1.0
    labels = []
    coast_vals = [(c, COAST_SHARE[c]) for c in COASTS]
    boxes = squarify([v for _, v in coast_vals], 0, 0, W, H)
    for (c, _), (bx, by, bw, bh) in zip(coast_vals, boxes):
        ports = [r for r in P if r["coast"] == c]
        rects = squarify([r["ships"] for r in ports], bx, by, bw, bh)
        for r, (x, y, w, h) in zip(ports, rects):
            ax.add_patch(Rectangle((x, y), w, h, facecolor=COAST_COLOR[c], edgecolor="white", lw=1.2))
            labels.append((r, x, y, w, h))
        ax.add_patch(Rectangle((bx, by), bw, bh, fill=False, edgecolor="white", lw=4))
    ax.set_xlim(0, W)
    ax.set_ylim(0, H)
    ax.invert_yaxis()
    ax.set_aspect("equal")
    # Label a rectangle only where the label fits inside it (measured after drawing)
    page.fig.canvas.draw()
    inv = ax.transData.inverted()
    for r, x, y, w, h in labels:
        name = r["short"].split(" (")[0]
        for txt, fs in ((f"{name}\n{pct(r['share'], 1)}", 10), (f"{name}\n{pct(r['share'], 1)}", 8.5),
                        (f"{name.replace('-', '-' + chr(10), 1).replace(' ', chr(10), 1)}\n{pct(r['share'], 1)}", 8.5)):
            t = ax.text(x + 0.007, y + 0.007, txt, ha="left", va="top", fontsize=fs, color="white",
                        fontweight="bold")
            bb = t.get_window_extent(renderer=page.fig.canvas.get_renderer())
            (x0, y0), (x1, y1) = inv.transform([[bb.x0, bb.y0], [bb.x1, bb.y1]])
            if abs(x1 - x0) < w - 0.012 and abs(y1 - y0) < h - 0.012:
                break
            t.remove()
    xx = 0.0
    for c, nm in zip(COASTS, ["dark blue", "light blue", "purple", "ochre"]):
        t = ax.text(xx, -0.02, f"{c} ({nm}) {pct(COAST_SHARE[c])}", ha="left", va="bottom", fontsize=10,
                    color=COAST_COLOR[c], fontweight="bold")
        page.fig.canvas.draw()
        bb = t.get_window_extent(renderer=page.fig.canvas.get_renderer())
        xx = inv.transform([[bb.x1, bb.y0]])[0][0] + 0.04
    vf.save(page, "share01_treemap")


# Circle packing ------------------------------------------------------------------------
def pack_circles(radii):
    """Greedy packing: largest first, each circle at the tangent spot nearest the center."""
    pos = [(0.0, 0.0)]
    for i in range(1, len(radii)):
        r = radii[i]
        best = None
        cand = []
        for j in range(i):
            xj, yj = pos[j]
            for k in range(j, i):
                xk, yk = pos[k]
                if j == k:
                    for a in np.linspace(0, 2 * np.pi, 24, endpoint=False):
                        d = radii[j] + r
                        cand.append((xj + d * np.cos(a), yj + d * np.sin(a)))
                    continue
                # circles tangent to both j and k
                d1, d2 = radii[j] + r, radii[k] + r
                dx, dy = xk - xj, yk - yj
                d = np.hypot(dx, dy)
                if d == 0 or d > d1 + d2 or d < abs(d1 - d2):
                    continue
                a = (d1 * d1 - d2 * d2 + d * d) / (2 * d)
                hh = np.sqrt(max(d1 * d1 - a * a, 0))
                mx, my = xj + a * dx / d, yj + a * dy / d
                cand.append((mx + hh * dy / d, my - hh * dx / d))
                cand.append((mx - hh * dy / d, my + hh * dx / d))
        P_ = np.array(pos)
        R_ = np.array(radii[:i])
        for cx, cy in sorted(cand, key=lambda c: c[0] ** 2 + c[1] ** 2):
            if np.all(np.hypot(P_[:, 0] - cx, P_[:, 1] - cy) >= R_ + r - 1e-9):
                best = (cx, cy)
                break
        pos.append(best)
    return np.array(pos)


def share_circles():
    radii = [np.sqrt(r["ships"] / np.pi) for r in P]
    xy = pack_circles(radii)
    n10 = sum(r["share"] for r in P[:10])
    page = OnePager(
        headline=f"The 10 busiest deep-draft ports take {pct(n10)} of large-ship port visits; the other 63 share "
                 f"the rest",
        subhead="One circle per deep-draft port, area = distinct large ships within 10 km, 2023 and 2024 together, "
                "colored by coast",
        source=SRC, theme="ntia", layout="hero", size=(11, 7.8),
        alt="Packed circles, one per deep-draft port, sized by large-ship port visits and colored by coast; "
            "Galveston, New Orleans, and Plaquemines are the largest circles, and dozens of small circles ring them.")
    ax = page.panel(0, grid=None)
    ax.set_axis_off()
    for r, rad, (x, y) in zip(P, radii, xy):
        col = COAST_COLOR[r["coast"]]
        ax.add_patch(Circle((x, y), rad * 0.97, facecolor=col, edgecolor="white", lw=0.8))
        if rad > 17:
            name = r["short"].split(" (")[0].replace("New York-New Jersey", "New York-\nNew Jersey")
            if " " in name and len(name) > 10 and "\n" not in name:
                name = name.replace(" ", "\n", 1)
            ax.text(x, y, f"{name}\n{r['ships']:,}", ha="center", va="center", fontsize=8.5 if rad < 24 else 9.5,
                    color="white", fontweight="bold")
    m = np.max(np.abs(xy) + np.array(radii)[:, None]) * 1.02
    ax.set_xlim(-m * 1.45, m * 1.05)
    ax.set_ylim(-m, m)
    ax.set_aspect("equal")
    coast_key(page, ax, 0.0, 0.95, 0.06)
    vf.save(page, "share02_circle_pack")


def share_pareto():
    top = P[:25]
    cum = np.cumsum([r["share"] for r in P])
    n50 = int(np.searchsorted(cum, 0.5)) + 1
    page = OnePager(
        headline=f"Thirteen ports take half of all large-ship port visits; the busiest 25 take {pct(cum[24])}",
        subhead="Share of large-ship port visits, the 25 busiest deep-draft ports, with the running total, 2023 and "
                "2024 together",
        source=SRC, theme="ntia", layout="hero", size=(11, 8.2), margin_right=1.2,
        alt="Horizontal bar chart of the 25 busiest deep-draft ports by share of large-ship port visits, colored by "
            "coast, with the running total beside each bar; the running total passes 50% at the 13th port.")
    ax = page.panel(0, grid="x")
    y = np.arange(len(top))[::-1]
    ax.barh(y, [100 * r["share"] for r in top], color=[COAST_COLOR[r["coast"]] for r in top], height=0.72)
    ax.set_yticks(y, [r["short"] for r in top], fontsize=9.5)
    xmax = 100 * top[0]["share"] * 1.18
    for yi, r, c in zip(y, top, cum[:25]):
        ax.text(100 * r["share"] + 0.08, yi, pct(r["share"], 1), va="center", fontsize=9, color=page.theme.text)
        ax.text(xmax * 1.02, yi, pct(c), va="center", fontsize=9, color=page.theme.text,
                fontweight="bold" if abs(c - cum[n50 - 1]) < 1e-9 else "normal", clip_on=False)
    ax.text(xmax * 1.02, len(top) - 0.2, "Running\ntotal", va="bottom", fontsize=9, color=page.theme.text,
            clip_on=False)
    ax.axhline(y[n50 - 1] - 0.5, color=page.theme.text, lw=0.8, ls="--")
    ax.text(xmax * 0.98, y[n50 - 1] - 0.62, "Half of all visits above this line", ha="right", va="top", fontsize=9,
            color=page.theme.text)
    ax.set_xlim(0, xmax)
    ax.set_ylim(-0.7, len(top) - 0.3)
    ax.set_xlabel("Share of large-ship port visits (%)")
    coast_key(page, ax, 0.62, 0.42, 0.05)
    vf.save(page, "share03_pareto")
    return n50


def share_concentration():
    s = np.array([r["share"] for r in P])
    cum = np.concatenate([[0], np.cumsum(s)])
    n = np.arange(len(cum))
    n50 = int(np.searchsorted(cum, 0.5))
    n80 = int(np.searchsorted(cum, 0.8))
    page = OnePager(
        headline=f"Large-ship port visits are concentrated: {n50} of 73 deep-draft ports take half, and {n80} take "
                 f"four-fifths",
        subhead="Cumulative share of large-ship port visits, ports ranked from busiest to least busy, 2023 and 2024 "
                "together",
        source=SRC, theme="ntia", layout="hero", size=(11, 7.4),
        alt="Concentration curve rising steeply from zero: the cumulative share of large-ship port visits passes "
            "50% at the 13th port and 80% at the 30th, against a dashed line for an even split across 73 ports.")
    ax = page.panel(0)
    ax.plot([0, 73], [0, 100], color=page.theme.context, ls="--", lw=1)
    ax.text(50, 100 * 50 / 73 - 4, "Even split across all 73 ports", rotation=0, fontsize=9.5,
            color=page.theme.text, ha="left")
    ax.step(n, 100 * cum, where="post", color=page.theme.accent, lw=2.5)
    for k, lab in ((n50, "half"), (n80, "four-fifths")):
        ax.plot([k, k, 0], [0, 100 * cum[k], 100 * cum[k]], color=page.theme.text, lw=0.8, ls=":")
        ax.text(k + 1, 100 * cum[k] - 3, f"{k} ports take {lab} ({pct(cum[k])})", fontsize=10, va="top",
                color=page.theme.accent, fontweight="bold")
    ax.set_xlim(0, 73)
    ax.set_ylim(0, 102)
    ax.set_xlabel("Number of ports, busiest first")
    ax.set_ylabel("Cumulative share of large-ship port visits (%)")
    vf.save(page, "share04_concentration")


def share_waffle():
    top = CX[:8]
    cells = [(r["complex"], int(round(100 * r["share"]))) for r in top]
    other = 100 - sum(c for _, c in cells)
    cells.append(("All other ports", other))
    cols = ["#163353", "#3F5FA8", "#5674C4", "#7F96D3", "#6E4F92", "#9C82BC", "#9A6B00", "#C9A54A", "#D5D7DA"]
    page = OnePager(
        headline=f"Eight port complexes take {100 - other}% of large-ship port visits, led by the lower "
                 f"Mississippi ({pct(top[0]['share'])}) and Houston-Galveston ({pct(top[1]['share'])})",
        subhead="Each square = 1% of large-ship port visits at the 73 deep-draft ports, 2023 and 2024 together "
                "(complexes group neighboring ports)",
        source=SRC + " Shares rounded to whole squares.",
        theme="ntia", layout="hero", size=(11, 7.4),
        alt="Waffle chart of 100 squares, each 1% of large-ship port visits, colored by port complex; the lower "
            "Mississippi and Houston-Galveston fill 29 squares, and all other ports fill about a third.")
    ax = page.panel(0, grid=None)
    ax.set_axis_off()
    k = 0
    for (name, n), col in zip(cells, cols):
        for _ in range(n):
            r_, c_ = divmod(k, 10)
            ax.add_patch(Rectangle((c_, 9 - r_), 0.9, 0.9, facecolor=col, edgecolor="none"))
            k += 1
    for i, ((name, n), col) in enumerate(zip(cells, cols)):
        yy = 9.45 - i * 1.1
        ax.add_patch(Rectangle((11, yy - 0.35), 0.7, 0.7, facecolor=col))
        ax.text(12, yy, f"{name}: {n}%", va="center", fontsize=10.5, color=page.theme.text,
                fontweight="bold" if i < 2 else "normal")
    ax.set_xlim(0, 21)
    ax.set_ylim(-0.2, 10)
    ax.set_aspect("equal")
    vf.save(page, "share05_waffle")


def share_marimekko():
    top = CX[:12]
    comp_types = {}
    for c in top:
        rows = [r for r in P if r["complex"] == c["complex"]]
        tv = {t: sum(r[t] for r in rows) for t in TYPES}
        tv["other"] = sum(r["ships"] for r in rows) - sum(tv.values())
        comp_types[c["complex"]] = tv
    tot = sum(c["visits"] for c in top)
    tank = {c["complex"]: comp_types[c["complex"]]["tanker"] / c["visits"] for c in top}
    tmax = max(tank, key=tank.get)
    page = OnePager(
        headline=f"Tankers make up {pct(tank[tmax])} of large-ship visits at {tmax} and "
                 f"{pct(tank['Houston-Galveston'])} at Houston-Galveston; cargo and container ships lead everywhere "
                 f"else",
        subhead="The 12 busiest port complexes: width = share of their large-ship port visits, height = ship-type "
                "mix, 2023 and 2024 together",
        source=SRC + " Types from the AIS ship-type code (tanker 80-89, cargo 70-79, passenger 60-69, military 35, "
                     "law enforcement 55).",
        theme="ntia", layout="hero", size=(11, 7.8), margin_right=2.0,
        alt="Marimekko chart of the 12 busiest port complexes with column width set by share of port visits and "
            "column height split by ship type; tanker share is highest in the Gulf complexes and cargo share "
            "highest in the Atlantic and Pacific complexes.")
    ax = page.panel(0, grid=None)
    x = 0.0
    for c in top:
        w = c["visits"] / tot
        tv = comp_types[c["complex"]]
        y = 0.0
        for t in TYPES + ["other"]:
            h = tv[t] / c["visits"]
            ax.add_patch(Rectangle((x, y), w, h, facecolor=TYPE_COLOR[t], edgecolor="white", lw=1))
            y += h
        ax.text(x + w / 2, 0.015, c["complex"], rotation=90, ha="center", va="bottom", fontsize=9,
                color="white", fontweight="bold")
        if w > 0.035:
            ax.text(x + w / 2, 1.01, pct(c["visits"] / TOTAL), ha="center", va="bottom", fontsize=8.5,
                    color=page.theme.text)
        x += w
    ax.text(0, 1.06, "Share of all port visits:", fontsize=9, color=page.theme.text, va="bottom")
    for i, t in enumerate(TYPES + ["other"]):
        ax.add_patch(Rectangle((1.02, 0.92 - i * 0.08), 0.025, 0.05, facecolor=TYPE_COLOR[t], clip_on=False))
        ax.text(1.055, 0.945 - i * 0.08, TYPE_LABEL[t], va="center", fontsize=9, clip_on=False,
                color=page.theme.text)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.set_xticks([])
    ax.set_yticks([0, 0.25, 0.5, 0.75, 1], ["0%", "25%", "50%", "75%", "100%"])
    ax.set_ylabel("Share of the complex's large-ship visits")
    for sp in ("top", "right", "bottom"):
        ax.spines[sp].set_visible(False)
    vf.save(page, "share06_marimekko")


def share_sunburst():
    page = OnePager(
        headline="Nearly half of all large-ship port visits are at Gulf ports, and a third of those are on the "
                 "lower Mississippi",
        subhead="Rings from the center: coast, port complex, port; angle = share of large-ship port visits, 2023 and "
                "2024 together",
        source=SRC, theme="ntia", layout="hero", size=(11, 7.8),
        alt="Sunburst chart with coasts in the inner ring, port complexes in the middle ring, and ports in the outer "
            "ring, each sized by share of large-ship port visits; the Gulf takes about half the circle.")
    ax = page.panel(0, grid=None)
    ax.set_axis_off()
    ax.set_aspect("equal")
    a0 = 90.0
    gulf_lm = 0
    for c in COASTS:
        ports = [r for r in P if r["coast"] == c]
        cs = sum(r["ships"] for r in ports) / TOTAL
        col = COAST_COLOR[c]
        ax.add_patch(Wedge((0, 0), 1.0, a0 - 360 * cs, a0, width=0.45, facecolor=col, edgecolor="white", lw=1.5))
        mid = np.radians(a0 - 180 * cs)
        if cs > 0.05:
            ax.text(0.775 * np.cos(mid), 0.775 * np.sin(mid), f"{c}\n{pct(cs)}", ha="center", va="center",
                    fontsize=10, color="white", fontweight="bold", zorder=10)
        comps = []
        for cx in dict.fromkeys(r["complex"] for r in ports):
            comps.append((cx, [r for r in ports if r["complex"] == cx]))
        comps.sort(key=lambda t: -sum(r["ships"] for r in t[1]))
        b0 = a0
        for cx, rows in comps:
            v = sum(r["ships"] for r in rows) / TOTAL
            if cx == "Lower Mississippi":
                gulf_lm = v / cs
            ax.add_patch(Wedge((0, 0), 1.45, b0 - 360 * v, b0, width=0.43, facecolor=col, alpha=0.75,
                               edgecolor="white", lw=1))
            p0 = b0
            for r in sorted(rows, key=lambda r: -r["ships"]):
                pv = r["ships"] / TOTAL
                ax.add_patch(Wedge((0, 0), 1.75, p0 - 360 * pv, p0, width=0.28, facecolor=col, alpha=0.5,
                                   edgecolor="white", lw=0.6))
                if pv > 0.022:
                    m3 = np.radians(p0 - 180 * pv)
                    ang = np.degrees(m3)
                    left = 90 < ang % 360 < 270
                    ax.text(1.8 * np.cos(m3), 1.8 * np.sin(m3), r["short"], ha="right" if left else "left",
                            va="center", fontsize=9, color=page.theme.text, rotation=ang - 180 if left else ang,
                            rotation_mode="anchor")
                p0 -= 360 * pv
            b0 -= 360 * v
        a0 -= 360 * cs
    ax.set_xlim(-2.9, 2.9)
    ax.set_ylim(-2.75, 2.45)
    _ = gulf_lm
    vf.save(page, "share07_sunburst")


def share_dorling():
    x, y = vf.alb(np.array([r["lon"] for r in P]), np.array([r["lat"] for r in P]))
    x, y = np.asarray(x, float).copy(), np.asarray(y, float).copy()
    rad = np.sqrt(np.array([r["ships"] for r in P])) * 4.0   # km on the map
    x0, y0 = x.copy(), y.copy()
    for _ in range(400):   # push overlapping circles apart, pull gently home
        moved = False
        for i in range(len(P)):
            dx = x - x[i]
            dy = y - y[i]
            d = np.hypot(dx, dy)
            need = rad + rad[i] + 6
            j = np.where((d < need) & (np.arange(len(P)) != i))[0]
            for k in j:
                dd = max(d[k], 1e-6)
                push = (need[k] - dd) / 2
                ux, uy = dx[k] / dd, dy[k] / dd
                x[k] += ux * push
                y[k] += uy * push
                x[i] -= ux * push
                y[i] -= uy * push
                moved = True
        x += 0.02 * (x0 - x)
        y += 0.02 * (y0 - y)
        if not moved:
            break
    page = OnePager(
        headline="On a map, the Gulf ports from Corpus Christi to the Mississippi form the largest cluster of "
                 "large-ship port visits",
        subhead="Dorling map: one circle per deep-draft port, area = distinct large ships within 10 km, nudged apart "
                "so none overlap, 2023 and 2024 together",
        source=SRC, theme="ntia", layout="hero", size=(11, 7.6),
        alt="Map of the lower 48 states with one non-overlapping circle per deep-draft port, sized by large-ship "
            "port visits and colored by coast; the largest circles crowd the Texas and Louisiana coast.")
    ax = page.panel(0, grid=None)
    vf.base_map(page, ax, vf.US_EXTENT)
    for i in np.argsort(-rad):
        r = P[i]
        ax.add_patch(Circle((x[i], y[i]), rad[i], facecolor=COAST_COLOR[r["coast"]], edgecolor="white", lw=0.7,
                            alpha=0.92, zorder=3))
    lab_pos = {"Galveston": (-1, -1), "Houston": (-1, 1), "New Orleans": (1, 1), "Plaquemines": (1, -1),
               "South Louisiana": (0, 1), "Port Arthur": (0, 1), "New York-New Jersey": (1, 0),
               "Long Beach": (-1, 0), "Baltimore": (1, 0), "Sabine Pass": (0, -1)}
    for i in range(10):
        r = P[i]
        ux, uy = lab_pos.get(r["short"], (1, 0))
        k = 0.7071 if ux and uy else 1.0
        ex, ey = x[i] + ux * k * rad[i], y[i] + uy * k * rad[i]          # circle edge
        tx, ty = ex + ux * k * 55, ey + uy * k * 55
        ax.plot([ex, tx], [ey, ty], color=page.theme.text, lw=0.7, zorder=5)
        ax.text(tx + ux * 8, ty + uy * 8, r["short"], ha={1: "left", -1: "right", 0: "center"}[ux],
                va={1: "bottom", -1: "top", 0: "center"}[uy], fontsize=9, color=page.theme.text,
                fontweight="bold", zorder=5, path_effects=HALO)
    for k, (s_, lab) in enumerate(((2000, "2,000 ships"), (500, "500"))):
        rr = np.sqrt(s_) * 4.0
        cxk = -2700 + k * 330
        ax.add_patch(Circle((cxk, 250 + rr), rr, fill=False, edgecolor=page.theme.text, lw=0.8))
        ax.text(cxk, 250 + 2 * rr + 25, lab, ha="center", va="bottom", fontsize=9, color=page.theme.text)
    coast_key(page, ax, 0.86, 0.30, 0.05)
    vf.save(page, "share08_dorling")


def share_coast_bars():
    page = OnePager(
        headline="Galveston, New York, and Long Beach lead their coasts, but no port takes more than a sixth of "
                 "any ocean coast's large-ship visits",
        subhead="How each coast's large-ship port visits split among its ports (top five named), 2023 and 2024 "
                "together",
        source=SRC, theme="ntia", layout="hero", size=(11, 6.8),
        alt="Four 100% stacked horizontal bars, one per coast, each split into its five busiest ports and the rest; "
            "no port takes more than a sixth of any ocean coast's port visits.")
    ax = page.panel(0, grid=None)
    for i, c in enumerate(COASTS):
        ports = [r for r in P if r["coast"] == c]
        tot = sum(r["ships"] for r in ports)
        x = 0.0
        yy = len(COASTS) - 1 - i
        for j, r in enumerate(ports[:5]):
            w = r["ships"] / tot
            ax.add_patch(Rectangle((x, yy - 0.35), w, 0.7, facecolor=COAST_COLOR[c], alpha=1 - 0.13 * j,
                                   edgecolor="white", lw=1.5))
            if w > 0.075:
                name = r["short"].split(" (")[0]
                if len(name) > 12:
                    name = name.replace("-", "-\n", 1) if "-" in name else name.replace(" ", "\n", 1)
                ax.text(x + w / 2, yy, f"{name}\n{pct(w)}", ha="center", va="center", fontsize=8.5,
                        color="white" if j < 3 else page.theme.text, fontweight="bold")
            x += w
        ax.add_patch(Rectangle((x, yy - 0.35), 1 - x, 0.7, facecolor="#D5D7DA", edgecolor="white", lw=1.5))
        ax.text(x + (1 - x) / 2, yy, f"{len(ports) - 5} others\n{pct(1 - x)}" if len(ports) > 5 else "",
                ha="center", va="center", fontsize=8.5, color=page.theme.text)
        ax.text(0, yy + 0.4, f"{c}: {tot:,} port visits", ha="left", va="bottom", fontsize=10,
                color=COAST_COLOR[c], fontweight="bold")
    ax.set_xlim(0, 1)
    ax.set_ylim(-0.6, len(COASTS) - 0.2)
    ax.set_yticks([])
    ax.set_xticks([0, 0.25, 0.5, 0.75, 1], ["0%", "25%", "50%", "75%", "100%"])
    for sp in ("top", "right", "left"):
        ax.spines[sp].set_visible(False)
    vf.save(page, "share09_coast_bars")


def share_years():
    top = P[:15]
    t23 = sum(r["ships_2023"] for r in P)
    t24 = sum(r["ships_2024"] for r in P)
    s23 = np.array([r["ships_2023"] / t23 for r in top])
    s24 = np.array([r["ships_2024"] / t24 for r in top])
    ch = s24 - s23
    big = int(np.argmax(np.abs(ch)))
    page = OnePager(
        headline=f"Port shares barely moved between years; the largest shift among the top 15 is "
                 f"{100 * abs(ch[big]):.1f} points at {top[big]['short']}",
        subhead="Share of large-ship port visits in 2023 (open circle) and 2024 (filled circle), the 15 busiest "
                "deep-draft ports",
        source=SRC, theme="ntia", layout="hero", size=(11, 7.6), margin_right=0.8,
        alt="Dumbbell chart of the 15 busiest deep-draft ports, each row joining its share of large-ship port visits "
            "in 2023 to its share in 2024; most pairs nearly touch.")
    ax = page.panel(0, grid="x")
    y = np.arange(len(top))[::-1]
    for yi, r, a_, b_, c_ in zip(y, top, s23, s24, ch):
        col = COAST_COLOR[r["coast"]]
        ax.plot([100 * a_, 100 * b_], [yi, yi], color=col, lw=2.2, zorder=2)
        ax.scatter([100 * a_], [yi], s=55, facecolor="white", edgecolor=col, lw=1.8, zorder=3)
        ax.scatter([100 * b_], [yi], s=55, color=col, zorder=4)
        ax.text(100 * max(a_, b_) + 0.12, yi, f"{round(100 * c_, 1) + 0.0:+.1f} pts".replace("+0.0", "0.0"), va="center", fontsize=9, color=col,
                fontweight="bold")
    ax.set_yticks(y, [r["short"] for r in top], fontsize=9.5)
    ax.set_xlim(0, 100 * max(s23.max(), s24.max()) * 1.15)
    ax.set_ylim(-0.7, len(top) - 0.3)
    ax.set_xlabel("Share of large-ship port visits (%)")
    coast_key(page, ax, 0.7, 0.42, 0.05)
    vf.save(page, "share10_years")


def main():
    share_treemap()
    share_circles()
    share_pareto()
    share_concentration()
    share_waffle()
    share_marimekko()
    share_sunburst()
    share_dorling()
    share_coast_bars()
    share_years()


if __name__ == "__main__":
    main()
