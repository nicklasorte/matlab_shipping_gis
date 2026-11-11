"""onepager.py: build a polished one-page data visualization with matplotlib.

A page has four parts: an optional marking, a takeaway headline with a
subhead, a grid of chart panels, and a source footer. The grid is chosen from
a few layouts. Panels use a gray-plus-one-accent style: context marks in gray,
the one mark that proves the headline in the accent color, direct labels
instead of legends.

Minimal use:

    from onepager import OnePager
    page = OnePager(
        headline="Zone A costs four times more than Zone B",
        subhead="Estimated annual cost by zone, millions of dollars",
        source="Source: Example agency analysis (2026).",
        theme="modern",            # or "ntia"
        layout="hero",
        alt="Bar chart of annual cost by zone. Zone A is highest.",
    )
    ax = page.panel(0)
    page.bars(ax, ["Zone A", "Zone B", "Zone C"], [40, 10, 22], highlight="Zone A")
    page.save("zone_cost")          # writes PNG, PDF, SVG, and a metadata file

The module sets matplotlib rcParams for the session when you create a page.
Call `reset_rcparams()` to restore the defaults.
"""

from __future__ import annotations

import json
import textwrap
from dataclasses import dataclass
from pathlib import Path

import matplotlib as mpl
import matplotlib.dates as mdates
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.collections import QuadMesh
from matplotlib.colors import LinearSegmentedColormap, to_hex, to_rgb
from matplotlib.patches import Rectangle
from matplotlib.text import Text

__all__ = ["OnePager", "THEMES", "Theme", "contrast_ratio", "reset_rcparams"]

_DEFAULT_RC = dict(mpl.rcParams)


# --------------------------------------------------------------------------
# Color math (shared with review.py)
# --------------------------------------------------------------------------

def _linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def relative_luminance(color) -> float:
    r, g, b = (_linear(v) for v in to_rgb(color))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast_ratio(fg, bg) -> float:
    """WCAG contrast ratio between two colors."""
    a, b = relative_luminance(fg), relative_luminance(bg)
    hi, lo = max(a, b), min(a, b)
    return (hi + 0.05) / (lo + 0.05)


# --------------------------------------------------------------------------
# Themes
# --------------------------------------------------------------------------

@dataclass(frozen=True)
class Theme:
    name: str
    font_family: str
    font_stack: tuple
    bg: str
    text: str
    muted: str          # secondary text
    accent: str         # the one highlight
    accent2: str        # second highlight or alert
    context: str        # gray for context marks
    grid: str
    panel: str          # tile fill
    ramp: tuple         # sequential colors, light to dark
    div: tuple          # diverging colors: low, middle, high
    headline_pt: float
    sub_pt: float
    panel_title_pt: float
    label_pt: float
    tick_pt: float
    source_pt: float
    kpi_pt: float
    min_pt: float
    marking: str | None
    bold_accent_text: bool
    margin_in: float

    def cmap(self, name: str | None = None) -> LinearSegmentedColormap:
        """Sequential colormap, light to dark."""
        return LinearSegmentedColormap.from_list(name or f"{self.name}_seq", list(self.ramp))

    def diverging_cmap(self, name: str | None = None) -> LinearSegmentedColormap:
        """Diverging colormap. Use only when the midpoint means something."""
        return LinearSegmentedColormap.from_list(name or f"{self.name}_div", list(self.div))


THEMES = {
    "modern": Theme(
        name="modern",
        font_family="sans-serif",
        font_stack=("Inter", "Helvetica Neue", "Arial", "Liberation Sans", "DejaVu Sans"),
        bg="#FFFFFF",
        text="#1B2433",
        muted="#4B5565",
        accent="#2457D6",
        accent2="#C2410C",
        context="#828C9B",
        grid="#E5E8EC",
        panel="#F2F4F7",
        ramp=("#E8EEFB", "#BDCDF3", "#7FA0E6", "#2F63D8", "#14306F"),
        div=("#C2410C", "#F2F4F7", "#2457D6"),
        headline_pt=24,
        sub_pt=12.5,
        panel_title_pt=11.5,
        label_pt=10,
        tick_pt=9.5,
        source_pt=8.5,
        kpi_pt=30,
        min_pt=8,
        marking=None,
        bold_accent_text=False,
        margin_in=0.65,
    ),
    # NTIA palette and rules from the slide-design skill: dark blue text, mid
    # gray context, light blue highlight, purple second highlight, Times,
    # 11 pt dark blue source line, DRAFT//PRE-DECISIONAL marking.
    "ntia": Theme(
        name="ntia",
        font_family="serif",
        font_stack=("Times New Roman", "Times", "Liberation Serif", "DejaVu Serif"),
        bg="#FFFFFF",
        text="#163353",
        muted="#163353",
        accent="#5674C4",
        accent2="#6E4F92",
        context="#8A8D91",
        grid="#E6E6E6",
        panel="#E8E9EA",
        ramp=("#E4E9F6", "#B4C2E6", "#7F96D3", "#3F5FA8", "#163353"),
        div=("#6E4F92", "#E8E9EA", "#163353"),
        headline_pt=24,
        sub_pt=13,
        panel_title_pt=12,
        label_pt=10.5,
        tick_pt=10,
        source_pt=11,
        kpi_pt=30,
        min_pt=8,
        marking="DRAFT//PRE-DECISIONAL",
        bold_accent_text=True,
        margin_in=0.65,
    ),
}


def reset_rcparams() -> None:
    """Restore the matplotlib defaults that were active when this module loaded."""
    mpl.rcParams.update(_DEFAULT_RC)


# --------------------------------------------------------------------------
# Layouts: name -> (nrows, ncols, height_ratios, width_ratios, slots(gs))
# --------------------------------------------------------------------------

LAYOUTS = {
    "hero": (1, 1, None, None, lambda g: [g[0, 0]]),
    "hero-right2": (2, 3, None, None, lambda g: [g[:, :2], g[0, 2], g[1, 2]]),
    "hero-bottom3": (2, 3, [1.8, 1], None, lambda g: [g[0, :], g[1, 0], g[1, 1], g[1, 2]]),
    "grid2x2": (2, 2, None, None, lambda g: [g[0, 0], g[0, 1], g[1, 0], g[1, 1]]),
    "kpi3-hero": (2, 3, [0.55, 1.8], None, lambda g: [g[0, 0], g[0, 1], g[0, 2], g[1, :]]),
    "kpi3-hero-bottom2": (
        3, 6, [0.75, 1.5, 0.95], None,
        lambda g: [g[0, 0:2], g[0, 2:4], g[0, 4:6], g[1, :], g[2, 0:3], g[2, 3:6]],
    ),
}


# --------------------------------------------------------------------------
# The page
# --------------------------------------------------------------------------

class OnePager:
    """One page: header, panel grid, footer."""

    def __init__(
        self,
        headline: str,
        subhead: str | None = None,
        source: str | None = None,
        theme: str | Theme = "modern",
        layout: str = "hero",
        size: tuple[float, float] = (11.0, 8.5),
        kicker: str | None = None,
        footer_right: str | None = None,
        alt: str | None = None,
        margin_right: float | None = None,
        marking: str | None | bool = True,
        gap_h_in: float = 0.7,
        gap_w_in: float = 0.65,
    ):
        """Create a page.

        headline: one sentence that states the takeaway.
        subhead: what is plotted, with units.
        source: footer text, such as "Source: NTIA analysis of ... (2026)."
        theme: "modern", "ntia", or a Theme.
        layout: one of LAYOUTS.
        size: page size in inches. Default is US letter, landscape.
        kicker: short label above the headline (modern theme only).
        footer_right: short text at the right of the footer, such as "Preliminary".
        alt: alt text that states the takeaway and the chart type.
        margin_right: extra right margin in inches, for direct labels at line ends.
        marking: True uses the theme's marking, a string overrides it, False or
            None removes it.
        gap_h_in, gap_w_in: space between panel rows and columns, in inches.
        """
        if layout not in LAYOUTS:
            raise ValueError(f"layout must be one of {sorted(LAYOUTS)}")
        self.theme = THEMES[theme] if isinstance(theme, str) else theme
        self.layout = layout
        self.headline = headline
        self.alt = alt
        self._apply_rc()

        t = self.theme
        W, H = size
        self.fig = plt.figure(figsize=size, dpi=100, facecolor=t.bg)
        self._W, self._H = W, H
        m = t.margin_in
        mr = m + (margin_right or 0.0)
        self._ml, self._mr = m, mr

        if marking is True:
            self.marking = t.marking
        elif marking:
            self.marking = str(marking)
        else:
            self.marking = None

        avail_in = W - m - mr
        cy = 0.3  # inches from the top of the page

        if self.marking:
            art = self._text(m, cy, self.marking, fontsize=9, fontweight="bold", color=t.text)
            cy += self._height_in(art) + 0.14
        if kicker and t.name == "modern":
            art = self._text(m, cy, kicker.upper(), fontsize=9, fontweight="bold", color=t.accent)
            cy += self._height_in(art) + 0.08
        art = self._fit(headline, m, cy, avail_in, fontsize=t.headline_pt, fontweight="bold",
                        color=t.text,
                        linespacing=1.0 if t.font_family == "sans-serif" else 1.08)
        cy += self._height_in(art) + 0.1
        if subhead:
            art = self._fit(subhead, m, cy, avail_in, fontsize=t.sub_pt, color=t.muted,
                            linespacing=1.2)
            cy += self._height_in(art) + 0.05
        top_gap = 0.3 if layout.startswith("kpi") else 0.5  # panel titles need room above
        self._content_top = 1 - (cy + top_gap) / H

        fy = 0.28  # inches from the bottom
        fh = 0.0
        right_w = 0.0
        if footer_right:
            art = self.fig.text((W - mr) / W, fy / H, footer_right, ha="right", va="bottom",
                                fontsize=t.source_pt, color=t.text, fontweight="bold")
            right_w = self._width_in(art) + 0.3
        if source:
            art = self._fit(source, m, None, avail_in - right_w, fontsize=t.source_pt,
                            color=t.text, bottom_in=fy)
            fh = self._height_in(art)
        elif footer_right:
            fh = 0.15
        self._content_bottom = (fy + fh + 0.5) / H

        nrows, ncols, hr, wr, slots = LAYOUTS[layout]
        # GridSpec spacing is a fraction of the average panel size; convert from inches.
        content_h = (self._content_top - self._content_bottom) * H
        content_w = W - m - mr
        avg_h = max((content_h - gap_h_in * (nrows - 1)) / nrows, 0.5)
        avg_w = max((content_w - gap_w_in * (ncols - 1)) / ncols, 0.5)
        self._gs = self.fig.add_gridspec(
            nrows, ncols, left=m / W, right=1 - mr / W,
            top=self._content_top, bottom=self._content_bottom,
            hspace=gap_h_in / avg_h if nrows > 1 else 0,
            wspace=gap_w_in / avg_w if ncols > 1 else 0,
            height_ratios=hr, width_ratios=wr,
        )
        self._fitted = False
        self._slots = slots(self._gs)
        self._axes: dict[int, plt.Axes] = {}

    # ---- rc and text helpers ------------------------------------------------

    def _apply_rc(self) -> None:
        t = self.theme
        mpl.rcParams.update({
            "font.family": t.font_family,
            f"font.{t.font_family}": list(t.font_stack),
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
            "axes.unicode_minus": False,
            "text.color": t.text,
            "axes.labelcolor": t.text,
            "xtick.color": t.text,
            "ytick.color": t.text,
        })

    def _renderer(self):
        return self.fig.canvas.get_renderer()

    def _bbox_px(self, art):
        return Text.get_window_extent(art, self._renderer())

    def _height_in(self, art) -> float:
        return self._bbox_px(art).height / self.fig.dpi

    def _width_in(self, art) -> float:
        return self._bbox_px(art).width / self.fig.dpi

    def _text(self, x_in, y_top_in, s, **kw):
        return self.fig.text(x_in / self._W, 1 - y_top_in / self._H, s, ha="left", va="top", **kw)

    def _fit(self, s, x_in, y_top_in, width_in, bottom_in=None, **kw):
        """Place wrapped text with the most characters per line that still fit width_in."""
        pt = kw.get("fontsize", 10)
        lo, hi = 8, max(12, int(width_in * 72 / (pt * 0.3)))
        best = lo
        while lo <= hi:
            mid = (lo + hi) // 2
            art = self._place(s, mid, x_in, y_top_in, bottom_in, **kw)
            fits = self._width_in(art) <= width_in + 0.01
            art.remove()
            if fits:
                best, lo = mid, mid + 1
            else:
                hi = mid - 1
        # Balance the lines: use the narrowest wrap that keeps the same line count,
        # so the last line isn't a single orphaned word.
        n_lines = len(textwrap.wrap(s, best))
        while best > 8 and len(textwrap.wrap(s, best - 1)) == n_lines:
            best -= 1
        return self._place(s, best, x_in, y_top_in, bottom_in, **kw)

    def _place(self, s, n, x_in, y_top_in, bottom_in, **kw):
        txt = "\n".join(textwrap.wrap(s, n)) or s
        if bottom_in is not None:
            return self.fig.text(x_in / self._W, bottom_in / self._H, txt, ha="left",
                                 va="bottom", **kw)
        return self._text(x_in, y_top_in, txt, **kw)

    # ---- panels ---------------------------------------------------------------

    def panel(self, i: int, title: str | None = None, grid: str | None = "y") -> plt.Axes:
        """Return a styled Axes for slot i. grid is "x", "y", "both", or None."""
        t = self.theme
        ax = self.fig.add_subplot(self._slots[i])
        self._axes[i] = ax
        ax.set_facecolor(t.bg)
        for side in ("top", "right", "left"):
            ax.spines[side].set_visible(False)
        ax.spines["bottom"].set_color(t.context)
        ax.spines["bottom"].set_linewidth(0.9)
        ax.tick_params(length=0, labelsize=t.tick_pt, colors=t.text, pad=5)
        ax.set_axisbelow(True)
        if grid:
            ax.grid(axis="both" if grid == "both" else grid, color=t.grid, linewidth=0.8)
        if title:
            ax.set_title(title, loc="left", fontsize=t.panel_title_pt, fontweight="bold",
                         color=t.text, pad=10)
        return ax

    def kpi(self, i: int, value: str, label: str, sub: str | None = None,
            accent: bool = False) -> plt.Axes:
        """Fill slot i with a big-number tile."""
        t = self.theme
        ax = self.fig.add_subplot(self._slots[i])
        self._axes[i] = ax
        ax.set_axis_off()
        tile = Rectangle((0, 0), 1, 1, transform=ax.transAxes, facecolor=t.panel,
                         edgecolor="none", zorder=0, gid="tile")
        ax.add_patch(tile)
        ax.text(0.07, 0.64, value, transform=ax.transAxes, fontsize=t.kpi_pt, fontweight="bold",
                color=t.accent if accent else t.text, va="center", ha="left")
        ax.text(0.07, 0.27 if sub else 0.25, label, transform=ax.transAxes,
                fontsize=t.label_pt + 0.5, color=t.text, va="center", ha="left")
        if sub:
            ax.text(0.07, 0.09, sub, transform=ax.transAxes, fontsize=t.min_pt + 0.5,
                    color=t.text, va="center", ha="left")
        return ax

    # ---- chart helpers ------------------------------------------------------------

    def bars(self, ax, labels, values, highlight=None, horizontal=True, sort=True,
             fmt="{:,.0f}", pad=0.16):
        """Gray bars with one or more highlighted bars and value labels. Values must be >= 0."""
        t = self.theme
        pairs = list(zip(labels, values))
        if sort:
            pairs.sort(key=lambda p: p[1], reverse=True)
        labs = [p[0] for p in pairs]
        vals = np.array([p[1] for p in pairs], dtype=float)
        hi = {highlight} if isinstance(highlight, str) else set(highlight or [])
        cols = [t.accent if lab in hi else t.context for lab in labs]
        vmax = float(vals.max()) if len(vals) else 1.0
        pos = np.arange(len(vals))
        if horizontal:
            out = ax.barh(pos, vals, color=cols, height=0.62, zorder=2)
            ax.set_yticks(pos, labels=labs)
            ax.invert_yaxis()
            ax.set_xlim(0, vmax * (1 + pad))
            ax.xaxis.set_visible(False)
            ax.spines["bottom"].set_visible(False)
            ax.spines["left"].set_visible(True)
            ax.spines["left"].set_color(t.context)
            ax.grid(False)
            for p, v, lab in zip(pos, vals, labs):
                ax.text(v + vmax * 0.015, p, fmt.format(v), va="center", ha="left",
                        fontsize=t.label_pt, fontweight="bold" if lab in hi else "normal",
                        color=t.text)
        else:
            out = ax.bar(pos, vals, color=cols, width=0.62, zorder=2)
            ax.set_xticks(pos, labels=labs)
            ax.set_ylim(0, vmax * (1 + pad))
            ax.yaxis.set_visible(False)
            ax.grid(False)
            for p, v, lab in zip(pos, vals, labs):
                ax.text(p, v + vmax * 0.015, fmt.format(v), va="bottom", ha="center",
                        fontsize=t.label_pt, fontweight="bold" if lab in hi else "normal",
                        color=t.text)
        return out

    def lines(self, ax, x, series: dict, highlight=None, fmt=None, end_labels=True):
        """Gray lines with one or more highlighted lines and direct end labels.

        Direct labels need room on the right: pass margin_right to OnePager.
        """
        t = self.theme
        hi = {highlight} if isinstance(highlight, str) else set(highlight or [])
        for name, y in series.items():
            if name not in hi:
                ax.plot(x, y, color=t.context, lw=1.7, solid_capstyle="round", zorder=2)
        for name, y in series.items():
            if name in hi:
                ax.plot(x, y, color=t.accent, lw=2.9, solid_capstyle="round", zorder=3)
        if end_labels:
            # Push labels apart so close line ends don't overlap. This uses the
            # current y limits, so set them before calling lines().
            ax.autoscale_view()
            dpi = ax.figure.dpi
            min_gap = t.label_pt * 1.35 * dpi / 72
            try:
                x_end = float(x[-1])
            except (TypeError, ValueError):  # dates
                x_end = mdates.date2num(x[-1])
            ends = sorted(
                (ax.transData.transform((x_end, y[-1]))[1], name) for name, y in series.items()
            )
            placed = [py for py, _ in ends]
            for _ in range(60):  # relax: push apart only the neighbors that collide
                moved = False
                for i in range(1, len(placed)):
                    gap = placed[i] - placed[i - 1]
                    if gap < min_gap - 0.5:
                        d = (min_gap - gap) / 2
                        placed[i] += d
                        placed[i - 1] -= d
                        moved = True
                if not moved:
                    break
            y_lo, y_hi = ax.bbox.y0 + min_gap / 2, ax.bbox.y1  # keep labels inside the axes
            placed = [min(max(p, y_lo), y_hi) for p in placed]
            offsets = {name: (new - py) * 72 / dpi
                       for (py, name), new in zip(ends, placed)}
            for name, y in series.items():
                label = name if not fmt else f"{name}  {fmt.format(y[-1])}"
                ax.annotate(label, (x[-1], y[-1]), xytext=(7, offsets[name]),
                            textcoords="offset points",
                            va="center", ha="left", fontsize=t.label_pt,
                            fontweight="bold" if name in hi else "normal",
                            color=t.accent if name in hi else t.text, annotation_clip=False)

    def ref_line(self, ax, value, axis="y", text=None):
        """Dashed reference line, such as a threshold, with a label."""
        t = self.theme
        style = dict(color=t.text, lw=1.1, ls=(0, (4, 3)), zorder=1.5)
        if axis == "y":
            ax.axhline(value, **style)
            if text:
                ax.text(1.0, value, text, transform=ax.get_yaxis_transform(), ha="right",
                        va="bottom", fontsize=t.label_pt, fontweight="bold", color=t.text)
        else:
            ax.axvline(value, **style)
            if text:
                ax.text(value, 1.0, " " + text, transform=ax.get_xaxis_transform(), ha="left",
                        va="top", fontsize=t.label_pt, fontweight="bold", color=t.text)

    def note(self, ax, text, xy, xytext=None, coords="data", ha="left", va="center",
             color=None, bold=True, wrap=26, textcoords=None):
        """Annotation on the chart. With xytext, draws a thin leader line to xy.

        coords sets the coordinate system for xy and, unless textcoords is given,
        for xytext too. Use textcoords="axes fraction" to keep the text inside
        a narrow panel while xy points at a data position.
        """
        t = self.theme
        color = color or t.text
        weight = "bold" if (bold or (color == t.accent and t.bold_accent_text)) else "normal"
        if wrap:
            text = "\n".join(textwrap.wrap(text, wrap))
        kw = dict(fontsize=t.label_pt, color=color, fontweight=weight, ha=ha, va=va,
                  linespacing=1.15)
        if xytext is None:
            return ax.annotate(text, xy, xycoords=coords, annotation_clip=False, **kw)
        return ax.annotate(
            text, xy, xytext=xytext, xycoords=coords, textcoords=textcoords or coords,
            annotation_clip=False,
            arrowprops=dict(arrowstyle="-", color=t.muted, lw=0.9, shrinkA=3, shrinkB=3), **kw)

    # ---- checks and export --------------------------------------------------------

    @staticmethod
    def _drawn_labels(axis):
        try:
            ticks = axis._update_ticks()  # private API; fall back if it changes
        except Exception:
            ticks = axis.get_major_ticks()
        return [tk.label1 for tk in ticks if tk.label1.get_visible()]

    def _fit_axes(self) -> None:
        """Shift first-column panels right so y tick labels start at the page margin.

        Without this, long category labels hang into the margin or off the page.
        The panel title moves with the labels so both stay on the margin line.
        """
        if self._fitted:
            return
        self._fitted = True
        fig = self.fig
        fig.canvas.draw()
        r = self._renderer()
        fw = fig.get_figwidth() * fig.dpi
        margin_px = self._ml * fig.dpi
        for ax in self._axes.values():
            if not ax.axison or abs(ax.get_position().x0 - self._ml / self._W) > 0.01:
                continue
            xs = [Text.get_window_extent(lab, r).x0
                  for lab in self._drawn_labels(ax.yaxis) if lab.get_text().strip()]
            if not xs:
                continue
            d = margin_px - min(xs)
            if d <= 1:
                continue
            pos = ax.get_position()
            new_w = pos.width - d / fw
            ax.set_position([pos.x0 + d / fw, pos.y0, new_w, pos.height])
            title = getattr(ax, "_left_title", None)
            if title is not None:
                title.set_x(-d / (new_w * fw))

    def lint(self) -> list[dict]:
        """Check the rendered page. Returns a list of {severity, message} issues."""
        t = self.theme
        fig = self.fig
        self._fit_axes()
        fig.canvas.draw()
        r = self._renderer()
        issues: list[dict] = []

        def add(sev, msg):
            issues.append({"severity": sev, "message": msg})

        drawn_tick_labels, all_tick_labels = set(), set()
        for ax in fig.axes:
            for axis in (ax.xaxis, ax.yaxis):
                for tick in axis.get_major_ticks() + axis.get_minor_ticks():
                    all_tick_labels.update((tick.label1, tick.label2))
                if not ax.axison or not axis.get_visible():
                    continue  # nothing is drawn for this axis
                try:
                    shown = axis._update_ticks()
                except Exception:  # private API; skip tick-label filtering if it changes
                    shown = []
                for tick in shown:
                    for lab in (tick.label1, tick.label2):
                        if lab.get_visible():
                            drawn_tick_labels.add(lab)

        items = []
        for txt in fig.findobj(Text):
            s = txt.get_text().strip()
            if not s or not txt.get_visible():
                continue
            if txt in all_tick_labels and txt not in drawn_tick_labels:
                continue
            bb = Text.get_window_extent(txt, r)
            if bb.width < 1 or bb.height < 1:
                continue
            items.append((txt, s, bb))

        fw, fh = fig.get_figwidth() * fig.dpi, fig.get_figheight() * fig.dpi
        for txt, s, bb in items:
            short = s.replace("\n", " ")[:40]
            size = txt.get_fontsize()
            if size < t.min_pt - 0.01:
                add("error", f"Text '{short}' is {size:.1f} pt; the minimum is {t.min_pt:g} pt.")
            if bb.x0 < -1 or bb.y0 < -1 or bb.x1 > fw + 1 or bb.y1 > fh + 1:
                add("error", f"Text '{short}' runs off the page edge.")
            elif (bb.x0 < 0.35 * fig.dpi or bb.x1 > fw - 0.35 * fig.dpi
                  or bb.y0 < 0.2 * fig.dpi or bb.y1 > fh - 0.2 * fig.dpi):
                add("warn", f"Text '{short}' sits inside the page margin.")
            weight = txt.get_fontweight()
            bold = weight in ("bold", "heavy", "black") or (isinstance(weight, (int, float)) and weight >= 600)
            large = size >= 18 or (size >= 14 and bold)
            need = 3.0 if large else 4.5
            cr = contrast_ratio(txt.get_color(), t.bg)
            if cr < need:
                if t.bold_accent_text and bold and txt.get_color() == t.accent:
                    pass  # brand rule: light blue text is allowed when bold
                else:
                    add("error", f"Text '{short}' has contrast {cr:.2f}:1; needs {need}:1.")

        for a in range(len(items)):
            for b in range(a + 1, len(items)):
                _, sa, ba = items[a]
                _, sb, bb_ = items[b]
                ix = min(ba.x1, bb_.x1) - max(ba.x0, bb_.x0)
                iy = min(ba.y1, bb_.y1) - max(ba.y0, bb_.y0)
                if ix > 1 and iy > 1:
                    smaller = min(ba.width * ba.height, bb_.width * bb_.height)
                    if ix * iy / smaller > 0.08:
                        add("error", "Text overlaps: '%s' and '%s'." % (
                            sa.replace("\n", " ")[:30], sb.replace("\n", " ")[:30]))

        for ax in fig.axes:
            if ax.get_legend() is not None:
                add("advice", "A legend is present. Prefer direct labels on the marks.")

        for color in sorted(self._mark_colors()):
            cr = contrast_ratio(color, t.bg)
            if cr < 3.0:
                add("warn", f"Mark color {color} has contrast {cr:.2f}:1; marks need 3:1.")

        if not self.alt:
            add("warn", "No alt text. Pass alt= with the takeaway and the chart type.")
        return issues

    def _mark_colors(self) -> set[str]:
        cols: set[str] = set()
        for ax in self.fig.axes:
            for ln in ax.lines:
                if ln.get_linestyle() in ("None", "none", "", " "):  # marker-only line
                    c = ln.get_markeredgecolor()
                    if not isinstance(c, str) or c.lower() in ("auto", "none"):
                        c = ln.get_markerfacecolor()
                else:
                    c = ln.get_color()
                if isinstance(c, str) and c.lower() in ("none", "auto"):
                    continue
                cols.add(to_hex(c).upper())
            for p in ax.patches:
                if p.get_gid() == "tile" or p.get_facecolor()[3] < 1:
                    continue
                cols.add(to_hex(p.get_facecolor(), keep_alpha=False).upper())
            for coll in ax.collections:
                if isinstance(coll, QuadMesh):
                    continue  # a continuous color scale, not a set of discrete marks
                fcs = {to_hex(fc, keep_alpha=False).upper() for fc in coll.get_facecolor()
                       if fc[3] == 1}
                if len(fcs) <= 12:  # more than that means a colormapped scatter or field
                    cols.update(fcs)
        return cols

    def save(self, basename: str, formats=("png", "pdf", "svg"), dpi: int = 300,
             quiet: bool = False) -> dict:
        """Write the page in each format plus <basename>.meta.json and <basename>.alt.txt.

        Returns the metadata dict. Prints any lint issues unless quiet is True.
        """
        base = Path(basename)
        base.parent.mkdir(parents=True, exist_ok=True)
        issues = self.lint()
        alt = self.alt or f"{self.headline} (chart type not specified)"
        paths = {}
        for fmt in formats:
            path = base.with_suffix(f".{fmt}")
            kw: dict = {}
            if fmt == "png":
                kw["metadata"] = {"Title": self.headline, "Description": alt}
            elif fmt == "pdf":
                kw["metadata"] = {"Title": self.headline, "Subject": alt}
            elif fmt == "svg":
                kw["metadata"] = {"Title": self.headline, "Description": alt}
            # No bbox_inches="tight": it changes the page size.
            self.fig.savefig(path, dpi=dpi, facecolor=self.theme.bg, **kw)
            paths[fmt] = str(path)
        base.with_suffix(".alt.txt").write_text(alt + "\n", encoding="utf-8")

        sizes = sorted({round(t.get_fontsize(), 1) for t in self.fig.findobj(Text)
                        if t.get_text().strip() and t.get_visible()})
        meta = {
            "theme": self.theme.name,
            "layout": self.layout,
            "page_inches": [self._W, self._H],
            "dpi": dpi,
            "background": self.theme.bg,
            "marking": self.marking,
            "font_sizes_pt": sizes,
            "mark_colors": sorted(self._mark_colors()),
            "accent": self.theme.accent,
            "context": self.theme.context,
            "alt": alt,
            "alt_supplied": bool(self.alt),
            "files": paths,
            "lint": issues,
        }
        base.with_suffix(".meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
        if not quiet:
            for issue in issues:
                print(f"[{issue['severity']}] {issue['message']}")
            print(f"Saved {', '.join(paths.values())}")
        return meta
