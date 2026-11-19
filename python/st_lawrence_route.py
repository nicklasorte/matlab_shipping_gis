"""Full St. Lawrence large-ship route, Lake Ontario to the Atlantic (display layer).

Joins three public sources on a 0.01 deg grid (lat 43 to 52, lon -80 to -55):
  ais   our MarineCadastre 2024-2025 AIS route cells (Lake Ontario, the Seaway, to Sorel)
  dfo   DFO 2024 Cargo + Tanker density at or above the threshold calibrated in
        python/st_lawrence_dfo.py (Quebec City to the Gulf)
  wb    World Bank / IMF Commercial ship density (AIS positions, 2015 to Feb 2021), used
        only where neither source above has data (Sorel to Quebec City); its threshold is
        calibrated against our route cells and the DFO cells where they overlap.
The Gulf part is limited to a polygon closed at Cabot Strait, the Strait of Canso,
and the Strait of Belle Isle, and to water connected to Quebec City. The result is a picture of where large ships run;
whether these cells become zone sources is decision D12.

Usage: python3 python/st_lawrence_route.py <dfo_tif_dir_or_clip> <wb_clip_tif> <natural_earth_dir>
Writes outputs/foreign_waterways/st_lawrence_route_rev1.{shp,...,kml} and
st_lawrence_route_summary_rev1.json.
"""
import json
import os
import sys
import warnings

import geopandas as gpd
import numpy as np
import rasterio
from rasterio.features import rasterize, shapes
from rasterio.transform import from_origin
from rasterio.warp import Resampling, reproject
from scipy.ndimage import binary_dilation, label
from shapely.geometry import Polygon, shape

warnings.filterwarnings("ignore")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "outputs", "foreign_waterways")
LAT0, LAT1, LON0, LON1, D = 43.0, 52.0, -80.0, -55.0, 0.01
NR, NC = int(round((LAT1 - LAT0) / D)), int(round((LON1 - LON0) / D))
TR = from_origin(LON0, LAT1, D, D)
# River, estuary, and Gulf of St. Lawrence, closed at Cabot Strait (Cape North to Cape Ray),
# the Strait of Canso, and the Strait of Belle Isle. Vertices are (lon, lat).
GULF = Polygon([(-71.6, 46.55), (-66.0, 47.9), (-64.6, 46.0), (-61.4, 45.72), (-60.40, 47.03),
                (-59.30, 47.62), (-57.10, 51.45), (-60.0, 52.0), (-71.6, 49.5)])
QUEBEC = (46.81, -71.20)


def warp(path, resampling=Resampling.max):
    out = np.full((NR, NC), np.nan)
    with rasterio.open(path) as s:
        src = s.read(1).astype(float)
        src[(src == s.nodata) | (src < 0)] = np.nan
        reproject(src, out, src_transform=s.transform, src_crs=s.crs, src_nodata=np.nan,
                  dst_transform=TR, dst_crs="EPSG:4326", dst_nodata=np.nan, resampling=resampling)
    return out


def cell(lat, lon):
    return int((LAT1 - lat) / D), int((lon - LON0) / D)


def best_threshold(values, target, dom):
    v = values[dom & (values > 0)]
    cands = np.quantile(v, np.linspace(0.05, 0.995, 300))
    jac = [((values >= t) & target & dom).sum() / max((((values >= t) | target) & dom).sum(), 1) for t in cands]
    k = int(np.argmax(jac))
    return float(cands[k]), float(jac[k])


def main(dfo_dir, wb_tif, ne_dir):
    calib = json.load(open(os.path.join(OUT, "st_lawrence_calibration_rev1.json")))
    t_dfo = calib["threshold_tracks_per_day_km2"]
    dfo = warp(os.path.join(dfo_dir, "CARGO_VPD_2024.tif")) + warp(os.path.join(dfo_dir, "TANKER_VPD_2024.tif"))
    wb = warp(wb_tif)
    rt = gpd.read_file(os.path.join(ROOT, "outputs/2024_2025/shipping_zone_2024_2025_routes_ais_only.shp")).to_crs(4326)
    ais = rasterize(((g, 1) for g in rt.geometry), out_shape=(NR, NC), transform=TR, fill=0).astype(bool)
    c = gpd.read_file(os.path.join(ne_dir, "ne_10m_admin_0_countries_lakes.shp"))
    land = rasterize(((g, 1) for g in c.geometry), out_shape=(NR, NC), transform=TR, fill=0).astype(bool)
    in_gulf = rasterize([(GULF, 1)], out_shape=(NR, NC), transform=TR, fill=0).astype(bool)
    # DFO water inside the polygon and connected to Quebec City.
    reg, _ = label(np.isfinite(dfo) & in_gulf, structure=np.ones((3, 3)))
    gulf = reg == reg[cell(*QUEBEC)]
    if not gulf[cell(*QUEBEC)]:
        raise RuntimeError("Quebec City is not on DFO water; check the grid")
    dfo_route = gulf & (dfo >= t_dfo)
    # World Bank threshold: match our AIS cells plus DFO route cells where WB and either exists.
    lat = np.broadcast_to(LAT1 - D * (np.arange(NR) + 0.5)[:, None], (NR, NC))
    lon = np.broadcast_to(LON0 + D * (np.arange(NC) + 0.5)[None, :], (NR, NC))
    river = (lat >= 44.0) & (lat <= 49.0) & (lon >= -77.0) & (lon <= -68.0) & ~land
    have_ref = river & (np.isfinite(dfo) | binary_dilation(ais, iterations=20))
    t_wb, j_wb = best_threshold(np.nan_to_num(wb), ais | dfo_route, have_ref & np.isfinite(wb))
    # Montreal to Quebec City, where AIS thins out and DFO has no data. No land mask here:
    # Natural Earth land covers parts of the narrow channel near Sorel; WB is zero on land anyway.
    gap = (lat >= 45.3) & (lat <= 47.0) & ~np.isfinite(dfo) & ~ais & (lon > -74.5) & (lon < -71.0)
    wb_route = gap & (np.nan_to_num(wb) >= t_wb)
    # Continuity: Lake Ontario outlet (Kingston) to Cabot Strait, 8-neighbour, 2-cell gaps bridged.
    allr = ais | dfo_route | wb_route
    lab, _ = label(binary_dilation(allr, iterations=2), structure=np.ones((3, 3)))
    kingston, cabot = cell(44.20, -76.40), cell(47.30, -60.0)
    near = lambda rc: set(np.unique(lab[rc[0] - 15:rc[0] + 16, rc[1] - 15:rc[1] + 16])) - {0}
    continuous = bool(near(kingston) & near(cabot))
    src = np.zeros((NR, NC), np.uint8)
    src[wb_route] = 3
    src[dfo_route] = 2
    src[ais & ((lon > -77.5) & (lon < -71) & (lat > 43.2) & (lat < 47.5))] = 1   # river and Lake Ontario outlet only
    names = {1: "MarineCadastre AIS 2024-2025 (route rule)", 2: "DFO AIS density 2024, cargo + tanker",
             3: "World Bank / IMF commercial density 2015-2021"}
    feats = [dict(geometry=shape(g), source=names[int(v)]) for g, v in shapes(src, mask=src > 0, transform=TR)]
    gdf = gpd.GeoDataFrame(feats, crs=4326).dissolve("source").reset_index()
    os.makedirs(OUT, exist_ok=True)
    gdf.to_file(os.path.join(OUT, "st_lawrence_route_rev1.shp"))
    gdf.to_file(os.path.join(OUT, "st_lawrence_route_rev1.kml"), driver="KML")
    summ = dict(dfo_threshold_tracks_per_year=calib["threshold_tracks_per_year"],
                wb_threshold_positions=round(t_wb, 1), wb_jaccard_vs_ais_and_dfo=round(j_wb, 3),
                cells_ais=int((src == 1).sum()), cells_dfo=int((src == 2).sum()), cells_wb=int((src == 3).sum()),
                continuous_lake_ontario_to_cabot_strait=continuous)
    json.dump(summ, open(os.path.join(OUT, "st_lawrence_route_summary_rev1.json"), "w"), indent=1)
    print(json.dumps(summ, indent=1))


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit("usage: python3 python/st_lawrence_route.py <dfo_tif_dir> <wb_clip_tif> <natural_earth_dir>")
    main(*sys.argv[1:])
