"""Known-answer tests for Python route-rule pieces (review R4MET-5).
Run: python3 -m pytest -q python/
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import alaska_satellite_lanes as sat  # noqa: E402
import ship_route_rules as rr  # noqa: E402


def test_select_hexagons_beyond_only():
    kap = np.array([500, 300, 100, 400, 0])
    in_grid = np.array([1, 1, 1, 1, 0], bool)
    near = np.array([1, 0, 0, 1, 0], bool)
    assert sat.select_hexagons(kap, in_grid, near, 250).tolist() == [True, True, False, True, False]
    assert sat.select_hexagons(kap, in_grid, near, 250, beyond_only=True).tolist() == [False, True, False, False, False]


def test_best_cutoff_finds_the_matching_threshold():
    # Near-shore hexagons with route cells are exactly those with 200 or more days.
    rng = np.random.default_rng(0)
    kap = rng.integers(1, 400, 500).astype(float)
    near = np.ones(500, bool)
    has = kap >= 200
    t, cands, jac = sat.best_cutoff(kap, near, has)
    assert jac.max() > 0.95
    assert abs(t - 200) <= 15     # nearest quantile candidate to 200


def test_jaccard():
    a = np.array([1, 2, 3, 4])
    b = np.array([3, 4, 5])
    assert abs(rr.jaccard(a, b) - 2 / 5) < 1e-12
