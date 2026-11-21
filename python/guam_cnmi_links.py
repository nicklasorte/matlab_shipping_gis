"""Straight-line link cells Guam -> Rota -> Tinian -> Saipan (labeled non-AIS assumption).

The sampled AIS days hold no large-ship lane near Saipan or Tinian (5 and 0 cells within 15 km),
so this writes the cells along straight lines between the harbors, 1 cell wide, as an extra
source for init_shipping_zone_guam_rev1 (cnmi_links=true). Grid matches that init file:
12 to 21.5 N, 143.5 to 147 E, 0.01 deg; index is column-major from the south-west cell, 1-based.
"""
import numpy as np, csv, sys
LAT0, LON0, STEP, NR, NC = 12.0, 143.5, 0.01, 950, 350
PORTS = [(13.4437, 144.6667), (14.1400, 145.1380), (14.9580, 145.6200), (15.2258, 145.7349)]  # Apra, Rota, Tinian, Saipan (G2: confirm)
cells = set()
for (a, b), (c, d) in zip(PORTS[:-1], PORTS[1:]):
    n = int(max(abs(c - a), abs(d - b)) / STEP * 2) + 2
    for t in np.linspace(0, 1, n):
        lat, lon = a + t * (c - a), b + t * (d - b)
        r, col = int((lat - LAT0) / STEP), int((lon - LON0) / STEP)
        assert 0 <= r < NR and 0 <= col < NC
        cells.add(col * NR + r + 1)
out = sys.argv[1] if len(sys.argv) > 1 else "outputs/guam/guam_cnmi_links_cells_rev1.csv"
with open(out, "w", newline="") as f:
    w = csv.writer(f)
    for i in sorted(cells):
        w.writerow([i])
print(len(cells), "cells ->", out)
