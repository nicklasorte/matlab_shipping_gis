"""Population in each zone (plan step R1, review R4OPP-3).

Usage: python3 python/zone_population.py [zone_root] [tag]

Counts the 2020 Census population whose block-group center of population lies
inside each zone polygon, for each region and distance (25, 50, 100 km).
Input: data/ref/CenPop2020_Mean_BG.txt (Census Bureau, 2020 Centers of
Population by block group, https://www2.census.gov/geo/docs/reference/cenpop2020/blkgrp/).
Zone shapefiles are read from zone_root (default: the repo's outputs/ folders);
tag names the run in the output (default "base").

A block group counts wholly in or wholly out by its population center, so
results are approximate at zone edges (block groups are small where people
live). The U.S. Virgin Islands aren't in the file, so the Puerto Rico and
USVI rows count Puerto Rico only.

Writes outputs/zone_population_rev1.csv (rows for the tag replace earlier
rows with the same tag). MATLAB twin: zone_population_rev1.m.
"""
import os
import sys

import numpy as np
import pandas as pd
import shapefile
from shapely import contains_xy
from shapely.geometry import shape
from shapely.ops import unary_union

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
# region, zone folder, file stem, grid (lat_min, lat_max, lon_min, lon_max), state FIPS filter
REGIONS = [
    ("lower48", "outputs/2024_2025", "shipping_zone_2024_2025", (22, 50, -130, -66), "not 02 15 72"),
    ("hawaii", "outputs/2024_2025/hawaii", "shipping_zone_hawaii_2024_2025", (17, 24, -162, -153), "15"),
    ("prusvi", "outputs/2024_2025/prusvi", "shipping_zone_prusvi_2024_2025", (16.5, 19.5, -68.5, -64), "72"),
    ("alaska", "outputs/2018_2019/alaska", "shipping_zone_alaska_2018_2019", (51, 72, -180, -129), "02"),
]
DISTANCES = (25, 50, 100)


def load_blockgroups():
    bg = pd.read_csv(os.path.join(ROOT, "data", "ref", "CenPop2020_Mean_BG.txt"), encoding="utf-8-sig",
                     dtype={"STATEFP": str})
    return bg


def in_region(bg, grid, states):
    a, b, c, d = grid
    box = bg.LATITUDE.between(a, b) & bg.LONGITUDE.between(c, d)
    if states.startswith("not"):
        return bg[box & ~bg.STATEFP.isin(states.split()[1:])]
    return bg[box & bg.STATEFP.isin(states.split())]


def zone(path):
    sf = shapefile.Reader(path)
    return unary_union([shape(s.__geo_interface__).buffer(0) for s in sf.shapes()])


def main(zone_root=None, tag="base", regions=None):
    bg = load_blockgroups()
    rows = []
    for name, folder, stem, grid, states in REGIONS:
        if regions and name not in regions:
            continue
        sub = in_region(bg, grid, states)
        total = int(sub.POPULATION.sum())
        lon, lat = sub.LONGITUDE.to_numpy(), sub.LATITUDE.to_numpy()
        base = zone_root if zone_root else os.path.join(ROOT, folder)
        for km in DISTANCES:
            path = os.path.join(base, f"{stem}_ships_{km}km.shp")
            if not os.path.exists(path):
                continue
            inside = contains_xy(zone(path), lon, lat)
            pop = int(sub.POPULATION.to_numpy()[inside].sum())
            rows.append(dict(run=tag, region=name, distance_km=km, population=pop, region_population=total,
                             share_pct=round(100 * pop / total, 2), block_groups_in_zone=int(inside.sum())))
    out = pd.DataFrame(rows)
    path = os.path.join(ROOT, "outputs", "zone_population_rev1.csv")
    if os.path.exists(path):
        old = pd.read_csv(path)
        out = pd.concat([old[old.run != tag], out], ignore_index=True)
    out.to_csv(path, index=False)
    print(out[out.run == tag].to_string(index=False))


if __name__ == "__main__":
    main(*sys.argv[1:3])
