"""Draw the stratified photo-coding sample (plan step A3).

Usage: python3 python/photo_sample_draw_rev1.py <kept_ships.csv> <out_dir> [seed]

Input columns: imo, mmsi, name, ship_group (cargo, tanker, passenger, other).
Writes <out_dir>/coder_a.csv and coder_b.csv. Coder A gets the whole sample,
coder B the random 20% marked second_coder=1. Both sheets carry the same blank
coding columns. Planted ships are added by the person running the coding.
"""
import os
import sys

import pandas as pd

QUOTA = {"cargo": 100, "tanker": 100, "passenger": 50, "other": 50}
OVERLAP = 0.20
BLANK = ["photo_url", "photo_date", "antennas_seen", "code", "note"]


def draw(ships, seed):
    need = {"imo", "mmsi", "name", "ship_group"}
    if not need <= set(ships.columns):
        raise ValueError(f"missing columns: {sorted(need - set(ships.columns))}")
    ships = ships.drop_duplicates("imo")
    bad = set(ships.ship_group) - set(QUOTA)
    if bad:
        raise ValueError(f"unknown ship_group values: {sorted(bad)}")
    parts = []
    for i, (group, n) in enumerate(QUOTA.items()):
        pool = ships[ships.ship_group == group]
        parts.append(pool.sample(n=min(n, len(pool)), random_state=seed + i))
    sample = pd.concat(parts, ignore_index=True)
    sample["second_coder"] = 0
    # Overlap drawn within each group so every group has second-coder ships.
    for i, group in enumerate(QUOTA):
        idx = sample.index[sample.ship_group == group]
        k = round(OVERLAP * len(idx))
        sample.loc[sample.loc[idx].sample(n=k, random_state=seed + 100 + i).index, "second_coder"] = 1
    for c in BLANK:
        sample[c] = ""
    # Shuffle so the sheet order doesn't reveal the group.
    return sample.sample(frac=1, random_state=seed + 200).reset_index(drop=True)


def main(src, out_dir, seed=20261113):
    sample = draw(pd.read_csv(src, dtype=str), int(seed))
    os.makedirs(out_dir, exist_ok=True)
    sample.to_csv(os.path.join(out_dir, "coder_a.csv"), index=False)
    sample[sample.second_coder == 1].to_csv(os.path.join(out_dir, "coder_b.csv"), index=False)
    print(f"sample {len(sample)}; second coder {int((sample.second_coder == 1).sum())}; seed {seed}")
    print(sample.groupby("ship_group").size().to_string())


if __name__ == "__main__":
    main(*sys.argv[1:4])
