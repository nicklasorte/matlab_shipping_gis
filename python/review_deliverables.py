"""Stage 5 deliverable checks for the review plan.

1. Zone and route files: every shapefile under outputs/2024_2025 and
   outputs/2018_2019 opens, has valid geometry, states WGS 84 in its .prj,
   doesn't cross 180 degrees, and covers the same area as its KML (within 0.1%).
2. Hand-off to the EMC analysis: the files Section 2 will need exist for each area.
3. Local copies of outside data: size and SHA-256 of each downloaded source file.
4. Word copy: figure count, captions, alt text, marking in every header and
   footer, and table numbering order.
5. Freeze: SHA-256 manifest of every output file, plus tool versions.

Usage: python3 python/review_deliverables.py
Writes docs/review/deliverables_rev1.json and docs/review/manifest_rev1.csv.
"""
import glob
import hashlib
import json
import os
import platform
import re
import sys
import xml.etree.ElementTree as ET

import numpy as np
import shapefile
from pyproj import Geod
from shapely.geometry import Polygon, shape
from shapely.validation import explain_validity

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, ".."))
OUT = os.path.join(ROOT, "docs", "review")
GEOD = Geod(ellps="WGS84")


def sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def geod_area(geom):
    return abs(GEOD.geometry_area_perimeter(geom)[0]) / 1e6


def kml_area(path):
    ns = {"k": "http://www.opengis.net/kml/2.2"}
    tree = ET.parse(path)
    total = 0.0
    for poly in tree.iter("{http://www.opengis.net/kml/2.2}Polygon"):
        def ring(el):
            txt = el.find(".//k:coordinates", ns).text.split()
            return [tuple(map(float, t.split(",")[:2])) for t in txt]
        outer = poly.find("k:outerBoundaryIs", ns)
        inner = poly.findall("k:innerBoundaryIs", ns)
        if outer is None:
            continue
        g = Polygon(ring(outer), [ring(i) for i in inner])
        total += geod_area(g)
    return total


def check_shapes():
    res = []
    files = sorted(glob.glob(os.path.join(ROOT, "outputs", "2024_2025", "**", "*.shp"), recursive=True)
                   + glob.glob(os.path.join(ROOT, "outputs", "2018_2019", "**", "*.shp"), recursive=True))
    for f in files:
        r = {"file": os.path.relpath(f, ROOT)}
        try:
            sf = shapefile.Reader(f)
            r["features"] = len(sf)
            r["fields"] = [x[0] for x in sf.fields[1:]]
            prj = f[:-4] + ".prj"
            r["prj_wgs84"] = os.path.isfile(prj) and ("WGS" in open(prj).read() and "84" in open(prj).read())
            invalid, area, cross180 = 0, 0.0, False
            for s in sf.shapes():
                if not s.points:
                    continue
                pts = np.array(s.points)
                if pts[:, 0].max() > 180 or pts[:, 0].min() < -180 or (pts[:, 0].max() - pts[:, 0].min()) > 180:
                    cross180 = True
                g = shape(s.__geo_interface__)
                if g.geom_type in ("Polygon", "MultiPolygon"):
                    if not g.is_valid:
                        invalid += 1
                        r.setdefault("invalid_reason", explain_validity(g)[:120])
                        g = g.buffer(0)
                    area += geod_area(g)
            r["invalid_features"] = invalid
            r["crosses_180"] = cross180
            r["area_km2"] = round(area, 1)
            kml = f[:-4] + ".kml"
            if os.path.isfile(kml) and area > 0:
                ka = kml_area(kml)
                r["kml_area_km2"] = round(ka, 1)
                r["kml_area_diff_pct"] = round(100 * (ka - area) / area, 3)
        except Exception as e:  # noqa: BLE001  report, don't stop
            r["error"] = str(e)[:200]
        res.append(r)
        print(json.dumps(r)[:300], flush=True)
    return res


HANDOFF = {
    "Lower 48": ("outputs/2024_2025", "shipping_zone_2024_2025"),
    "Hawaii": ("outputs/2024_2025/hawaii", "shipping_zone_hawaii_2024_2025"),
    "Puerto Rico and USVI": ("outputs/2024_2025/prusvi", "shipping_zone_prusvi_2024_2025"),
    "Alaska": ("outputs/2018_2019/alaska", "shipping_zone_alaska_2018_2019"),
}
NEEDS = {"routes polygons": "_routes.shp", "band zones table": "_band_zones.csv",
         "fixed S-band sites": "_sites.csv", "port check": "_port_check.csv",
         "25 km zone": "_band_2900-3000MHz_25km.shp", "100 km zone": "_band_3030-3070MHz_100km.shp",
         "run log": "_run.log"}


def check_handoff():
    out = {}
    for area, (d, stem) in HANDOFF.items():
        out[area] = {k: os.path.isfile(os.path.join(ROOT, d, stem + suf)) for k, suf in NEEDS.items()}
    readme = open(os.path.join(ROOT, "README.md")).read()
    out["README describes zone files"] = all(w in readme for w in ("band_zones", "routes"))
    return out


def check_sources():
    files = [p for p in glob.glob(os.path.join(ROOT, "data", "**", "*"), recursive=True)
             if os.path.isfile(p) and not os.path.basename(p).startswith(("ais_cells_", "flag_pairs_"))]
    return [{"file": os.path.relpath(p, ROOT), "bytes": os.path.getsize(p), "sha256": sha(p)} for p in sorted(files)]


def check_word():
    from docx import Document
    d = Document(os.path.join(ROOT, "docs", "2.7GHz_Routes_and_Zones_Sections_DRAFT.docx"))
    body = d.element.body
    pics = body.findall(".//{http://schemas.openxmlformats.org/drawingml/2006/picture}pic")
    docpr = body.findall(".//{http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing}docPr")
    no_alt = sum(1 for e in docpr if not (e.get("descr") or "").strip())
    text = "\n".join(p.text for p in d.paragraphs)
    figs = re.findall(r"^Figure (A-\d+[a-z]?|\d+)\.", text, flags=re.M)
    tabs = [int(x) for x in re.findall(r"^Table (\d+)\.", text, flags=re.M)]
    marks = []
    for s in d.sections:
        h = " ".join(p.text for p in s.header.paragraphs)
        f = " ".join(p.text for p in s.footer.paragraphs)
        marks.append(("DRAFT//PRE-DECISIONAL" in h, "DRAFT//PRE-DECISIONAL" in f))
    return {"pictures": len(pics), "pictures_without_alt_text": no_alt,
            "figure_captions": len(figs), "table_captions_in_order": tabs == sorted(tabs), "table_numbers": tabs,
            "sections": len(marks), "sections_marked_header_and_footer": sum(a and b for a, b in marks),
            "text_placeholders_for_missing_images": text.count("[image:")}


def manifest():
    rows = []
    for p in sorted(glob.glob(os.path.join(ROOT, "outputs", "**", "*"), recursive=True)):
        if os.path.isfile(p):
            rows.append((os.path.relpath(p, ROOT), os.path.getsize(p), sha(p)))
    with open(os.path.join(OUT, "manifest_rev1.csv"), "w") as f:
        f.write("file,bytes,sha256\n")
        for r in rows:
            f.write("%s,%d,%s\n" % r)
    return len(rows)


def versions():
    import numpy
    import pandas
    import scipy
    import shapely
    import pyproj
    return {"python": platform.python_version(), "numpy": numpy.__version__, "pandas": pandas.__version__,
            "scipy": scipy.__version__, "shapely": shapely.__version__, "pyproj": pyproj.__version__,
            "matlab": "R2025b (from the run logs)"}


def main():
    res = {"handoff": check_handoff(), "word": check_word(), "versions": versions()}
    print(json.dumps(res, indent=1), flush=True)
    res["shapes"] = check_shapes()
    res["sources"] = check_sources()
    res["manifest_files"] = manifest()
    bad = [s for s in res["shapes"] if s.get("error") or s.get("invalid_features") or s.get("crosses_180")
           or not s.get("prj_wgs84") or abs(s.get("kml_area_diff_pct", 0)) > 0.1]
    res["shape_files_failing"] = [s["file"] for s in bad]
    json.dump(res, open(os.path.join(OUT, "deliverables_rev1.json"), "w"), indent=1)
    print("shapefiles:", len(res["shapes"]), "failing:", len(bad))


if __name__ == "__main__":
    sys.exit(main())
