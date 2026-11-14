"""Gross tonnage of U.S.-flag kept ships from the Coast Guard PSIX web service
(plan step C5, data plan A6).

Usage: python3 python/psix_gt_kept_ships.py [max_ships]

Reads data/kept_ships_2024_2025.csv, keeps U.S.-flag ships (MMSI country
codes 303, 338, 366-369) with a call sign, and asks the public PSIXData web
service (https://cgmix.uscg.mil/xml/PSIXData.asmx) for each call sign:
getVesselSummaryXMLString gives the PSIX vessel ID, getVesselTonnageXMLString
the tonnage rows. PSIX lists Convention (Subpart B) tonnage as two rows, gross
and net, with unit labels ("Long Ton", "Short Ton") that don't follow the
measure, so gt_psix is the larger Convention value and nt_psix the smaller;
every raw row is kept in psix_tonnage_rows.csv for checking. A call sign that
returns several PSIX vessels is matched by name; if none match, the row is
marked ambiguous and gets no tonnage.

Writes data/psix_gt_kept_ships.csv (mmsi, imo, name, call_sign, psix_vessel_id,
psix_name, gt_psix, nt_psix, regulatory_gt_psix, match) and
data/psix_tonnage_rows.csv. One request a second; standard library only.
"""
import csv
import html
import os
import re
import sys
import time
import urllib.request

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
URL = "https://cgmix.uscg.mil/xml/PSIXData.asmx"
US_MID = ("303", "338", "366", "367", "368", "369")


def call(op, **kw):
    body = "".join(f"<{k}>{html.escape(str(v))}</{k}>" for k, v in kw.items())
    env = ('<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'
           f'<soap:Body><{op} xmlns="https://cgmix.uscg.mil">{body}</{op}></soap:Body></soap:Envelope>')
    req = urllib.request.Request(URL, data=env.encode(), headers={
        "Content-Type": "text/xml; charset=utf-8", "SOAPAction": f'"https://cgmix.uscg.mil/{op}"'})
    for attempt in range(3):
        try:
            return html.unescape(urllib.request.urlopen(req, timeout=60).read().decode())
        except OSError:
            if attempt == 2:
                raise
            time.sleep(5)


def records(xml, tag):
    return [dict(re.findall(r"<(\w+)>([^<]*)</\1>", block)) for block in re.findall(rf"<{tag}>(.*?)</{tag}>", xml, re.S)]


def norm(s):
    return re.sub(r"[^A-Z0-9]", "", (s or "").upper())


def main(max_ships=None):
    with open(os.path.join(ROOT, "data", "kept_ships_2024_2025.csv"), newline="") as f:
        ships = [r for r in csv.DictReader(f) if r["mmsi"][:3] in US_MID and r["call_sign"]]
    if max_ships:
        ships = ships[:int(max_ships)]
    out, raw = [], []
    for k, s in enumerate(ships):
        summ = records(call("getVesselSummaryXMLString", VesselID="", VesselName="", CallSign=s["call_sign"], VIN="",
                            HIN="", Flag="", Service="", BuildYear=""), "VesselSummary")
        time.sleep(1)
        row = dict(mmsi=s["mmsi"], imo=s["imo"], name=s["name"], call_sign=s["call_sign"], psix_vessel_id="",
                   psix_name="", gt_psix="", nt_psix="", regulatory_gt_psix="", match="")
        cand = [v for v in summ if norm(v.get("VesselCallSign")) == norm(s["call_sign"])]
        if len(cand) > 1:
            cand = [v for v in cand if norm(v.get("VesselName")) == norm(s["name"])] or cand
        if not cand:
            row["match"] = "not found"
        elif len(cand) > 1:
            row["match"] = f"ambiguous ({len(cand)})"
        else:
            v = cand[0]
            row["psix_vessel_id"], row["psix_name"] = v.get("VesselId", ""), v.get("VesselName", "")
            row["match"] = "call sign and name" if norm(v.get("VesselName")) == norm(s["name"]) else "call sign only"
            ton = records(call("getVesselTonnageXMLString", VesselID=row["psix_vessel_id"]), "VesselTonnage")
            time.sleep(1)
            for t in ton:
                raw.append(dict(mmsi=s["mmsi"], psix_vessel_id=row["psix_vessel_id"], value=t.get("MeasureOfWeight", ""),
                                tonnage_type=t.get("TonnageTypeLookupName", ""), unit=t.get("UnitOfMeasureLookupName", "")))
            conv = sorted(float(t["MeasureOfWeight"]) for t in ton
                          if t.get("TonnageTypeLookupName", "").startswith("Convention") and t.get("MeasureOfWeight"))
            reg = sorted(float(t["MeasureOfWeight"]) for t in ton
                         if t.get("TonnageTypeLookupName", "").startswith("Regulatory") and t.get("MeasureOfWeight"))
            if conv:
                row["gt_psix"], row["nt_psix"] = f"{conv[-1]:.0f}", (f"{conv[0]:.0f}" if len(conv) > 1 else "")
            if reg:
                row["regulatory_gt_psix"] = f"{reg[-1]:.0f}"
        out.append(row)
        if k % 25 == 0:
            print(k, len(ships), row["call_sign"], row["match"], row["gt_psix"], flush=True)
    with open(os.path.join(ROOT, "data", "psix_gt_kept_ships.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(out[0]))
        w.writeheader()
        w.writerows(out)
    with open(os.path.join(ROOT, "data", "psix_tonnage_rows.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["mmsi", "psix_vessel_id", "value", "tonnage_type", "unit"])
        w.writeheader()
        w.writerows(raw)
    found = sum(1 for r in out if r["gt_psix"])
    print(f"U.S.-flag kept ships with a call sign: {len(out)} | with PSIX gross tonnage: {found}")


if __name__ == "__main__":
    main(*sys.argv[1:2])
