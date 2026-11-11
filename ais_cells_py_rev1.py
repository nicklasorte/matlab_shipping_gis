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
FILTERS = {
    # merchant, military, law enforcement, dredging, other: p.filt
    "main": {"types": sorted(set([0, 33, 35, 55] + list(range(60, 90)) + list(range(90, 100)))),
             "min_length_m": 100.0, "no_imo_types": [35, 55]},
    # towing with an IMO number (ocean-going tug-barges): p.filt_towing
    "towing": {"types": [31, 32, 52], "min_length_m": 100.0, "no_imo_types": []},
}

NUM_ROW = round((LATLIM[1] - LATLIM[0]) / CELL_DEG)
NUM_COL = round((LONLIM[1] - LONLIM[0]) / CELL_DEG)


def cache_name(day, filt):
    vt = filt["types"]
    filt_key = "L%g_imo1_sog0_vt%d-%d-n%d-s%d" % (filt["min_length_m"], min(vt), max(vt), len(vt), sum(vt))
    if filt["no_imo_types"]:
        filt_key += "_ni" + "-".join(str(t) for t in filt["no_imo_types"])
    grid_key = "%g_%g_%g_%g_d%g" % (LATLIM + LONLIM + (CELL_DEG,))
    return "ais_cells_%s_%s_%s_rev1.mat" % (day.replace("-", ""), filt_key, grid_key)


def day_url(day):
    yr = int(day[:4])
    if yr >= 2024:
        return "https://noaaocm.blob.core.windows.net/ais/csv2/csv%d/ais-%s.csv.zst" % (yr, day)
    return "https://coast.noaa.gov/htdata/CMSP/AISDataHandler/%d/AIS_%s.zip" % (yr, day.replace("-", "_"))


def discrete(lat, lon):
    """geographicToDiscrete for this cells reference; ok=False outside the grid.

    Intrinsic coordinate y = 0.5 + (lat - lat0)*cells_per_degree, rounded half up.
    This exact form reproduced MATLAB's pairs for 2024-01-03 (166,382 of 166,382);
    dividing by 0.01 instead differed in 22 boundary pairs.
    """
    cpd = round(1 / CELL_DEG)
    row = np.floor(0.5 + (lat - LATLIM[0]) * cpd + 0.5)
    col = np.floor(0.5 + (lon - LONLIM[0]) * cpd + 0.5)
    row = np.minimum(row, NUM_ROW)  # the top and east edges belong to the last cell
    col = np.minimum(col, NUM_COL)
    ok = (lat >= LATLIM[0]) & (lat <= LATLIM[1]) & (lon >= LONLIM[0]) & (lon <= LONLIM[1])
    return row, col, ok


def num(arr):
    """Text column to float; unparseable values become NaN (as MATLAB's %f does)."""
    return pd.to_numeric(pd.Series(arr.to_pylist(), dtype="string"), errors="coerce").to_numpy(dtype=float, na_value=np.nan)


def process_stream(stream, filters):
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
    acc = {k: {"pairs": [], "mmsi": set(), "rows": 0} for k in filters}
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
            a = acc[k]
            a["rows"] += int(good.sum())
            a["mmsi"].update(np.unique(mmsi).tolist())
            row, colx, ok = discrete(lat, lon)
            cell = row[ok] + (colx[ok] - 1) * NUM_ROW
            a["pairs"].append(np.unique(np.column_stack([cell, mmsi[ok]]), axis=0))
    out = {}
    for k, a in acc.items():
        p = np.unique(np.vstack(a["pairs"]), axis=0) if a["pairs"] else np.zeros((0, 2))
        out[k] = (p, a["rows"], len(a["mmsi"]))
    if bad["rows"]:
        print("  skipped %d malformed rows" % bad["rows"], flush=True)
    return out


def build_day(day, out_dir):
    todo = {k: f for k, f in FILTERS.items() if not os.path.isfile("%s/%s" % (out_dir, cache_name(day, f)))}
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
            res = process_stream(zstandard.ZstdDecompressor().stream_reader(tmp), todo)
        else:
            with zipfile.ZipFile(tmp) as z:
                member = [n for n in z.namelist() if n.endswith(".csv")][0]
                with z.open(member) as f:
                    res = process_stream(f, todo)
    for k, (pairs, rows, nm) in res.items():
        out = "%s/%s" % (out_dir, cache_name(day, todo[k]))
        tmp_out = out + ".part.mat"  # rename into place so a reader never sees a partial file
        scipy.io.savemat(tmp_out, {"pairs": pairs.astype(float), "num_row_kept": float(rows),
                                   "num_mmsi_kept": float(nm)}, do_compression=True)
        os.replace(tmp_out, out)
        print("%s %s rows %d mmsi %d pairs %d" % (day, k, rows, nm, len(pairs)), flush=True)


if __name__ == "__main__":
    out_dir = sys.argv[1]
    for d in sys.argv[2:]:
        build_day(d, out_dir)
