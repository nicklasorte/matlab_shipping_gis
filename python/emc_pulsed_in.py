"""Protection levels (peak I/N) for pulsed radar-to-radar interference, NEXRAD and shipborne S-band radars.

NEXRAD as victim: Rec. ITU-R M.1849-3, section 8.4.2:
    I/N_pulse = I/N_constant - 10 log10(f_c),  I/N_constant = -10 dB,
    f_c = PRF_i * (tau_i + tau_g)  (Case II of Rec. ITU-R RS.1280 section 3.2; PRFs not integer-related),
with the NEXRAD range gate tau_g taken as its pulse width (ROC: 1.52-1.62 us short, 4.61-4.81 us long; nominal 1.57 and 4.71 us).
Ship radar as victim: Rec. ITU-R M.1460-2 recommends -6 dB; its Annex 3 (Table 10) measured no effect from 1-2 us pulses at
0.1% and 1.0% duty cycle up to +40 dB (Radar B) and +30 dB (Radar C). This script reports NEXRAD's duty cycle against that range.

Interferer parameters: ship magnetron, M.1460-2 Table 4 (shortest pulse 0.05 us goes with the highest PRF 4,000 Hz; longest 1.2 us with
375 Hz, per its note 1); solid-state Radar No. 3B, M.1460-2 Table 1 (pulses 0.1, 5, 33 us; PRI 12, 64, 365 us), treated as unmodulated
(its pulses are FM, which would lower the duty cycle seen in NEXRAD's 636 kHz filter, so this is the stricter case); NEXRAD, ROC sheet.
Writes outputs/emc/pulsed_in_criteria_rev1.csv.
"""
import csv
import math
import os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "outputs", "emc", "pulsed_in_criteria_rev1.csv")
IN_CONST = -10.0
GATES_US = {"NEXRAD short pulse (1.57 us gate)": 1.57, "NEXRAD long pulse (4.71 us gate)": 4.71}
SHIP = [("Ship magnetron, shortest pulse", 0.05, 4000.0), ("Ship magnetron, longest pulse", 1.2, 375.0),
        ("Solid-state 3B, short (unmodulated)", 0.1, 1e6 / 12), ("Solid-state 3B, medium (unmodulated)", 5.0, 1e6 / 64),
        ("Solid-state 3B, long (unmodulated)", 33.0, 1e6 / 365)]
NEXRAD = [("NEXRAD short pulse, 1,304 Hz", 1.57, 1304.0), ("NEXRAD short pulse, 318 Hz", 1.57, 318.0),
          ("NEXRAD long pulse, 452 Hz", 4.71, 452.0), ("NEXRAD long pulse, 318 Hz", 4.71, 318.0)]


def main():
    rows = []
    for gname, tg in GATES_US.items():
        for name, ti, prf in SHIP:
            fc = min(1.0, prf * (ti + tg) * 1e-6)
            rows.append(["NEXRAD", gname, name, ti, round(prf, 1), round(100 * prf * ti * 1e-6, 4), round(fc, 5),
                         round(IN_CONST - 10 * math.log10(fc), 1), "M.1849-3 8.4.2"])
    for name, ti, prf in NEXRAD:
        dc = prf * ti * 1e-6
        rows.append(["Ship radar", "IF 2.5-28 MHz (pulse not stretched)", name, ti, round(prf, 1), round(100 * dc, 4), "",
                     "-6 (recommended); no effect to +30/+40 measured", "M.1460-2 recommends 3; Annex 3 Table 10"])
    with open(OUT, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["victim", "victim_mode", "interferer", "pulse_us", "prf_hz", "duty_cycle_pct", "f_c",
                    "peak_IN_dB", "basis"])
        w.writerows(rows)
    for r in rows:
        print(*r, sep=" | ")


if __name__ == "__main__":
    main()
