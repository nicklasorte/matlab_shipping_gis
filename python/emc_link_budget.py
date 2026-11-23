"""Co-channel required path loss, NEXRAD and shipborne S-band radars (Python twin of emc_required_loss_rev1.m).

L_req = P_t - L_t + G_t + G_r - L_r - OTR - (N + I/N), main beam to main beam, both directions.
OTR: Rec. ITU-R SM.337-6 eq. (6). NEXRAD I/N: Rec. ITU-R M.1849-3 section 8.4.2 (pulsed). Ship I/N: -6 dB.
Reads data/emc/radar_params_rev1.csv and radar_modes_rev1.csv; writes outputs/emc/cochannel_required_loss_py_rev1.csv.
Must agree with the MATLAB table to 0.01 dB (test_emc_cochannel_rev1.m).
"""
import csv
import math
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


def load():
    P = {}
    with open(os.path.join(ROOT, "data", "emc", "radar_params_rev1.csv")) as f:
        for r in csv.DictReader(f):
            v, lo, hi = float(r["value"]), float(r["low"]), float(r["high"])
            if not lo <= v <= hi:
                raise ValueError(f"emc:outOfRange {r['system']}.{r['parameter']}")
            P.setdefault(r["system"], {})[r["parameter"]] = v
    with open(os.path.join(ROOT, "data", "emc", "radar_modes_rev1.csv")) as f:
        modes = [dict(r) for r in csv.DictReader(f)]
    for m in modes:
        for k in ("pulse_us", "prf_hz", "peak_kw", "gain_dbi", "if_mhz", "nf_db", "tx_bw_mhz", "otr_k"):
            m[k] = float(m[k])
    return P, modes


def otr(bt, br, k):
    return max(0.0, k * math.log10(bt / br))


def required_loss(P, modes, nexrad_in="pulsed", ship_in=None):
    ship_in = P["ship"]["in_db"] if ship_in is None else ship_in
    nx = P["nexrad"]
    pulses = [("short", nx["pulse_short_us"], nx["tx_bw_short_mhz"], nx["rx_bw_short_khz"] / 1e3),
              ("long", nx["pulse_long_us"], nx["tx_bw_long_mhz"], nx["rx_bw_long_khz"] / 1e3)]
    nx_eirp = 10 * math.log10(nx["peak_power_kw"] * 1e6) - nx["tx_line_loss_db"] + nx["gain_dbi"]
    rows = []
    for name, tau, bt, br in pulses:
        n_nx = -174 + 10 * math.log10(br * 1e6) + nx["nf_db"]
        for m in modes:
            eirp = 10 * math.log10(m["peak_kw"] * 1e6) - P["ship"]["tx_line_loss_db"] + m["gain_dbi"]
            o = otr(m["tx_bw_mhz"], br, int(m["otr_k"]))
            if nexrad_in == "pulsed":
                fc = min(1.0, m["prf_hz"] * (m["pulse_us"] + tau) * 1e-6)
                i_n = nx["in_constant_db"] - 10 * math.log10(fc)
            else:
                i_n = nx["in_constant_db"]
            lreq = eirp + nx["gain_dbi"] - nx["rx_line_loss_db"] - o - (n_nx + i_n)
            rows.append(["ship to NEXRAD", m["system"], m["mode"], "NEXRAD " + name, lreq])
            n_s = -174 + 10 * math.log10(m["if_mhz"] * 1e6) + m["nf_db"]
            o2 = otr(bt, m["if_mhz"], 20)
            lreq2 = nx_eirp + m["gain_dbi"] - P["ship"]["rx_line_loss_db"] - o2 - (n_s + ship_in)
            rows.append(["NEXRAD to ship", m["system"], "NEXRAD " + name, m["mode"], lreq2])
    return rows


def main():
    P, modes = load()
    rows = required_loss(P, modes)
    out = os.path.join(ROOT, "outputs", "emc", "cochannel_required_loss_py_rev1.csv")
    with open(out, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["direction", "system", "interferer", "victim", "l_req_db"])
        for r in rows:
            w.writerow(r[:4] + [f"{r[4]:.6f}"])
    for r in sorted(rows, key=lambda r: -r[4])[:8]:
        print(f"{r[0]:15s} {r[1]:12s} {r[2]:22s} {r[3]:15s} {r[4]:7.2f}")


if __name__ == "__main__":
    main()
