"""Build the decision table (plan workstream R) from zone-run logs (land only; population dropped November 20).

Usage: python3 python/decision_table.py <log_dir>

Reads "U.S. land in zone" lines from each run log in log_dir (written by the
MATLAB zone runs) and writes outputs/decision_table_rev1.csv: one row per run
and region with land at 25, 50, and 100 km and the change from the base run of
that region.
"""
import os
import re
import sys

import pandas as pd

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
# run log name -> (region, base run, description, decision or finding).
# alaska.log is the all-400-hexagon run (made before D2 changed the Alaska
# default); alaska_west180 is left out because the 2018-2019 files hold no
# reports west of 180 (D11).
RUNS = {
    "lower48": ("lower48", "lower48", "Base: lower 48, current method", ""),
    "no_tug": ("lower48", "lower48", "Tug-barge rule off", "D7, R4OPP-1"),
    "both_years": ("lower48", "lower48", "Cell must meet the ship threshold in both years", "R4OPP-7"),
    "no_great_lakes": ("lower48", "lower48", "Without Great Lakes and St. Lawrence routes", "D8, R4OPP-2"),
    "great_lakes_only": ("lower48", "lower48", "Great Lakes and St. Lawrence routes only (the Great Lakes layer)", "D8, R4OPP-2"),
    "underway": ("lower48", "lower48", "Reports over 3 knots only (ships under way)", "D10, R4OPP-4"),
    "no_lakers": ("lower48", "lower48", "Without ships seen only inside the Great Lakes box (by ship)", "R5MET-1, R5OPP-2"),
    "lakers_only": ("lower48", "lower48", "Only ships seen only inside the Great Lakes box (by ship)", "R5MET-1, R5OPP-2"),
    "no_st_lawrence": ("lower48", "lower48", "Without the St. Lawrence cells from Canadian and World Bank density", "D12"),
    "alaska_all400": ("alaska", "alaska_d2", "All 400 satellite hexagons", "D2"),
    "alaska_x0.5": ("alaska", "alaska_all400", "Satellite cutoff at half (all hexagons at or above it)", "R3OPP-1"),
    "alaska_x2": ("alaska", "alaska_all400", "Satellite cutoff at double (all hexagons at or above it)", "R3OPP-1"),
    "guam": ("guam", "guam", "Base: Guam and the Northern Mariana Islands (ship-days rule)", "D13"),
    "hawaii": ("hawaii", "hawaii", "Base: Hawaii", ""),
    "prusvi": ("prusvi", "prusvi", "Base: Puerto Rico and USVI", ""),
    "alaska_d2": ("alaska", "alaska_d2", "Base after D2: satellite hexagons beyond 74 km only (290)", "D2, R3OPP-1"),
    "alaska_nosat": ("alaska", "alaska_d2", "No satellite hexagons", "R2OPP-1"),
}
LAND = re.compile(r"(\d+) km: \d+ regions, U\.S\. land in zone (\d+) km\^2")


def land_from_log(path):
    out = {}
    for line in open(path, errors="replace"):
        m = LAND.search(line)
        if m:
            out[int(m.group(1))] = int(m.group(2))
    return out


def main(log_dir):
    land = {}
    for run in RUNS:
        p = os.path.join(log_dir, f"{run}.log")
        if os.path.exists(p):
            land[run] = land_from_log(p)
    rows = []
    for run, (region, base, desc, ref) in RUNS.items():
        if run not in land or len(land[run]) < 3:
            continue
        row = dict(run=run, region=region, description=desc, decision_or_finding=ref,
                   source_log=os.path.relpath(os.path.join(log_dir, f"{run}.log"), ROOT))
        for km in (25, 50, 100):
            row[f"land_{km}km_km2"] = land[run][km]
            if base in land and base != run and km in land[base]:
                row[f"land_change_{km}km_pct"] = round(100 * (land[run][km] / land[base][km] - 1), 1)
        rows.append(row)
    out = pd.DataFrame(rows)
    out.to_csv(os.path.join(ROOT, "outputs", "decision_table_rev1.csv"), index=False)
    print(out.drop(columns=["source_log", "description"]).to_string(index=False))


if __name__ == "__main__":
    main(sys.argv[1])
