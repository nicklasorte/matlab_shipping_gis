"""Day caches at other length cutoffs (80 m and 120 m) for the length sensitivity check.

Downloads each 2024-2025 sample day once and writes cell and ship pair caches
for the main and tug-barge filters at 80 m and 120 m, on the lower-48, Hawaii,
and Puerto Rico grids, into data/length_variants/ (same file format and names
as the committed 100 m caches, with L80 or L120 in the name). Alaska is left out:
its 2018-2019 days would need another 104 downloads.

Usage: python3 python/build_length_variants.py [day ...]   (default: all 104 days)
"""
import os
import sys
import tempfile

import requests
import scipy.io
import zstandard

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, ROOT)
sys.path.insert(0, HERE)
import ais_cells_py_rev1 as cells  # noqa: E402
import ship_period as PER  # noqa: E402

OUT = os.path.join(ROOT, "data", "length_variants")
GRIDS = (None, "hawaii", "prusvi")
FILTS = {f"{k}{L}": dict(v, min_length_m=float(L)) for k, v in cells.FILTERS.items() for L in (80, 120)}


def done(day):
    return all(os.path.isfile(os.path.join(OUT, cells.cache_name(day, f, g))) for f in FILTS.values() for g in GRIDS)


def build(day):
    url = cells.day_url(day)
    with tempfile.TemporaryFile() as tmp:
        with requests.get(url, stream=True, timeout=600) as r:
            r.raise_for_status()
            for chunk in r.iter_content(8 << 20):
                tmp.write(chunk)
        tmp.seek(0)
        res = cells.process_stream(zstandard.ZstdDecompressor().stream_reader(tmp), FILTS, GRIDS)
    for (g, k), (pairs, rows, nm) in res.items():
        out = os.path.join(OUT, cells.cache_name(day, FILTS[k], g))
        tmp_out = out + ".part.mat"
        scipy.io.savemat(tmp_out, {"pairs": pairs.astype(float), "num_row_kept": float(rows),
                                   "num_mmsi_kept": float(nm)}, do_compression=True)
        os.replace(tmp_out, out)
    print(day, "done", flush=True)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    days = sys.argv[1:] or [d.isoformat() for d in PER.days()]
    for d in days:
        if not done(d):
            build(d)
