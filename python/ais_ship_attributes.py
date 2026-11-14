"""Stream a MarineCadastre AIS CSV from stdin and write one row per listed ship
with its most common static fields that day (plan step C1).

Usage: ... | python3 ais_ship_attributes.py <mmsi_list.csv> > attributes_<day>.csv
mmsi_list.csv needs an "mmsi" column (data/kept_mmsi_2024_2025.csv).
Output columns: mmsi, imo, vessel_name, call_sign, vessel_type, length, width,
reports. Each field is the most common non-blank value the ship sent that day.
Standard library only, so it runs with the Mac's /usr/bin/python3.
"""
import collections
import csv
import sys

FIELDS = ["imo", "vessel_name", "call_sign", "vessel_type", "length", "width"]


def main():
    with open(sys.argv[1], newline="") as fh:
        keep = {r["mmsi"] for r in csv.DictReader(fh)}
    reader = csv.reader(sys.stdin)
    header = [h.lower() for h in next(reader)]
    idx = {k: header.index(k) for k in ["mmsi"] + FIELDS}
    counts = {}
    for row in reader:
        if len(row) <= idx["mmsi"] or row[idx["mmsi"]] not in keep:
            continue
        c = counts.setdefault(row[idx["mmsi"]], [collections.Counter() for _ in FIELDS] + [0])
        for j, f in enumerate(FIELDS):
            v = row[idx[f]].strip()
            if v:
                c[j][v] += 1
        c[-1] += 1
    w = csv.writer(sys.stdout, lineterminator="\n")
    w.writerow(["mmsi"] + FIELDS + ["reports"])
    for m, c in sorted(counts.items()):
        w.writerow([m] + [(c[j].most_common(1)[0][0] if c[j] else "") for j in range(len(FIELDS))] + [c[-1]])


if __name__ == "__main__":
    main()
