"""Build the decision table (plan workstream R) from zone-run logs and population.

Usage: python3 python/decision_table.py <log_dir>

Reads "U.S. land in zone" lines from each run log in log_dir (written by the
MATLAB zone runs) and the population rows in outputs/zone_population_rev1.csv,
and writes outputs/decision_table_rev1.csv: one row per run and region with
land and population at 25, 50, and 100 km and the change from the base run of
that region.
"""
import os
import re
import sys

import pandas as pd

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
# run log name -> (region, base run, description, decision or finding)
RUNS = {
    "lower48": ("lower48", "lower48", "Base: lower 48, current method", ""),
    "no_tug": ("lower48", "lower48", "Tug-barge rule off", "D7, R4OPP-1"),
    "both_years": ("lower48", "lower48", "Cell must meet the ship threshold in both years", "R4OPP-7"),
    "no_great_lakes": ("lower48", "lower48", "Without Great Lakes and St. Lawrence routes", "D8, R4OPP-2"),
    "great_lakes_only": ("lower48", "lower48", "Great Lakes and St. Lawrence routes only (the Great Lakes layer)", "D8, R4OPP-2"),
    "underway": ("lower48", "lower48", "Reports over 3 knots only (ships under way)", "D10, R4OPP-4"),
    "hawaii": ("hawaii", "hawaii", "Base: Hawaii", ""),
    "prusvi": ("prusvi", "prusvi", "Base: Puerto Rico and USVI", ""),
    "alaska_d2": ("alaska", "alaska_d2", "Base after D2: satellite hexagons beyond 74 km only (290)", "D2, R3OPP-1"),
    "alaska_all400": ("alaska", "alaska_d2", "All 400 satellite hexagons (base before D2)", "D2"),
    "alaska_nosat": ("alaska", "alaska_d2", "No satellite hexagons", "R2OPP-1"),
    "alaska_west180": ("alaska_west", "alaska_west180", "Western Aleutians, 172 E to 180 (separate grid)", "D11, R4OPP-13"),
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
    pop = pd.DataFrame()
    pp = os.path.join(ROOT, "outputs", "zone_population_rev1.csv")
    if os.path.exists(pp):
        pop = pd.read_csv(pp)
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
            if not pop.empty:
                hit = pop[(pop.run == run) & (pop.distance_km == km)]
                if len(hit):
                    row[f"population_{km}km"] = int(hit.population.iloc[0])
        rows.append(row)
    out = pd.DataFrame(rows)
    out.to_csv(os.path.join(ROOT, "outputs", "decision_table_rev1.csv"), index=False)
    print(out.drop(columns=["source_log", "description"]).to_string(index=False))


if __name__ == "__main__":
    main(sys.argv[1])
