"""Build the kept-ship list for 2024-2025 (plan step C1).

Usage: python3 python/kept_ships_aggregate.py <attr_dir>

Reads the per-day attribute files written by python/kept_ship_attributes.sh
(attr_dir/attributes_<day>.csv: mmsi, imo, vessel_name, call_sign,
vessel_type, length, width, reports) and data/kept_mmsi_2024_2025.csv (the
16,085 MMSI numbers in the route caches, with ship_group and days_seen).

For each MMSI, each attribute is the value reported most often over the 104
days, weighted by reports; blanks and IMO0000000 don't count. Writes:
  data/kept_ships_2024_2025.csv    one row per MMSI: mmsi, imo, name,
                                   call_sign, ship_group, vessel_type,
                                   length_m, days_seen, attr_days
  data/kept_ships_photo_frame.csv  the photo-sampling frame: one row per IMO
                                   number (imo, mmsi, name, ship_group); ships
                                   without a valid IMO number (military, law
                                   enforcement, and placeholders such as
                                   0000001 that fail the check digit) are
                                   left out, and an IMO seen
                                   under two MMSI numbers keeps the one seen
                                   on more days
Stops if an MMSI in the list has no attribute row on any day.
"""
import glob
import os
import re
import sys

import pandas as pd

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


def weighted_mode(df, col):
    d = df[[ "mmsi", col, "reports"]].copy()
    d[col] = d[col].astype("string").str.strip()
    d = d[d[col].notna() & (d[col] != "") & (d[col] != "IMO0000000") & (d[col] != "0")]
    w = d.groupby(["mmsi", col], as_index=False)["reports"].sum()
    w = w.sort_values(["mmsi", "reports", col], ascending=[True, False, True])
    return w.drop_duplicates("mmsi").set_index("mmsi")[col]


def imo_valid(imo):
    """IMO ship number check: seven digits, the last equal to the sum of the first six times 7..2, mod 10."""
    if not isinstance(imo, str) or not re.fullmatch(r"\d{7}", imo) or imo == "0000000":
        return False
    return sum(int(d) * w for d, w in zip(imo[:6], range(7, 1, -1))) % 10 == int(imo[6])


def main(attr_dir):
    files = sorted(glob.glob(os.path.join(attr_dir, "attributes_*.csv")))
    if not files:
        raise SystemExit(f"no attributes_*.csv in {attr_dir}")
    A = pd.concat([pd.read_csv(f, dtype=str).assign(day=os.path.basename(f)[11:21]) for f in files], ignore_index=True)
    A["reports"] = pd.to_numeric(A["reports"], errors="coerce").fillna(0)
    kept = pd.read_csv(os.path.join(ROOT, "data", "kept_mmsi_2024_2025.csv"), dtype=str)
    out = kept[["mmsi", "ship_group", "days_seen"]].set_index("mmsi")
    for col, name in [("imo", "imo"), ("vessel_name", "name"), ("call_sign", "call_sign"),
                      ("vessel_type", "vessel_type"), ("length", "length_m")]:
        out[name] = weighted_mode(A, col)
    out["attr_days"] = A.groupby("mmsi")["day"].nunique()
    missing = out.index[out["attr_days"].isna()]
    if len(missing):
        raise SystemExit(f"{len(missing)} kept MMSI numbers have no attribute row, e.g. {list(missing[:5])}")
    out = out.reset_index()[["mmsi", "imo", "name", "call_sign", "ship_group", "vessel_type", "length_m",
                             "days_seen", "attr_days"]]
    out.to_csv(os.path.join(ROOT, "data", "kept_ships_2024_2025.csv"), index=False)
    frame = out[out["imo"].notna()].copy()
    frame["imo"] = frame["imo"].str.replace("IMO", "", regex=False).str.strip()
    frame = frame[frame["imo"].map(imo_valid)]          # check digit; drops placeholders such as 0000001
    frame["days_seen_n"] = pd.to_numeric(frame["days_seen"], errors="coerce")
    frame = frame.sort_values(["imo", "days_seen_n", "mmsi"], ascending=[True, False, True]).drop_duplicates("imo")
    frame[["imo", "mmsi", "name", "ship_group"]].to_csv(os.path.join(ROOT, "data", "kept_ships_photo_frame.csv"), index=False)
    print(f"days: {len(files)} | kept MMSI: {len(out)} (list {len(kept)}) | with IMO: {out.imo.notna().sum()} | "
          f"photo frame (one per IMO): {len(frame)}")
    print(out.ship_group.value_counts().to_string())


if __name__ == "__main__":
    main(sys.argv[1])
