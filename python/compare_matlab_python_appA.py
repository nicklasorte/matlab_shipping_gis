"""Compare the MATLAB and Python Appendix A tables for the analysis period.

For every CSV in outputs/<period>/viz_matlab that has a Python counterpart
in outputs/<period>/viz, reports the row counts, the text columns that
differ, and the largest relative difference in each numeric column
(|matlab - python| / max(|python|, 1)). Rows are matched in file order
(both implementations write the same order). Python rounds some columns
for the paper, so a value counts as different only when it differs by more
than half a unit in the last digit Python printed.

Usage: python3 python/compare_matlab_python_appA.py
Writes outputs/<period>/viz_matlab/compare_python.json and prints a table.
"""
import glob
import json
import os
import sys

import numpy as np
import pandas as pd

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ship_period as PER  # noqa: E402  analysis years

ROOT = os.path.join(HERE, "..")
M_DIR = os.path.join(ROOT, "outputs", PER.TAG, "viz_matlab")
P_DIR = os.path.join(ROOT, "outputs", PER.TAG, "viz")


def norm(df):
    df = df.copy()
    df.columns = [c.strip().lower() for c in df.columns]
    for c in df.columns:   # dates: MATLAB writes 03-Jan-2024, Python 2024-01-03
        if c in ("day", "date"):
            df[c] = pd.to_datetime(df[c], format="mixed").dt.strftime("%Y-%m-%d")
    return df


def decimals(text):
    """Digits after the decimal point in each value as Python printed it."""
    t = text.fillna("").astype(str)
    return t.str.extract(r"\.(\d+)$")[0].str.len().fillna(0).to_numpy(int)


def compare(name):
    m = norm(pd.read_csv(os.path.join(M_DIR, name), keep_default_na=False, na_values=[""]))
    p_text = pd.read_csv(os.path.join(P_DIR, name), dtype=str, keep_default_na=False)
    p_text.columns = [c.strip().lower() for c in p_text.columns]
    p = norm(pd.read_csv(os.path.join(P_DIR, name), keep_default_na=False, na_values=[""]))
    r = {"rows_matlab": len(m), "rows_python": len(p),
         "columns_only_matlab": sorted(set(m.columns) - set(p.columns)),
         "columns_only_python": sorted(set(p.columns) - set(m.columns))}
    cols = [c for c in p.columns if c in m.columns]
    text = [c for c in cols if not (pd.api.types.is_numeric_dtype(p[c]) and pd.api.types.is_numeric_dtype(m[c]))]
    num = [c for c in cols if c not in text]
    if len(m) != len(p):
        return r
    # Both implementations write rows in the same order; sorting would mix up ties.
    r["text_columns_differing"] = [c for c in text
                                   if not (m[c].astype(str).str.strip() == p[c].astype(str).str.strip()).all()]
    worst, beyond = {}, {}
    for c in num:
        a, b = m[c].to_numpy(float), p[c].to_numpy(float)
        # Python rounds some columns for the paper; allow half a unit in its last digit.
        tol = 0.5 * 10.0 ** (-decimals(p_text[c])) * (1 + 1e-9) + 1e-9 * np.abs(b)
        diff = np.abs(a - b)
        nan_mismatch = np.isnan(a) != np.isnan(b)
        diff[np.isnan(a) & np.isnan(b)] = 0
        worst[c] = float(np.nanmax(diff / np.maximum(np.abs(b), 1))) if len(diff) else 0.0
        beyond[c] = int(np.sum((diff > tol) | nan_mismatch))
    r["max_rel_diff"] = worst
    r["rows_beyond_rounding"] = beyond
    r["max_rel_diff_any"] = max(worst.values()) if worst else 0.0
    r["cells_beyond_rounding"] = int(sum(beyond.values()))
    return r


def main():
    names = sorted(os.path.basename(f) for f in glob.glob(os.path.join(M_DIR, "*.csv")))
    res = {}
    for n in names:
        if os.path.isfile(os.path.join(P_DIR, n)):
            res[n] = compare(n)
        else:
            res[n] = {"python_counterpart": False}
    with open(os.path.join(M_DIR, "compare_python.json"), "w") as f:
        json.dump(res, f, indent=1)
    print(f"{'file':28s} {'rows M':>8s} {'rows P':>8s} {'max rel diff':>13s} {'beyond rounding':>16s}  notes")
    for n, r in res.items():
        if "rows_matlab" not in r:
            print(f"{n:28s}  no Python counterpart")
            continue
        bz = r.get("rows_beyond_rounding", {})
        wc = ",".join(f"{k}:{v}" for k, v in bz.items() if v)
        note = " ".join(filter(None, [wc, "text differs: " + ",".join(r["text_columns_differing"]) if r.get("text_columns_differing") else "",
                                      "cols only M: " + ",".join(r["columns_only_matlab"]) if r["columns_only_matlab"] else "",
                                      "cols only P: " + ",".join(r["columns_only_python"]) if r["columns_only_python"] else ""]))
        print(f"{n:28s} {r['rows_matlab']:8d} {r['rows_python']:8d} {r.get('max_rel_diff_any', float('nan')):13.2e} {r.get('cells_beyond_rounding', -1):16d}  {note}")


if __name__ == "__main__":
    main()
