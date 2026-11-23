"""Peak NEXRAD-ship antenna coupling beyond the horizon, relative to main beam to main beam (Python twin of the
"peak" level of emc_coupling_rev1.m).

Beyond the radio horizon each antenna radiates toward the other along its horizon ray, el = -sqrt(2h/ae), with
ITM's effective earth radius (curvature 157e-9 (1 - 0.04665 exp(Ns/179.3)) 1/m). NEXRAD's lowest cut sits at
tilt P.nexrad.lowest_tilt_deg; its main beam is Gaussian, -12 (theta/bw)^2 dB, bw = beamwidth_deg * 2850/f.
The ship fan beam (vertical beamwidth el_bw_deg, tilt 0) is approximated by the same Gaussian form, which is
within 0.001 dB of the M.1851-2 rectangular aperture this close to boresight.
Writes outputs/emc/coupling_peak_py_rev1.csv; must agree with the "peak" rows of coupling_levels_rev1.csv to
0.01 dB (test_emc_coupling_rev1.m).
"""
import csv
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, HERE)
import emc_link_budget as lb  # noqa: E402


def horizon_deg(h_m, n0):
    ae_km = 1e-3 / (157e-9 * (1 - 0.04665 * math.exp(n0 / 179.3)))
    return -math.degrees(math.sqrt(2 * h_m * 1e-3 / ae_km))


def peak_dg(P, f_mhz, system):
    nx = P["nexrad"]
    el_n = horizon_deg(nx["height_m"], P["analysis"]["n0"])
    el_s = horizon_deg(P["ship"]["height_m"], P["analysis"]["n0"])
    bw = nx["beamwidth_deg"] * 2850 / f_mhz
    g_n = max(-12 * ((nx["lowest_tilt_deg"] - el_n) / bw) ** 2, nx["sidelobe_db"])
    s = P[system]
    g_s = -12 * ((s["tilt_deg"] - el_s) / s["el_bw_deg"]) ** 2
    return g_n + g_s


def main():
    P, _ = lb.load()
    out = os.path.join(ROOT, "outputs", "emc", "coupling_peak_py_rev1.csv")
    with open(out, "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["f_mhz", "system", "dg_db"])
        for f in range(2800, 3101, 5):
            for s in ("magnetron", "solid_state"):
                w.writerow([f, s, f"{peak_dg(P, f, s):.6f}"])
    print("wrote", out, "dg at 3050 MHz:", round(peak_dg(P, 3050, "magnetron"), 4))


if __name__ == "__main__":
    main()
