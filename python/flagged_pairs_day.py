"""Cell and ship pairs that come only from flagged AIS reports, for one day.

A report is flagged when it is a position jump (implied speed over 50 kn and
more than 1 km from the ship's previous report) or a possible duplicate MMSI
(more than 50 km from the ship's previous report within 10 minutes), the
same tests as python/ais_qc_day.py. A (cell, MMSI) pair is "flagged only"
when every report of that ship in that cell that day is flagged. Removing
these pairs from the day caches gives the routes without flagged reports
(python/ship_flagged_rebuild.py).

The script also rebuilds the day's full pair set from the raw file and
compares it with the committed cache, so a mismatch in the filter shows up.

Usage: python3 python/flagged_pairs_day.py YYYY-MM-DD [...]
Writes data/flagged/flag_pairs_<day>.npz (one array per grid) and
data/flagged/flag_pairs_<day>.json (counts and the cache check).
"""
import json
import os
import sys

import numpy as np
import pandas as pd
import scipy.io

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, ROOT)
sys.path.insert(0, HERE)
import ais_cells_py_rev1 as cells  # noqa: E402
from ais_qc_day import haversine_km, load_day  # noqa: E402

OUT = os.path.join(ROOT, "data", "flagged")
GRIDS_2024 = (None, "hawaii", "prusvi")   # None = lower 48
GRIDS_2018 = ("alaska180",)


def flags(d):
    """Boolean per report: jump or possible duplicate MMSI (the later report of the pair)."""
    o = np.lexsort((d["t"], d["mmsi"]))
    mm, t, la, lo = d["mmsi"][o], d["t"][o], d["lat"][o], d["lon"][o]
    same = mm[1:] == mm[:-1]
    dt_h = (t[1:] - t[:-1]).astype("timedelta64[s]").astype(float) / 3600
    dk = haversine_km(la[:-1], lo[:-1], la[1:], lo[1:])
    with np.errstate(divide="ignore", invalid="ignore"):
        v_kn = dk / 1.852 / dt_h
    jump = same & (dt_h > 0) & (v_kn > 50) & (dk > 1)
    dup = same & (dt_h <= 10 / 60) & (dk > 50)
    f = np.zeros(len(mm), bool)
    f[1:] = jump | dup
    out = np.zeros(len(f), bool)
    out[o] = f
    return out


def unique_pairs(cell, mmsi):
    if len(cell) == 0:
        return np.zeros((0, 2), np.int64)
    return np.unique(np.column_stack([cell, mmsi]), axis=0)


def setdiff_rows(a, b):
    """Rows of a not in b (both int64 n x 2)."""
    if len(a) == 0 or len(b) == 0:
        return a
    key = lambda p: p[:, 0] * (1 << 31) + p[:, 1]  # noqa: E731  MMSI < 2**31
    return a[~np.isin(key(a), key(b))]


def main(day):
    grids = GRIDS_2018 if int(day[:4]) in (2018, 2019) else GRIDS_2024
    d = load_day(day)
    mmsi = pd.to_numeric(pd.Series(d["mmsi"]), errors="coerce").to_numpy(float)
    keep = np.isfinite(mmsi)
    d = {k: v[keep] for k, v in d.items()}
    mmsi = mmsi[keep].astype(np.int64)
    flag = flags(d)
    arrays, res = {}, {"day": day, "reports": int(len(flag)), "flagged_reports": int(flag.sum())}
    for g in grids:
        row, col, ok = cells.discrete(d["lat"], d["lon"], g)
        cell = (row + (col - 1) * cells.grid_size(g)[0]).astype(np.int64)
        good = unique_pairs(cell[ok & ~flag], mmsi[ok & ~flag])
        bad = unique_pairs(cell[ok & flag], mmsi[ok & flag])
        only = setdiff_rows(bad, good)
        name = g or "conus"
        arrays[name] = only
        allp = unique_pairs(cell[ok], mmsi[ok])
        cache = scipy.io.loadmat(os.path.join(ROOT, "data", cells.cache_name(day, cells.FILTERS["main"], g)))["pairs"]
        cache = cache.astype(np.int64).reshape(-1, 2)
        res[name] = {"pairs": int(len(allp)), "flagged_only_pairs": int(len(only)),
                     "flagged_only_cells": int(len(np.unique(only[:, 0]))) if len(only) else 0,
                     "cache_pairs": int(len(cache)),
                     "pairs_not_in_cache": int(len(setdiff_rows(allp, cache))),
                     "cache_pairs_not_rebuilt": int(len(setdiff_rows(cache, allp)))}
    os.makedirs(OUT, exist_ok=True)
    np.savez_compressed(os.path.join(OUT, f"flag_pairs_{day}.npz"), **arrays)
    with open(os.path.join(OUT, f"flag_pairs_{day}.json"), "w") as f:
        json.dump(res, f, indent=1)
    print(json.dumps(res))


if __name__ == "__main__":
    for dd in sys.argv[1:]:
        if os.path.isfile(os.path.join(OUT, f"flag_pairs_{dd}.json")):
            continue
        main(dd)
