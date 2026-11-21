"""Tabulate the Guam ship-days sensitivity run (review R6MET-2) from the run logs.

Usage: python3 python/guam_sensitivity.py [log dir] -> outputs/guam/guam_sensitivity_rev1.csv
"""
import csv, os, re, sys
D = sys.argv[1] if len(sys.argv) > 1 else "outputs/rerun_logs_20261121/guam_sensitivity"
rows = []
for sd in (2, 3, 4, 6, 8, 12):
    for lk in ("false", "true"):
        t = open(f"{D}/sd{sd}_links_{lk}.log").read()
        assert t.count("COMMIT ") == 1 and t.count("shipping_zone_rev1: done") == 1, (sd, lk)
        a = {int(d): float(v) for d, v in re.findall(r"(\d+) km: \d+ regions, U.S. land in zone (\d+) km", t)}
        land = float(re.search(r"U.S. land in the grid: (\d+) km", t).group(1))
        src = int(re.search(r"AIS source cells \(ship_days rule\): (\d+)", t).group(1))
        ports = int(re.search(r"Port check: (\d) of 4", t).group(1))
        rows.append(dict(min_ship_days=sd, links=lk, ais_cells=src, km2_25=a[25], km2_50=a[50], km2_100=a[100],
                         land_in_grid_km2=land, ports_reached=ports))
os.makedirs("outputs/guam", exist_ok=True)
with open("outputs/guam/guam_sensitivity_rev1.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
for r in rows: print(r)
