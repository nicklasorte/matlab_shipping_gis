# Round 3 data review: radar models and research-ship truth set

DRAFT//PRE-DECISIONAL

Date: November 13, 2026. Reviewer: independent data agent (round 3). Scope:
`data/ship_radar_models.csv` with `docs/review/sband_radar_models_rev1.md`, and
`data/sband_truth_ships.csv` with `docs/review/sband_truth_ships_rev1.md`.
Public sources only. No other file was edited.

## Summary

- **Radar table:** I sampled 13 rows (Furuno FAR-2238S, FAR-2238S-NXT,
  FAR-2137S, FAR-2837S, FR-2135S; JRC JMR-9230-S, -S3, -9272-S, -9282-S,
  -9282-SH; Kelvin Hughes SharpEye; Kongsberg; ITU-R M.1460-1 generic). Most
  quoted values match their sources: frequency, peak power, beamwidths,
  sidelobes, IF, noise figure, and the JRC pulse tables. The two main problems:
  - The photo-coding rule fails against the table's own cited source. Furuno's
    installation manual lists a 10 ft X-band antenna (XN30AF), so "10 ft or
    longer is S-band" is wrong.
  - The guide states the rule three different ways.

  The same manual also lists a 60 kW S-band fishing radar (FAR-2268DS) that the
  table leaves out. Several pulse/PRF pairings and one JRC row copy values from
  a sibling scanner without saying so.
- **Truth-ship table:** All cited pages were reached directly or through the
  fetch tool, except as noted in R3DAT-28.
  - Two `gross_tonnage` values are full-load displacement, not tonnage: Ronald
    H. Brown 3,250 and Henry B. Bigelow 2,479.
  - The doc's finding 2 (four ships under 3,000 GT) uses the IRVSI figures,
    which the doc itself says not to use.
  - Kilo Moana's IRVSI page names a Sperry Bridgemaster E250 radar that the CSV
    missed.
  - A cross-reference note for Thomas Jefferson points to Gordon Gunter's page.
  - The Ronald H. Brown note says neither source is dated. Both are.
  - Sally Ride's length (238 ft) is published, so all nine S-band ships, not
    eight, are under 100 m.

## Findings

| ID | Type | Row or location | Finding | Evidence | Suggested fix |
| --- | --- | --- | --- | --- | --- |
| R3DAT-1 | Wrong value | Radar guide, Finding 3 and `photo_code_by_antenna` column definition | The rule "10 ft or longer is S-band" and the statement "X-band antennas run 4–9 ft" are refuted by the table's own cited Furuno manual. | IME36520U (helpjuice URL in `antenna_source_url`), equipment list "X-band TR-UP (Fishing specification)": FAR-2258 with XN24AF 8 ft and XN30AF 10 ft, 50 kW, "Unavailable on IMO-type radars." | Code 10–11.9 ft as "likely S-band (10 ft X-band exists on non-IMO fishing radars)". Keep only 12 ft or longer as S-band. Add a FAR-2258 X-band row. |
| R3DAT-2 | Wording | Radar guide: Finding 3, column table, closing paragraph | The guide gives three different photo-coding rules: 12 ft or longer is S-band (Finding 3); 10 ft or longer is S-band, 8–9.9 ft unclear, under 8 ft X-band (column table and CSV); and "antennas shorter than 10 ft are unclear, not X-band" (closing paragraph). | Internal text of `sband_radar_models_rev1.md`. | Choose one rule after R3DAT-1 and use it in all three places and in the CSV. |
| R3DAT-3 | Unsupported | Radar table coverage; guide Finding 2 and "Magnetron S-band radars: 30 kW peak" | The cited Furuno manual lists S-band models the table omits: FAR-2268DS (60 kW, SN30AF/SN36AF/SN30DF 10 and 12 ft, fishing, non-IMO) and FAR-2338SW (RTR-109). A 60 kW S-band emitter contradicts the "30 kW for magnetrons" summary used for EMC. | IME36520U: "S-band TR-UP (Fishing specification) Magnetron radar: FAR-2268DS ... 10 ft, 60 kW ... 12 ft, 60 kW". The transceiver table lists RTR-144 (60 kW) and RTR-109 (30 kW, FAR-2338SW). | Add both rows. Change the EMC summary to "30 kW typical (IMO); up to 60 kW on fishing variants; ITU envelope 30–75 kW". |
| R3DAT-4 | Wrong value | Radar row FAR-2238S, `pulse_prf_pairs_us_hz` | The row says "PRR about 600–3000 Hz". The brochure's S-band PRR list ends at 600 Hz, with a footnote of 500 Hz on the 96 NM range. | Radio Holland FAR-22x8 brochure: PRR "3000, 3000, 1500, 1200, 1000, 600*", "*: 500 Hz on 96 NM range." | Change to "about 500–3000 Hz". List the six PRR values. |
| R3DAT-5 | Inference | Radar row JMR-9230-S3 (NKE-1139) | Frequency, power, pulse/PRF pairs, IF, IF bandwidth, and noise figure are copied from NKE-1130 without a label. The FCC section for NKE-1139 gives only size, beamwidth, sidelobes, polarization, and rpm. The inference is reasonable, because it's the 3-unit version of the same 30 kW radar, but it isn't marked. | fcc.report CKENKE2632 exhibit, section 24.25 (NKE-1139): no frequency, power, or pulse table. Section 24.26 (NKE-1130) has them. | Add `rf_note`: "transceiver values INFERRED from NKE-1130 (FCC 24.26); NKE-1139 section gives antenna data only". |
| R3DAT-6 | Inference | Radar rows FAR-2137S and FR-2135S, `pulse_prf_pairs_us_hz` and `max_duty_cycle_pct` | The brochures list pulse lengths and PRRs for each range scale. They don't pair them, so the pairs in the CSV (for example, 0.7/1000 or 600) are constructed. The pairing is plausible: longest pulse with lowest PRR. The 0.072% duty cycle depends on it, and neither row says so. | FAR-2137S brochure: "3 NM: 0.15, 0.3, 0.5, 0.7 µs; PRR 3000, 1500, 1000" (4 pulses, 3 PRRs). FR-2135S: "3 NM: 2 from 0.15/0.3/0.5/0.6; 1900/1100/600". | Mark the pairs "INFERRED from range-scale table". The duty cycle can stay. |
| R3DAT-7 | Wrong value | Radar row FAR-2338S; rows FAR-2238S and -NXT | FAR-2338S has `antenna_ft` = 12.5 but `photo_code_by_antenna` = "unknown (length not stated)". The same SN36CF antenna is 12 ft in rows FAR-2238S and FAR-2238S-NXT. | Furuno Norway MED certificate (FAR-2xx8.pdf): "RTR-107 SN36CF-RSB-129 12.5 ft". The FAR-22x8 brochure: "SN36CF 12 ft". | Set the photo code to "S-band". Use one length for SN36CF (12 ft per the brochure), with a note that the MED certificate says 12.5 ft. |
| R3DAT-8 | Wording | Radar rows JMR-9230-S, -9272-S, -9282-S, -9282-SH, Kongsberg | `antenna_ft` is the nominal radiator length. JRC's FCC filing gives only the swing circle, which is closer to what a photo shows. The 8 ft JRC S-band scanner sweeps 2.77 m (9.1 ft), and the 12 ft scanners sweep 4.0 m (13.1 ft). | FCC CKENKE2632: NKE-2632 "Height 720 × Swing Circle 2770 (mm)"; NKE-1130 and NKE-1632 "Swing Circle 4000 (mm)". | Add a `swing_circle_m` column where known, and tell photo coders which dimension the rule uses. |
| R3DAT-9 | Wrong value | Radar guide, "Main points for the EMC analysis" (Both) | "Sidelobes at −26 dB to −30 dB" leaves out the Furuno −24 dB within ±10°. | FAR-2137S brochure and FAR-22x8 brochure: SN-30AF/SN-36AF and SN36CF "−24 dB (within ±10°)". | Change to "−24 dB to −30 dB". |
| R3DAT-10 | Wording | Radar guide, `max_duty_cycle_pct` row | "JRC solid-state is about 2.1%, which matches its stated average power (5.8 W of 250 W peak)." 2.1% × 250 W = 5.25 W. 5.8 W is an upper bound ("or lower") and equals 2.3%. | FCC CKENKE2632 NKE-1632/2632: "Average power 5.8 W or lower"; peak "250 W ±50%". | Change "matches" to "is consistent with (5.8 W is a stated upper bound)". |
| R3DAT-11 | Inference | Radar rows JMR-9272-S, -9282-S, -9282-SH (`freq_high_mhz` 3069); guide Finding 1 ("3035–3075 MHz") | `freq_high` counts only the ±4 MHz tolerance on the Q0N carrier. It leaves out the 8 MHz frequency deviation of the long pulse. Depending on how the sweep sits on the carrier, emission can reach about 3073 MHz. The guide's 3035–3075 MHz also understates Furuno NXT's upper edge, 3078.75 MHz, which the CSV gives. | FCC CKENKE2632: Q0N "3065 ±4 MHz or 3060 ±4 MHz", second pulse "8 MHz" deviation. FAR-22x8 brochure: CH2 Q0N "3073.75 MHz ±5 MHz". | Add a note that occupied bandwidth isn't modeled. In the guide, write "about 3035–3079 MHz". |
| R3DAT-12 | Wording | Radar row SharpEye (`frequency_channels`); guide Finding 1 | "Eight selectable channels across the whole 2900–3100 MHz band" goes beyond the source. The datasheet gives the band and the channel count, not the channel frequencies. | Mackay copy of the Kelvin Hughes datasheet: "FREQUENCY 2.9–3.1 GHz (8 SELECTABLE CHANNELS)". | Write "8 selectable channels within 2.9–3.1 GHz (channel frequencies not published)". |
| R3DAT-13 | Wording | Radar guide, `sector_blanking` row | "Often toward the ship's own structure or another radar" isn't in MSC.192(79). "Must" overstates a resolution that recommends governments ensure compliance. Carriage becomes mandatory through type approval. | MSC.192(79) 7.3: "mute facility to inhibit the transmission of radar energy over a preset sector. The mute sector should be set up on installation." The resolution "RECOMMENDS Governments to ensure that radar equipment installed on or after 1 July 2008 conform". | Drop the "often toward" clause or cite a source for it. Write "required by MSC.192(79) 7.3 (applied through type approval)". |
| R3DAT-14 | Wording | Radar guide, Columns section | "The file holds 34 rows: 22 S-band models and 12 X-band models." The file has 35 data rows, and 23 are S-band, counting the ITU-R M.1460-1 generic row. | `data/ship_radar_models.csv` row count. | Write "35 rows: 22 S-band models, 1 ITU generic S-band row, and 12 X-band models". |
| R3DAT-15 | Wording | Radar rows FAR-2238S, FAR-2238S-NXT (`imo_category`, `ship_size_hint`); FAR-3230S | The MED certificate lists the FAR-22x8 S-band radars as CAT 2/3, not only CAT 2. FAR-3230S is certified as CAT 1 or CAT 2, depending on the monitor. | Furuno Norway FAR-2xx8.pdf: "CAT 2/3 radars FAR-2218(-BB) ... FAR-2238S(-BB), FAR-2238-NXT(-BB)". FAR-3xx0(14).pdf: "CAT1, CAT2 ... (dependent of monitor and antenna rpm)". | Change to "CAT 2/3" and add the CAT 3 size hint. Change FAR-3230S to "CAT 1 or 2 (by monitor)". |
| R3DAT-16 | Wrong value | Radar row FAR-2837S, `rotation_rpm` and `antenna_options` | The row gives only 21/26 rpm. The FAR-28x7 brochure also lists 45 rpm S-band gearboxes, the same as the FAR-2137S. | ManualsLib FAR-2817/2827/2837S brochure p. 6: S-band rotation "21/26 rpm" and "45 rpm" (gearboxes RSB-098 to RSB-102). | Change to "21/26 or 45 (HSC)". |
| R3DAT-17 | Wording | Radar guide, `antenna_gain_db` row | "Only Raytheon Anschütz states it" leaves out the ITU generic row, which gives 26–28 dB. | ITU-R M.1460-1 Table 4: gain 26–28 dB. | Write "Only Raytheon Anschütz states it for a model; ITU-R M.1460-1 gives 26–28 dB". |
| R3DAT-18 | Unsupported | Radar sources: fcc.report, kongsberg.com, manualslib.com, radioholland.com | A plain HTTP client can't fetch these four hosts. Three serve a Cloudflare challenge page, and radioholland.com fails the TLS certificate-chain check. I confirmed their contents only through the fetch tool's extracted text. Later reviewers may not be able to reproduce the check. | curl, November 13, 2026: fcc.report, kongsberg.com, and manualslib.com returned 403 "Just a moment..."; radioholland.com returned "unable to get local issuer certificate". | Keep dated local copies under `data/sources/` (where licensing allows), or cite the FCC's own EAS record for CKENKE2632. |
| R3DAT-19 | Wrong value | Truth row Ronald H. Brown (3 rows), `gross_tonnage` = 3250 | 3,250 is the ship's displacement. Its gross tonnage is 3,180. | WHOI copy of NOAA Brown specs: "Displacement 3250 tons", no GT. Wikipedia NOAAS Ronald H. Brown: "3,180 GT", "Displacement: 3,250 tons". VesselFinder IMO 9105786: GT 3,180. | Set `gross_tonnage` to 3180, sourced to Wikipedia or VesselFinder. Note that IRVSI's "3250 GRT" is the displacement. |
| R3DAT-20 | Wrong value | Truth row Henry B. Bigelow, `gross_tonnage` = 2479; doc Finding 2 "2,479 GT" | 2,479 is the full-load displacement in metric tons, which IRVSI labels "GRT". The CSV already treats sister ship Oscar Dyson's identical 2,479 as displacement. | NOAA HB spec sheet (2018): "Displacement: 2479 tons". Wikipedia NOAAS Henry B. Bigelow: "2,479 metric tons (full load)", GT not given. IRVSI shipID=988: "2479 GRT". | Blank `gross_tonnage` (or find a GT source) and note that it's displacement. Fix Finding 2. |
| R3DAT-21 | Unsupported | Truth doc, Finding 2 ("Four carry S-band below 3,000 GT") | The finding relies on IRVSI "GRT" numbers. The Cautions section says not to use them for the 3,000 GT test, and at least two are displacement (R3DAT-19, R3DAT-20). An independent figure for Thomas Jefferson is 1,767 GT, not 1,466. The conclusion probably holds, because all four are about 2,500 t or less, but the numbers aren't GT. The SOLAS framing ("fitted by choice") is also weak: SOLAS Reg. I/3 excludes government ships on non-commercial service, so a GT threshold doesn't govern NOAA ships. | VesselFinder IMO 8892033 (Thomas Jefferson): GT 1,767. VesselFinder IMO 8835114 (Okeanos Explorer): GT 2,062, which agrees with IRVSI. See R3DAT-20 for Henry B. Bigelow. | Restate as "four ships of about 1,800–2,500 GT or less (secondary sources) carry S-band". Cite a GT source for each. Change "below the SOLAS threshold, fitted by choice" to "not subject to SOLAS carriage rules (government ships); S-band fitted by owner choice". |
| R3DAT-22 | Wrong value | Truth row Kilo Moana (`radar_make`, `radar_model_as_stated`, `source_text`, `note`); doc Results table | The IRVSI page names a make and model. The CSV quotes only "Radar" and says no make, model, or band. | IRVSI shipID=466 (last updated 10/23/2009): "Navigational Equipment: TSS POSMV, Gyro Compass, Raytheon STD-20, Raytheon Raychart 420, Radar, Sperry Marine Decca Bridgemaster E250". | Set make to Sperry Marine (Decca) and model to "Bridgemaster E250", with band not stated. Quote the full line. In the doc, move Kilo Moana into the "band not stated" group. |
| R3DAT-23 | Wrong value | Truth row Thomas Jefferson, `note` | The note says shipID=987 carries the same text as Thomas Jefferson's page. shipID=987 is Gordon Gunter's page, IMO 8835255, call sign WTEO. | IRVSI shipID=987: name Gordon Gunter, "X-Band and S-Band Radar with ARPA Display LORAN C receiver (Northstar 800)". | Delete the cross-reference, or move it to the Gordon Gunter row as a duplicate IRVSI entry (shipID 240 and 987). |
| R3DAT-24 | Wrong value | Truth rows Ronald H. Brown, `note` and `source_text` | The note says "dates not stated on either", but both sources are dated. The IRVSI page is the later of the two, which weakens the guess that IRVSI is older. The quoted `source_text` is also stitched together, not verbatim. | IRVSI shipID=221: "Two Sperry Rascar Touch Screen navigational radars on the bridge. One radar is an S-band (10 cm) 30 kW radar and the other is an X-band (3 cm) 25 kW radar", "Last updated 7/11/2018". The WHOI-hosted OMAO PDF, as returned by the fetch tool, says "Reviewed: July 17, 2017". | Record both dates. Quote the IRVSI text verbatim. Keep confidence low, but note that the Sperry listing is the later one. |
| R3DAT-25 | Wrong value | Truth row Healy, `call_sign` | The source gives a call sign, but the CSV leaves it blank. | UNOLS healy_2.pdf: "Call Sign: NEPP". It also confirms "Length OA: 128m", "16000 GRT", "IMO# 009083380". | Set `call_sign` to NEPP. |
| R3DAT-26 | Unsupported | Truth doc Finding 1 ("Eight of the nine ... have a published length"); Next section | Sally Ride's length and tonnage are published, so 9 of 9 S-band ships are under 100 m. Sally Ride is also above 3,000 GT. | Scripps "R/V Sally Ride Specifications": "238 feet", gross tonnage "3,043 tons", radio call sign "WSAF". | Add length 72.5 m, GT 3,043, and call sign WSAF to both Sally Ride rows. Change Finding 1 to "all nine". |
| R3DAT-27 | Wording | Truth doc, Results table row 3 | The heading "A radar listed with no make, model or band, or none listed" is inaccurate. Bell M. Shimada (Sperry Bridgemaster) and Kilo Moana (R3DAT-22) list a make and model but no band. | IRVSI shipID=992: "Sperry Bridgemaster Radar". | Change to "Band not stated, or no radar listed". |
| R3DAT-28 | Unsupported | All 10 `researchvessels.org/ship_info_display.asp` URLs | A direct fetch on November 13, 2026, returned a GitHub Pages 404 for every IRVSI URL, because the site has moved. The fetch tool still returned page content, probably from a cache, and I checked values against that. The Wayback Machine has snapshots from 2021–2024, but web.archive.org was blocked in this session. Several IRVSI pages are stale: Thomas G. Thompson last updated 1/27/2005, Kilo Moana 10/23/2009. | curl: 404 "Page not found · GitHub Pages". Wayback availability API lists snapshots, for example shipID=221 at 20241016. | Replace each link with its Wayback snapshot URL. Add a `source_last_updated` column. |
| R3DAT-29 | Wording | Truth doc, Matching to AIS; truth rows Okeanos Explorer, Thomas Jefferson, Sally Ride (`imo`) | "Use IMO first (Atlantis, Ronald H. Brown, Henry B. Bigelow)" leaves out Gordon Gunter and Healy, which already have IMO numbers in the CSV. IMO numbers for other S-band ships are public on secondary sites. | VesselFinder: Okeanos Explorer IMO 8835114 (WTDH), Thomas Jefferson IMO 8892033 (WTEA). TrustedDocks: Sally Ride 9695171. | List all five ships with IMO numbers. Add the secondary-source IMO numbers, flagged as secondary. |
| R3DAT-30 | Wording | Truth doc, "What's in the table" | "Ships come from the UNOLS fleet and the NOAA fleet" leaves out Healy, which is a USCG ship. | CSV `fleet` = USCG for Healy. | Write "UNOLS, NOAA, and one USCG icebreaker". |

## Confirmed

### Radar table

- **ITU-R M.1460-1 generic row:** Every Table 4 value matches the
  recommendation:
  - Frequency 3020–3080 MHz.
  - Peak power 30–75 kW.
  - Pulse 0.05–1.2 µs at a PRF of 375–4000 Hz.
  - Beamwidth 1–4° horizontal and 24–30° vertical.
  - Sidelobes 23–28 dB within ±10° and 31–32 dB outside.
  - Gain 26–28 dB.
  - Rotation 20–60 rpm.
  - IF 45–60 MHz, with bandwidths of 6–28 and 2.5–6 MHz.
  - Noise figure 3–8.5 dB.

  The recommendation also gives more than 300,000 units (Table 3), I/N of
  −6 dB "even if multiple interferers are present", "most ... use slotted array
  antennas", and horizontal as the predominant polarization.
  "Magnetron (as of 2006)" and "single frequency" are reasonable inferences, but
  the recommendation doesn't state them.
- **MSC.192(79):** Transmitter mute is 7.3. Roll and pitch up to ±10° without
  substantial impairment is 5.6. The 15 m antenna height in the detection tests
  is 5.3.1.1. The standard applies to equipment installed on or after July 1,
  2008. The S-band definition is 2.9–3.1 GHz (5.1.2).
- **FAR-2238S and FAR-2238S-NXT:**
  - Frequencies, including the NXT P0N/Q0N channels, ±5 MHz, and the CSV's
    3038.75–3078.75 MHz span.
  - 30 kW and 250 W ("equivalent to magnetron radar 30 kW").
  - SN36CF 12 ft, 1.8° by 25°, sidelobes −24/−30 dB, horizontal polarization.
  - 24 or 42 rpm.
  - CAT 2 with the 19-inch display, from the product page.
- **Installation manual:** It lists the 8 ft and 10 ft S-band radiators (SN24CF
  and SN30CF) as "Unavailable on IMO-type radars".
- **FAR-2338S and FAR-3230S frequency inference:** Reasonable. The MED
  certificates list the same RTR-107 transceiver and SN36CF-RSB-129 antenna as
  the FAR-2238S.
- **FAR-2137S:** 3050 ±30 MHz, 30 kW, SN-30AF/SN-36AF at 10 or 12 ft,
  2.3°/1.8° by 25°, sidelobes −24/−30 dB, 21/26 or 45 rpm, IF 60 MHz log with
  40/10/3 MHz bandwidths, slotted waveguide antenna. The listed standards
  (IEC 60936-1 and MSC.64(67)) support "predates MSC.192(79)".
- **FAR-2837S:** 3050 ±30 MHz, 30 kW, the same antennas, beamwidths, and
  sidelobes, and IF 60 MHz.
- **FR-2135S:** 3050 ±30 MHz, 30 kW, SN5AF 9 ft and SN7AF 12 ft, 2.3°/1.9° by
  25°, 24 rpm, IF 60 MHz with 28/3 MHz bandwidths, noise figure 4 dB.
- **JRC NKE-1130 (FCC):** 3050 ±20 MHz, 30 kW, all seven pulse/PRF pairs,
  1.9° by 25°, sidelobes −26/−30 dB, horizontal polarization, about 24 rpm,
  IF 60 MHz with 25/8/3 MHz bandwidths, noise figure 7.5 dB. "Magnetron
  (likely)" is reasonable: the filing's NKE-1130 diagrams show a "MAG POWER
  SUPPLY".
- **JRC NKE-1632, NKE-2632, and NKE-2632-H (FCC):**
  - P0N 3035 MHz; Q0N 3065 ±4 or 3060 ±4 MHz.
  - 250 W.
  - First and second pulses with 8 MHz deviation.
  - 5.8 W average or lower.
  - 1.9° or 2.7° by 25°, sidelobes −26/−30 dB.
  - 24 or 48 rpm.
  - IF 63 MHz, 30 MHz bandwidth, noise figure 4.0 dB.
- **Duty-cycle arithmetic:** Correct for every sampled row.
- **SharpEye:**
  - 2.9–3.1 GHz with 8 channels, 200 W, 660:1 compression.
  - IF 60 MHz, 20 MHz bandwidth, noise figure under 4 dB.
  - 15 m range resolution, 3.9 m (12 ft 9 in) antenna.
  - MED CAT 1 and CAT 2, from the Hensoldt page. The Hensoldt page now lists
    24-inch and 27-inch displays, not the 22-inch and 26-inch CMSSE variants.
- **Kongsberg:** 3050 ±20 MHz, 30 kW, NKE-1130-12S/KM at 12 ft, 1.9° by 25°,
  27 rpm, and the seven pulse/PRF pairs identical to JRC's NKE-1130. This
  supports the shared-scanner finding.

### Truth-ship table

- **Sally Ride:** The quote is verbatim, including the WaMoS note.
- **Roger Revelle:** The quote is verbatim. The science X-band radar is in the
  lab.
- **Ronald H. Brown:** IMO 9105786, call sign WTEC, and 83.5 m match IRVSI. The
  WHOI copy has "2 Furuno FAR 21x7" under "RADARS (X AND S BAND)" and 274 ft.
- **Sikuliaq:** The BridgeMaster E X-band quote is correct. The length is
  261 ft.
- **Okeanos Explorer:** The quote is verbatim. WTDH, 68.3 m, and 2062 GRT match
  IRVSI.
- **Henry B. Bigelow:**
  - The spec sheet confirms WTDF, 208.6 ft, and Furuno FAR-3000 Series X and S.
  - IRVSI confirms IMO 9349057, 63.58 m, and "Navigational Equipment: Unknown".
- **Atlantis:** "Furuno 2835X S-Band with ARPA" and "Furuno 2825 X-Band" appear
  on both IRVSI and the WHOI page. IMO 9105798, KAQP, 83.5 m, and 3200 GRT match.
- **Thomas G. Thompson:** 84 m, 3250 GRT, and the bare "Radar" text match.
- **Kilo Moana:** WDA7827, 56.69 m, and 1407 GRT match. The radar text was
  misread (R3DAT-22).
- **Bell M. Shimada:** WTED, 63.58 m, and "Sperry Bridgemaster Radar" match.
- **Marcus G. Langseth:** "235-foot, 3834-gross ton" matches. No navigation
  radar is listed.
- **Neil Armstrong:** The fact sheet lists no radar.
- **Thomas Jefferson:** WTEA, 63.4 m, 1466 GRT, and "X-Band and S-Band Radar
  with an ARPA display" match.
- **Oscar Dyson:** WTEP, 208.6 ft, 2479 metric tons displacement, and
  "Radars (X and S Band) 2 Sperry Marine / Bridge Master" match.
- **Healy:** 128 m, 16000 GRT, IMO 9083380, and "Radar, Gyro, GPS, DopLog"
  match.
- **Reuben Lasker and Fairweather:** 208.70 ft and 231.00 ft. Neither page
  mentions radar.
- **Gordon Gunter:** IMO 8835255, WTEO, 68.3 m, 1904 GRT, and the radar text
  match.
- **UNOLS VesselSpecs 18Aug15:**
  - Atlantis 274 ft, 3,304 ITC.
  - Langseth 237 ft 3 in, 3834.
  - Revelle 273 ft 2 in, 3,180.
  - Sikuliaq 261 ft, TBD.
  - Thompson 273 ft, 3,058.
  - Kilo Moana 186 ft, 3,060.

  The doc's GRT-against-ITC caveat for Kilo Moana (1,407 against 3,060) and
  Atlantis (3,200 against 3,304) is correct.
- **Doc Finding 1:** The eight lengths listed match the CSV, and all are under
  100 m.

## Not checked

- SOLAS Reg. V/19.2.3.2 and V/19.2.7.1 wording. No URL is cited, and I didn't
  fetch the convention.
- Rows outside the sample: Wärtsilä, Sperry, Raytheon Anschütz, JRC JMR-93xx,
  and the X-band rows.
- Koden "X-band only".
