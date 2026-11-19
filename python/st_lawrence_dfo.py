"""St. Lawrence large-ship sources from the DFO 2024 AIS vessel density maps (plan F3, F4).

Our MarineCadastre AIS stops near Sorel; DFO's Northwest Atlantic density maps
(Canadian Coast Guard terrestrial plus satellite AIS, 1 km, tracks per day per km2,
by vessel class) cover the river from Quebec City to the sea. This script:
  1. Resamples DFO Cargo + Tanker 2024 to the lower-48 0.01 deg grid (cell maximum).
  2. Calibrates a density threshold against our AIS route cells in U.S. waters within
     74 km of U.S. land, Chesapeake Bay to Cape Cod (lat < 43.5, lon < -69), by the
     Jaccard index, and reports it on a held-out area (Gulf of Maine, lat >= 43.5).
  3. Applies it in foreign water on the St. Lawrence side (lat >= 45.6, lon >= -74),
     more than 5 cells from any route cell, within 150 km of U.S. land, and reports the
     U.S. land a 25, 50, and 100 km zone around those cells would add beyond the current
     zones, at 1, 2, 5, 10, and 30 times the threshold.
Screening-grade geometry: Natural Earth 1:10m land, planar distances on the grid
(km per cell fixed at 45 N) for the calibration domain. MATLAB twin: pending (plan F4).

Usage: python3 python/st_lawrence_dfo.py <dfo_tif_dir> <natural_earth_dir>
Writes outputs/foreign_waterways/st_lawrence_calibration_rev1.json,
st_lawrence_sensitivity_rev1.csv, st_lawrence_source_cells_rev1.csv.
"""
import json
import os
import sys
import warnings

import geopandas as gpd
import numpy as np
import pandas as pd
import rasterio
from rasterio.features import rasterize
from rasterio.transform import from_origin
from rasterio.warp import Resampling, reproject
from scipy.ndimage import binary_dilation, distance_transform_edt
from shapely.geometry import box
from shapely.ops import unary_union

warnings.filterwarnings("ignore")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "outputs", "foreign_waterways")
LAT0, LAT1, LON0, LON1, D = 38.0, 50.0, -77.0, -66.0, 0.01
NR, NC = int(round((LAT1 - LAT0) / D)), int(round((LON1 - LON0) / D))
TR = from_origin(LON0, LAT1, D, D)   # row 0 is the north edge
KM_PER_CELL = (1.112, 0.79)          # (lat, lon) near 45 N
REACH_KM = 74                        # terrestrial AIS reach, as for Alaska (40 nmi)


def warp(path):
    out = np.full((NR, NC), np.nan)
    with rasterio.open(path) as s:
        reproject(s.read(1), out, src_transform=s.transform, src_crs=s.crs, src_nodata=-9999,
                  dst_transform=TR, dst_crs="EPSG:4326", dst_nodata=np.nan, resampling=Resampling.max)
    return out


def jaccard(a, b, dom):
    a, b = a & dom, b & dom
    return float((a & b).sum() / max((a | b).sum(), 1))


def main(tif_dir, ne_dir):
    paths = [os.path.join(tif_dir, f"{c}_VPD_2024.tif") for c in ("CARGO", "TANKER")]
    for p in paths:
        if not os.path.exists(p):
            raise FileNotFoundError(p)
    dens = warp(paths[0]) + warp(paths[1])
    rt = gpd.read_file(os.path.join(ROOT, "outputs/2024_2025/shipping_zone_2024_2025_routes_ais_only.shp")).to_crs(4326)
    route = rasterize(((g, 1) for g in rt.geometry), out_shape=(NR, NC), transform=TR, fill=0).astype(bool)
    c = gpd.read_file(os.path.join(ne_dir, "ne_10m_admin_0_countries_lakes.shp"))
    land = {k: rasterize(((g, 1) for g in c[c.ADMIN == n].geometry), out_shape=(NR, NC), transform=TR, fill=0).astype(bool)
            for k, n in (("us", "United States of America"), ("ca", "Canada"))}
    dus = distance_transform_edt(~land["us"], sampling=KM_PER_CELL)
    dca = distance_transform_edt(~land["ca"], sampling=KM_PER_CELL)
    lat = np.broadcast_to(LAT1 - D * (np.arange(NR) + 0.5)[:, None], (NR, NC))
    lon = np.broadcast_to(LON0 + D * (np.arange(NC) + 0.5)[None, :], (NR, NC))
    water = np.isfinite(dens)
    base = water & (dus < dca) & (dus <= REACH_KM)
    cal, test = base & (lat < 43.5) & (lon < -69.0), base & (lat >= 43.5)
    cands = np.quantile(dens[cal & (dens > 0)], np.linspace(0.05, 0.995, 300))
    jac = np.array([jaccard(dens >= t, route, cal) for t in cands])
    t = float(cands[jac.argmax()])
    calib = dict(threshold_tracks_per_day_km2=round(t, 5), threshold_tracks_per_year=round(t * 366, 1),
                 jaccard_calibration=round(float(jac.max()), 3), jaccard_holdout=round(jaccard(dens >= t, route, test), 3),
                 calibration_cells=int(cal.sum()), calibration_route_cells=int((route & cal).sum()),
                 holdout_dfo_cells=int(((dens >= t) & test).sum()), holdout_route_cells=int((route & test).sum()),
                 holdout_both=int(((dens >= t) & route & test).sum()),
                 dfo_source="DFO Vessel Density Mapping of 2024 AIS Data in the Northwest Atlantic, Cargo + Tanker")
    dom = water & (dca < dus) & ~binary_dilation(route, iterations=5) & (dus <= 150) & (lat >= 45.6) & (lon >= -74)
    usa = c[c.ADMIN == "United States of America"].to_crs(6933).geometry.union_all()
    zone = {km: gpd.read_file(os.path.join(ROOT, f"outputs/2024_2025/shipping_zone_2024_2025_ships_{km}km_land.shp"))
            .to_crs(6933).geometry.union_all() for km in (25, 50, 100)}
    rows = []
    for f in (1, 2, 5, 10, 30):
        m = dom & (dens >= t * f)
        ii, jj = np.nonzero(m)
        src = gpd.GeoSeries([unary_union([box(LON0 + D * j, LAT1 - D * (i + 1), LON0 + D * (j + 1), LAT1 - D * i)
                                          for i, j in zip(ii, jj)])], crs=4326).to_crs("+proj=aeqd +lat_0=47.5 +lon_0=-70")
        rec = dict(threshold_times=f, tracks_per_year=round(t * f * 366), source_cells=int(m.sum()))
        for km in (25, 50, 100):
            z = src.buffer(km * 1000).to_crs(6933).iloc[0].intersection(usa)
            rec[f"new_us_land_km2_{km}"] = round(z.difference(zone[km]).area / 1e6)
        rows.append(rec)
        if f == 1:
            pd.DataFrame({"lat": lat[m].round(3), "lon": lon[m].round(3), "cargo_tanker_tracks_per_day_km2": dens[m].round(4),
                          "us_km": dus[m].round(1)}).to_csv(os.path.join(OUT, "st_lawrence_source_cells_rev1.csv"), index=False)
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "st_lawrence_calibration_rev1.json"), "w") as fh:
        json.dump(calib, fh, indent=1)
    sens = pd.DataFrame(rows)
    sens.to_csv(os.path.join(OUT, "st_lawrence_sensitivity_rev1.csv"), index=False)
    print(json.dumps(calib, indent=1))
    print(sens.to_string(index=False))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("usage: python3 python/st_lawrence_dfo.py <dfo_tif_dir> <natural_earth_dir>")
    main(sys.argv[1], sys.argv[2])
