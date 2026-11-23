"""Required loss after FDR against NEXRAD tuned frequency, 2800-3100 MHz (Python twin of the required-loss part
of init_emc_nexrad_sweep_rev1.m).

Each ship radar mode sits at the tuning closest to NEXRAD inside its published range (radar_modes_rev1.csv
f_lo_mhz, f_hi_mhz, f_step_mhz). NEXRAD gain = G(3050 MHz) + 20 log10(f/3050). L_req after FDR = co-channel
L_req (emc_link_budget) - OFR(df) (emc_fdr, span 600 MHz). Writes outputs/emc/nexrad_sweep_lreq_py_rev1.csv in
the MATLAB row order; must agree with nexrad_sweep_lreq_rev1.csv to 0.01 dB (test_emc_nexrad_sweep_rev1.m).
"""
import copy
import csv
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, HERE)
import emc_fdr as fdr  # noqa: E402
import emc_link_budget as lb  # noqa: E402

F_NX = np.arange(2800, 3101, 5)
SPAN = 600.0


def ship_tuning(m, f):
    lo, hi, step = float(m["f_lo_mhz"]), float(m["f_hi_mhz"]), float(m["f_step_mhz"])
    if step > 0:
        ch = np.arange(lo, hi + step / 2, step)
        fs = ch[np.argmin(np.abs(f - ch))]
    else:
        fs = min(max(f, lo), hi)
    return fs, abs(f - fs)


def main():
    P, modes = lb.load()
    nx = P["nexrad"]
    bpf = [nx["bpf_f1_mhz"], nx["bpf_f2_mhz"], nx["bpf_f3_mhz"], nx["bpf_f4_mhz"]]
    f = np.arange(-SPAN, SPAN + fdr.STEP / 2, fdr.STEP)
    dfm = np.array([[ship_tuning(m, fn)[1] for m in modes] for fn in F_NX])
    df_u = np.unique(dfm)
    # OFR per pair, same order as lb.required_loss rows
    ofr = []
    for tau in (nx["pulse_short_us"], nx["pulse_long_us"]):
        Hn = fdr.sel_nexrad(f, tau, bpf)
        Pn = fdr.emission(f, tau, nx["rise_us"])
        for m in modes:
            chirp = m["tx_bw_mhz"] if m["otr_k"] == 10 else 0.0
            rise = P["magnetron"]["rise_us"] if m["system"] == "magnetron" else 0.0
            Pm = fdr.emission(f, m["pulse_us"], rise, chirp)
            Hs = fdr.sel_ship(f, m["if_mhz"], P["ship"]["if_floor_db"], P["ship"]["if_poles"])
            ofr.append(fdr.ofr(df_u, Pm, Hn, f.size))
            ofr.append(fdr.ofr(df_u, Pn, Hs, f.size))
    nm = len(modes)
    cases = (("pulsed", P["ship"]["in_db"]), ("constant", P["ship"]["in_pulsed_db"]))
    out = os.path.join(ROOT, "outputs", "emc", "nexrad_sweep_lreq_py_rev1.csv")
    with open(out, "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["f_nexrad_mhz", "direction", "system", "interferer", "victim", "df_mhz", "l_req_db"])
        for i, fn in enumerate(F_NX):
            Pi = copy.deepcopy(P)
            Pi["nexrad"]["gain_dbi"] = nx["gain_dbi"] + 20 * np.log10(fn / P["analysis"]["f_mhz"])
            for nexrad_in, ship_in in cases:
                rows = lb.required_loss(Pi, modes, nexrad_in, ship_in)
                for k, (d, s, it, v, lreq) in enumerate(rows):
                    m = (k // 2) % nm
                    q = int(np.where(df_u == dfm[i, m])[0][0])
                    w.writerow([int(fn), d, s, it, v, f"{dfm[i, m]:g}", f"{lreq - ofr[k][q]:.6f}"])
    print("wrote", out)


if __name__ == "__main__":
    main()
