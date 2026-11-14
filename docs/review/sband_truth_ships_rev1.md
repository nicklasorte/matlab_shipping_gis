# Research-ship truth set (first pass)

DRAFT//PRE-DECISIONAL

Date: November 13, 2026. Data: `data/sband_truth_ships.csv`. Plan step A1 of
`docs/plans/ship_data_sources_plan_rev1.md`. Public pages only; each row cites
its source and quotes the text it relies on.

## What's in the table

The table has 25 rows for 18 research and survey ships, one row per radar. Ships
come from the UNOLS and NOAA fleets, plus one Coast Guard icebreaker (Healy).
Corrected November 13, 2026, after the round-three data review
(`docs/review/round3/agent_data_r3.md`).

| Result | Ships |
| --- | --- |
| S-band radar confirmed by a source | Sally Ride, Roger Revelle, Ronald H. Brown, Okeanos Explorer, Henry B. Bigelow, Atlantis, Thomas Jefferson, Oscar Dyson, Gordon Gunter (9) |
| Only an X-band radar listed | Sikuliaq (1) |
| Band not stated, or no radar listed | Thomas G. Thompson, Kilo Moana, Bell M. Shimada, Marcus G. Langseth, Neil Armstrong, Healy, Reuben Lasker, Fairweather (8) |

No Army Corps hopper dredge is in the table. The pages found give no radar
detail (a solicitation draft, a news release, and a fleet page that returned a
bot check).

## Findings

1. **Research and survey ships carry S-band radars below the length proxy.**
   All nine S-band ships have a published length: Atlantis and Ronald H. Brown
   at 83.5 m, Roger Revelle at 83.3 m, Sally Ride at 72.5 m, Okeanos Explorer
   and Gordon Gunter at 68.3 m, Henry B. Bigelow and Oscar Dyson at 63.6 m, and
   Thomas Jefferson at 63.4 m. All nine are under the 100 m cutoff in Section
   1.4, so the proxy misses them.
2. **Some carry S-band well below 3,000 GT, by the figures available.** Okeanos
   Explorer (2,062), Gordon Gunter (1,904), and Thomas Jefferson (1,466; a
   secondary source gives 1,767 GT) have published figures under 3,000, but
   these are IRVSI "GRT" values, not the ITC gross tonnage that SOLAS uses, so
   the comparison is indicative only. Henry B. Bigelow and Oscar Dyson have no
   gross tonnage on record here (the 2,479 figure is displacement). Four are at
   or above 3,000 GT: Sally Ride (3,043), Ronald H. Brown (3,180), Roger Revelle
   (3,180 ITC), and Atlantis (3,304 ITC). These
   are government or government-owned ships, which SOLAS Regulation I/3 leaves
   out when on noncommercial service, so their radars reflect the owner's
   specification, not a carriage rule.
3. **A radar model may not say which band it is.** Okeanos Explorer's page lists
   Furuno FAR 2837S and FAR 2827X with no bands; the band comes from the model
   suffix (S or X), matched to `ship_radar_models.csv`. Treat these rows as
   "inferred".

## Cautions

- **This is not a sample.** These are government and research ships, chosen
  because their spec sheets are public. They show that non-SOLAS ships carry
  S-band. They don't give a rate.
- **Two sources disagree on Ronald H. Brown.** IRVSI (last updated July 11,
  2018) lists Sperry Rascar S-band (30 kW) and X-band (25 kW) radars. A
  WHOI-hosted NOAA spec sheet (2017) lists two Furuno FAR-21x7 radars, X and S
  band. Which is current is unresolved, so the rows are low confidence. Both
  agree on S-band.
- **Atlantis's S-band model is printed "2835X".** The page labels it S-band.
  The model string may be a typo; the band label is the stated fact.
- **Two tonnage measures, and some "GRT" is displacement.** `gross_tonnage` is
  the IRVSI figure (GRT) unless a note gives another source; for Ronald H.
  Brown it is 3,180 GT from a secondary source, because IRVSI's 3,250 is the
  displacement, and Henry B. Bigelow's IRVSI 2,479 (also displacement) is
  dropped.
  `gt_itc_unols` is the UNOLS ITC gross tonnage, the measure SOLAS uses. They
  can differ a lot: Kilo Moana is 1,407 GRT but 3,060 ITC, and Atlantis is
  3,200 GRT but 3,304 ITC. Use the ITC column for the 3,000 GT test where it
  exists. Roger Revelle (3,180 ITC) and Thomas G. Thompson (3,058 ITC) are
  above 3,000 by ITC.
- **A missing radar is not an absent radar.** Sikuliaq's page lists only an
  X-band radar. Eight pages list no radar at all or no band.
- **Blank cells mean not found.** IMO numbers for Sally Ride, Okeanos Explorer,
  and Thomas Jefferson come from secondary vessel-tracking sites and are marked
  so in the notes. MMSI isn't on any page found.
- **Sources may move.** The IRVSI pages (researchvessels.org) returned a 404 to a
  direct fetch on November 13, 2026; the values were read from a fetched copy.
  Some pages are old (Thomas G. Thompson 2005, Kilo Moana 2009).

## Matching to AIS

The AIS data held in the repo is cell counts, not per-ship records, so the match
to AIS ships runs on the Mac. Use IMO number first (Atlantis, Ronald H. Brown,
Henry B. Bigelow, Gordon Gunter, and Healy from primary pages; Sally Ride,
Okeanos Explorer, and Thomas Jefferson from secondary sites), then call sign,
then name. Report which of these ships fall
inside the kept AIS set and whether the length proxy keeps them.

## Next

- Add the other NOAA and UNOLS ships (Rainier, Pisces, Nancy Foster, Hugh R.
  Sharp) from operator handbooks; some are on sites this
  session can't reach.
- Add the Corps dredges from the Corps fleet listing, which a person can
  download.

## Sources

- [Sally Ride navigation handbook](https://scripps.ucsd.edu/ships/sally-ride/handbook/section-6-navigation-and-communications-capability)
- [Roger Revelle navigation handbook](https://scripps.ucsd.edu/ships/revelle/handbook/section-6-navigation-and-communications-capability)
- IRVSI ship pages: [Ronald H. Brown](https://www.researchvessels.org/ship_info_display.asp?shipID=221),
  [Bell M. Shimada](https://www.researchvessels.org/ship_info_display.asp?shipID=992),
  [Okeanos Explorer](https://www.researchvessels.org/ship_info_display.asp?shipID=991),
  [Atlantis](https://www.researchvessels.org/ship_info_display.asp?shipID=138),
  [Thomas G. Thompson](https://www.researchvessels.org/ship_info_display.asp?shipID=80),
  [Kilo Moana](https://www.researchvessels.org/ship_info_display.asp?shipID=466),
  [Henry B. Bigelow](https://www.researchvessels.org/ship_info_display.asp?shipID=988)
- [NOAA Oscar Dyson spec sheet](https://www.omao.noaa.gov/sites/default/files/documents/NOAA%20Ship%20Oscar%20Dyson%20-%20Final.pdf),
  [Thomas Jefferson (IRVSI)](https://www.researchvessels.org/ship_info_display.asp?shipID=675),
  [Healy (UNOLS)](https://www.unols.org/sites/default/files/healy_2.pdf),
  [Reuben Lasker](https://omao.noaa.gov/marine-operations/ships/reuben-lasker),
  [Fairweather](https://www.omao.noaa.gov/mo/ships/fairweather)
- [NOAA Henry B. Bigelow spec sheet](https://www.omao.noaa.gov/sites/default/files/documents/HB%20SpecSheet%2002JUL2018.pdf)
- [NOAA Ronald H. Brown specs (WHOI copy)](https://science.whoi.edu/users/olga/SPIROPA/data/meetings/2019%20Cruise%20Planning/NOAA%20Brown%20Specs.pdf)
- [Sikuliaq scientific equipment](https://ops.sikuliaq.alaska.edu/shipboard-services/equipment-and-instrumentation/scientific-equipment),
  [Sikuliaq specifications](https://www.sikuliaq.alaska.edu/ops/skq_specs.html)
- [Langseth specs](https://lamont.columbia.edu/research-divisions/marine-large-programs/office-marine-operations/langseth)
- [UNOLS vessel specifications (August 2015)](https://www.unols.org/sites/default/files/VesselSpecs_18Aug15.pdf), [Gordon Gunter (IRVSI)](https://www.researchvessels.org/ship_info_display.asp?shipID=240)
- [WHOI R/V Atlantis navigation equipment](https://whoi.edu/what-we-do/explore/ships/ships-atlantis/ships-atlantis-scientific-equipment/ships-atlantis-scientific-equipment-navigation-equipment)
- [R/V Neil Armstrong fact sheet](https://www.whoi.edu/wp-content/uploads/2026/09/RVArmstrong-fact-sheetV2.pdf)
