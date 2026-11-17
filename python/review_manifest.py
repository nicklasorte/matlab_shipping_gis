"""Baseline manifest for the technical review (review plan step 1, workstream V).

Usage: python3 python/review_manifest.py <out_dir> [docx]

Writes to out_dir:
  manifest.json      git commit, Python and package versions, SHA-256 of the Word
                     copy, and SHA-256 and size of every committed file under
                     data/ (except the per-day AIS caches), outputs/, config/,
                     and the MATLAB and Python sources
  docx_inventory.csv every paragraph of the Word copy: index, style, whether it's
                     a caption, and its first 120 characters, so later reviews
                     can cite stable excerpts
The MATLAB release and toolboxes come from the Mac (ver output) and are added
by hand to manifest.json under "matlab".
"""
import hashlib
import json
import os
import platform
import subprocess
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


def sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def tracked():
    out = subprocess.run(["git", "-C", ROOT, "ls-files"], capture_output=True, text=True, check=True).stdout.split("\n")
    keep = []
    for p in out:
        if not p or "/ais_cells_" in p:
            continue
        if p.startswith(("data/", "outputs/", "config/", "python/")) or p.endswith(".m"):
            keep.append(p)
    return keep


def main(out_dir, docx=None):
    os.makedirs(out_dir, exist_ok=True)
    docx = docx or os.path.join(ROOT, "docs", "2.7GHz_Routes_and_Zones_Sections_DRAFT.docx")
    commit = subprocess.run(["git", "-C", ROOT, "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
    pkgs = {}
    for name in ("numpy", "pandas", "scipy", "shapely", "pyproj", "shapefile", "matplotlib"):
        try:
            mod = __import__(name)
            pkgs[name] = getattr(mod, "__version__", "unknown")
        except ImportError:
            pkgs[name] = "not installed"
    files = {p: {"sha256": sha(os.path.join(ROOT, p)), "bytes": os.path.getsize(os.path.join(ROOT, p))}
             for p in tracked() if os.path.isfile(os.path.join(ROOT, p))}
    man = {"commit": commit, "python": platform.python_version(), "packages": pkgs,
           "docx": {"path": os.path.relpath(docx, ROOT), "sha256": sha(docx)}, "files": files}
    with open(os.path.join(out_dir, "manifest.json"), "w") as f:
        json.dump(man, f, indent=1)
    from docx import Document
    d = Document(docx)
    with open(os.path.join(out_dir, "docx_inventory.csv"), "w") as f:
        f.write("index,style,caption,excerpt\n")
        for i, p in enumerate(d.paragraphs):
            t = p.text.strip().replace('"', "'")
            if not t:
                continue
            cap = t.startswith(("Figure ", "Table "))
            f.write(f'{i},"{p.style.name}",{int(cap)},"{t[:120]}"\n')
    print(f"commit {commit[:8]}; {len(files)} files hashed; docx {man['docx']['sha256'][:12]}")


if __name__ == "__main__":
    main(*sys.argv[1:3])
