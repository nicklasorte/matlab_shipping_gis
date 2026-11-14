"""Estimate the share of kept ships that carry an S-band radar from the photo
coding (plan step C4; protocol docs/protocols/photo_coding_protocol_rev1.md).

Usage:
  python3 python/sband_carriage_rate.py <coder_a.csv> <coder_b.csv> <key.csv> <kept_ships.csv> [out_dir]

Inputs:
  coder_a.csv, coder_b.csv  filled coding sheets (imo, code, ...); codes are
                            S, X_only, unclear, no_radar, no_photo
  key.csv                   imo, ship_group, second_coder; planted research
                            ships carry ship_group "planted"
  kept_ships.csv            imo, ship_group for every kept ship (group weights)

Coder A's codes are the estimate; coder B's are used only for agreement.
Outputs (out_dir, default outputs/2024_2025/carriage):
  sband_carriage_rate.csv   one row per group plus "overall": n coded, n S,
                            rate with 95% Wilson interval, the unclear bounds
                            (every unclear is S / none is), and no_photo share
  sband_carriage_checks.json  Cohen's kappa on the overlap, planted ships coded S

Rate (protocol "Estimate" 1-3): S over coded ships with a photo that are not
unclear or no_photo. The overall rate weights each group by its share of the
kept ships; its interval combines the group variances (normal approximation),
because a Wilson interval has no standard stratified form.
"""
import json
import math
import os
import sys

import pandas as pd

CODES = ["S", "X_only", "unclear", "no_radar", "no_photo"]
GROUPS = ["cargo", "tanker", "passenger", "other"]
Z = 1.959963984540054   # two-sided 95% normal quantile


def wilson(k, n, z=Z):
    """Wilson score interval for k successes in n trials; (nan, nan) when n is 0."""
    if n == 0:
        return float("nan"), float("nan")
    p = k / n
    den = 1 + z * z / n
    mid = (p + z * z / (2 * n)) / den
    half = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / den
    return mid - half, mid + half


def cohen_kappa(a, b, labels=CODES):
    """Unweighted Cohen's kappa for two equal-length label lists."""
    n = len(a)
    if n == 0:
        return float("nan")
    po = sum(x == y for x, y in zip(a, b)) / n
    pe = sum((a.count(c) / n) * (b.count(c) / n) for c in labels)
    return float("nan") if pe == 1 else (po - pe) / (1 - pe)


def read_sheet(path):
    s = pd.read_csv(path, dtype=str)
    s["imo"] = s["imo"].str.strip()
    s["code"] = s["code"].fillna("").str.strip()
    bad = sorted(set(s["code"]) - set(CODES))
    if bad:
        raise ValueError(f"{path}: unknown or blank codes {bad}; every row needs one of {CODES}")
    if s["imo"].duplicated().any():
        raise ValueError(f"{path}: an IMO number appears twice")
    return s


def group_row(codes):
    n_s = int((codes == "S").sum())
    n_unclear = int((codes == "unclear").sum())
    n_photo = int((codes != "no_photo").sum())
    n = n_photo - n_unclear                      # coded with a usable photo, not unclear
    lo, hi = wilson(n_s, n)
    return dict(ships=len(codes), coded=n, s=n_s, unclear=n_unclear, no_photo=len(codes) - n_photo,
                rate=n_s / n if n else float("nan"), wilson_lo=lo, wilson_hi=hi,
                bound_none_unclear_s=n_s / n_photo if n_photo else float("nan"),
                bound_all_unclear_s=(n_s + n_unclear) / n_photo if n_photo else float("nan"),
                no_photo_share=(len(codes) - n_photo) / len(codes) if len(codes) else float("nan"))


def estimate(coder_a, coder_b, key, kept):
    key = key.assign(imo=key["imo"].astype(str).str.strip())
    a = coder_a.merge(key[["imo", "ship_group", "second_coder"]], on="imo", how="left")
    if a["ship_group"].isna().any():
        raise ValueError("coder A rows with no key entry: " + ", ".join(a.loc[a.ship_group.isna(), "imo"]))
    weights = kept["ship_group"].value_counts(normalize=True)
    rows, var, wsum, est, lo_b, hi_b = [], 0.0, 0.0, 0.0, 0.0, 0.0
    for g in GROUPS:
        r = group_row(a.loc[a.ship_group == g, "code"])
        r["group"], r["weight"] = g, float(weights.get(g, 0.0))
        rows.append(r)
        if r["coded"] > 0 and r["weight"] > 0:
            p = r["rate"]
            est += r["weight"] * p
            var += r["weight"] ** 2 * p * (1 - p) / r["coded"]
            lo_b += r["weight"] * r["bound_none_unclear_s"]
            hi_b += r["weight"] * r["bound_all_unclear_s"]
            wsum += r["weight"]
    if wsum > 0:
        est, lo_b, hi_b, var = est / wsum, lo_b / wsum, hi_b / wsum, var / wsum ** 2
    sd = math.sqrt(var)
    rows.append(dict(group="overall", weight=wsum, ships=int(a.ship_group.isin(GROUPS).sum()),
                     coded=sum(r["coded"] for r in rows), s=sum(r["s"] for r in rows),
                     unclear=sum(r["unclear"] for r in rows), no_photo=sum(r["no_photo"] for r in rows),
                     rate=est, wilson_lo=max(0.0, est - Z * sd), wilson_hi=min(1.0, est + Z * sd),
                     bound_none_unclear_s=lo_b, bound_all_unclear_s=hi_b,
                     no_photo_share=sum(r["no_photo"] for r in rows) / max(1, int(a.ship_group.isin(GROUPS).sum()))))
    table = pd.DataFrame(rows)[["group", "weight", "ships", "coded", "s", "unclear", "no_photo", "rate",
                                "wilson_lo", "wilson_hi", "bound_none_unclear_s", "bound_all_unclear_s",
                                "no_photo_share"]]
    both = coder_a.merge(coder_b[["imo", "code"]], on="imo", suffixes=("_a", "_b"))
    kappa = cohen_kappa(list(both.code_a), list(both.code_b))
    planted = a[a.ship_group == "planted"]
    checks = dict(overlap_ships=len(both), cohen_kappa=kappa, kappa_meets_0_7=bool(kappa >= 0.7),
                  agreement=float((both.code_a == both.code_b).mean()) if len(both) else float("nan"),
                  planted_ships=len(planted),
                  planted_coded_s=int((planted.code == "S").sum()),
                  planted_not_s=list(planted.loc[planted.code != "S", "imo"]))
    return table, checks


def main(a_path, b_path, key_path, kept_path, out_dir=None):
    out_dir = out_dir or os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "outputs", "2024_2025", "carriage")
    os.makedirs(out_dir, exist_ok=True)
    table, checks = estimate(read_sheet(a_path), read_sheet(b_path), pd.read_csv(key_path, dtype=str),
                             pd.read_csv(kept_path, dtype=str))
    table.to_csv(os.path.join(out_dir, "sband_carriage_rate.csv"), index=False, float_format="%.4f")
    with open(os.path.join(out_dir, "sband_carriage_checks.json"), "w") as f:
        json.dump(checks, f, indent=1)
    print(table.to_string(index=False))
    print(json.dumps(checks, indent=1))


if __name__ == "__main__":
    main(*sys.argv[1:6])
