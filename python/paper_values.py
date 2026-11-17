"""Write values the paper cites that no other output file holds (plan step T3;
review R4NUM-9, R4NUM-13, R4NUM-14).

Usage: python3 python/paper_values.py
Writes outputs/paper_values_rev1.json and adds head_port_km to
outputs/2024_2025/viz/corridor_summary.csv.

- Section 1.6: median absolute difference between AIS length and Wikidata
  length for the matched cargo, tanker, and passenger ships.
- Section 1.4: lengths of the large ships (3,000 GT or more) the 100 m test
  drops, and the share of them at 87-99 m.
- Appendix A.6: share of route cells in groups of 5 cells or fewer, and the
  largest connected group's share (8-connected), for all route cells and the
  one-year cells.
- Table 6 and Figure A-18: each corridor's head-port distance (corridor_marks.csv).
"""
import csv
import json
import os

import numpy as np
import pandas as pd
from scipy import ndimage

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
VIZ = os.path.join(ROOT, "outputs", "2024_2025", "viz")


def gt_check():
    v = pd.read_csv(os.path.join(ROOT, "data", "ais_vessels_2024_4days.csv"))
    w = pd.read_csv(os.path.join(ROOT, "data", "wikidata_imo_gt_len.csv"))
    v = v[v.vessel_type.between(60, 89) & v.imo.notna()].copy()
    v["imo"] = v.imo.astype(str).str.replace("IMO", "").str.replace(".0", "", regex=False).str.strip()
    w["imo"] = w.imo.astype(str)
    w["gt"] = pd.to_numeric(w["gt"], errors="coerce")
    w["len"] = pd.to_numeric(w["len"], errors="coerce")
    m = v.merge(w, on="imo")
    m = m[m["gt"] > 0]
    both = m[m.length_m.notna() & m.len.notna() & (m.len > 0)]
    big_drop = m[(m["gt"] >= 3000) & (m.length_m < 100)]
    return {
        "matched_ships": int(len(m)),
        "median_abs_length_difference_m": round(float((both.length_m - both.len).abs().median()), 2),
        "large_ships_dropped": int(len(big_drop)),
        "dropped_share_87_to_99_m": round(float(big_drop.length_m.between(87, 99).mean()), 3),
        "dropped_median_length_m": float(big_drop.length_m.median()),
    }


def specks():
    z = np.load(os.path.join(VIZ, "viz_cells.npz"))
    nr = int(z["grid"][3])   # grid = [lat0, lon0, cell size, rows, columns]
    out = {}
    for name, cells in (("all_route_cells", z["route_cells"]), ("one_year_cells", np.setdiff1d(z["route_cells"], z["both_years"]))):
        cells = np.asarray(cells, np.int64)
        r, c = (cells - 1) % nr, (cells - 1) // nr
        r0, c0 = r.min(), c.min()
        img = np.zeros((r.max() - r0 + 1, c.max() - c0 + 1), bool)
        img[r - r0, c - c0] = True
        lab, n = ndimage.label(img, structure=np.ones((3, 3)))
        size = np.bincount(lab.ravel())[1:]
        out[name] = {"cells": int(len(cells)), "groups": int(n),
                     "share_in_groups_of_5_or_fewer": round(float(size[size <= 5].sum() / len(cells)), 4),
                     "largest_group_share": round(float(size.max() / len(cells)), 4)}
    return out


def head_ports():
    """Add head_port_km (the corridor's end mark) to corridor_summary.csv."""
    marks = pd.read_csv(os.path.join(VIZ, "corridor_marks.csv"))
    end = marks[marks.role == "end"].set_index("corridor").km
    path = os.path.join(VIZ, "corridor_summary.csv")
    summ = pd.read_csv(path)
    summ["head_port_km"] = summ.corridor.map(end)
    summ.to_csv(path, index=False)
    return {c: float(k) for c, k in end.items()}


def main():
    vals = {"note": "Values cited in the paper with no other output file (plan step T3)",
            "gt_check_section_1_4_and_1_6": gt_check(), "route_cell_groups_appendix_a6": specks(),
            "corridor_head_port_km_table_6": head_ports()}
    with open(os.path.join(ROOT, "outputs", "paper_values_rev1.json"), "w") as f:
        json.dump(vals, f, indent=1)
    print(json.dumps(vals, indent=1))


if __name__ == "__main__":
    main()
