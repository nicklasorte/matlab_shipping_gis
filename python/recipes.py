"""recipes.py: chart recipes for onepager.py pages.

Each function draws into an Axes made with `page.panel()` and follows the page's
theme: gray context, one accent, direct labels, no legends. Functions that
compute a number from your data return it, so the headline can quote the value
instead of a typed copy.

    from onepager import OnePager
    import recipes

    page = OnePager("...", layout="hero-bottom3", ...)
    share = recipes.cdf_exceedance(page, page.panel(1, "Exceedance"), samples, threshold=1.5)

Recipes:
    cdf_exceedance    Share of samples above each level, with a threshold.
    coverage_heatmap  Gridded field on the theme's sequential ramp, with a threshold contour.
    zones_map         Zones as polygons, no extra libraries.
    zones_map_geo     Zones from a GeoDataFrame, with an optional light basemap.
    time_series       Lines with shaded event periods and direct labels.
    range_bars        Median and a range (such as 5th to 95th percentile) per scenario.
"""

from __future__ import annotations

import warnings

import matplotlib.dates as mdates
import numpy as np
from matplotlib import patheffects as pe
from matplotlib.colors import to_rgba
from matplotlib.patches import Polygon

__all__ = ["cdf_exceedance", "coverage_heatmap", "zones_map", "zones_map_geo",
           "time_series", "range_bars"]


def _pct_ticks(ax):
    ax.set_yticks([0, 25, 50, 75, 100], labels=[f"{v}%" for v in (0, 25, 50, 75, 100)])


def _halo(text_artist):
    """White outline so a label stays readable over a map or heat map."""
    text_artist.set_path_effects([pe.withStroke(linewidth=3, foreground="white")])


def _clean_map_axes(ax):
    ax.set_xticks([])
    ax.set_yticks([])
    ax.grid(False)
    for spine in ax.spines.values():
        spine.set_visible(False)


# --------------------------------------------------------------------------

def cdf_exceedance(page, ax, samples, threshold, limit_label="Limit", note=None):
    """Plot the share of samples above each level and mark a threshold.

    Use an exceedance curve when the question is "how often does it go over X".
    Returns the percentage of samples above the threshold.
    """
    t = page.theme
    x = np.sort(np.asarray(samples, dtype=float))
    n = len(x)
    share = 100 * (1 - np.arange(1, n + 1) / n)
    ax.step(np.r_[x[0], x], np.r_[100, share], where="post", color=t.accent, lw=2.6, zorder=3)
    above = float(100 * np.mean(x > threshold))
    page.ref_line(ax, threshold, axis="x", text=limit_label)
    ax.set_xlim(0 if x[0] >= 0 else x[0], x[-1])
    ax.set_ylim(0, 100)
    _pct_ticks(ax)
    text = note or f"{above:.0f}% exceed the {limit_label.lower()}"
    # The text sits at a fixed spot inside the panel so it can't spill into a neighbor.
    page.note(ax, text, xy=(threshold, above), xytext=(0.45, 0.5), coords="data",
              textcoords="axes fraction", wrap=16)
    return above


def coverage_heatmap(page, ax, x, y, field, threshold=None, vmin=None, vmax=None,
                     cbar_label=None, cbar_ticks=None, diverging=False, equal_aspect=False,
                     cbar_box=(0.70, 0.08, 0.26, 0.035)):
    """Draw a gridded field on the theme's ramp, with one contour at the threshold.

    x and y are 1-D axes (or 2-D meshes) and field has shape (len(y), len(x)).
    Never use a rainbow map: the ramp runs light to dark in one hue. Pass
    diverging=True only when the midpoint means something, such as zero change.
    """
    t = page.theme
    cmap = t.diverging_cmap() if diverging else t.cmap()
    im = ax.pcolormesh(x, y, field, cmap=cmap, vmin=vmin, vmax=vmax, shading="auto",
                       rasterized=True)
    if threshold is not None:
        ax.contour(x, y, field, levels=[threshold], colors=[t.text], linewidths=1.6)
    if equal_aspect:
        ax.set_aspect("equal")
        ax.set_anchor("NW")  # keep the map under its panel title
    _clean_map_axes(ax)
    cax = ax.inset_axes(list(cbar_box))
    cb = page.fig.colorbar(im, cax=cax, orientation="horizontal")
    if cbar_ticks is not None:
        cb.set_ticks(cbar_ticks)
    cb.outline.set_visible(False)
    cax.tick_params(length=0, labelsize=t.tick_pt, colors=t.text)
    if cbar_label:
        cax.text(0.0, 2.8, cbar_label, transform=cax.transAxes, ha="left", va="bottom",
                 fontsize=t.label_pt, fontweight="bold", color=t.text)
    return im


def zones_map(page, ax, zones, highlight=None, labels=True, pad=0.05):
    """Draw zones as polygons. zones maps a name to a list of (x, y) vertices.

    Context zones are gray and the highlighted zones use the accent. Coordinates
    are planar (for example meters in a projected CRS); the aspect is kept equal.
    """
    t = page.theme
    hi = {highlight} if isinstance(highlight, str) else set(highlight or [])
    xs, ys = [], []
    for name, ring in zones.items():
        pts = np.asarray(ring, dtype=float)
        on = name in hi
        color = t.accent if on else t.context
        ax.add_patch(Polygon(pts, closed=True, facecolor=to_rgba(color, 0.38 if on else 0.22),
                             edgecolor=color, linewidth=2.0 if on else 1.2,
                             zorder=3 if on else 2))
        xs += list(pts[:, 0])
        ys += list(pts[:, 1])
    dx, dy = (max(xs) - min(xs)) * pad, (max(ys) - min(ys)) * pad
    ax.set_xlim(min(xs) - dx, max(xs) + dx)
    ax.set_ylim(min(ys) - dy, max(ys) + dy)
    ax.set_aspect("equal")
    ax.set_anchor("NW")  # keep the map's left edge on the panel title and page margin
    _clean_map_axes(ax)
    if labels:
        for name, ring in zones.items():
            cx, cy = np.asarray(ring, dtype=float).mean(axis=0)
            txt = ax.text(cx, cy, name, ha="center", va="center", fontsize=t.label_pt,
                          fontweight="bold" if name in hi else "normal", color=t.text, zorder=5)
            _halo(txt)


def zones_map_geo(page, ax, gdf, name_col, highlight=None, basemap=True, labels=True,
                  crs="EPSG:3857", pad=0.05, attribution_size=8):
    """Draw zones from a GeoDataFrame over an optional light basemap.

    Needs geopandas, and contextily for the basemap (pip install geopandas
    contextily). Tiles download from the internet. If they can't, the zones
    still draw and a warning explains why. Keep the basemap attribution: it is
    a license condition, and the source line should credit the map data too.
    """
    try:
        import geopandas  # noqa: F401
    except ImportError as exc:
        raise ImportError("zones_map_geo needs geopandas: pip install geopandas contextily") from exc
    t = page.theme
    hi = {highlight} if isinstance(highlight, str) else set(highlight or [])
    g = gdf.to_crs(crs)
    for name, row in g.groupby(name_col):
        on = name in hi
        color = t.accent if on else t.context
        row.plot(ax=ax, facecolor=to_rgba(color, 0.38 if on else 0.22), edgecolor=color,
                 linewidth=2.0 if on else 1.2, zorder=3 if on else 2)
    minx, miny, maxx, maxy = g.total_bounds
    dx, dy = (maxx - minx) * pad, (maxy - miny) * pad
    ax.set_xlim(minx - dx, maxx + dx)
    ax.set_ylim(miny - dy, maxy + dy)
    ax.set_aspect("equal")
    ax.set_anchor("NW")
    if basemap:
        try:
            import contextily as cx
            cx.add_basemap(ax, crs=g.crs, source=cx.providers.CartoDB.PositronNoLabels,
                           attribution_size=attribution_size, zorder=0)
        except Exception as exc:  # no network, or contextily missing
            warnings.warn(f"Basemap skipped ({type(exc).__name__}: {exc}). Zones drawn without tiles.")
    _clean_map_axes(ax)
    if labels:
        for _, row in g.iterrows():
            pt = row.geometry.representative_point()
            txt = ax.text(pt.x, pt.y, str(row[name_col]), ha="center", va="center",
                          fontsize=t.label_pt,
                          fontweight="bold" if row[name_col] in hi else "normal",
                          color=t.text, zorder=5)
            _halo(txt)


def time_series(page, ax, x, series, highlight=None, events=(), fmt=None):
    """Lines with direct labels and shaded event periods.

    x can be numbers or dates. events is a list of (start, end, label). Set the
    y limits before calling if you need specific ones; end labels use them.
    """
    t = page.theme
    for start, end, label in events:
        ax.axvspan(start, end, color=t.context, alpha=0.16, linewidth=0, zorder=0)
        ax.text(start, 1.0, " " + label, transform=ax.get_xaxis_transform(), va="top", ha="left",
                fontsize=t.label_pt, fontweight="bold", color=t.text)
    page.lines(ax, x, series, highlight=highlight, fmt=fmt)
    first = x[0]
    if not isinstance(first, (int, float, np.integer, np.floating)):
        # An explicit locator avoids AutoDateLocator's "unable to pick an interval" warning
        # when minticks/maxticks are narrowed.
        span_days = float(mdates.date2num(x[-1]) - mdates.date2num(x[0]))
        if span_days > 6 * 365:
            locator = mdates.YearLocator(base=max(1, round(span_days / 365 / 5)))
        elif span_days > 1.25 * 365:
            locator = mdates.MonthLocator(bymonth=(1, 7))
        else:
            locator = mdates.AutoDateLocator()
        ax.xaxis.set_major_locator(locator)
        ax.xaxis.set_major_formatter(mdates.ConciseDateFormatter(locator))


def range_bars(page, ax, labels, low, mid, high, highlight=None, fmt="{:,.0f}",
               range_label="5th to 95th percentile", sort=True):
    """One bar per scenario for the spread of a Monte Carlo or forecast result.

    The bar runs from low to high and the dot marks the middle value (the
    median). A single worst case hides the spread; this shows it. Panels made
    for this recipe look best with page.panel(i, grid="x").
    """
    t = page.theme
    rows = list(zip(labels, low, mid, high))
    if sort:
        rows.sort(key=lambda r: r[2], reverse=True)
    hi = {highlight} if isinstance(highlight, str) else set(highlight or [])
    for i, (lab, lo, md, hg) in enumerate(rows):
        on = lab in hi
        ax.hlines(i, lo, hg, color=t.accent if on else t.context, linewidth=7, capstyle="round",
                  zorder=2)
        ax.plot([md], [i], "o", markersize=9, markerfacecolor="white", markeredgecolor=t.text,
                markeredgewidth=1.6, zorder=4)
        ax.annotate(fmt.format(md), (md, i), xytext=(0, 11), textcoords="offset points",
                    ha="center", va="bottom", fontsize=t.label_pt,
                    fontweight="bold" if on else "normal", color=t.text)
    ax.set_yticks(range(len(rows)), labels=[r[0] for r in rows])
    ax.set_ylim(len(rows) - 0.4, -0.9)
    ax.spines["left"].set_visible(False)
    ax.set_xlabel(f"Dot: median. Bar: {range_label}.", fontsize=t.tick_pt, labelpad=8)
