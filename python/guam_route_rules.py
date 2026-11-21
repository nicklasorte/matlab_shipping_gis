"""Guam and CNMI: compare the ship-days route rule with NOAA AIS Vessel Transit Counts and the unique-ships rule.

K = 6 ship-days and T = 8 NOAA transits were calibrated on the lower 48 (python/ship_route_rules.py,
outputs/2024_2025/islands/route_rules.json). This script applies them unchanged to the Guam grid
(12 to 21.5 N, 143.5 to 147 E, 0.01 deg, row 1 = south) and sweeps both thresholds.

NOAA raster: ais-transit-count-2025.tif (the 2024 file stops at 174 W and does not hold Guam). The
calibration used the 2024 file; the year differs and is stated in the paper. Cell value = maximum 100 m
count inside the 0.01 deg cell, as in ship_route_rules.noaa_cells.
unique_ships in the zone file counts distinct MMSI over both years together, so "at least N ships"
here is a superset of the lower-48 rule (4 ships in either year).

Usage: python3 python/guam_route_rules.py [raster path or /vsicurl URL]
Writes outputs/guam/guam_route_rules_rev1.json and outputs/guam/guam_noaa_cells_rev1.npz.
"""
import json
import os
import sys

import numpy as np
import rasterio
import rasterio.windows
import scipy.io as sio
from pyproj import Transformer
from rasterio.windows import from_bounds
from scipy import ndimage

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
LAT0, LON0, STEP, NR, NC = 12.0, 143.5, 0.01, 950, 350
PORTS = {"Apra Harbor": (13.4437, 144.6667), "Rota": (14.14, 145.138), "Tinian": (14.958, 145.62),
         "Saipan": (15.2258, 145.7349)}
HUB = "Apra Harbor"
K, T = 6, 8
URL = "/vsicurl/https://ocmgeodatastor1.blob.core.windows.net/marinecadastre/ais/aistransit/ais-transit-count-2025.tif"
MAT = os.path.join(ROOT, "outputs", "guam", "shipping_zone_guam_2024_2025_ships_rev1.mat")
OUT = os.path.join(ROOT, "outputs", "guam")
TO_M = Transformer.from_crs(4326, 3857, always_xy=True)
TO_LL = Transformer.from_crs(3857, 4326, always_xy=True)


def noaa_grid(src):
    """Max NOAA transit count per grid cell, array (NR, NC)."""
    x0, y0 = TO_M.transform(LON0, LAT0)
    x1, y1 = TO_M.transform(LON0 + NC * STEP, LAT0 + NR * STEP)
    out = np.zeros((NR, NC), np.int64)
    with rasterio.Env(CURL_CA_BUNDLE="/root/.ccr/ca-bundle.crt", GDAL_DISABLE_READDIR_ON_OPEN="EMPTY_DIR"):
        with rasterio.open(src) as r:
            if r.crs.to_epsg() != 3857:
                raise RuntimeError("guam_route_rules:crs: expected EPSG:3857")
            w = from_bounds(x0, y0, x1, y1, r.transform).round_offsets().round_lengths()
            for off in range(0, int(w.height), 1024):
                sub = rasterio.windows.Window(w.col_off, w.row_off + off, w.width, min(1024, int(w.height) - off))
                a = r.read(1, window=sub)
                rows, cols = np.nonzero(a)
                if not len(rows):
                    continue
                tr = r.window_transform(sub)
                lon, lat = TO_LL.transform(tr.c + (cols + 0.5) * tr.a, tr.f + (rows + 0.5) * tr.e)
                ri, ci = np.floor((lat - LAT0) / STEP).astype(int), np.floor((lon - LON0) / STEP).astype(int)
                ok = (ri >= 0) & (ri < NR) & (ci >= 0) & (ci < NC)
                np.maximum.at(out, (ri[ok], ci[ok]), a[rows, cols][ok].astype(np.int64))
    return out


def km(lat1, lon1, lat2, lon2):
    p = np.pi / 180
    a = np.sin((lat2 - lat1) * p / 2) ** 2 + np.cos(lat1 * p) * np.cos(lat2 * p) * np.sin((lon2 - lon1) * p / 2) ** 2
    return 6371.0088 * 2 * np.arcsin(np.sqrt(a))


def checks(mask, gap_km=2.0):
    """Nearest route cell per port, and connection to Apra through route cells (8-neighbor, one-cell gaps bridged)."""
    bridged = ndimage.binary_closing(mask, structure=np.ones((3, 3))) | mask
    lab, _ = ndimage.label(bridged, structure=np.ones((3, 3)))
    rr, cc = np.nonzero(mask)
    res, hub = {}, None
    for name, (la, lo) in PORTS.items():
        if not len(rr):
            res[name] = {"km": None, "connected_to_hub": False}
            continue
        d = km(la, lo, LAT0 + (rr + .5) * STEP, LON0 + (cc + .5) * STEP)
        i = int(np.argmin(d))
        res[name] = {"km": round(float(d[i]), 1), "label": int(lab[rr[i], cc[i]])}
        if name == HUB:
            hub = res[name]["label"]
    for v in res.values():
        if "label" in v:
            v["connected_to_hub"] = bool(v.pop("label") == hub and v["km"] <= gap_km)
    return {"route_cells": int(mask.sum()), "ports_within_2km": int(sum(v["km"] is not None and v["km"] <= gap_km for v in res.values())),
            "ports_connected_to_hub": int(sum(v["connected_to_hub"] for v in res.values())), "ports": res}


def jac(a, b):
    return float((a & b).sum() / max(1, (a | b).sum()))


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else URL
    m = sio.loadmat(MAT)
    sd, us = m["ship_days"].astype(np.int64), m["unique_ships"].astype(np.int64)
    if sd.shape != (NR, NC):
        raise RuntimeError("guam_route_rules:shape: unexpected grid")
    nz = noaa_grid(src)
    np.savez_compressed(os.path.join(OUT, "guam_noaa_cells_rev1.npz"), noaa_max=nz.astype(np.int32))
    base_sd, base_t = sd >= K, nz >= T
    res = {"K": K, "T": T, "raster": "ais-transit-count-2025.tif", "noaa_cells_ge1": int((nz > 0).sum()),
           "base": {"ship_days_cells": int(base_sd.sum()), "noaa_cells": int(base_t.sum()),
                    "jaccard": round(jac(base_sd, base_t), 3),
                    "ship_days_cells_in_noaa_T": round(float((base_sd & base_t).sum() / base_sd.sum()), 3),
                    "noaa_T_cells_in_ship_days": round(float((base_sd & base_t).sum() / base_t.sum()), 3)},
           "ship_days": {}, "unique_ships": {}, "noaa": {}, "near_port_cells": {}}
    for k in (2, 3, 4, 6, 8, 12):
        res["ship_days"][str(k)] = checks(sd >= k)
    for n in (1, 2, 3, 4):
        res["unique_ships"][str(n)] = checks(us >= n)
    for t in (1, 2, 3, 5, 8, 10, 15, 20, 30, 50):
        r = checks(nz >= t)
        r["jaccard_with_ship_days_K"] = round(jac(base_sd, nz >= t), 3)
        res["noaa"][str(t)] = r
    rr, cc = np.mgrid[0:NR, 0:NC]
    la, lo = LAT0 + (rr + .5) * STEP, LON0 + (cc + .5) * STEP
    for name, (pla, plo) in PORTS.items():
        near = km(pla, plo, la, lo) <= 15
        res["near_port_cells"][name] = {"ais_ship_days_ge1": int((near & (sd >= 1)).sum()), "ais_max": int(sd[near].max()),
                                        "noaa_ge1": int((near & (nz >= 1)).sum()), "noaa_max": int(nz[near].max()),
                                        "noaa_ge_T": int((near & (nz >= T)).sum())}
    with open(os.path.join(OUT, "guam_route_rules_rev1.json"), "w") as f:
        json.dump(res, f, indent=1)
    print(json.dumps({k: res[k] for k in ("base", "near_port_cells")}, indent=1))
    for fam in ("ship_days", "unique_ships", "noaa"):
        for k, v in res[fam].items():
            print(fam, k, v["route_cells"], v["ports_within_2km"], v["ports_connected_to_hub"], v.get("jaccard_with_ship_days_K", ""))


if __name__ == "__main__":
    main()
