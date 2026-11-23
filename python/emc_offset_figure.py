"""Figure: separation (50% of time) against frequency offset, NEXRAD and shipborne S-band radars.

Reads outputs/emc/offset_envelope_rev1.csv (largest distance over all mode pairs) and writes
docs/emc/fig_offset_separation_rev1.{png,svg} with alt text in docs/emc/fig_offset_separation_rev1.alt.txt.
"""
import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
E = pd.read_csv(os.path.join(ROOT, "outputs", "emc", "offset_envelope_rev1.csv"))
BLUE, PURPLE, GRAY, DARK = "#5674C4", "#7B3F98", "#8A8D91", "#1F2A44"
plt.rcParams.update({"font.family": "serif", "font.serif": ["Liberation Serif", "Times New Roman", "DejaVu Serif"],
                     "font.size": 10})
fig, axes = plt.subplots(1, 2, figsize=(8.5, 4.4), sharey=True)
panels = [("ship to NEXRAD", "Ship radar into NEXRAD", {"NEXRAD pulsed": ("pulsed level", "-"), "NEXRAD constant": ("-10 dB", "--")}),
          ("NEXRAD to ship", "NEXRAD into ship radar", {"ship -6 dB": ("-6 dB", "-"), "ship 30 dB": ("+30 dB", "--")})]
def dodge(ys, gap):
    # Spread end labels apart by at least gap (km), keeping their order.
    order = sorted(range(len(ys)), key=lambda i: ys[i])
    out = list(ys)
    for a, b in zip(order, order[1:]):
        if out[b] - out[a] < gap:
            out[b] = out[a] + gap
    return out


for ax, (dirn, title, prot) in zip(axes, panels):
    labels = []
    for sys, color, lab in (("magnetron", BLUE, "Magnetron"), ("solid_state", PURPLE, "Solid state")):
        for key, (plab, ls) in prot.items():
            g = E[(E.direction == dirn) & (E.system == sys) & (E.protection == key)].sort_values("df_mhz")
            ax.plot(g.df_mhz, g.d_km_p50, color=color, ls=ls, lw=2 if ls == "-" else 1.4)
            labels.append((g.d_km_p50.iloc[-1], f"{lab}, {plab}", color))
    ys = dodge([l[0] for l in labels], 45)
    for (y0, txt, color), y in zip(labels, ys):
        ax.annotate(txt, (150, y0), xytext=(153, y), textcoords="data", va="center",
                    fontsize=8.5, color=color, fontweight="bold", annotation_clip=False)
    ax.axvline(60, color=GRAY, lw=1, ls=":")
    ax.text(61, 1150, "60 MHz: widest offset\ninside 3020-3080 MHz", fontsize=8, color=DARK, va="top")
    ax.set_title(title, fontsize=11, color=DARK, loc="left", fontweight="bold")
    ax.set_xlabel("Frequency offset (MHz)")
    ax.set_xlim(0, 150); ax.set_ylim(0, 1200)
    for s in ("top", "right"):
        ax.spines[s].set_visible(False)
    ax.grid(axis="y", color="#E5E5E5", lw=0.6)
axes[0].set_ylabel("Separation for 50% of time (km)")
fig.subplots_adjust(left=0.08, right=0.83, wspace=0.62, bottom=0.13, top=0.9)
out = os.path.join(ROOT, "docs", "emc", "fig_offset_separation_rev1")
fig.savefig(out + ".png", dpi=300)
fig.savefig(out + ".svg")
alt = ("Two line charts of separation distance for 50% of the time against frequency offset from 0 to 150 MHz, "
       "main beam to main beam. Left, ship radar into NEXRAD: magnetron radars fall from 606 km co-channel to 91 km "
       "at 60 MHz with NEXRAD's pulsed protection level (1,003 to 302 km at -10 dB); the solid-state radar falls "
       "only from 872 to 465 km (984 to 564 km at -10 dB). Right, NEXRAD into ship radar: from 1,003 to 533 km "
       "(magnetron) and 1,125 to 433 km (solid state) at the ship's -6 dB level, and from 531 to 166 km and 638 to "
       "78 km at +30 dB. A dotted line marks 60 MHz, the widest offset inside 3020-3080 MHz.")
open(out + ".alt.txt", "w").write(alt)
print(out)
