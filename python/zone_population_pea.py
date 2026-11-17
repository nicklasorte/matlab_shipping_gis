"""Population in each zone by FCC license area (Partial Economic Area, PEA).

Usage: python3 python/zone_population_pea.py [tag]

Maps 2020 Census block groups to PEAs through their county (47 CFR Part 27,
Appendix A to Subpart A, "List of Partial Economic Areas With Corresponding
Counties", eCFR as of October 1, 2026: data/ref/pea_counties_47cfr27.csv) and
counts each PEA's population inside the 25, 50, and 100 km zones of all four
regions (zone files as in python/zone_population.py). This shows what each
zone covers in the units wireless licenses are sold in.

Writes outputs/zone_population_pea_rev1.csv (one row per PEA) and prints a
summary: PEAs with any population in a zone, and PEAs with more than half of
their population in it. Counties that changed since the PEA list (for example
in Alaska) are reported as unmatched.
"""
import os
import sys

import numpy as np
import pandas as pd
from shapely import contains_xy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import zone_population as zp  # noqa: E402

ROOT = zp.ROOT


def main(tag="base"):
    bg = zp.load_blockgroups()
    bg["county_fips"] = bg.STATEFP + bg.COUNTYFP.astype(int).astype(str).str.zfill(3)
    # County changes since the PEA list: Valdez-Cordova split into Chugach and Copper
    # River (2019), Wade Hampton renamed Kusilvak (2015), Shannon renamed Oglala Lakota (2015).
    bg["county_fips"] = bg.county_fips.replace({"02063": "02261", "02066": "02261", "02158": "02270", "46102": "46113"})
    pea = pd.read_csv(os.path.join(ROOT, "data", "ref", "pea_counties_47cfr27.csv"), dtype=str)
    bg = bg.merge(pea[["county_fips", "pea"]], on="county_fips", how="left")
    unmatched = bg[bg.pea.isna()]
    for km in zp.DISTANCES:
        bg[f"in_{km}km"] = False
    for name, folder, stem, grid, states in zp.REGIONS:
        sub = zp.in_region(bg, grid, states)
        for km in zp.DISTANCES:
            path = os.path.join(ROOT, folder, f"{stem}_ships_{km}km.shp")
            if os.path.exists(path):
                inside = contains_xy(zp.zone(path), sub.LONGITUDE.to_numpy(), sub.LATITUDE.to_numpy())
                bg.loc[sub.index[inside], f"in_{km}km"] = True
    rows = []
    for p, g in bg[bg.pea.notna()].groupby("pea"):
        tot = int(g.POPULATION.sum())
        first = pea[pea.pea == p].iloc[0]
        row = dict(run=tag, pea=int(p), first_county=f"{first.county}, {first.state}", population=tot)
        for km in zp.DISTANCES:
            pin = int(g.POPULATION[g[f"in_{km}km"]].sum())
            row[f"pop_in_{km}km"] = pin
            row[f"share_in_{km}km"] = round(pin / tot, 4) if tot else np.nan
        rows.append(row)
    out = pd.DataFrame(rows).sort_values("pea")
    out.to_csv(os.path.join(ROOT, "outputs", "zone_population_pea_rev1.csv"), index=False)
    print(f"PEAs: {len(out)}; block groups without a PEA: {len(unmatched)} "
          f"(population {int(unmatched.POPULATION.sum()):,}; counties {sorted(unmatched.county_fips.unique())[:8]})")
    for km in zp.DISTANCES:
        s = out[f"share_in_{km}km"]
        print(f"{km} km: PEAs with any population in the zone {int((s > 0).sum())}; more than half {int((s > 0.5).sum())}; "
              f"all {int((s >= 0.999).sum())}")
    print(out.sort_values("population", ascending=False).head(12)[["pea", "first_county", "population", "share_in_25km", "share_in_50km", "share_in_100km"]].to_string(index=False))


if __name__ == "__main__":
    main(*sys.argv[1:2])
