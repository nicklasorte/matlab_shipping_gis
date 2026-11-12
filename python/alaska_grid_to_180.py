"""Make Alaska day caches on the 180 W to 129 W grid from the 172 E to 129 W caches.

The "alaska" grid stores longitudes 172 E to 129 W as 172-231 (0-360). Its column
801 starts at 180 degrees, so the cells east of 180 map to the "alaska180" grid
(-180 to -129) by subtracting 800 from the column. Rows are the same (51-72 N).
Pairs west of 180 are dropped. Output names follow cache_name(day, filt, "alaska180"),
so MATLAB (ais_cache_name_rev1.m) finds them for a grid of [51 72] x [-180 -129].

Usage: python3 python/alaska_grid_to_180.py   (all 2018-2019 Alaska caches in data/)
"""
import glob
import os
import sys

import numpy as np
import scipy.io

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, ROOT)
import ais_cells_py_rev1 as cells  # noqa: E402

COL_SHIFT = round((180.0 - cells.GRIDS["alaska"][1][0]) / cells.CELL_DEG)   # 800
NR = cells.grid_size("alaska")[0]
assert NR == cells.grid_size("alaska180")[0]


def main():
    n = 0
    for f in sorted(glob.glob(os.path.join(ROOT, "data", "ais_cells_*_51_72_172_231_d0.01_rev1.mat"))):
        out = f.replace("_51_72_172_231_", "_51_72_-180_-129_")
        if os.path.isfile(out):
            continue
        m = scipy.io.loadmat(f)
        p = m["pairs"].reshape(-1, 2)
        cell = p[:, 0].astype(np.int64)
        col = (cell - 1) // NR + 1
        row = (cell - 1) % NR + 1
        keep = col > COL_SHIFT
        newcell = row[keep] + (col[keep] - COL_SHIFT - 1) * NR
        q = np.column_stack([newcell.astype(float), p[keep, 1]])
        tmp = out + ".part.mat"
        scipy.io.savemat(tmp, {"pairs": q, "num_row_kept": m["num_row_kept"], "num_mmsi_kept": m["num_mmsi_kept"]},
                         do_compression=True)
        os.replace(tmp, out)
        n += 1
    print("wrote", n)


if __name__ == "__main__":
    main()
