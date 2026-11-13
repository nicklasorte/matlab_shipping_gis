"""Summarize the data-validity checks (ais_qc_day.py) for every area and day.

Reads outputs/<period>/qc/ais_qc_*.json and outputs/2018_2019/qc/ais_qc_*.json,
turns each check into a rate, and applies the gate: an area passes on a day when each rate is at or below a
fixed limit (LIMITS below).

Rates:
  bad_mmsi_pct          ships with a bad MMSI / ships
  bad_imo_pct           IMO numbers failing the check digit / ships with an IMO
  jump_pct              ships with a position jump / ships
  dup_mmsi_pct          ships with a possible duplicate MMSI / ships
  inland_off_route_pct  reports more than 2 km inland, off routes and lakes / reports
  flag_route_pct        route cells made only by flagged reports / route cells

Usage: python3 python/qc_summary.py
Writes outputs/<period>/qc/qc_summary.csv and qc_summary.md.
"""
import glob
import json
import os
import sys

import pandas as pd

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ship_period as PER  # noqa: E402  analysis years

ROOT = os.path.join(HERE, "..")
OUT = os.path.join(ROOT, "outputs", PER.TAG, "qc")
RATES = ["bad_mmsi_pct", "bad_imo_pct", "jump_pct", "dup_mmsi_pct", "inland_off_route_pct", "flag_route_pct"]


def rows():
    files = sorted(glob.glob(os.path.join(OUT, "ais_qc_*.json"))) + \
        sorted(glob.glob(os.path.join(ROOT, "outputs", "2018_2019", "qc", "ais_qc_*.json")))
    for f in files:
        d = json.load(open(f))
        for area, r in d.items():
            if not isinstance(r, dict) or "reports" not in r or "route_cells" not in r:
                continue
            yield {
                "area": area, "day": d["day"], "ships": r["ships"], "reports": r["reports"],
                "bad_mmsi_pct": 100 * r["ships_bad_mmsi"] / r["ships"],
                "bad_imo_pct": 100 * r["ships_imo_bad_check_digit"] / max(r["ships_with_imo"], 1),
                "jump_pct": 100 * r["ships_with_jump"] / r["ships"],
                "dup_mmsi_pct": 100 * r["ships_possible_duplicate_mmsi"] / r["ships"],
                "inland_off_route_pct": 100 * r["reports_on_land_2km_off_routes"] / r["reports"],
                "flag_route_pct": 100 * r["of_which_route_cells"] / r["route_cells"],
                "flag_route_cells": r["of_which_route_cells"],
                "n_bad_mmsi_pct": r["ships_bad_mmsi"], "n_bad_imo_pct": r["ships_imo_bad_check_digit"],
                "n_jump_pct": r["ships_with_jump"], "n_dup_mmsi_pct": r["ships_possible_duplicate_mmsi"],
                "n_inland_off_route_pct": r["reports_on_land_2km_off_routes"], "n_flag_route_pct": r["of_which_route_cells"],
                "inland_off_route_ships": r["ships_on_land_2km_off_routes"],
            }


LABEL = {"bad_mmsi_pct": "bad MMSI", "bad_imo_pct": "bad IMO", "jump_pct": "jumps",
         "dup_mmsi_pct": "shared MMSI", "inland_off_route_pct": "inland", "flag_route_pct": "flagged route cells"}


def gate_text(r):
    if r.passes_gate:
        return "pass"
    worse = "; ".join(f"{LABEL[c]} above the limit ({r['n_' + c]})" for c in r.worse_than_lower_48.split(","))
    return worse + (", no route cell affected" if r.no_route_effect else ", route cells affected")


# Fixed gate limits (review CA-58: limits taken from the lower-48 days being
# tested could never fail the lower 48). Set November 13, 2026, from the worst
# lower-48 rate on the four 2024-2025 days checked, rounded up.
LIMITS = pd.Series({"bad_mmsi_pct": 1.0, "bad_imo_pct": 1.0, "jump_pct": 15.0, "dup_mmsi_pct": 12.0,
                    "inland_off_route_pct": 1.0, "flag_route_pct": 0.2})


def main():
    t = pd.DataFrame(list(rows())).sort_values(["area", "day"]).reset_index(drop=True)
    ref = LIMITS
    t["passes_gate"] = [all(r[c] <= ref[c] + 1e-12 for c in RATES) for _, r in t.iterrows()]
    t["worse_than_lower_48"] = [",".join(c for c in RATES if r[c] > ref[c] + 1e-12) for _, r in t.iterrows()]
    # Small areas can exceed a lower-48 rate by one ship. The second test asks
    # whether the excess could change a route: no route cell made only by
    # flagged reports, and no reports inland off the routes.
    t["no_route_effect"] = (t.flag_route_cells == 0) & (t.n_inland_off_route_pct == 0)
    t.to_csv(os.path.join(OUT, "qc_summary.csv"), index=False)
    lines = ["| Area | Day | Ships | Bad MMSI | Bad IMO | Jumps | Shared MMSI | Inland off routes | Route cells only from flagged reports | Gate |",
             "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |"]
    for _, r in t.iterrows():
        lines.append(f"| {r.area} | {r.day} | {r.ships:,} | {r.bad_mmsi_pct:.1f}% | {r.bad_imo_pct:.1f}% | {r.jump_pct:.1f}% | "
                     f"{r.dup_mmsi_pct:.1f}% | {r.inland_off_route_pct:.2f}% | {r.flag_route_cells:,} ({r.flag_route_pct:.3f}%) | "
                     f"{gate_text(r)} |")
    open(os.path.join(OUT, "qc_summary.md"), "w").write("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
