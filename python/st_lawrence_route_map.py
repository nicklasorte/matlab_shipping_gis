"""Map of the full St. Lawrence route layer (python/st_lawrence_route.py).

Usage: python3 python/st_lawrence_route_map.py <natural_earth_dir>
Writes outputs/foreign_waterways/st_lawrence_route_map_rev1.png and .alt.txt.
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
OUT = os.path.join(ROOT, "outputs", "foreign_waterways")
COL = {"MarineCadastre AIS 2024-2025 (route rule)": ("#1F2A44", "Our AIS routes, 2024–2025"),
       "DFO AIS density 2024, cargo + tanker": ("#5674C4", "Canadian AIS density, 2024 (cargo and tanker)"),
       "World Bank / IMF commercial density 2015-2021": ("#7B4FA0", "World Bank AIS density, 2015–2021 (fills Montreal to Québec City)")}
ALT = ("Map of eastern Canada and the northeastern United States showing the St. Lawrence large-ship route as one "
       "continuous band from Lake Ontario past Montreal and Québec City, through the estuary and the Gulf of St. Lawrence, "
       "to Cabot Strait and the Atlantic. Colors show the source of each part: our AIS routes on Lake Ontario and the "
       "upper river, World Bank density from Montreal to Québec City, and Canadian density from Québec City to the sea. "
       "Northern Maine lies about 55 to 100 km south of the estuary.")


def main(ne_dir):
    c = gpd.read_file(os.path.join(ne_dir, "ne_10m_admin_0_countries_lakes.shp")).cx[-82:-52, 40:54]
    r = gpd.read_file(os.path.join(OUT, "st_lawrence_route_rev1.shp"))
    fig, ax = plt.subplots(figsize=(10, 5.6), dpi=200)
    c[c.ADMIN != "United States of America"].plot(ax=ax, color="#F2F2F2", edgecolor="#B0B3B7", lw=0.4)
    c[c.ADMIN == "United States of America"].plot(ax=ax, color="#DADCDF", edgecolor="#8A8D91", lw=0.4)
    for src, (col, lab) in COL.items():
        g = r[r.source == src]
        g.plot(ax=ax, color=col, edgecolor=col, lw=0.6)
        ax.plot([], [], color=col, lw=4, label=lab)
    for x, y, t in [(-74.6, 45.75, "Montreal"), (-72.3, 47.0, "Québec City"), (-69.3, 45.6, "Maine"),
                    (-77.6, 43.45, "Lake Ontario"), (-59.6, 46.75, "Cabot Strait"), (-75.5, 43.2, "New York")]:
        ax.text(x, y, t, fontsize=8, color="#1F2A44", ha="center")
    ax.set_xlim(-80, -55)
    ax.set_ylim(42.5, 51.8)
    ax.set_aspect(1 / 0.69)
    ax.set_axis_off()
    ax.legend(loc="upper left", fontsize=7.5, frameon=False)
    ax.set_title("Large ships run the whole St. Lawrence, from Lake Ontario to the Atlantic", fontsize=11, loc="left",
                 color="#1F2A44")
    fig.text(0.01, 0.01, "Source: NTIA analysis of MarineCadastre AIS (2024–2025); Fisheries and Oceans Canada AIS vessel "
             "density (2024); World Bank / IMF Global Shipping Traffic Density (2015–2021); Natural Earth. "
             "DRAFT//PRE-DECISIONAL", fontsize=6, color="#1F2A44")
    out = os.path.join(OUT, "st_lawrence_route_map_rev1")
    fig.savefig(out + ".png", metadata={"Description": ALT})
    open(out + ".alt.txt", "w").write(ALT + "\n")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: python3 python/st_lawrence_route_map.py <natural_earth_dir>")
    main(sys.argv[1])
