"""Make Alaska day caches on the 172 E to 180 grid from the 172 E to 129 W caches
(decision D11, review R4OPP-13: the western Aleutians).

The "alaska" grid stores longitudes 172 E to 129 W as 172-231 (0-360). Its first
800 columns cover 172 E to 180, which is exactly the [51 72] x [172 180] grid, so
those cells keep their row and column. Pairs east of 180 are dropped. Output names
follow MATLAB's ais_cache_name_rev1.m for a grid of [51 72] x [172 180].

Usage: python3 python/alaska_grid_west_of_180.py [data_dir]
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

COL_180 = round((180.0 - cells.GRIDS["alaska"][1][0]) / cells.CELL_DEG)   # 800 columns west of 180
NR = cells.grid_size("alaska")[0]


def main(data_dir=None):
    data_dir = data_dir or os.path.join(ROOT, "data")
    n = 0
    for f in sorted(glob.glob(os.path.join(data_dir, "ais_cells_*_51_72_172_231_d0.01_rev1.mat"))):
        out = f.replace("_51_72_172_231_", "_51_72_172_180_")
        if os.path.isfile(out):
            continue
        m = scipy.io.loadmat(f)
        p = m["pairs"].reshape(-1, 2)
        cell = p[:, 0].astype(np.int64)
        col = (cell - 1) // NR + 1
        keep = col <= COL_180
        q = np.column_stack([cell[keep].astype(float), p[keep, 1]])
        tmp = out + ".part.mat"
        scipy.io.savemat(tmp, {"pairs": q, "num_row_kept": m["num_row_kept"], "num_mmsi_kept": m["num_mmsi_kept"]},
                         do_compression=True)
        os.replace(tmp, out)
        n += 1
    print("wrote", n)


if __name__ == "__main__":
    main(*sys.argv[1:2])
