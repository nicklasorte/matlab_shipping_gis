"""Figure 1: large-ship routes in the lower 48 states with the St. Lawrence to the Atlantic.

Python version of plot_routes_map_rev1.m (same projection, colors, and type), extended
east to Cabot Strait so the St. Lawrence route shows its whole length. Dark blue: the
lower-48 route cells (AIS, charted lanes, racons). Light blue: St. Lawrence cells from
Canadian and World Bank AIS density (python/st_lawrence_route.py).

Usage: python3 python/fig01_routes_lower48.py <census_state_shp> <natural_earth_dir>
Writes docs/viz_python/fig01_routes_lower48_rev1.png and .alt.txt.
"""
import os
import sys
import warnings

import geopandas as gpd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

warnings.filterwarnings("ignore")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DARK, LIGHT, LAND, OTHER, LINE = "#163353", "#5674C4", "#E8E9EA", "#F5F5F6", "#8A8D91"
ALB = "EPSG:5070"
plt.rcParams["font.family"] = ["Liberation Serif"]   # metric-compatible with Times New Roman
ALT = ("Map of the lower 48 states with large-ship routes in dark blue along the Atlantic, Gulf, and Pacific coasts, "
       "across the Great Lakes, and up a few deep rivers. A light blue route continues from Lake Ontario down the "
       "St. Lawrence River past Montreal and Québec City, through the Gulf of St. Lawrence, to Cabot Strait and the "
       "Atlantic, passing about 55 to 100 km north of Maine.")


def main(state_shp, ne_dir):
    st = gpd.read_file(state_shp)
    st = st[~st.STUSPS.isin(["AK", "HI", "PR", "VI", "GU", "MP", "AS"])].to_crs(ALB)
    ne = gpd.read_file(os.path.join(ne_dir, "ne_10m_admin_0_countries_lakes.shp"))
    other = ne[ne.ADMIN.isin(["Canada", "Mexico", "The Bahamas", "Cuba"])].cx[-140:-50, 15:56].to_crs(ALB)
    rt = gpd.read_file(os.path.join(ROOT, "outputs/2024_2025/shipping_zone_2024_2025_routes.shp")).to_crs(ALB)
    sl = gpd.read_file(os.path.join(ROOT, "outputs/foreign_waterways/st_lawrence_route_rev1.shp"))
    sl = sl[~sl.source.str.startswith("MarineCadastre")].to_crs(ALB)
    fig = plt.figure(figsize=(7.5, 5.9), dpi=300)
    ax = fig.add_axes([0.02, 0.10, 0.96, 0.76])
    other.plot(ax=ax, color=OTHER, edgecolor="#C9CBCE", lw=0.25)
    st.plot(ax=ax, color=LAND, edgecolor=LINE, lw=0.3)
    sl.plot(ax=ax, color=LIGHT, edgecolor=LIGHT, lw=0.35)
    rt.plot(ax=ax, color=DARK, edgecolor=DARK, lw=0.15)
    x0, y0, x1, y1 = rt.total_bounds
    sx0, sy0, sx1, sy1 = sl.total_bounds
    ax.set_xlim(x0 - 40e3, max(x1, sx1) + 40e3)
    ax.set_ylim(y0 - 40e3, max(y1, sy1) + 40e3)
    ax.set_aspect("equal")
    ax.set_axis_off()
    pt = gpd.GeoSeries.from_xy([-70.5, -78.5], [31.5, 49.2], crs=4326).to_crs(ALB)
    ax.text(pt.x[0], pt.y[0], "Large-ship routes\n(2024-2025 AIS)", color=DARK, fontsize=9, fontweight="bold", ha="center")
    ax.text(pt.x[1], pt.y[1], "St. Lawrence route\n(Canadian and World Bank\nAIS density)", color=LIGHT,
            fontsize=8, fontweight="bold", ha="center")
    xs, ys = ax.get_xlim()[0] + 80e3, ax.get_ylim()[0] + 60e3
    ax.plot([xs, xs + 500e3], [ys, ys], color=DARK, lw=1.5)
    ax.text(xs + 250e3, ys + 80e3, "500 km", color=DARK, fontsize=8, ha="center")
    fig.text(0.5, 0.975, "DRAFT//PRE-DECISIONAL", color=DARK, fontsize=8, fontweight="bold", ha="center")
    fig.text(0.02, 0.925, "Large ships stay on the coasts, the Great Lakes, the St. Lawrence,\nand a few deep rivers (2024-2025)",
             color=DARK, fontsize=12, fontweight="bold", va="center")
    fig.text(0.02, 0.012, "Source: NTIA analysis of MarineCadastre AIS (104 days in 2024-2025; merchant, military, tug-barge, and "
             "other seagoing ships 100 m or longer; 1 km cells used by 4 or more ships), NOAA shipping fairways and S-band racons, "
             "Fisheries and Oceans Canada AIS vessel density (2024), World Bank / IMF ship density (2015-2021), Census 2023 "
             "boundaries, and Natural Earth.", color=DARK, fontsize=7, wrap=True)
    out = os.path.join(ROOT, "docs", "viz_python", "fig01_routes_lower48_rev1")
    fig.savefig(out + ".png", facecolor="white", metadata={"Description": ALT})
    open(out + ".alt.txt", "w").write(ALT + "\n")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("usage: python3 python/fig01_routes_lower48.py <census_state_shp> <natural_earth_dir>")
    main(*sys.argv[1:])
