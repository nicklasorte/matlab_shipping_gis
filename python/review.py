#!/usr/bin/env python3
"""Review a one-page chart exported by onepager.py.

Usage:
    python review.py PAGE.png [--meta PAGE.meta.json] [--out DIR]

What it does:
1. Builds a contact sheet, PAGE.review.png, with the original, a grayscale
   version, and two color-vision-deficiency simulations. Open it and look.
2. Prints the issues onepager.py found when it exported the page.
3. Checks the palette: how far apart the mark colors stay in grayscale and
   under red-green color blindness.
4. Prints the visual checklist that a script can't answer.

Exit status is 1 when there's an error, so you can use it in a loop:
fix, re-export, review again.
"""

from __future__ import annotations

import argparse
import itertools
import json
import sys
from pathlib import Path

import numpy as np
from matplotlib.colors import to_rgb
from PIL import Image, ImageDraw

from onepager import relative_luminance

# Machado, Oliveira, and Fernandes (2009), severity 1.0, applied in linear RGB.
CVD = {
    "Deuteranopia (green-blind)": np.array([
        [0.367322, 0.860646, -0.227968],
        [0.280085, 0.672501, 0.047413],
        [-0.011820, 0.042940, 0.968881]]),
    "Protanopia (red-blind)": np.array([
        [0.152286, 1.052583, -0.204868],
        [0.114503, 0.786281, 0.099216],
        [-0.003882, -0.048116, 1.051998]]),
    "Tritanopia (blue-blind)": np.array([
        [1.255528, -0.076749, -0.178779],
        [-0.078411, 0.930809, 0.147602],
        [0.004733, 0.691367, 0.303900]]),
}

CHECKLIST = [
    "The headline is one sentence that states the takeaway, and the numbers match it.",
    "Glance for three seconds: the eye lands on the one highlighted mark.",
    "The highlighted mark is labeled directly, so no legend is needed.",
    "Grayscale panel: the highlight still stands out; labels carry the rest.",
    "Colorblind panels: no two marks that carry meaning merge.",
    "No clipped, touching, or overlapping labels, and the margins look even.",
    "Bars start at zero, there are no dual axes, and panels that compare share scales.",
    "Units appear in the subhead or on the axis, and the source line is present.",
    "The same number has the same value and rounding everywhere on the page.",
    "The alt text states the takeaway and the chart type.",
]


def srgb_to_linear(a):
    a = np.asarray(a, dtype=float)
    return np.where(a <= 0.04045, a / 12.92, ((a + 0.055) / 1.055) ** 2.4)


def linear_to_srgb(a):
    a = np.clip(a, 0, 1)
    return np.where(a <= 0.0031308, a * 12.92, 1.055 * a ** (1 / 2.4) - 0.055)


def simulate(rgb01, matrix):
    """Apply a color-vision-deficiency matrix to sRGB values in [0, 1]."""
    return linear_to_srgb(srgb_to_linear(rgb01) @ matrix.T)


def to_lab(rgb01):
    lin = srgb_to_linear(rgb01)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = (m @ lin) / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 216 / 24389, np.cbrt(xyz), (24389 / 27 * xyz + 16) / 116)
    return np.array([116 * f[1] - 16, 500 * (f[0] - f[1]), 200 * (f[1] - f[2])])


def delta_e(a, b):
    return float(np.linalg.norm(to_lab(a) - to_lab(b)))


def contact_sheet(png: Path, out: Path) -> Path:
    img = Image.open(png).convert("RGB")
    arr = np.asarray(img, dtype=float) / 255.0
    views = [("Original", img)]
    gray = Image.fromarray((np.dot(arr, [0.2126, 0.7152, 0.0722]) * 255).astype("uint8")).convert("RGB")
    views.append(("Grayscale", gray))
    for name in ("Deuteranopia (green-blind)", "Protanopia (red-blind)"):
        sim = simulate(arr.reshape(-1, 3), CVD[name]).reshape(arr.shape)
        views.append((name, Image.fromarray((sim * 255).astype("uint8"))))
    w = 1100
    h = int(img.height * w / img.width)
    cap = 34
    sheet = Image.new("RGB", (2 * w + 30, 2 * (h + cap) + 30), "white")
    draw = ImageDraw.Draw(sheet)
    for i, (name, view) in enumerate(views):
        x, y = 10 + (i % 2) * (w + 10), 10 + (i // 2) * (h + cap + 10)
        draw.text((x, y + 8), name, fill="black")
        sheet.paste(view.resize((w, h), Image.LANCZOS), (x, y + cap))
        draw.rectangle([x, y + cap, x + w - 1, y + cap + h - 1], outline="#999999")
    sheet.save(out)
    return out


def palette_report(colors: list[str], accent: str | None, context: str | None) -> list[str]:
    lines: list[str] = []
    colors = sorted(set(colors))
    if len(colors) < 2:
        return lines
    for a, b in itertools.combinations(colors, 2):
        ra, rb = np.array(to_rgb(a)), np.array(to_rgb(b))
        worst_name, worst = "normal vision", delta_e(ra, rb)
        for name, mat in CVD.items():
            d = delta_e(simulate(ra, mat), simulate(rb, mat))
            if d < worst:
                worst_name, worst = name, d
        lum_gap = abs(relative_luminance(a) - relative_luminance(b))
        notes = []
        if worst < 20:
            notes.append(f"close under {worst_name} (difference {worst:.0f}; want 20 or more)")
        if lum_gap < 0.08:
            notes.append(f"similar lightness in grayscale (gap {lum_gap:.2f}); label the marks directly")
        if notes:
            lines.append(f"{a} vs {b}: " + "; ".join(notes))
    return lines


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    ap.add_argument("png", type=Path)
    ap.add_argument("--meta", type=Path, help="metadata file; defaults to PAGE.meta.json")
    ap.add_argument("--out", type=Path, help="folder for the contact sheet; defaults to the PNG's folder")
    args = ap.parse_args()

    png = args.png
    meta_path = args.meta or png.with_suffix(".meta.json")
    meta = json.loads(meta_path.read_text()) if meta_path.exists() else None
    out_dir = args.out or png.parent
    out_dir.mkdir(parents=True, exist_ok=True)
    sheet = contact_sheet(png, out_dir / f"{png.stem}.review.png")

    errors = 0
    print(f"Contact sheet: {sheet}")
    print("Open it and look at all four views before you decide the page is done.\n")

    if meta is None:
        print(f"No metadata at {meta_path}; skipping automated checks. "
              "Export with OnePager.save() to get them.\n")
    else:
        print("Automated checks from export")
        issues = meta.get("lint", [])
        for issue in issues:
            print(f"  [{issue['severity']}] {issue['message']}")
            errors += issue["severity"] == "error"
        if not issues:
            print("  No lint issues: no overlaps, no clipped text, sizes and contrast pass.")
        if meta.get("theme") == "ntia" and not meta.get("marking"):
            print("  [error] NTIA theme without the DRAFT//PRE-DECISIONAL marking.")
            errors += 1
        if not meta.get("alt_supplied"):
            print("  [warn] Alt text was not supplied; the headline was used as a stand-in.")
        px = Image.open(png).size
        want = (round(meta["page_inches"][0] * meta["dpi"]), round(meta["page_inches"][1] * meta["dpi"]))
        if px != want:
            print(f"  [warn] PNG is {px[0]}x{px[1]} px; expected {want[0]}x{want[1]}.")
        print(f"  Font sizes on the page (pt): {meta.get('font_sizes_pt')}")
        print()
        print("Palette checks")
        pal = palette_report(meta.get("mark_colors", []), meta.get("accent"), meta.get("context"))
        for line in pal or ["  Mark colors stay distinct in grayscale and under color blindness."]:
            print(f"  {line}" if pal else line)
        print()

    print("Visual checklist (answer each by looking at the contact sheet)")
    for i, item in enumerate(CHECKLIST, 1):
        print(f"  {i:2d}. [ ] {item}")
    print("\nFix every 'no', re-export, and review again." if errors == 0 else
          f"\n{errors} error(s) found. Fix them, re-export, and review again.")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
