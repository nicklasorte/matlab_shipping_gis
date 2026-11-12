"""Build per-day AIS cell caches (same format as ais_cache_day_rev1.m) in Python.

Use this when MATLAB's machine is short on disk or bandwidth: it streams each
daily MarineCadastre file (2024+ .csv.zst, 2023 and earlier .zip) without
writing the CSV to disk, applies the same ship filter as
ais_large_ship_cells_rev1.m, bins reports onto the same 0.01-degree grid, and
saves the unique [cell_index, mmsi] pairs as a .mat file that
ais_cache_day_rev1.m loads as is. One download serves several filters
(FILTERS below); each filter gets its own cache file, named exactly as
ais_cache_name_rev1.m names it.

Grid: georefcells(latlim, lonlim, d, d) with MATLAB defaults
(ColumnsStartFrom 'south', RowsStartFrom 'west'); linear index is column-major,
1-based, as sub2ind returns.

Usage:
  python3 ais_cells_py_rev1.py OUT_DIR YYYY-MM-DD [YYYY-MM-DD ...]
  python3 ais_cells_py_rev1.py --types OUT_DIR YYYY-MM-DD ...   (ship-type groups)
  python3 ais_cells_py_rev1.py [--with-types] --grids=hawaii,prusvi OUT_DIR YYYY-MM-DD ...   (other grids, one pass)
"""
import os
import sys
import tempfile
import zipfile

import numpy as np
import pandas as pd
import pyarrow as pa
import pyarrow.csv as pv
import requests
import scipy.io
import zstandard

# Must match init_shipping_zone_rev1.m (p.filt and p.filt_towing)
LATLIM = (22.0, 50.0)
LONLIM = (-130.0, -66.0)
CELL_DEG = 0.01
# Extra grids filled in the same pass over each day's file (--grids). Each grid's
# limits go into its cache file names, so the lower-48 caches never change.
GRIDS = {
    "conus": (LATLIM, LONLIM),
    "hawaii": ((17.0, 24.0), (-162.0, -153.0)),
    "prusvi": ((16.5, 19.5), (-68.5, -64.0)),
}
FILTERS = {
    # merchant, military, law enforcement, dredging, other: p.filt
    "main": {"types": sorted(set([0, 33, 35, 55] + list(range(60, 90)) + list(range(90, 100)))),
             "min_length_m": 100.0, "no_imo_types": [35, 55]},
    # towing with an IMO number (ocean-going tug-barges): p.filt_towing
    "towing": {"types": [31, 32, 52], "min_length_m": 100.0, "no_imo_types": []},
}

# Ship-type groups for the "where each type goes" maps (init_ship_geo_rev1.m,
# python/ship_geo_products.py). Same length and IMO rules as "main".
TYPE_FILTERS = {
    "cargo": {"types": list(range(70, 80)), "min_length_m": 100.0, "no_imo_types": []},
    "tanker": {"types": list(range(80, 90)), "min_length_m": 100.0, "no_imo_types": []},
    "passenger": {"types": list(range(60, 70)), "min_length_m": 100.0, "no_imo_types": []},
    "government": {"types": [35, 55], "min_length_m": 100.0, "no_imo_types": [35, 55]},
}

NUM_ROW = round((LATLIM[1] - LATLIM[0]) / CELL_DEG)
NUM_COL = round((LONLIM[1] - LONLIM[0]) / CELL_DEG)


def cache_name(day, filt, grid=None):
    vt = filt["types"]
    filt_key = "L%g_imo1_sog0_vt%d-%d-n%d-s%d" % (filt["min_length_m"], min(vt), max(vt), len(vt), sum(vt))
    if filt["no_imo_types"]:
        filt_key += "_ni" + "-".join(str(t) for t in filt["no_imo_types"])
    la, lo = GRIDS[grid] if grid else (LATLIM, LONLIM)
    grid_key = "%g_%g_%g_%g_d%g" % (la + lo + (CELL_DEG,))
    return "ais_cells_%s_%s_%s_rev1.mat" % (day.replace("-", ""), filt_key, grid_key)


def day_url(day):
    yr = int(day[:4])
    if yr >= 2024:
        return "https://noaaocm.blob.core.windows.net/ais/csv2/csv%d/ais-%s.csv.zst" % (yr, day)
    return "https://coast.noaa.gov/htdata/CMSP/AISDataHandler/%d/AIS_%s.zip" % (yr, day.replace("-", "_"))


def grid_size(grid=None):
    la, lo = GRIDS[grid] if grid else (LATLIM, LONLIM)
    return round((la[1] - la[0]) / CELL_DEG), round((lo[1] - lo[0]) / CELL_DEG)


def discrete(lat, lon, grid=None):
    """geographicToDiscrete for this cells reference; ok=False outside the grid.

    Intrinsic coordinate y = 0.5 + (lat - lat0)*cells_per_degree, rounded half up.
    This exact form reproduced MATLAB's pairs for 2024-01-03 (166,382 of 166,382);
    dividing by 0.01 instead differed in 22 boundary pairs.
    """
    cpd = round(1 / CELL_DEG)
    la, lo = GRIDS[grid] if grid else (LATLIM, LONLIM)
    nr, nc = grid_size(grid)
    row = np.floor(0.5 + (lat - la[0]) * cpd + 0.5)
    col = np.floor(0.5 + (lon - lo[0]) * cpd + 0.5)
    row = np.minimum(row, nr)  # the top and east edges belong to the last cell
    col = np.minimum(col, nc)
    ok = (lat >= la[0]) & (lat <= la[1]) & (lon >= lo[0]) & (lon <= lo[1])
    return row, col, ok


def num(arr):
    """Text column to float; unparseable values become NaN (as MATLAB's %f does)."""
    return pd.to_numeric(pd.Series(arr.to_pylist(), dtype="string"), errors="coerce").to_numpy(dtype=float, na_value=np.nan)


def process_stream(stream, filters, grids=(None,)):
    opts = pv.ReadOptions(block_size=64 << 20)
    # Read the filter columns as text and convert here: a few rows carry bad
    # values (MMSI 'I367333430' on a 2023 day) that break type inference.
    text_cols = ["MMSI", "mmsi", "LAT", "LON", "lat", "lon", "latitude", "longitude",
                 "IMO", "imo", "VesselType", "vessel_type", "Length", "length"]
    # Rows with the wrong number of fields (a stray leading comma on a 2023 day)
    # are skipped and counted.
    bad = {"rows": 0}

    def skip_row(row):
        bad["rows"] += 1
        return "skip"

    head = pv.open_csv(stream, read_options=opts,
                       parse_options=pv.ParseOptions(invalid_row_handler=skip_row),
                       convert_options=pv.ConvertOptions(strings_can_be_null=False,
                                                         column_types={c: pa.string() for c in text_cols}))
    names = head.schema.names
    key = [n.lower().replace("_", "") for n in names]
    want = {"mmsi": ["mmsi"], "lat": ["lat", "latitude"], "lon": ["lon", "longitude"],
            "imo": ["imo"], "vt": ["vesseltype"], "length": ["length"]}
    col = {}
    for k, alts in want.items():
        hits = [i for i, x in enumerate(key) if x in alts]
        if not hits:
            raise RuntimeError("column %s not found" % k)
        col[k] = names[hits[0]]
    acc = {(g, k): {"pairs": [], "mmsi": set(), "rows": 0} for g in grids for k in filters}
    for batch in head:
        vt = num(batch.column(names.index(col["vt"])))
        ln = num(batch.column(names.index(col["length"])))
        imo_arr = batch.column(names.index(col["imo"]))
        imo = np.array([(s is not None and len(s) > 0) for s in imo_arr.cast(pa.string()).to_pylist()])
        for k, filt in filters.items():
            keep = np.isin(vt, filt["types"]) & (ln >= filt["min_length_m"])
            keep &= imo | np.isin(vt, filt["no_imo_types"])
            if not keep.any():
                continue
            lat = num(batch.column(names.index(col["lat"])).filter(pa.array(keep)))
            lon = num(batch.column(names.index(col["lon"])).filter(pa.array(keep)))
            mmsi = num(batch.column(names.index(col["mmsi"])).filter(pa.array(keep)))
            good = ~np.isnan(mmsi)  # a report with no readable MMSI can't be counted as a ship
            lat, lon, mmsi = lat[good], lon[good], mmsi[good]
            for g in grids:
                a = acc[(g, k)]
                row, colx, ok = discrete(lat, lon, g)
                a["rows"] += int(ok.sum()) if g else int(good.sum())
                a["mmsi"].update(np.unique(mmsi[ok] if g else mmsi).tolist())
                cell = row[ok] + (colx[ok] - 1) * grid_size(g)[0]
                a["pairs"].append(np.unique(np.column_stack([cell, mmsi[ok]]), axis=0))
    out = {}
    for k, a in acc.items():
        p = np.unique(np.vstack(a["pairs"]), axis=0) if a["pairs"] else np.zeros((0, 2))
        out[k] = (p, a["rows"], len(a["mmsi"]))
    if bad["rows"]:
        print("  skipped %d malformed rows" % bad["rows"], flush=True)
    return out


def build_day(day, out_dir, grids=(None,)):
    todo = {k: f for k, f in FILTERS.items()
            if any(not os.path.isfile("%s/%s" % (out_dir, cache_name(day, f, g))) for g in grids)}
    if not todo:
        print("%s cached" % day, flush=True)
        return
    url = day_url(day)
    with tempfile.TemporaryFile() as tmp:
        with requests.get(url, stream=True, timeout=600) as r:
            r.raise_for_status()
            for chunk in r.iter_content(8 << 20):
                tmp.write(chunk)
        tmp.seek(0)
        if url.endswith(".zst"):
            res = process_stream(zstandard.ZstdDecompressor().stream_reader(tmp), todo, grids)
        else:
            with zipfile.ZipFile(tmp) as z:
                member = [n for n in z.namelist() if n.endswith(".csv")][0]
                with z.open(member) as f:
                    res = process_stream(f, todo, grids)
    for (g, k), (pairs, rows, nm) in res.items():
        out = "%s/%s" % (out_dir, cache_name(day, todo[k], g))
        if os.path.isfile(out):
            continue
        tmp_out = out + ".part.mat"  # rename into place so a reader never sees a partial file
        scipy.io.savemat(tmp_out, {"pairs": pairs.astype(float), "num_row_kept": float(rows),
                                   "num_mmsi_kept": float(nm)}, do_compression=True)
        os.replace(tmp_out, out)
        print("%s %s %s rows %d mmsi %d pairs %d" % (day, g or "conus", k, rows, nm, len(pairs)), flush=True)


if __name__ == "__main__":
    args = sys.argv[1:]
    grids = (None,)
    if args and args[0] == "--types":
        FILTERS = TYPE_FILTERS
        args = args[1:]
    if args and args[0] == "--with-types":   # main, towing, and the ship-type groups in one pass
        FILTERS = {**FILTERS, **TYPE_FILTERS}
        args = args[1:]
    if args and args[0].startswith("--grids="):
        grids = tuple(None if g == "conus" else g for g in args[0].split("=", 1)[1].split(","))
        args = args[1:]
    out_dir = args[0]
    for d in args[1:]:
        build_day(d, out_dir, grids)
