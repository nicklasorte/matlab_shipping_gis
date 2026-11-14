"""Where do the S-band research ships (data/sband_truth_ships.csv) sail, and does
the large-ship filter keep them? Plan step A1, match to AIS.

Reads the per-day AIS extracts written by python/truth_ship_tracks.sh (all
reports from the truth-set MMSI numbers on the 104 route days, 2024-2025) and,
for each ship:
  - the AIS identity it reports (IMO, type, length; most common value),
  - which step of the large-ship filter drops it (Section 1.4: vessel type in
    the kept list, length of 100 m or more, IMO number required),
  - the days and reports seen, and the share of reports inside the clipped
    25, 50, and 100 km zones of any region (lower 48, Hawaii, Puerto Rico and
    USVI, Alaska) and within 25 km of a lower-48 AIS route cell.

Usage: python3 python/truth_ship_zone_check.py <tracks_dir>
Writes outputs/2024_2025/truth_ship_zone_check_rev1.csv.
"""
import glob
import os
import sys

import numpy as np
import pandas as pd
import shapefile
from scipy.spatial import cKDTree
from shapely import contains_xy
from shapely.geometry import shape
from shapely.ops import unary_union

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, HERE)
import ship_viz_products as vp  # noqa: E402

# Ship and MMSI: AIS records in data/ais_vessels_2024_4days.csv matched by IMO, or
# secondary sites where marked (see docs/review/sband_truth_ships_rev1.md).
SHIPS = {
    "369140000": "Sally Ride", "367800100": "Roger Revelle", "368996000": "Ronald H. Brown",
    "369888000": "Okeanos Explorer", "369991000": "Henry B. Bigelow", "367241000": "Atlantis",
    "369958000": "Thomas Jefferson", "368926382": "Oscar Dyson", "303913000": "Gordon Gunter",
}
KEPT_TYPES = set([0, 33, 35, 55] + list(range(60, 90)) + list(range(90, 100)))
NO_IMO_TYPES = {35, 55}
ZONES = [
    ("outputs/2024_2025", "shipping_zone_2024_2025"),
    ("outputs/2024_2025/hawaii", "shipping_zone_hawaii_2024_2025"),
    ("outputs/2024_2025/prusvi", "shipping_zone_prusvi_2024_2025"),
    ("outputs/2018_2019/alaska", "shipping_zone_alaska_2018_2019"),
]


def zone(km):
    parts = []
    for d, stem in ZONES:
        sf = shapefile.Reader(os.path.join(ROOT, d, f"{stem}_ships_{km}km.shp"))
        parts += [shape(s.__geo_interface__).buffer(0) for s in sf.shapes()]
    return unary_union(parts)


def mode(s):
    s = s.dropna()
    return s.mode().iloc[0] if len(s) else np.nan


def filter_verdict(vtype, length, imo):
    why = []
    if pd.isna(vtype) or int(vtype) not in KEPT_TYPES:
        why.append("type")
    if pd.isna(length) or float(length) < 100:
        why.append("length")
    has_imo = isinstance(imo, str) and imo.strip() not in ("", "IMO0000000")
    if not has_imo and (pd.isna(vtype) or int(vtype) not in NO_IMO_TYPES):
        why.append("IMO")
    return "kept" if not why else "dropped: " + ", ".join(why)


def main(tracks_dir):
    files = sorted(glob.glob(os.path.join(tracks_dir, "tracks_*.csv")))
    days = [os.path.basename(f)[7:17] for f in files]
    T = pd.concat([pd.read_csv(f, dtype=str).assign(day=d) for f, d in zip(files, days)], ignore_index=True)
    T.columns = [c.lower() for c in T.columns]
    for c in ("latitude", "longitude", "length", "vessel_type"):
        T[c] = pd.to_numeric(T[c], errors="coerce")
    T = T[T.mmsi.isin(SHIPS)].copy()
    lat, lon = T.latitude.to_numpy(), T.longitude.to_numpy()
    for km in (25, 50, 100):
        T[f"in_{km}km_zone"] = contains_xy(zone(km), lon, lat)
    z = np.load(os.path.join(ROOT, "outputs", "2024_2025", "viz", "viz_cells.npz"))
    rl, ro = vp.cell_latlon(z["route_cells"])
    d = vp.chord_to_arc(cKDTree(vp.ecef(rl, ro)).query(vp.ecef(lat, lon))[0])
    T["km_to_l48_route"] = d
    rows = []
    for mmsi, ship in SHIPS.items():
        S = T[T.mmsi == mmsi]
        if S.empty:
            rows.append(dict(ship=ship, mmsi=mmsi, days_seen=0, reports=0, days_sampled=len(days)))
            continue
        vtype, length, imo = mode(S.vessel_type), mode(S.length), mode(S.imo)
        rows.append(dict(
            ship=ship, mmsi=mmsi, ais_imo=imo, ais_vessel_type=vtype, ais_length_m=length,
            ais_name=mode(S.vessel_name), filter_result=filter_verdict(vtype, length, imo),
            days_sampled=len(days), days_seen=S.day.nunique(), reports=len(S),
            share_in_25km_zone=round(S.in_25km_zone.mean(), 3), share_in_50km_zone=round(S.in_50km_zone.mean(), 3),
            share_in_100km_zone=round(S.in_100km_zone.mean(), 3),
            share_within_25km_of_l48_route=round((S.km_to_l48_route <= 25).mean(), 3),
            days_in_25km_zone=S[S.in_25km_zone].day.nunique(),
            lat_range=f"{S.latitude.min():.1f} to {S.latitude.max():.1f}",
            lon_range=f"{S.longitude.min():.1f} to {S.longitude.max():.1f}"))
    out = pd.DataFrame(rows)
    path = os.path.join(ROOT, "outputs", "2024_2025", "truth_ship_zone_check_rev1.csv")
    out.to_csv(path, index=False)
    print(out.to_string())
    print("days with files:", len(days), "| reports:", len(T))


if __name__ == "__main__":
    main(sys.argv[1])
