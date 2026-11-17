DRAFT//PRE-DECISIONAL

# Round 5 numbers check: content added November 17, 2026

Reviewer: independent numbers agent (blind; didn't write the content). Repo at
commit `f19c183`. Date: November 17, 2026.

## Summary

I checked about 120 numbers in six areas: Appendix B (Tables B-1 and B-2 and
the model counts), zone population, PEA counts, AIS offshore shares, PSIX gross
tonnage, and Alaska land. I found 11 items: 5 Fix and 6 Note. The AIS offshore
shares, the PSIX counts, the PEA counts, the model counts, all 23 rows of
Table B-2, and the Alaska land arithmetic all check. The Fix items are three
Table B-1 ranges that leave out a model's stated value (solid-state antenna
length, solid-state fast-craft rotation, magnetron average power). They also
include the lower-48 100 km population (175.9 million), which the committed
100 km zone file doesn't reproduce (it gives 175.8 million). The last Fix is
the Alaska 100 km land values, which differ from the committed November 14 logs
with no committed log behind the new values. To recompute, I ran
`python/zone_population.py` and `python/zone_population_pea.py` on a scratch
copy of the committed zone files. No repo file other than this report was
changed.

## Findings

| ID | Severity | Location | Problem | Evidence (file and computed value) | Suggested fix |
| --- | --- | --- | --- | --- | --- |
| R5NUM-1 | Fix | Appendix B, Table B-1, Antenna length, solid-state | The range leaves out the Kelvin Hughes SharpEye antenna, 12.8 ft. Table B-2 lists it. | `data/ship_radar_models.csv`, SharpEye S-band: `antenna_ft` = 12.8. Solid-state values stated: 12, 8, 12.8. | "8 ft (2.4 m) to 12.8 ft (3.9 m); 12 ft on most models", or add "12.8 ft (3.9 m) on one model". |
| R5NUM-2 | Fix | Appendix B, Table B-1, Rotation rate, solid-state | "48 rpm for fast craft" leaves out the Furuno FAR-2238S-NXT fast-craft rate, 42 rpm. Table B-2 lists it. | CSV, FAR-2238S-NXT: `rotation_rpm` = "24 or 42 (high-speed craft)"; JMR-9282-SH: 48. Fast-craft range: 42 to 48 rpm. | "24 rpm; 42 rpm to 48 rpm for fast craft". |
| R5NUM-3 | Fix | Appendix B, Table B-1, Average power, magnetron | The calculation uses 0.065% to 0.072%, but the row above gives 0.065% to 0.075%, and the footnote says average power is peak power times the stated maximum duty cycle. The Raytheon Anschutz Synapsis value (0.075%) is left out. | CSV `max_duty_cycle_pct`: 0.072 (FAR-2137S, FR-2135S), 0.065 (JMR-9230-S, -S3, K-Bridge), 0.075 (Synapsis). 30 kW x 0.065% = 19.5 W; x 0.072% = 21.6 W; x 0.075% = 22.5 W. | "About 20 W (30 kW at 0.065% to 0.075%, computed: 19.5 W to 22.5 W)". "About 20 W" can stay. |
| R5NUM-4 | Fix | Paper population statement: lower 48, 100 km, 175.9 million (53%) | The committed `outputs/zone_population_rev1.csv` row `lower48,100` (175,877,373; 124,784 block groups) doesn't come from the committed 100 km zone file. Rerunning the script on `outputs/2024_2025/shipping_zone_2024_2025_ships_100km.shp` (last changed `7efad48`, November 13) gives 175,795,891 (53.39%; 124,710 block groups). That value matches the earlier `committed_r1` row in `22f7d0a` and the lower-48 sum in `outputs/zone_population_pea_rev1.csv`. The 25 km and 50 km rows reproduce exactly. The `lower48` row likely came from an uncommitted November 17 rerun (see R5NUM-5). | Scratch rerun of `python/zone_population.py`: 100,256,837 / 138,773,271 / 175,795,891. Committed CSV: 100,256,837 / 138,773,271 / 175,877,373. The PEA CSV sum for lower-48 PEAs at 100 km is 175,795,891. | Commit the zone files and log of the run behind 175,877,373 (then rerun the PEA script), or state 175.8 million. The 53% share holds either way (53.39% against 53.42%). |
| R5NUM-5 | Fix | Alaska land, 100 km: base after D2 319,271 km² and all 400 hexagons 354,593 km² | Neither 100 km value is in a committed file. The committed November 14 logs give 318,352 (`alaska_beyond.log`) and 353,639 (`alaska.log`). The 25 km and 50 km values match those logs exactly. 353,639 is also the paper's Alaska value listed in `CLAUDE.md`. Both 100 km values moved up by about 950 km² with no stated reason. | `outputs/rerun_logs_20261114/alaska.log` lines 114 to 116: 112,426 / 210,895 / 353,639. `alaska_beyond.log`: 90,926 / 181,074 / 318,352. `docs/plans/next_steps_rev1.md` line 58 still says 318,352. `docs/plans/decision_memo_rev1.md` line 18 uses 319,271 and 354,593. | Commit the November 17 logs and state why the 100 km land changed. Update `CLAUDE.md` (353,639) and `next_steps_rev1.md` (318,352) to match. The arithmetic holds with either pair (see "Checks that passed"). |
| R5NUM-6 | Note | Appendix B, Table B-1, Frequency, solid-state ("3035 MHz to 3074 MHz") | The range mixes nominal values. 3074 is the rounded 3073.75 MHz nominal channel and leaves out the ± 5 MHz tolerance. The CSV `freq_high_mhz` for that model is 3078.75. Both endpoints are attained as nominal frequencies, so the range is correct only if it's read as nominal. The B.2 statement (3020 MHz to 3080 MHz) still holds with tolerances. | CSV FAR-2238S-NXT: `freq_low_mhz` 3038.75, `freq_high_mhz` 3078.75. JRC JMR-9272/9282: 3035 to 3069. | Say "nominal 3035 MHz to 3074 MHz (3079 MHz with tolerance)". |
| R5NUM-7 | Note | Appendix B, Table B-1 Frequency, solid-state, and B.1 ("two to eight selectable channels") | The CSV calls the JRC solid-state channels fixed by option, not selectable. Only the Furuno NXT pair is selectable (two channels). SharpEye has eight. | CSV `frequency_channels`, JMR-9272-S, -9282-S, -9282-SH: "fixed: P0N 3035 MHz with Q0N 3065 or 3060 MHz (+/-4) by option". | "two frequencies (fixed by option on JRC models, two selectable channels on Furuno), or eight selectable channels on one model". |
| R5NUM-8 | Note | Appendix B, Table B-1, Average power, solid-state ("5.8 W or less") | The value is quoted from the data sheet, but peak power times maximum duty cycle (the footnote's method for magnetron radars) gives 250 W x 2.1% = 5.25 W. The value is correct as quoted. The two columns use different methods. | CSV JMR-9272/9282: `peak_power_w` 250, `max_duty_cycle_pct` 2.1, `average_power_w` "5.8 or lower". | Add "(data sheet)" to the solid-state cell, or note the method in the footnote. |
| R5NUM-9 | Note | `data/ship_radar_models.csv`, FAR-2338S and FAR-3230S | `freq_spec` says "not stated", but `freq_low_mhz` and `freq_high_mhz` hold 3020 and 3080 (inferred from FAR-2238S). Appendix B correctly counts both as not stated, so the count of ten holds. A script that computes ranges from the numeric columns would count 12 models with a stated frequency. Also, B.1 says the 5 inferred magnetron types follow "from the peak power and pulses", but for the Sperry VisionMaster the inference is from power only (Table B-2 says so). | CSV rows FAR-2338S, FAR-3230S. CSV `transmitter` for Sperry: "magnetron (likely)", no pulse data. | Blank the two numeric columns, or add an `inferred` note. In B.1, say "from the peak power (and pulses, where stated)". |
| R5NUM-10 | Note | `outputs/zone_population_pea_rev1.csv`, Alaska PEAs 212, 264, 298 | The PEA file (`df7194f`) was written before D2 (`f19c183`) and uses the all-400 Alaska zones. Its 25 km and 50 km totals equal the `alaska_all400` rows. Rerun on the committed D2 zones: PEA 212 25 km 277,849 (was 288,744); PEA 264 78,677 / 154,515 / 200,597 (was 109,694 / 195,017 / 203,101); PEA 298 25 km 10,046 (was 11,231). The paper counts don't change: 85 and 44 at 25 km, 131 and 92 at 100 km. | Scratch rerun of `python/zone_population_pea.py` on the committed zone files. | Rerun the PEA script after R5NUM-4 is settled and commit the result. |
| R5NUM-11 | Note | Puerto Rico 25 km zone, 87% | The share is correct for Puerto Rico only. The Census file has no USVI block groups, so the region total (3,285,874) is Puerto Rico's population. If the paper labels it "Puerto Rico and USVI", the label overstates what was counted. The script docstring says this. | `outputs/zone_population_rev1.csv` `prusvi,25`: 2,854,762 / 3,285,874 = 86.88%. | Keep "Puerto Rico" in the paper and add that USVI isn't counted. |

## Checks that passed

**Appendix B (against `data/ship_radar_models.csv`, 24 S-band rows):**

- 23 models plus the ITU-R M.1460-1 row. 7 manufacturers (Furuno, JRC, Kelvin
  Hughes, Kongsberg, Raytheon Anschutz, Sperry Marine, Wartsila).
- Transmitter types: 12 magnetron (7 stated, 5 "likely"), 9 solid-state, 2 not
  stated (JMR-9330-S, NAVI-RADAR 4000).
- Ten models with `freq_spec` "not stated". One model with an antenna gain
  (Synapsis, 28 dBi).
- Table B-1 ranges that hold, with both endpoints attained:
  - Magnetron: frequency ± 20 / ± 30 MHz, peak power 30 kW (60 kW one model),
    pulse 0.06 to 1.2 µs, PRF 500 to 3,000 Hz, duty 0.065% to 0.075%,
    antenna 12 ft with 9 ft and 10 ft options, horizontal beamwidth 1.8° to
    2.3°, vertical beamwidth 25° to 26°, sidelobes -24/-26 and -30 dB,
    rotation 21 to 27 and 42 to 45 rpm, IF 3 to 40 MHz, noise figure 4 to
    7.5 dB.
  - Solid-state: peak power 200 to 250 W, short pulse 0.07 to 1.14 µs, long
    pulse 4.6 to 18.3 µs over 8 MHz, PRF 640 to 2,280 Hz, duty 2.1%,
    horizontal beamwidth 1.8° to 2.7°, vertical beamwidth 25°, IF 20 to
    30 MHz, noise figure 4 dB or less.
  - ITU column: all rows match the M.1460-1 row.
- B.1 ratios: 30 kW / 250 W = 120 (more than 100). 250 W / 30 kW = 0.83% (less
  than 1%). B.2: 21 to 27 rpm is 2.2 s to 2.9 s per turn.
- Table B-2: all 23 rows match the CSV in transmitter, frequency, peak power,
  antenna length, horizontal beamwidth, rotation rate, and confidence.

**Population (`outputs/zone_population_rev1.csv`; shares recomputed in
Python, maximum difference from `share_pct` 0.00):**

- Lower 48: 100,256,837 (30.45%), 138,773,271 (42.15%), and 175,877,373
  (53.42%), which round to the paper's figures. See R5NUM-4 for the 100 km
  row.
- Region total 329,260,619 = 331,449,281 (2020 U.S.) - 733,391 (Alaska) -
  1,455,271 (Hawaii), exactly.
- Hawaii 50 km 99.38%. Puerto Rico 25 km 86.88%. `alaska_d2` 59.83% /
  72.16% / 79.29%.
- Alaska 25 km 481,884 (all 400) against 438,787 (D2). The scratch rerun on
  the committed D2 zones reproduces the `alaska_d2` rows, Hawaii, and Puerto
  Rico exactly.
- Tug-barge: 100,256,837 - 98,044,031 = 2,212,806, which rounds to 2.2
  million.

**PEA (`outputs/zone_population_pea_rev1.csv`, 412 PEAs, none with zero
population):**

- 25 km: 85 reached, 44 more than half. 50 km: 102 and 64. 100 km: 131 and
  92.
- "More than half" gives the same counts with `> 0.5` and `>= 0.5`. The
  scratch rerun gives the same counts.

**AIS offshore (1 nmi = 1.852 km):**

- 2024-2025: 658,867 cells, 52.00% beyond 50 nmi, 17.03% beyond 200 nmi.
- 2023-2024: 661,137 cells, 52.43% and 17.87%.
- Beyond 200 nmi, 2024-2025: Pacific 34.98%, Gulf 9.54%, Atlantic 5.84%,
  Great Lakes 0.00%.
- All match the document after rounding, including the cell counts.

**PSIX (789 rows, all joined on mmsi, 493 with a numeric GT):**

- Match "call sign and name", "name and call sign", or "name" with GT: towing
  (31, 32, 52) 164 ships, 0 at 3,000 GT or more, median 497. Others 246, 224
  at 3,000 GT or more (91.1%).
- First-pass table (call sign and name only) also reproduces: 159 / 0 / 497;
  232 / 212 / 29,801; cargo 139, 97%, 36,751; tanker 62, 87%, 29,801;
  passenger 16, 94%, 5,871.
- Second-pass bookkeeping: 28 "name" + 5 "name and call sign" = 33. 109 + 17 =
  126 looked up.
- Minor: the Results table still shows the first-pass counts, while Section
  1.5 uses the second-pass counts. The text says so, but a reader could quote
  the table.

**Alaska land (arithmetic only for the values not in a committed log):**

- 90,926 / 181,074 / 319,271 of 1,520,713 km² = 5.98% / 11.91% / 20.99%,
  which round to 6%, 12%, and 21%. 1,520,713 matches the grid land in both
  logs.
- All 400 against base: +23.65% / +16.47% / +11.06%, which round to 24%, 16%,
  and 11%. With the November 14 100 km values (353,639 / 318,352) the change
  is still +11.08%.
- No satellite lanes 90,923 / 181,070 / 317,670 km² is smaller than the base at
  every distance, by 3 / 4 / 1,601 km² (consistent with "within 4 km² at 25 and
  50 km").
- 290 + 110 = 400 hexagons.
