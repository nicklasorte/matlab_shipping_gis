"""Co-channel separation for a share of time with interference (Python twin of emc_joint_rev1.m and the
co-channel rows of init_emc_statistics_rev1.m, at 3050 MHz).

Inputs written by the MATLAB run: outputs/emc/stat_itm_3050_rev1.csv (ITM area-mode loss by distance and time
percentage) and stat_mag_3050_rev1.csv (mutual antenna gain exceedance curves by takeoff angle, from
mutual_antenna_gain). The share of time with interference at distance d for a pair with x = L_req - G_nexrad is
    p(d) = sum_g pmf_MAG(g; d) * T(d, x + g),  T(d, y) = share of time that ITM loss < y,
computed here directly (MATLAB uses an FFT correlation). The separation is the largest distance where
p > q (q = 10, 1, 0.1%), interpolated in -10 log10(p) as in emc_separation_rev1.
Writes outputs/emc/stat_cochannel_py_rev1.csv; must agree with the 3050 MHz rows of
stat_separation_sweep_rev1.csv to 1 km (test_emc_statistics_rev1.m).
"""
import csv
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, HERE)
import emc_link_budget as lb  # noqa: E402

Q = (10.0, 1.0, 0.1)
DX = 0.1


def takeoff_deg(d_km, h_m, n0):
    ae = 1e-3 / (157e-9 * (1 - 0.04665 * math.exp(n0 / 179.3)))
    r = math.sqrt(2 * h_m * 1e-3 / ae)
    d_los = 2 * ae * r
    return np.where(d_km > d_los, -np.degrees(r), np.degrees(-d_km / (2 * ae)))


def pmfs(rows):
    by_el = {}
    for r in rows:
        by_el.setdefault(round(float(r["el_nexrad_deg"]), 6), []).append((float(r["gain_dbi"]), float(r["exceed_pct"]) / 100))
    gmin = min(v[0][0] for v in by_el.values())
    gmax = max(v[-1][0] for v in by_el.values())
    g = np.round(np.arange(math.floor(gmin / DX), math.ceil(gmax / DX) + 1) * DX, 10)
    out = {}
    for el, c in by_el.items():
        c = np.array(sorted(c))
        k = np.searchsorted(c[:, 0], g, side="right") - 1        # "previous" interpolation
        e = np.where(k >= 0, c[np.clip(k, 0, None), 1], 1.0)
        e[g >= c[-1, 0]] = 0.0
        out[el] = -np.diff(np.concatenate(([1.0], e)))
    return g, out


def separation(d, p, q):
    L = -10 * np.log10(np.maximum(p, 1e-15))
    lr = -10 * math.log10(q / 100)
    k = np.nonzero(L < lr)[0]
    if k.size == 0:
        return d[0], -1
    k = k[-1]
    if k == d.size - 1:
        return d[-1], 1
    return float(np.interp(lr, [L[k], L[k + 1]], [d[k], d[k + 1]])), 0


def main():
    P, modes = lb.load()
    em = os.path.join(ROOT, "outputs", "emc")
    with open(os.path.join(em, "stat_itm_3050_rev1.csv")) as f:
        rd = csv.reader(f)
        hdr = next(rd)
        A = np.array([[float(v) for v in r] for r in rd])
    d = A[:, 0]
    qf = np.array([float(h[1:].replace("_", ".")) for h in hdr[1:]]) / 100
    L = A[:, 1:] + np.arange(1, qf.size + 1) * 1e-9
    el = takeoff_deg(d, P["nexrad"]["height_m"], P["analysis"]["n0"])
    with open(os.path.join(em, "stat_mag_3050_rev1.csv")) as f:
        mag = list(csv.DictReader(f))
    gp = {s: pmfs([r for r in mag if r["system"] == s]) for s in ("magnetron", "solid_state")}
    with open(os.path.join(em, "nexrad_sweep_separation_rev1.csv")) as f:
        rows = [r for r in csv.DictReader(f) if r["f_nexrad_mhz"] == "3050"]
    out = os.path.join(em, "stat_cochannel_py_rev1.csv")
    with open(out, "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["direction", "system", "interferer", "victim", "protection", "x_db", "d_km_q10", "d_km_q1", "d_km_q0_1"])
        for r in rows:
            g, pm = gp[r["system"]]
            x = float(r["l_req_db"]) - float(r["nexrad_gain_dbi"])
            p = np.empty(d.size)
            for i in range(d.size):
                y = x + g
                T = np.interp(y, L[i], qf, left=qf[0], right=qf[-1])
                p[i] = np.dot(pm[round(float(el[i]), 6)], T)
            seps = [separation(d, np.clip(p, 0, 1), q)[0] for q in Q]
            w.writerow([r["direction"], r["system"], r["interferer"], r["victim"], r["protection"], f"{x:.6f}"]
                       + [f"{s:.4f}" for s in seps])
    print("wrote", out)


if __name__ == "__main__":
    main()
