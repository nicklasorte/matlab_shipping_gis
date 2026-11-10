"""Build per-day AIS cell caches (same format as ais_cache_day_rev1.m) in Python.

Use this when MATLAB's machine is short on disk or bandwidth: it streams each
daily MarineCadastre file (2024+ .csv.zst, 2023 and earlier .zip) without
writing the CSV to disk, applies the same ship filter as
ais_large_ship_cells_rev1.m, bins reports onto the same 0.01-degree grid, and
saves the unique [cell_index, mmsi] pairs as a .mat file that
ais_cache_day_rev1.m loads as is.

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
import pyarrow as pa
import pyarrow.csv as pv
import requests
import scipy.io
import zstandard

# Must match init_shipping_zone_rev1.m
LATLIM = (24.0, 50.0)
LONLIM = (-125.5, -66.0)
CELL_DEG = 0.01
VESSEL_TYPES = sorted(set([0, 31, 32, 33, 35, 52, 55] + list(range(60, 90)) + list(range(90, 100))))
MIN_LENGTH_M = 100.0
NO_IMO_TYPES = {35, 55}
if os.environ.get("SHIPGIS_OLD_TYPES"):  # validation only: the filter before towing was added
    VESSEL_TYPES = sorted(set([0, 33, 35, 55] + list(range(60, 90)) + list(range(90, 100))))

NUM_ROW = round((LATLIM[1] - LATLIM[0]) / CELL_DEG)
NUM_COL = round((LONLIM[1] - LONLIM[0]) / CELL_DEG)


def cache_name(day):
    vt = VESSEL_TYPES
    filt_key = "L%g_imo1_sog0_vt%d-%d-n%d-s%d_ni35-55" % (MIN_LENGTH_M, min(vt), max(vt), len(vt), sum(vt))
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


def process_stream(stream):
    opts = pv.ReadOptions(block_size=64 << 20)
    head = pv.open_csv(stream, read_options=opts,
                       convert_options=pv.ConvertOptions(strings_can_be_null=False))
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
    pairs = []
    mmsi_all = set()
    rows_kept = 0
    for batch in head:
        vt = batch.column(names.index(col["vt"])).to_numpy(zero_copy_only=False).astype(float)
        ln = batch.column(names.index(col["length"])).to_numpy(zero_copy_only=False).astype(float)
        imo_arr = batch.column(names.index(col["imo"]))
        imo = np.array([(s is not None and len(s) > 0) for s in imo_arr.cast(pa.string()).to_pylist()])
        keep = np.isin(vt, VESSEL_TYPES) & (ln >= MIN_LENGTH_M)
        keep &= imo | np.isin(vt, list(NO_IMO_TYPES))
        if not keep.any():
            continue
        lat = batch.column(names.index(col["lat"])).to_numpy(zero_copy_only=False).astype(float)[keep]
        lon = batch.column(names.index(col["lon"])).to_numpy(zero_copy_only=False).astype(float)[keep]
        mmsi = batch.column(names.index(col["mmsi"])).to_numpy(zero_copy_only=False).astype(float)[keep]
        rows_kept += int(keep.sum())
        mmsi_all.update(np.unique(mmsi).tolist())
        row, colx, ok = discrete(lat, lon)
        cell = row[ok] + (colx[ok] - 1) * NUM_ROW
        pairs.append(np.unique(np.column_stack([cell, mmsi[ok]]), axis=0))
    if pairs:
        p = np.unique(np.vstack(pairs), axis=0)
    else:
        p = np.zeros((0, 2))
    return p, rows_kept, len(mmsi_all)


def build_day(day, out_dir):
    if os.path.isfile("%s/%s" % (out_dir, cache_name(day))):
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
            stream = zstandard.ZstdDecompressor().stream_reader(tmp)
            pairs, rows, nm = process_stream(stream)
        else:
            with zipfile.ZipFile(tmp) as z:
                member = [n for n in z.namelist() if n.endswith(".csv")][0]
                with z.open(member) as f:
                    pairs, rows, nm = process_stream(f)
    out = "%s/%s" % (out_dir, cache_name(day))
    tmp_out = out + ".part.mat"  # rename into place so a reader never sees a partial file
    scipy.io.savemat(tmp_out, {"pairs": pairs.astype(float), "num_row_kept": float(rows),
                           "num_mmsi_kept": float(nm)}, do_compression=True)
    os.replace(tmp_out, out)
    print("%s rows %d mmsi %d pairs %d" % (day, rows, nm, len(pairs)), flush=True)


if __name__ == "__main__":
    out_dir = sys.argv[1]
    for d in sys.argv[2:]:
        build_day(d, out_dir)
