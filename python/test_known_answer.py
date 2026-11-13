"""Known-answer test: a synthetic AIS day with known cells, through the Python pipeline.

Ten made-up ships at cell centers (and on grid edges), so every expected cell
can be written down by hand:
  ships 1-6  straight tracks in the lower 48
  ship 7     one report on each edge of the lower-48 grid (top and east edges
             belong to the last row and column)
  ship 8     reports on both sides of 180 degrees; the Alaska grid stops at 180,
             so the report at 179.995 E must be dropped
  ship 9     a planted position jump (far report 10 minutes after a near one);
             the pipeline keeps it, and flagged_pairs_day.flags() must flag it
  ship 10    90 m long, so the 100 m filter must drop it
The expected cells are computed here without ais_cells_py_rev1.discrete().
Writes tests/known_answer/ais-2030-01-02.csv and expected.json (for the
MATLAB check, check_known_answer_rev1.m) and exits nonzero on any mismatch.

Usage: python3 python/test_known_answer.py
"""
import io
import json
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, ROOT)
sys.path.insert(0, HERE)
import ais_cells_py_rev1 as cells  # noqa: E402
import flagged_pairs_day as fp  # noqa: E402

OUT = os.path.join(ROOT, "tests", "known_answer")
GRIDS = {"conus": ((22.0, 50.0), (-130.0, -66.0)), "alaska180": ((51.0, 72.0), (-180.0, -129.0))}


def expected_cell(lat, lon, grid):
    """1-based column-major index by hand: centers are unambiguous; top and east edges -> last cell."""
    (la0, la1), (lo0, lo1) = GRIDS[grid]
    if not (la0 <= lat <= la1 and lo0 <= lon <= lo1):
        return None
    nr, nc = round((la1 - la0) * 100), round((lo1 - lo0) * 100)
    r = min(math.floor(round((lat - la0) * 100, 6)) + 1, nr)
    c = min(math.floor(round((lon - lo0) * 100, 6)) + 1, nc)
    return r + (c - 1) * nr


def make_reports():
    rep = []   # mmsi, time, lat, lon, length

    def add(m, t, la, lo, ln=200):
        rep.append((m, t, la, lo, ln))
    for i in range(6):
        for k in range(5):
            add(366000001 + i, f"2030-01-02T0{k}:00:00", 30.005 + 0.5 * i + 0.01 * k, -80.005 + 0.02 * k)
    add(366000007, "2030-01-02T01:00:00", 50.0, -70.005)    # top edge
    add(366000007, "2030-01-02T02:00:00", 40.005, -66.0)    # east edge
    add(366000007, "2030-01-02T03:00:00", 22.0, -90.005)    # bottom edge
    add(366000007, "2030-01-02T04:00:00", 35.005, -130.0)   # west edge
    add(366000008, "2030-01-02T01:00:00", 60.005, -179.995)
    add(366000008, "2030-01-02T02:00:00", 60.005, 179.995)  # west of 180: outside the Alaska grid
    add(366000008, "2030-01-02T03:00:00", 60.005, -179.985)
    add(366000009, "2030-01-02T01:00:00", 35.005, -75.005)
    add(366000009, "2030-01-02T01:10:00", 45.005, -125.005)  # planted jump
    add(366000009, "2030-01-02T01:20:00", 35.015, -75.005)
    add(366000010, "2030-01-02T01:00:00", 33.005, -78.005, 90)  # too short
    return rep


def main():
    os.makedirs(OUT, exist_ok=True)
    rep = make_reports()
    lines = ["mmsi,base_date_time,longitude,latitude,sog,cog,heading,vessel_name,imo,call_sign,vessel_type,status,length,width,draft,cargo,transceiver"]
    for m, t, la, lo, ln in rep:
        lines.append(f"{m},{t},{lo:.6f},{la:.6f},12.0,90,90,TEST,IMO9{m % 1000000:06d},CALL,70,0,{ln},30,10,70,A")
    csv_text = "\n".join(lines) + "\n"
    open(os.path.join(OUT, "ais-2030-01-02.csv"), "w").write(csv_text)
    exp = {g: sorted({(expected_cell(la, lo, g), m) for m, t, la, lo, ln in rep
                      if ln >= 100 and expected_cell(la, lo, g) is not None}) for g in GRIDS}
    json.dump({g: [[c, m] for c, m in v] for g, v in exp.items()}, open(os.path.join(OUT, "expected.json"), "w"), indent=1)
    res = cells.process_stream(io.BytesIO(csv_text.encode()), {"main": cells.FILTERS["main"]}, grids=(None, "alaska180"))
    ok = True
    for g, key in (("conus", None), ("alaska180", "alaska180")):
        got = sorted({(int(c), int(m)) for c, m in res[(key, "main")][0]})
        same = got == exp[g]
        ok &= same
        print(f"{g}: expected {len(exp[g])} pairs, Python {len(got)}, {'exact' if same else 'MISMATCH'}")
        if not same:
            print("  missing:", sorted(set(exp[g]) - set(got)), " extra:", sorted(set(got) - set(exp[g])))
    # The jump report must be flagged
    d = {"mmsi": np.array([str(r[0]) for r in rep]), "t": np.array([r[1] for r in rep], dtype="datetime64[s]"),
         "lat": np.array([r[2] for r in rep]), "lon": np.array([r[3] for r in rep])}
    f = fp.flags(d)
    jump_idx = [i for i, r in enumerate(rep) if r[0] == 366000009 and r[2] == 45.005]
    flagged_ok = bool(f[jump_idx].all()) and int(f.sum()) >= 1
    print(f"jump flagged: {flagged_ok} ({int(f.sum())} reports flagged)")
    ok &= flagged_ok
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
