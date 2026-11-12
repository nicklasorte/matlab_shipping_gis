"""Count large ships and all reports by area in one MarineCadastre day (coverage check).

Usage: python3 python/ais_coverage_probe.py YYYY-MM-DD [...]
Prints, per area box: all reports, large-ship reports (main filter), and distinct
large ships; plus the overall lat/lon extent of every report in the file.
"""
import os
import sys
import tempfile
import zipfile

import numpy as np
import pyarrow as pa
import pyarrow.csv as pv
import requests
import zstandard

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import ais_cells_py_rev1 as cells  # noqa: E402

AREAS = {  # (lat0, lat1, lon0, lon1); lon may wrap (lon0 > lon1)
    "Lower 48 grid": (22, 50, -130, -66),
    "Alaska": (51, 72, 172, -129),
    "Hawaii": (17, 24, -162, -153),
    "Puerto Rico and USVI": (16.5, 19.5, -68.5, -64),
    "Guam and CNMI": (12, 21, 143, 147),
    "American Samoa": (-15.5, -10.5, -172, -168),
}


def in_box(lat, lon, b):
    la = (lat >= b[0]) & (lat <= b[1])
    lo = (lon >= b[2]) & (lon <= b[3]) if b[2] <= b[3] else (lon >= b[2]) | (lon <= b[3])
    return la & lo


def probe(day):
    url = cells.day_url(day)
    filt = cells.FILTERS["main"]
    lat_all, lon_all, keep_all, mmsi_all = [], [], [], []
    with tempfile.TemporaryFile() as tmp:
        with requests.get(url, stream=True, timeout=600) as r:
            r.raise_for_status()
            for chunk in r.iter_content(8 << 20):
                tmp.write(chunk)
        size = tmp.tell()
        tmp.seek(0)
        if url.endswith(".zst"):
            stream = zstandard.ZstdDecompressor().stream_reader(tmp)
        else:
            z = zipfile.ZipFile(tmp)
            stream = z.open([n for n in z.namelist() if n.endswith(".csv")][0])
        text = ["MMSI", "mmsi", "LAT", "LON", "lat", "lon", "latitude", "longitude", "IMO", "imo",
                "VesselType", "vessel_type", "Length", "length"]
        rd = pv.open_csv(stream, read_options=pv.ReadOptions(block_size=64 << 20),
                         parse_options=pv.ParseOptions(invalid_row_handler=lambda r: "skip"),
                         convert_options=pv.ConvertOptions(column_types={c: pa.string() for c in text}))
        names = rd.schema.names
        key = [n.lower().replace("_", "") for n in names]

        def col(*alts):
            return names[[i for i, x in enumerate(key) if x in alts][0]]
        c = {"lat": col("lat", "latitude"), "lon": col("lon", "longitude"), "vt": col("vesseltype"),
             "len": col("length"), "imo": col("imo"), "mmsi": col("mmsi")}
        for b in rd:
            g = lambda k: cells.num(b.column(names.index(c[k])))  # noqa: E731
            lat, lon, vt, ln, mm = g("lat"), g("lon"), g("vt"), g("len"), g("mmsi")
            imo = np.array([(s is not None and len(s) > 0) for s in b.column(names.index(c["imo"])).to_pylist()])
            k = np.isin(vt, filt["types"]) & (ln >= filt["min_length_m"])
            if not os.environ.get("NOIMO"):
                k &= imo | np.isin(vt, filt["no_imo_types"])
            lat_all.append(lat)
            lon_all.append(lon)
            keep_all.append(k)
            mmsi_all.append(mm)
    lat, lon = np.concatenate(lat_all), np.concatenate(lon_all)
    k, mm = np.concatenate(keep_all), np.concatenate(mmsi_all)
    print(f"{day}: {size / 1e6:.0f} MB, {len(lat):,} reports, lat {np.nanmin(lat):.2f} to {np.nanmax(lat):.2f}, "
          f"lon {np.nanmin(lon):.2f} to {np.nanmax(lon):.2f}")
    for name, bx in AREAS.items():
        m = in_box(lat, lon, bx)
        print(f"  {name:22s} reports {m.sum():>10,}  large-ship reports {(m & k).sum():>9,}  "
              f"large ships {len(np.unique(mm[m & k])):>5,}")
    # coarse histogram of reports north of 50 N or west of -130 (outside the lower-48 grid)
    out = (lat > 50) | (lon < -130) | (lon > 0)
    print(f"  reports outside the lower-48 grid: {out.sum():,}")
    if out.any():
        h, _, _ = np.histogram2d(lat[out], lon[out], bins=[[10, 20, 30, 40, 50, 55, 60, 65, 72],
                                                          [-180, -170, -160, -150, -140, -130, -60, 0, 180]])
        print("  lat x lon counts outside the grid (rows 10-72 N, cols -180..180):")
        print(h.astype(int))


if __name__ == "__main__":
    for d in sys.argv[1:]:
        probe(d)
