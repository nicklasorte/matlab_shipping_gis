"""Data-validity checks on one MarineCadastre day, for the large ships our filter keeps.

Checks (each a share of large-ship reports or ships, by area):
  1. MMSI format: 9 digits, and the first three digits (Maritime Identification
     Digits) between 201 and 775 (ITU-R M.585 ship station range).
  2. Static data: length over 400 m; IMO number fails its check digit.
  3. Physics: implied speed over 50 kn between consecutive reports of one ship
     (position jumps), and reported speed over ground over 40 kn.
  4. Duplicate MMSI: one MMSI reporting two positions more than 50 km apart
     within 10 minutes (two transmitters sharing an MMSI, or spoofing).
  5. Positions on land: reports more than 2 km inside Census state polygons
     (cb_2023_us_state_500k), each area in its own projected CRS (equal-area except EPSG:32161 for Puerto Rico,
     which is conformal; fine for a 2 km inland test), split
     into the Great Lakes (lower 48 only; inside state lines), route cells
     (narrow rivers and channels the 1:500,000 shoreline closes), and the rest
     (truly off the water).
  7. Whether flagged reports (jumps, duplicate MMSIs) create any cells on their
     own, and how many of those are route cells.
  6. Time stamps outside the file's day.

Usage: python3 python/ais_qc_day.py YYYY-MM-DD [...]
Days in 2018-2019 check Alaska against the 2018-2019 Alaska routes and write
outputs/2018_2019/qc. Other days check the lower 48, Hawaii, and Puerto Rico
and the USVI against the routes of the current period (ship_period.py) and
write outputs/<period>/qc/ais_qc_<day>.json.
"""
import json
import os
import sys
import tempfile
import zipfile

import numpy as np
import shapely
import pyarrow as pa
import pyarrow.csv as pv
import requests
import shapefile
import zstandard
from shapely import contains_xy
from shapely.geometry import shape
from shapely.ops import unary_union
from pyproj import Transformer

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, ROOT)
import ais_cells_py_rev1 as cells  # noqa: E402

sys.path.insert(0, HERE)
import ship_period as PER  # noqa: E402  analysis years

STATES = os.path.join(ROOT, "data", "cb_2023_us_state_500k", "cb_2023_us_state_500k.shp")
O = os.path.join(ROOT, "outputs")
# area: (lat0, lat1, lon0, lon1), grid, projection for the land test, states, route cells
AREAS = {
    "Lower 48 grid": ((22, 50, -130, -66), None, "EPSG:5070", None,
                      (os.path.join(O, PER.TAG, "viz", "viz_cells.npz"), "route_cells")),
    "Hawaii": ((17, 24, -162, -153), "hawaii", "ESRI:102007", ("HI",),
               (os.path.join(O, PER.TAG, "islands", "hawaii_rule_cells.npz"), "ship_days_6")),
    "Puerto Rico and USVI": ((16.5, 19.5, -68.5, -64), "prusvi", "EPSG:32161", ("PR", "VI"),
                             (os.path.join(O, PER.TAG, "islands", "prusvi_routes.npz"), "route_cells")),
    "Alaska to 180": ((51, 72, -180, -129), "alaska180", "EPSG:3338", ("AK",),
                      (os.path.join(O, "2018_2019", "alaska", "alaska_rule_cells.npz"), "ship_days_6")),
}
NOT_L48 = ("AK", "HI", "PR", "VI", "GU", "MP", "AS")


def imo_ok(s):
    """IMO check digit: sum of digits 1-6 times weights 7..2, mod 10, equals digit 7."""
    d = "".join(ch for ch in str(s) if ch.isdigit())
    if len(d) != 7:
        return False
    return sum(int(d[i]) * (7 - i) for i in range(6)) % 10 == int(d[6])


def haversine_km(la1, lo1, la2, lo2):
    p1, p2 = np.radians(la1), np.radians(la2)
    a = np.sin((p2 - p1) / 2) ** 2 + np.cos(p1) * np.cos(p2) * np.sin(np.radians(lo2 - lo1) / 2) ** 2
    return 2 * 6371.0088 * np.arcsin(np.sqrt(np.minimum(a, 1)))


def load_day(day):
    url = cells.day_url(day)
    filt = cells.FILTERS["main"]
    keep = {k: [] for k in ("mmsi", "t", "lat", "lon", "sog", "len", "imo")}
    with tempfile.TemporaryFile() as tmp:
        with requests.get(url, stream=True, timeout=600) as r:
            r.raise_for_status()
            for chunk in r.iter_content(8 << 20):
                tmp.write(chunk)
        tmp.seek(0)
        if url.endswith(".zst"):
            stream = zstandard.ZstdDecompressor().stream_reader(tmp)
        else:
            z = zipfile.ZipFile(tmp)
            stream = z.open([n for n in z.namelist() if n.endswith(".csv")][0])
        rd = pv.open_csv(stream, read_options=pv.ReadOptions(block_size=64 << 20),
                         parse_options=pv.ParseOptions(invalid_row_handler=lambda r: "skip"),
                         convert_options=pv.ConvertOptions(strings_can_be_null=False))
        names = rd.schema.names
        key = [n.lower().replace("_", "") for n in names]

        def col(*alts):
            return names[[i for i, x in enumerate(key) if x in alts][0]]
        c = {"mmsi": col("mmsi"), "t": col("basedatetime"), "lat": col("lat", "latitude"),
             "lon": col("lon", "longitude"), "sog": col("sog"), "vt": col("vesseltype"),
             "len": col("length"), "imo": col("imo")}
        for b in rd:
            g = lambda k: cells.num(b.column(names.index(c[k])).cast(pa.string()))  # noqa: E731
            vt, ln = g("vt"), g("len")
            imo = np.array([str(x) if x is not None else "" for x in b.column(names.index(c["imo"])).cast(pa.string()).to_pylist()])
            has_imo = np.char.str_len(imo) > 0
            k = np.isin(vt, filt["types"]) & (ln >= filt["min_length_m"]) & (has_imo | np.isin(vt, filt["no_imo_types"]))
            if not k.any():
                continue
            kk = pa.array(k)
            keep["mmsi"].append(np.array(b.column(names.index(c["mmsi"])).filter(kk).cast(pa.string()).to_pylist()))
            t = b.column(names.index(c["t"])).filter(kk).cast(pa.string()).to_pylist()
            keep["t"].append(np.array(t, dtype="datetime64[s]"))
            keep["lat"].append(g("lat")[k])
            keep["lon"].append(g("lon")[k])
            keep["sog"].append(g("sog")[k])
            keep["len"].append(ln[k])
            keep["imo"].append(imo[k])
    return {k: np.concatenate(v) for k, v in keep.items()}


def main(day):
    alaska_day = int(day[:4]) in (2018, 2019)
    out = os.path.join(O, "2018_2019" if alaska_day else PER.TAG, "qc")
    d = load_day(day)
    n = len(d["mmsi"])
    res = {"day": day, "large_ship_reports": int(n)}
    for area, ((a0, a1, o0, o1), grid, crs, states, (rfile, rkey)) in AREAS.items():
        if alaska_day != (grid == "alaska180"):
            continue
        land, to_m = land_polygon(crs, states)
        route = np.load(rfile)[rkey]
        res.setdefault("route_cells_from", {})[area] = os.path.relpath(rfile, ROOT) + ":" + rkey
        m = (d["lat"] >= a0) & (d["lat"] <= a1) & (d["lon"] >= o0) & (d["lon"] <= o1)
        if not m.any():
            continue
        x = {k: v[m] for k, v in d.items()}
        ships = np.unique(x["mmsi"])
        r = {"reports": int(m.sum()), "ships": int(len(ships))}
        # 1. MMSI format
        s9 = np.array([len(s) == 9 and s.isdigit() for s in ships])
        mid = np.array([int(s[:3]) if len(s) == 9 and s.isdigit() else -1 for s in ships])
        r["ships_bad_mmsi"] = int(np.sum(~s9 | (mid < 201) | (mid > 775)))
        # 2. Static data
        first = {}
        for mm, ln, im in zip(x["mmsi"], x["len"], x["imo"]):
            first.setdefault(mm, (ln, im))
        r["ships_length_over_400m"] = int(sum(v[0] > 400 for v in first.values()))
        with_imo = [v[1] for v in first.values() if v[1]]
        r["ships_imo_bad_check_digit"] = int(sum(not imo_ok(v) for v in with_imo))
        r["ships_with_imo"] = len(with_imo)
        # 3. Physics and 4. duplicates, per ship in time order
        o = np.lexsort((x["t"], x["mmsi"]))
        mm, t, la, lo = x["mmsi"][o], x["t"][o], x["lat"][o], x["lon"][o]
        same = mm[1:] == mm[:-1]
        dt_h = (t[1:] - t[:-1]).astype("timedelta64[s]").astype(float) / 3600
        dk = haversine_km(la[:-1], lo[:-1], la[1:], lo[1:])
        with np.errstate(divide="ignore", invalid="ignore"):
            v_kn = dk / 1.852 / dt_h
        jump = same & (dt_h > 0) & (v_kn > 50) & (dk > 1)
        r["reports_implied_speed_over_50kn"] = int(jump.sum())
        r["ships_with_jump"] = int(len(np.unique(mm[1:][jump])))
        r["reports_sog_over_40kn"] = int(np.sum(x["sog"] > 40))
        dup = same & (dt_h <= 10 / 60) & (dk > 50)
        r["ships_possible_duplicate_mmsi"] = int(len(np.unique(mm[1:][dup])))
        # 5. On land, more than 2 km in, in the area's projected CRS
        if land is not None:
            xm, ym = to_m.transform(x["lon"], x["lat"])
            inland = contains_xy(land, xm, ym)
            # Lake reports are split out as a separate class (the lakes aren't in the state polygons), and the 1:500,000 shoreline closes
            # narrow rivers, so split on-land reports by where they are.
            lakes = (x["lat"] > 41) & (x["lat"] < 49.5) & (x["lon"] > -92.5) & (x["lon"] < -75.8)
            if grid is not None:
                lakes[:] = False
            row, col, ok = cells.discrete(x["lat"], x["lon"], grid)
            cell = (row + (col - 1) * cells.grid_size(grid)[0]).astype(np.int64)
            cell[~ok] = -1
            on_route = np.isin(cell, route)
            r["reports_on_land_2km"] = int(inland.sum())
            r["reports_on_land_2km_great_lakes"] = int((inland & lakes).sum())
            r["reports_on_land_2km_on_route_cells"] = int((inland & ~lakes & on_route).sum())
            r["reports_on_land_2km_off_routes"] = int((inland & ~lakes & ~on_route).sum())
            r["ships_on_land_2km_off_routes"] = int(len(np.unique(x["mmsi"][inland & ~lakes & ~on_route])))
            # Do flagged reports (jumps, duplicates) create route cells on their own?
            flag = np.zeros(len(mm), bool)
            flag[1:] |= jump | dup
            flag_o = np.zeros(len(flag), bool)
            flag_o[o] = flag
            good_cells = set(cell[~flag_o].tolist())
            only_flag = set(cell[flag_o].tolist()) - good_cells
            r["cells_only_from_flagged_reports"] = len(only_flag)
            r["of_which_route_cells"] = int(np.isin(np.fromiter(only_flag, np.int64, len(only_flag)), route).sum())
            r["route_cells"] = int(len(route))
        # 6. Time stamps
        day0 = np.datetime64(day)
        r["reports_outside_day"] = int(np.sum((x["t"] < day0) | (x["t"] >= day0 + np.timedelta64(1, "D"))))
        res[area] = r
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, f"ais_qc_{day}.json"), "w") as f:
        json.dump(res, f, indent=1)
    print(json.dumps(res, indent=1))


_LAND = {}


def land_polygon(crs, states):
    """Land of the given states (None: the lower 48) shrunk by 2 km, in CRS meters."""
    key = (crs, states)
    if key not in _LAND:
        to_m = Transformer.from_crs(4326, crs, always_xy=True)
        sf = shapefile.Reader(STATES)
        polys = []
        for shp, rec in zip(sf.shapes(), sf.records()):
            keep = rec["STUSPS"] not in NOT_L48 if states is None else rec["STUSPS"] in states
            if not keep:
                continue
            g = shape(shp.__geo_interface__)
            if states == ("AK",):   # Aleutian parts east of 180 come as lon > 0; drop them (outside the grid)
                g = g.intersection(shapely.box(-180, 50, -129, 72))
            polys.append(shapely.transform(g, lambda xy: np.column_stack(to_m.transform(xy[:, 0], xy[:, 1]))))
        _LAND[key] = (unary_union(polys).buffer(-2000), to_m)
    return _LAND[key]


if __name__ == "__main__":
    for dd in sys.argv[1:]:
        main(dd)
