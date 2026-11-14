"""Draw the stratified photo-coding sample (plan step A3).

Usage: python3 python/photo_sample_draw_rev1.py <kept_ships.csv> <out_dir> [seed]

Input columns: imo, mmsi, name, ship_group (cargo, tanker, passenger, other).
Writes three files to <out_dir>:
  coder_a.csv  every sampled ship, in a shuffled order
  coder_b.csv  the second-coder subset (about 20% of each group)
  key.csv      imo, ship_group, second_coder: kept by the person running the
               coding, not given to the coders, so neither coder sees the group
               or which ships are double-coded (review R3COD-15)
The coder sheets carry imo, mmsi, name, and the blank coding columns.

The draw is reproducible: rows are sorted by IMO number before sampling, so
the same ships and seed give the same sample in any input order (R3COD-3).
Blank IMO numbers, a ship listed under two groups, and unknown groups stop the
run; a group smaller than its quota is taken whole, with a warning (R3COD-4).
Planted ships are added by the person running the coding.
"""
import os
import sys
import warnings

import pandas as pd

QUOTA = {"cargo": 100, "tanker": 100, "passenger": 50, "other": 50}
OVERLAP = 0.20
BLANK = ["photo_url", "photo_date", "antennas_seen", "code", "note"]


def draw(ships, seed):
    need = {"imo", "mmsi", "name", "ship_group"}
    if not need <= set(ships.columns):
        raise ValueError(f"missing columns: {sorted(need - set(ships.columns))}")
    ships = ships.copy()
    ships["imo"] = ships["imo"].astype("string").str.strip()
    if ships["imo"].isna().any() or (ships["imo"] == "").any():
        raise ValueError("blank IMO numbers in the input; every kept ship needs one")
    bad = set(ships.ship_group) - set(QUOTA)
    if bad:
        raise ValueError(f"unknown ship_group values: {sorted(bad)}")
    groups = ships.groupby("imo")["ship_group"].nunique()
    if (groups > 1).any():
        raise ValueError(f"ships listed under more than one group: {sorted(groups[groups > 1].index)[:10]}")
    ships = ships.drop_duplicates("imo").sort_values("imo", kind="mergesort").reset_index(drop=True)
    parts = []
    for i, (group, n) in enumerate(QUOTA.items()):
        pool = ships[ships.ship_group == group]
        if len(pool) < n:
            warnings.warn(f"group {group!r} has {len(pool)} ships, fewer than its quota of {n}; taking all of them")
        parts.append(pool.sample(n=min(n, len(pool)), random_state=seed + i))
    sample = pd.concat(parts, ignore_index=True)
    sample["second_coder"] = 0
    # Overlap drawn within each group so every group has second-coder ships
    # (at least one for any non-empty group).
    for i, group in enumerate(QUOTA):
        idx = sample.index[sample.ship_group == group]
        if len(idx) == 0:
            continue
        k = max(1, round(OVERLAP * len(idx)))
        sample.loc[sample.loc[idx].sample(n=k, random_state=seed + 100 + i).index, "second_coder"] = 1
    for c in BLANK:
        sample[c] = ""
    return sample.sample(frac=1, random_state=seed + 200).reset_index(drop=True)


def main(src, out_dir, seed=20261113):
    sample = draw(pd.read_csv(src, dtype=str), int(seed))
    os.makedirs(out_dir, exist_ok=True)
    sheet = ["imo", "mmsi", "name"] + BLANK
    sample[sheet].to_csv(os.path.join(out_dir, "coder_a.csv"), index=False)
    sample.loc[sample.second_coder == 1, sheet].to_csv(os.path.join(out_dir, "coder_b.csv"), index=False)
    sample[["imo", "ship_group", "second_coder"]].to_csv(os.path.join(out_dir, "key.csv"), index=False)
    print(f"sample {len(sample)}; second coder {int((sample.second_coder == 1).sum())}; seed {seed}")
    print(sample.groupby("ship_group").size().to_string())


if __name__ == "__main__":
    main(*sys.argv[1:4])
