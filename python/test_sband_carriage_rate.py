"""Tests for python/sband_carriage_rate.py on synthetic coding sheets.
Run: python3 -m pytest python/test_sband_carriage_rate.py
"""
import math
import os
import sys

import numpy as np
import pandas as pd
import pytest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sband_carriage_rate as cr  # noqa: E402


def test_wilson_reference_values():
    # Wilson (1927); 50 of 100 gives 0.4038 to 0.5962, 0 of 10 gives 0 to 0.2775
    lo, hi = cr.wilson(50, 100)
    assert lo == pytest.approx(0.40383, abs=1e-5) and hi == pytest.approx(0.59617, abs=1e-5)
    lo, hi = cr.wilson(0, 10)
    assert lo == pytest.approx(0.0, abs=1e-12) and hi == pytest.approx(0.27753, abs=1e-5)
    assert all(math.isnan(x) for x in cr.wilson(0, 0))


def test_kappa_reference_values():
    assert cr.cohen_kappa(["S", "X_only"] * 5, ["S", "X_only"] * 5) == pytest.approx(1.0)
    # 2x2 table [[20, 5], [10, 15]]: po 0.70, pe 0.50, kappa 0.40
    a = ["S"] * 25 + ["X_only"] * 25
    b = ["S"] * 20 + ["X_only"] * 5 + ["S"] * 10 + ["X_only"] * 15
    assert cr.cohen_kappa(a, b) == pytest.approx(0.40)


def synthetic(seed=1, rate={"cargo": 0.8, "tanker": 0.9, "passenger": 0.5, "other": 0.3}):
    rng = np.random.default_rng(seed)
    rows, key = [], []
    for g, n in cr.__dict__.get("QUOTA", {"cargo": 100, "tanker": 100, "passenger": 50, "other": 50}).items():
        for i in range(n):
            imo = f"{g[:1]}{i:06d}"
            u = rng.random()
            code = "no_photo" if u < 0.05 else ("unclear" if u < 0.10 else ("S" if rng.random() < rate[g] else "X_only"))
            rows.append(dict(imo=imo, code=code))
            key.append(dict(imo=imo, ship_group=g, second_coder="1" if i % 5 == 0 else "0"))
    for i in range(5):
        rows.append(dict(imo=f"P{i:06d}", code="S" if i else "X_only"))
        key.append(dict(imo=f"P{i:06d}", ship_group="planted", second_coder="0"))
    a = pd.DataFrame(rows)
    b = a[a.imo.isin([k["imo"] for k in key if k["second_coder"] == "1"])].copy()
    b.loc[b.index[:3], "code"] = "unclear"          # three disagreements
    kept = pd.DataFrame(dict(imo=range(1000), ship_group=["cargo"] * 400 + ["tanker"] * 300 + ["passenger"] * 100 + ["other"] * 200))
    return a, b, pd.DataFrame(key), kept


def test_estimate_hand_check():
    a, b, key, kept = synthetic()
    table, checks = cr.estimate(a, b, key, kept)
    t = table.set_index("group")
    for g in cr.GROUPS:
        codes = a.merge(key, on="imo").query("ship_group == @g").code
        n = ((codes != "no_photo") & (codes != "unclear")).sum()
        assert t.loc[g, "coded"] == n
        assert t.loc[g, "rate"] == pytest.approx((codes == "S").sum() / n)
        assert t.loc[g, "bound_none_unclear_s"] <= t.loc[g, "rate"] + 0.06
        assert t.loc[g, "bound_none_unclear_s"] <= t.loc[g, "bound_all_unclear_s"]
        assert t.loc[g, "wilson_lo"] < t.loc[g, "rate"] < t.loc[g, "wilson_hi"]
    w = {"cargo": 0.4, "tanker": 0.3, "passenger": 0.1, "other": 0.2}
    assert t.loc["overall", "rate"] == pytest.approx(sum(w[g] * t.loc[g, "rate"] for g in w))
    assert checks["planted_ships"] == 5 and checks["planted_coded_s"] == 4
    assert checks["overlap_ships"] == 60 and 0.7 < checks["cohen_kappa"] < 1.0


def test_unknown_code_stops(tmp_path):
    p = tmp_path / "a.csv"
    pd.DataFrame(dict(imo=["1"], code=["S-band"])).to_csv(p, index=False)
    with pytest.raises(ValueError, match="unknown or blank codes"):
        cr.read_sheet(str(p))


def test_missing_key_stops():
    a, b, key, kept = synthetic()
    with pytest.raises(ValueError, match="no key entry"):
        cr.estimate(a, b, key.iloc[1:], kept)
