"""Tests for photo_sample_draw_rev1.py (review R3COD-3, R3COD-4, R3COD-5).

Run: python3 -m pytest python/test_photo_sample_draw.py   (or python3 python/test_photo_sample_draw.py)
"""
import os
import sys
import warnings

import pandas as pd

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import photo_sample_draw_rev1 as ps  # noqa: E402


def ships(counts):
    rows, k = [], 9000000
    for g, n in counts.items():
        for _ in range(n):
            k += 1
            rows.append((str(k), str(300000000 + k), f"S{k}", g))
    return pd.DataFrame(rows, columns=["imo", "mmsi", "name", "ship_group"])


def test_quota_and_overlap():
    s = ps.draw(ships({"cargo": 300, "tanker": 300, "passenger": 80, "other": 80}), 7)
    assert s.groupby("ship_group").size().to_dict() == {"cargo": 100, "tanker": 100, "passenger": 50, "other": 50}
    assert s.groupby("ship_group").second_coder.sum().to_dict() == {"cargo": 20, "tanker": 20, "passenger": 10, "other": 10}
    assert s.imo.is_unique


def test_order_independent():
    d = ships({"cargo": 300, "tanker": 300, "passenger": 80, "other": 80})
    a = set(ps.draw(d, 7).imo)
    b = set(ps.draw(d.sample(frac=1, random_state=3), 7).imo)
    assert a == b


def test_short_group_warns_and_gets_a_second_coder():
    with warnings.catch_warnings(record=True) as w:
        warnings.simplefilter("always")
        s = ps.draw(ships({"cargo": 120, "tanker": 120, "passenger": 2, "other": 60}), 7)
    assert any("passenger" in str(x.message) for x in w)
    assert (s.ship_group == "passenger").sum() == 2
    assert s.loc[s.ship_group == "passenger", "second_coder"].sum() == 1


def test_blank_imo_and_two_groups_fail():
    d = ships({"cargo": 120, "tanker": 120, "passenger": 60, "other": 60})
    bad = d.copy()
    bad.loc[0, "imo"] = None
    for frame in (bad,):
        try:
            ps.draw(frame, 7)
        except ValueError:
            pass
        else:
            raise AssertionError("blank IMO accepted")
    two = pd.concat([d, d.iloc[[0]].assign(ship_group="tanker")])
    try:
        ps.draw(two, 7)
    except ValueError:
        pass
    else:
        raise AssertionError("ship in two groups accepted")


if __name__ == "__main__":
    for name, fn in list(globals().items()):
        if name.startswith("test_"):
            fn()
            print("ok", name)
