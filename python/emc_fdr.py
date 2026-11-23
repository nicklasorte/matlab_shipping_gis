"""Off-frequency rejection and required loss against frequency offset (Python twin of emc_emission_rev1,
emc_selectivity_rev1, emc_ofr_rev1, and the offset sweep in init_emc_offset_rev1.m).

FDR = OTR + OFR (Rec. ITU-R SM.337-6 eqs. 3-6). OTR is in the co-channel required loss; this script computes
OFR(df) = 10 log10( int P H / int P(f) H(f+df) ) for every pair and writes outputs/emc/offset_ofr_py_rev1.csv.
Must agree with MATLAB to 0.01 dB (test_emc_offset_rev1.m).
"""
import csv
import os

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
import sys
sys.path.insert(0, HERE)
import emc_link_budget as lb  # noqa: E402

DF = np.concatenate([np.arange(0, 10, 0.25), np.arange(10, 60, 1.0), np.arange(60, 151, 2.0)])
SPAN, STEP = 400.0, 0.005


def emission(f, tau, rise, chirp=0.0):
    af = np.abs(f)
    if chirp > 0:
        p = np.ones_like(af)
        out = af > chirp / 2
        p[out] = (chirp / 2 / af[out]) ** 2
        return p
    with np.errstate(divide="ignore"):
        p = np.minimum(1, (1 / (np.pi * af * tau)) ** 2)
        if rise > 0:
            p = p * np.minimum(1, (1 / (np.pi * af * rise)) ** 2)
    p[af == 0] = 1
    return p


def sel_nexrad(f, tau, bpf):
    af = np.abs(f)
    with np.errstate(divide="ignore"):
        mf = np.minimum(1, (1 / (np.pi * af * tau)) ** 2)
    mf[af == 0] = 1
    bpf_db = np.interp(np.minimum(af, bpf[3]), [0] + list(bpf), [0, 0.5, 3, 30, 60])
    return mf * 10 ** (-bpf_db / 10)


def sel_ship(f, if_mhz, floor_db, poles):
    h = 1 / (1 + (2 * np.abs(f) / if_mhz) ** (2 * poles))
    return np.maximum(h, 10 ** (-floor_db / 10))


def ofr(df, P, H, n):
    m = 1 << int(np.ceil(np.log2(2 * n - 1)))
    c = np.real(np.fft.ifft(np.fft.fft(P, m) * np.fft.fft(H[::-1], m)))[: 2 * n - 1]
    lag = np.arange(-(n - 1), n) * STEP
    c0 = np.interp(0, lag, c)
    cd = np.interp(-df, lag, c)
    return 10 * np.log10(c0 / cd)


def pairs(P, modes):
    nx = P["nexrad"]
    bpf = [nx["bpf_f1_mhz"], nx["bpf_f2_mhz"], nx["bpf_f3_mhz"], nx["bpf_f4_mhz"]]
    f = np.arange(-SPAN, SPAN + STEP / 2, STEP)
    for name, tau in (("short", nx["pulse_short_us"]), ("long", nx["pulse_long_us"])):
        Hn = sel_nexrad(f, tau, bpf)
        Pn = emission(f, tau, nx["rise_us"])
        for m in modes:
            chirp = m["tx_bw_mhz"] if m["otr_k"] == 10 else 0.0
            rise = P["magnetron"]["rise_us"] if m["system"] == "magnetron" else 0.0
            Pm = emission(f, m["pulse_us"], rise, chirp)
            yield "ship to NEXRAD", m["system"], m["mode"], "NEXRAD " + name, ofr(DF, Pm, Hn, f.size)
            Hs = sel_ship(f, m["if_mhz"], P["ship"]["if_floor_db"], P["ship"]["if_poles"])
            yield "NEXRAD to ship", m["system"], "NEXRAD " + name, m["mode"], ofr(DF, Pn, Hs, f.size)


def main():
    P, modes = lb.load()
    out = os.path.join(ROOT, "outputs", "emc", "offset_ofr_py_rev1.csv")
    with open(out, "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["direction", "system", "interferer", "victim"] + [f"df_{d:g}" for d in DF])
        for d, s, i, v, o in pairs(P, modes):
            w.writerow([d, s, i, v] + [f"{x:.6f}" for x in o])
    print("wrote", out)


if __name__ == "__main__":
    main()
