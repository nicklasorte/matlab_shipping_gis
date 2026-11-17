"""Second pass on the PSIX tonnage lookup (plan step C8): look up by vessel name
the U.S.-flag kept ships that the call-sign pass didn't match or found ambiguous.

Usage: python3 python/psix_gt_by_name.py
Reads data/psix_gt_kept_ships.csv, queries the PSIX web service by name for rows
whose match is "not found" or "ambiguous", keeps a candidate only when exactly one
PSIX vessel has the same normalized name (and, when PSIX gives one, the same call
sign), and writes the updated rows back with match "name" or "name and call sign".
"""
import csv
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import psix_gt_kept_ships as px  # noqa: E402

ROOT = px.ROOT


def main():
    path = os.path.join(ROOT, "data", "psix_gt_kept_ships.csv")
    rows = list(csv.DictReader(open(path)))
    todo = [r for r in rows if r["match"].startswith(("not found", "ambiguous")) and r["name"]]
    fixed = 0
    for r in todo:
        summ = px.records(px.call("getVesselSummaryXMLString", VesselID="", VesselName=r["name"], CallSign="", VIN="",
                                  HIN="", Flag="", Service="", BuildYear=""), "VesselSummary")
        time.sleep(1)
        cand = [v for v in summ if px.norm(v.get("VesselName")) == px.norm(r["name"])
                and v.get("CountryLookupName", "").upper() == "UNITED STATES"]
        with_cs = [v for v in cand if px.norm(v.get("VesselCallSign")) == px.norm(r["call_sign"])]
        pick = with_cs if with_cs else cand
        if len(pick) != 1:
            continue
        v = pick[0]
        ton = px.records(px.call("getVesselTonnageXMLString", VesselID=v["VesselId"]), "VesselTonnage")
        time.sleep(1)
        conv = sorted(float(t["MeasureOfWeight"]) for t in ton
                      if t.get("TonnageTypeLookupName", "").startswith("Convention") and t.get("MeasureOfWeight"))
        reg = sorted(float(t["MeasureOfWeight"]) for t in ton
                     if t.get("TonnageTypeLookupName", "").startswith("Regulatory") and t.get("MeasureOfWeight"))
        r.update(psix_vessel_id=v["VesselId"], psix_name=v.get("VesselName", ""),
                 gt_psix=f"{conv[-1]:.0f}" if conv else "", nt_psix=f"{conv[0]:.0f}" if len(conv) > 1 else "",
                 regulatory_gt_psix=f"{reg[-1]:.0f}" if reg else "",
                 match="name and call sign" if with_cs else "name")
        fixed += 1
    with open(path, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    print(f"second pass: {len(todo)} rows tried, {fixed} matched by name; "
          f"rows with PSIX gross tonnage now {sum(1 for r in rows if r['gt_psix'])} of {len(rows)}")


if __name__ == "__main__":
    main()
