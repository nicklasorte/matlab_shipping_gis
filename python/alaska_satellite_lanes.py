"""Add satellite-AIS lanes to the Alaska routes, beyond the reach of shore receivers.

The MarineCadastre data come from Coast Guard receivers on shore (about 40 nautical
miles of reach), so busy lanes far offshore are missing (check_alaska_kapsar.py).
The North Pacific and Arctic Marine Vessel Traffic Dataset (Kapsar and others, 2022;
Arctic Data Center doi:10.18739/A2XG9FC41; CC BY 4.0) counts ships from satellite
AIS in 625 km2 hexagons. This script:

  1. Sums cargo and tanker operating days (nOprD_C + nOprD_T) per hexagon over the
     24 months of 2018-2019.
  2. Sets the cutoff on hexagons inside shore-receiver range (centroid within
     74 km of the coastline), where our routes are complete: the cutoff whose
     busy-hexagon set best matches the hexagons that hold our route cells
     (Jaccard index).
  3. Keeps every hexagon at or above that cutoff, anywhere in the grid east of
     180 degrees, and writes the water cells inside them (cell centers not on
     Census land) as extra ship water for shipping_zone_rev1 (p.extra_source_csv).

Kapsar has no length cut, so cargo and tanker are the closest match to the large-
ship filter; the hexagons are coarse (about 27 km across), so the added ship water
is wider than a lane.

Usage: python3 python/alaska_satellite_lanes.py [FACTOR]
Writes outputs/2018_2019/alaska/satellite_lane_cells.csv and satellite_lanes.json.
With FACTOR (for example 0.5 or 2), the cutoff is FACTOR times the best-match
cutoff, for the cutoff sensitivity check in Section 5.3, and the files get the
suffix _x<FACTOR> (satellite_lane_cells_x0.5.csv). "beyond" keeps only the
hexagons beyond shore-receiver range (suffix _beyond, review R3OPP-1); "sweep"
writes the Jaccard index at cutoffs from 300 to 650 days (review R3OPP-11).
"""
import json
import os
import sys

import numpy as np
import shapefile
from matplotlib.path import Path
from pyproj import Transformer
from shapely import contains_xy
from shapely.geometry import shape
from shapely.ops import unary_union

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, HERE)
sys.path.insert(0, ROOT)
import ais_cells_py_rev1 as cells  # noqa: E402
import ship_viz_products as vp  # noqa: E402
import ship_island_routes as isl  # noqa: E402
import check_alaska_kapsar as kc  # noqa: E402

GRID = "alaska180"
AK = os.path.join(ROOT, "outputs", "2018_2019", "alaska")
SHORE_RANGE_KM = 74.0   # about 40 nautical miles
TO_LL = Transformer.from_crs(3338, 4326, always_xy=True)
TO_AK = Transformer.from_crs(4326, 3338, always_xy=True)


def main(factor=None, beyond_only=False, sweep=False):
    polys, ops, _ = kc.read_hex()
    hid = list(polys)
    kap = np.array([ops[h] for h in hid], float)
    cent = np.array([polys[h].mean(axis=0) for h in hid])
    lon_c, lat_c = TO_LL.transform(cent[:, 0], cent[:, 1])
    in_grid = (lon_c > -180) & (lon_c < -129) & (lat_c >= 51) & (lat_c <= 72)
    # Hexagons holding our ship-track route cells
    z = np.load(os.path.join(AK, "alaska_rule_cells.npz"))
    route = z["ship_days_6"]
    la, lo = isl.cell_latlon(route, GRID)
    x, y = TO_AK.transform(lo, la)
    has = np.zeros(len(hid), bool)
    for k, h in enumerate(hid):
        p = polys[h]
        m = (x >= p[:, 0].min()) & (x <= p[:, 0].max()) & (y >= p[:, 1].min()) & (y <= p[:, 1].max())
        if m.any() and Path(p).contains_points(np.column_stack([x[m], y[m]])).any():
            has[k] = True
    tree = isl.coast_tree(GRID)
    shore_km = vp.chord_to_arc(tree.query(vp.ecef(lat_c, lon_c))[0])
    near = in_grid & (shore_km <= SHORE_RANGE_KM)
    # Cutoff: best Jaccard match near shore
    cands = np.unique(np.quantile(kap[near & (kap > 0)], np.linspace(0.05, 0.95, 37)))
    jac = []
    for t in cands:
        a, b = near & (kap >= t), near & has
        jac.append((a & b).sum() / max(1, (a | b).sum()))
    jac = np.array(jac)
    T_best = float(cands[np.argmax(jac)])
    if sweep:
        # Review R3OPP-11: the candidate list jumps from 272 to 659 days; test between.
        grid_t = [T_best] + list(range(300, 651, 50)) + [float(cands[cands > T_best].min())]
        rows = {}
        for t in grid_t:
            a, b = near & (kap >= t), near & has
            rows[f"{t:.0f}"] = {"jaccard_near_shore": round(float((a & b).sum() / max(1, (a | b).sum())), 3),
                                "hexagons_kept": int((in_grid & (kap >= t)).sum()),
                                "hexagons_kept_beyond_shore_range": int((in_grid & (kap >= t) & ~near).sum())}
        with open(os.path.join(AK, "satellite_cutoff_sweep_rev1.json"), "w") as f:
            json.dump({"note": "Jaccard index near shore (within 74 km) between Kapsar hexagons at or above each cutoff and hexagons holding ship-track route cells (review R3OPP-11)",
                       "cutoffs": rows}, f, indent=1)
        print(json.dumps(rows, indent=1))
        return
    T = T_best if factor is None else T_best * factor
    sfx = ("" if factor is None else f"_x{factor:g}") + ("_beyond" if beyond_only else "")
    keep = in_grid & (kap >= T)
    if beyond_only:
        keep &= ~near   # review R3OPP-1: only hexagons the shore receivers can't see
    # Water cells inside the kept hexagons
    sf = shapefile.Reader(vp.os.path.join(ROOT, "data", "cb_2023_us_state_500k", "cb_2023_us_state_500k.shp"))
    land = unary_union([shape(s.__geo_interface__) for s, r in zip(sf.shapes(), sf.records()) if r["STUSPS"] == "AK"])
    (la0, _), (lo0, _) = cells.GRIDS[GRID]
    nr, nc = cells.grid_size(GRID)
    out = []
    for k in np.nonzero(keep)[0]:
        p = polys[hid[k]]
        plo, pla = TO_LL.transform(p[:, 0], p[:, 1])
        r0, r1 = int((min(pla) - la0) / cells.CELL_DEG), int((max(pla) - la0) / cells.CELL_DEG) + 1
        c0, c1 = int((min(plo) - lo0) / cells.CELL_DEG), int((max(plo) - lo0) / cells.CELL_DEG) + 1
        rr, cc = np.meshgrid(np.arange(max(r0, 0), min(r1, nr - 1) + 1), np.arange(max(c0, 0), min(c1, nc - 1) + 1), indexing="ij")
        rr, cc = rr.ravel(), cc.ravel()
        glat, glon = la0 + cells.CELL_DEG * (rr + 0.5), lo0 + cells.CELL_DEG * (cc + 0.5)
        gx, gy = TO_AK.transform(glon, glat)
        inside = Path(p).contains_points(np.column_stack([gx, gy]))
        inside &= ~contains_xy(land, glon, glat)
        out.append(rr[inside] + 1 + cc[inside] * nr)   # 1-based linear index, column-major from the south
    lin = np.unique(np.concatenate(out)).astype(np.int64)
    np.savetxt(os.path.join(AK, f"satellite_lane_cells{sfx}.csv"), lin, fmt="%d")
    res = {"source": "Kapsar and others (2022), doi:10.18739/A2XG9FC41, CC BY 4.0; months 2018-01 to 2019-12",
           "measure": "cargo plus tanker operating days per 625 km2 hexagon, summed over 24 months",
           "hexagons_in_grid": int(in_grid.sum()), "hexagons_near_shore": int(near.sum()),
           "cutoff_operating_days": T, "best_match_cutoff": T_best, "factor": factor or 1.0,
           "jaccard_at_cutoff_near_shore": round(float(((near & (kap >= T)) & (near & has)).sum()
                                                       / max(1, ((near & (kap >= T)) | (near & has)).sum())), 3),
           "jaccard_curve": {f"{c:.0f}": round(float(j), 3) for c, j in zip(cands, jac)},
           "hexagons_kept": int(keep.sum()), "hexagons_kept_beyond_shore_range": int((keep & ~near).sum()),
           "kept_hexagons_without_our_routes": int((keep & ~has).sum()),
           "water_cells_added": int(len(lin))}
    with open(os.path.join(AK, f"satellite_lanes{sfx}.json"), "w") as f:
        json.dump(res, f, indent=1)
    print(json.dumps({k: v for k, v in res.items() if k != "jaccard_curve"}, indent=1))


if __name__ == "__main__":
    # python3 python/alaska_satellite_lanes.py [FACTOR] [beyond] [sweep]
    args = sys.argv[1:]
    fac = next((float(a) for a in args if a.replace(".", "", 1).isdigit()), None)
    main(fac, beyond_only="beyond" in args, sweep="sweep" in args)
