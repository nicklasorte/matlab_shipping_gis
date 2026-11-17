**DRAFT//PRE-DECISIONAL**

# Round 5 opposing reader (red team) review

Paper: *2.7 GHz study: Large-ship routes and frequency-dependent zones*, doc revision 616
(`docs/review/round5/paper_rev616.md`).
Reviewer: AI opposing reader, blind (read only the paper snapshot and the public repo outside
`docs/review/` and `docs/plans/`).
Date: November 17, 2026.

## Summary

This review reads the paper as two hostile filers in an FCC proceeding would: a commercial wireless
carrier that wants smaller zones, and a federal or maritime safety interest that wants larger ones.

The numbers hold. Every Table 8 value, the population totals, and the PEA counts trace exactly to
`outputs/decision_table_rev1.csv`, `outputs/zone_population_rev1.csv`,
`outputs/zone_population_pea_rev1.csv`, and the run logs in `outputs/rerun_logs_20261117/`. An
independent rebuild from the daily cell caches reproduces the 649,737 non-tug AIS cells exactly.

The attacks land on the rules, not the arithmetic. The paper says plainly that several rules have no
carriage rule behind them, and a carrier would quote those sentences back:

- **Carrier side.** The strongest attacks are the tug-barge rule, the Great Lakes layer, and the
  presence-only threshold. The paper's own data show that no tug in the kept set is 3,000 GT or more,
  yet the rule adds 10% of the 25 km land and 2.2 million people. A new test in this review finds
  that 73% of Great Lakes AIS route cells depend on U.S.- and Canadian-flag ships (mostly lakers),
  which no SOLAS rule covers. No run in Table 8 weights cells by traffic.
- **Federal side.** The strongest attack is the Alaska decision to drop the 110 near-shore satellite
  hexagons. It rests on an assumption that shore-receiver tracks are complete within 74 km, and the
  paper's own Section 5.3 evidence contradicts that assumption. The 1-in-7 sampling also makes "four
  ships a year" a much higher bar on real traffic than the text implies.
- **Either side.** Table 8 changes one rule at a time and reports only land and people. It doesn't
  show the combined low and high envelopes, port connectivity, or license-area effects. Both sides
  can therefore pick the row that suits them.

Counts: 21 findings. 4 Strong, 11 Moderate, 6 Weak.

## Tests run for this review

All tests used only committed repo data. The scripts are scratch work and aren't committed.

1. **Carriage rate below 100%.** The test loaded the 104 lower-48 main-filter daily caches
   (`data/ais_cells_2024*/2025*_..._vt0-99-..._22_50_-130_-66_d0.01_rev1.mat`). It dropped each ship
   (MMSI) at random with probability 1 − p and reapplied the four-ships-in-either-year rule. The
   base gives 649,737 cells, which matches Section A.5. Cells kept at p = 0.9, 0.8, 0.7, and 0.5 were
   89.6%, 80.1%, 68.6%, and 47.3%.
2. **Great Lakes flag split.** The test used the same caches, limited to the decision-run box
   [41 49.5 −92.5 −74.5]. A ship counts as U.S. or Canadian flag when its MMSI MID is 366 to 369 or
   316.
   - Ships kept in the box: 335 in 2024 and 322 in 2025. U.S. and Canadian flag: 114 and 107.
   - Cells with 4 or more ships in either year: 47,515 for all ships, and 13,023 (27%) for
     foreign-flag ships alone.
3. **PEA recount.** The recount of `outputs/zone_population_pea_rev1.csv` gives 85, 102, and 131
   PEAs with any population in the 25, 50, and 100 km zones. More than half the population is in
   the zone in 44, 64, and 92 PEAs. `data/ref/pea_counties_47cfr27.csv` lists 416 PEAs. The output
   has 412, without PEA 413 (Guam and the Northern Mariana Islands), 414 (U.S. Virgin Islands), 415
   (American Samoa), or 416 (Gulf of Mexico).
4. **Alaska hexagons.** `outputs/2018_2019/alaska/satellite_lanes.json` and
   `satellite_lanes_beyond.json` report 283 of 400 and 265 of 290 kept hexagons "without our
   routes". Of the 110 near-shore hexagons that were dropped, 18 therefore hold no ship-track route
   cell.
5. **Port connectivity by run.** The run logs report deep-draft ports reached as follows: base 70
   of 73, both years 66, under way 69, without the tug-barge rule 70, routes outside the Great Lakes
   61.

## Findings

| ID | Side | Strength | Location | Attack | Best answer available now | What would close it |
| --- | --- | --- | --- | --- | --- | --- |
| R5OPP-1 | Too large | Strong | Section 1.5 item 3; Table 8 row 2; Section A.5 | The paper concedes that the tug-barge rule "is a protective choice, not a carriage rule." None of the 164 U.S.-flag towing vessels matched in PSIX is 3,000 GT or more (median 497 GT). The rule still adds 10%, 4%, and 2% of zone land and 2.2 million people at 25 km. A carrier would call this zone area with no regulatory basis. The AIS length that passes the 100 m test is the tow's length, not the vessel's. | Integrated tug-barge units can be measured as one vessel and may then reach 3,000 GT. 33 CFR 164.72 requires radar on towing vessels, without naming a band. Tug-barge cells add only about 1% of route cells (Section A.5). | Treat tug-barges as a separate layer, as for the Great Lakes, with their own land and people. Or show S-band carriage evidence for the towing fleet, for example a photo-coded sample of the 164 matched tugs, or a count of integrated units measured as one vessel. Reword "without the tug-barge rule" in Table 8: the run excludes tugs entirely, but the wording reads as if it lifts a restriction. |
| R5OPP-2 | Either | Strong | Sections 1.1 and 3.1; Table 8 rows 5 and 6 | **Carrier:** The Great Lakes layer is a quarter of zone land (74,385 km² and 15.4 million people at 25 km), and the paper says the S-band assumption there has "no carriage rule behind it." 33 CFR 164.35 and 164.37 require one radar (1,600 GT and up) or two radars (10,000 GT and up) without naming a band, so X-band radars meet them. In this review's test, foreign-flag ships alone support only 27% of Great Lakes AIS route cells, so 73% depend on U.S.- and Canadian-flag ships. **Federal:** Ocean-going "salties" are SOLAS ships, and they are about two-thirds of the ships kept in the box. Splitting the layer by a lat-lon box puts SOLAS Seaway traffic in the "no carriage rule" layer. | 33 CFR 164.35 applies on the Great Lakes. Many lakers are 10,000 GT or more and carry two radars, but the bands aren't known. | Split the layer by flag or voyage (salties and lakers), not by box, and rerun. Get carriage evidence for lakers, for example a photo-coded sample of the U.S. and Canadian lake fleet. Report how many Great Lakes route cells and how much land the salties support alone. |
| R5OPP-3 | Too large | Strong | Section 1.5 item 1; Sections A.1 and A.6 | A cell with 4 sampled ships a year gets the same protection as the Houston Ship Channel. Of the 658,867 AIS cells, 344,850 (52%) saw fewer than 10 ships, and the busiest 6% of cells carry half the traffic. The paper calls the threshold "a presence test, not an interference criterion" but still builds the population and PEA headlines from it. No Table 8 row tests a traffic-weighted rule. | The EMC analysis will set the criterion (Section 3), and the zones are examples. Zones are stable to sampling (±2%). | Add a Table 8 row that keeps only the cells carrying 90%, 95%, or 99% of ship-cell visits, and report land, people, and ports reached. State in Section 3.1 that the population figures are for presence zones, not for interference zones. |
| R5OPP-4 | Either | Moderate | Table 8 | Each row changes one rule. The protective choices stack: either-year union, a 2-ship port-approach rule, tug-barges, ships at berth, charted lanes, and racons. The 25 km reductions alone are 10%, 6%, 2%, and 3%. Neither the combined minimum nor the combined maximum (all 400 Alaska hexagons, 80 m, 3 ships) is shown, so each filer can claim the base is unrepresentative. | Each row is a separate full run that traces to a log. | Add two envelope rows: all reducing choices together and all protective choices together, with the base between them. |
| R5OPP-5 | Too small | Strong | Section 5.1 (satellite lanes); Sections 5.2 and 5.3 | The base drops the 110 near-shore hexagons because "ship tracks are taken as complete" within 74 km. The paper's own evidence contradicts that assumption. Receiver locations aren't published, and gaps occur near shore (Section 1.10). Shelikof Strait, Bristol Bay, and the north side of the Aleutians have no route cells (Section 5.3). Valdez, Nikiski, and Dutch Harbor sit 3.0, 6.8, and 1.0 km from routes, against 0.6 km with all 400 hexagons. Of the 110 dropped hexagons, 18 hold no ship-track route cell (test 4). The cutoff was also calibrated in the same near-shore band that the decision then discards. The 74 km reach is an assumption between the Coast Guard's 24 and 50 nautical miles, and neither end is tested. The cost is 24%, 16%, and 11% of land and 43,097 people at 25 km. | Hexagons are about 27 km across, so they overstate lane width. 92 of the 110 overlap existing routes. The paper calls the 400-hexagon run "the more protective reading." | Replace the distance rule with a gap-fill rule: keep near-shore hexagons that hold no route cell (18), or trim them to the water not already within a set distance of a route cell. Test the reach at 45 km (24 nautical miles) and 93 km (50 nautical miles) and report land and people. |
| R5OPP-6 | Too small | Moderate | Sections 1.3 and 1.5; Section 1.10 (Sampled days) | The threshold is 4 ships seen on 52 Wednesdays, not 4 ships a year. A ship that passes a cell once a year has about a 1-in-7 chance of being sampled, so a lane of one-time visitors needs about 28 ships a year to count. A weekly service on another weekday is never seen. The paper finds that half-samples lose about 5%, 3%, and 1% of land, and that all days "would likely be somewhat larger." It doesn't estimate how much. | The zones are stable across random halves (2% or less). The port-approach rule lowers the bar near ports. Held-out days put 98% of visits within 25 km. | Build zones from 13, 26, 52, and 104 days, fit the land curve, and extrapolate to 730 days. Or run every day of one quarter and compare. Test held-out days that aren't Wednesdays. State the effective threshold in Section 1.5. |
| R5OPP-7 | Too large | Moderate | Sections 1.1 and 1.10 (Carriage, not use) | The routes assume that every ship of 3,000 GT or more carries an S-band radar. SOLAS V/19.2.7.1 allows a second 9 GHz radar instead, and the paper says the share is unknown. | This review's test answers most of the attack, but the paper doesn't make the argument. Route cells fall about in step with the carriage rate (89.6% of cells at 90% carriage, 47.3% at 50%). Removing about half the cells through random half-samples cut land by only about 5%, 3%, and 1% (Section 1.10). Geometry is therefore insensitive to carriage; aggregate EMC isn't. | Add a carriage-rate run (for example 70% and 50%) to Table 8 with land and people. State that carriage matters for the EMC aggregate, not much for zone geometry. Report the photo-coded carriage rate when it is ready. |
| R5OPP-8 | Too small | Moderate | Section 1.4; Section A.8 | The 100 m test keeps only 86% of passenger ships of 3,000 GT or more, and 16% of kept ships (towing, military, dredging, other) are untested. At 80 m, land grows by 13.0%, 11.8%, and 11.7%, driven by 80 to 100 m ships on the Columbia and Snake Rivers and the Mississippi above Baton Rouge. A maritime filer would ask whether any of them is 3,000 GT or more. | 80 m adds only 2.4% more ships, and Figure 2 shows 98.1% recall for ships of 3,000 GT or more. River cruise vessels are domestic and mostly small. | Match the 80 to 100 m ships that drive the inland growth to PSIX or Wikidata gross tonnage. Report how many are 3,000 GT or more and where they operate. |
| R5OPP-9 | Too large | Weak | Section 1.10 (Carriage, not use); Table 8 row 4 | The paper keeps ships at anchor and at the berth "because a ship's radar may run there," with no evidence. A carrier would say radars are commonly off alongside. | The effect is small: 2%, 1%, and 1% of land and 0.8 million people at 25 km. Ships at anchor keep a lookout, and COLREG Rule 7 calls for proper use of radar if fitted. Under-way ships pass through the same port cells. | Cite a source on radar use at anchor and at the berth, or say that the choice moves land by 2% or less whichever way it falls. The under-way run also loses Coos Bay (69 of 73 ports). |
| R5OPP-10 | Either | Moderate | Section 3.1; Table 8 row 3 | Table 8 reports only land and people. The both-years run cuts land by only 6%, but it disconnects 4 more deep-draft ports: Portland, Maine; Grays Harbor; Coos Bay; and Morehead City (66 of 73). A carrier will cite the 6% as "persistent use"; a federal filer will cite the lost ports. | The logs record ports reached for each run. | Add a "deep-draft ports reached" column to Table 8: base 70, no tug 70, both years 66, under way 69, outside the Great Lakes 61. |
| R5OPP-11 | Too large | Moderate | Section 3.1 (population); Figure 4 alt text; Section 3 | The 100.3, 138.8, and 175.9 million figures will be read as people encumbered. The zones are great-circle geometry with no terrain or propagation, and the 100 km zone applies only to 40 of the 200 MHz. Weighted by MHz, the lower-48 example covers about 38.6% of MHz-pops (100.3M × 100 MHz + 138.8M × 60 MHz + 175.9M × 40 MHz, divided by 329.3M × 200 MHz), not the 53% a reader takes from the 100 km figure. | Section 3 says every distance is an example and gives no interference result. | Report MHz-pops for each band and in total, next to the people counts. Repeat the "geometry only" caveat next to the population sentence and in Table 8. |
| R5OPP-12 | Either | Moderate | Section 3.1 (PEA sentence) | "85 of the 412 PEAs" uses the wrong denominator. 47 CFR 27 lists 416 PEAs, and the output has none of PEAs 413 to 416. PEA 414 (U.S. Virgin Islands) lies inside the Puerto Rico zones. PEA 416 (Gulf of Mexico) is all water and almost certainly falls largely inside the zones. "Reach" means a block-group population center inside a zone, which undercounts PEAs that a zone overlaps by area. A carrier would argue that encumbrance follows license area. | The counts reproduce exactly from the committed file for the 412 PEAs with Census block groups. | State the denominator as 416 and say which PEAs aren't counted and why. Add an area-overlap count (PEA polygons intersected with zone polygons, land and water) and the Gulf of Mexico PEA's water share. |
| R5OPP-13 | Too small | Moderate | Section 1.10 (Receiver coverage); Sections 4.2 and 4.1 | The paper doesn't know where the receivers are, can't document satellite completeness offshore, and attributes the Hilo gap to a possible receiver gap. In Hawaii, only 81% to 82% of held-out visits fall within 25 km. A federal filer would argue that the routes undercount wherever coverage is thin. | 98% of held-out lower-48 visits fall within 25 km. Hawaii's 25 km zone already holds 94% of its people. | Compare near-shore lower-48 route cells with NOAA AIS Vessel Transit Counts, as done for Hawaii, to find coverage holes. Ask the Coast Guard Navigation Center for receiver coverage, or a public coverage map, and cite it. |
| R5OPP-14 | Too small | Moderate | Section 1.10 (Ships without AIS) | The zones are presented as maritime S-band zones but leave out Navy and other government ships and Navy radiolocation radars in the band. Dahlgren and Indian Head lie outside the 25 km zone, and PMRF sits at its edge. | The paper discloses the gap, and SOLAS excludes warships. | In Section 3, state that the zones cover commercial ship radars only, and name the separate process that covers federal radiolocation and Navy operating areas. Check the 33 CFR Part 334 areas against the zones. |
| R5OPP-15 | Too small | Moderate | Section 5.1; Section 1.4 (ship type); Section 5.3 | Alaska routes use 2018–2019 data, seven years older than the rest of the paper. The ship-type test drops all fishing vessels, including the Bering Sea factory trawler fleet, many of which may carry S-band radars, and Bristol Bay and the Bering Sea south of 58.7° N have no route cells. | MarineCadastre filtered Alaska out of later files. Kapsar has no length cut and partly fills the gaps. | Compare Kapsar 2020 with 2018–2019 for trend. Count fishing-type ships with IMO numbers and lengths of 60 m or more in the Alaska files, and report where they operate. |
| R5OPP-16 | Too large | Weak | Section 1.5 items 2 and 4 | Charted lanes and racons add 0.6% to 1.8% of land with no observed traffic. The 2-ship port-approach rule adds 3% at 25 km. | Lanes are charted routing measures, and the effects are small. | No change needed beyond the envelope rows in R5OPP-4. |
| R5OPP-17 | Too large | Weak | Section 1.4 (tests 1 and 3); Table 2 | "Other or unknown" types (47 ships) and dredges are kept without a tonnage check. The IMO test passes any filled field, including a U.S. official number. | The counts are small (55 of 1,980 ships on July 10, 2024). | Match those ships to PSIX gross tonnage, as done for towing vessels. |
| R5OPP-18 | Either | Weak | Section 1.5 (last paragraph) and item 3; Table 8 | The paper gives the tug-barge effect on the 25 km zone as both "lost 12% of its land" and "10% smaller." The 12% probably uses the AIS and port-approach cells only, but this review couldn't find the source file in `outputs/`. An opposing filer would use the inconsistency to question every number. | The basis likely differs (sensitivity cells against full zones). | Use one figure, or state the basis of each. Cite the output file for the 12%. |
| R5OPP-19 | Too small | Weak | Section 6; `outputs/zone_population_rev1.csv` | The Puerto Rico and U.S. Virgin Islands rows count Puerto Rico's people only. Mayaguez is outside the 25 km zone, and the Vieques Sound route is missing. | The paper says "Puerto Rico's people" accurately. | Add U.S. Virgin Islands population from the 2020 Island Areas census. Check AIS coverage at Mayaguez and Vieques Sound. |
| R5OPP-20 | Too small | Weak | Section 4.2 | Port Allen, 24.6 km from a route, falls outside the 25 km zone because the boundary is simplified to about 0.5 km. The simplification can therefore cut into the zone. | The effect is a few hundred meters along the boundary. | Simplify the boundary outward only, for example buffer by the tolerance before simplifying, so that no point within D km falls outside. |
| R5OPP-21 | Too small | Moderate | Section 3 (second paragraph) | Ship radar receivers pass about 2700 to 3200 MHz before filtering, but the zones cover only 2900 to 3100 MHz. A federal filer would argue that the zones need to cover 2700 to 2900 MHz too. | The paper flags the question for the EMC analysis. | Section 2 should answer it with receiver selectivity data (for example ITU-R M.1460-1 and manufacturer filter curves). |

## Claims that held up

- **Table 8 traceability.** Every land and population value matches `outputs/decision_table_rev1.csv`
  and the run logs, and the percentages round correctly.
- **Independent cell count.** A rebuild from the daily caches gives exactly 649,737 non-tug AIS
  cells, as Section A.5 states.
- **Population totals.** The lower-48 total (329,260,619), Alaska (733,391), Hawaii (1,455,271), and
  Puerto Rico (3,285,874) match the 2020 Census. The zone counts reproduce from the committed CSV.
- **PEA counts.** The recount gives 85 and 44 at 25 km, and 131 and 92 at 100 km, for the 412 PEAs
  in the file. Only the denominator is wrong (R5OPP-12).
- **Under-way choice.** The effect is small, as stated: 2% or less of land, and 0.8 million people
  at 25 km.
- **Alaska satellite land.** Satellite hexagons beyond 74 km add little land (90,923 against
  90,926 km² at 25 km), as Section 5.1 states.
- **Length proxy.** Precision (99.6%) and recall (98.1%) are reported with honest limits on the
  match rate and the types that weren't tested.
- **Small S-band ships.** The 93% figure for research and survey ships is disclosed with its
  weighting and shore bias. It supports the claim that the 100 m test loses little zone coverage.
- **Regulatory basis.** 33 CFR 164.35 and 164.37 require radar without naming a band, which matches
  the paper's statement in Section 1.1.

## Sources

- SOLAS Chapter V, Regulation 19, paragraph 2.7.1 (3 GHz radar or a second 9 GHz radar for ships of
  3,000 GT and up), as summarized by
  [Radio Holland, navigational carriage requirements](https://www.radioholland.com/about-radio-holland/regulations/navigational-carriage-requirements/).
- [33 CFR 164.35](https://www.law.cornell.edu/cfr/text/33/164.35) and
  [33 CFR 164.37](https://www.law.cornell.edu/cfr/text/33/164.37): radar for vessels of 1,600 GT and
  up, and a second independent radar for vessels of 10,000 GT and up; no band named.
- [33 CFR Part 164](https://www.law.cornell.edu/cfr/text/33/part-164), including 164.72 (towing
  vessel equipment).
- 47 CFR Part 27, Appendix A to Subpart A, list of PEAs with corresponding counties, as committed in
  `data/ref/pea_counties_47cfr27.csv` (416 PEAs).
- COLREG Rule 7(b), use of radar equipment if fitted and operational.

**DRAFT//PRE-DECISIONAL**
