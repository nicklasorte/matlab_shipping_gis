# Research-ship truth set (first pass)

DRAFT//PRE-DECISIONAL

Date: November 13, 2026. Data: `data/sband_truth_ships.csv`. Plan step A1 of
`docs/plans/ship_data_sources_plan_rev1.md`. Public pages only; each row cites
its source and quotes the text it relies on.

## What's in the table

The table has 19 rows for 12 research and survey ships, one row per radar. Ships
come from the UNOLS fleet and the NOAA fleet.

| Result | Ships |
| --- | --- |
| S-band radar confirmed by a source | Sally Ride, Roger Revelle, Ronald H. Brown, Okeanos Explorer, Henry B. Bigelow, Atlantis (6) |
| Only an X-band radar listed | Sikuliaq (1) |
| A radar listed with no make, model or band, or none listed | Thomas G. Thompson, Kilo Moana, Bell M. Shimada, Marcus G. Langseth, Neil Armstrong (5) |

No Army Corps hopper dredge is in the table. The pages found give no radar
detail (a solicitation draft, a news release, and a fleet page that returned a
bot check).

## Findings

1. **Research and survey ships carry S-band radars below the length proxy.**
   Four of the six S-band ships have a published length: Atlantis and Ronald H.
   Brown at 83.5 m, Okeanos Explorer at 68.3 m, and Henry B. Bigelow at 63.6 m.
   All four are under the 100 m cutoff in Section 1.4, so the proxy misses them.
2. **Two carry S-band below 3,000 GT.** Henry B. Bigelow (2,479 GT) and Okeanos
   Explorer (2,062 GT) are under the SOLAS threshold for a required S-band
   radar, so these were fitted by choice or by owner specification.
3. **A radar model may not say which band it is.** Okeanos Explorer's page lists
   Furuno FAR 2837S and FAR 2827X with no bands; the band comes from the model
   suffix (S or X), matched to `ship_radar_models.csv`. Treat these rows as
   "inferred".

## Cautions

- **This is not a sample.** These are government and research ships, chosen
  because their spec sheets are public. They show that non-SOLAS ships carry
  S-band. They don't give a rate.
- **Two sources disagree on Ronald H. Brown.** One lists Sperry Rascar S-band
  (30 kW) and X-band (25 kW) radars. A second lists two Furuno FAR-21x7 radars,
  X and S band. Neither is dated, so the rows are low confidence. Both agree on
  S-band.
- **Atlantis's S-band model is printed "2835X".** The page labels it S-band.
  The model string may be a typo; the band label is the stated fact.
- **A missing radar is not an absent radar.** Sikuliaq's page lists only an
  X-band radar. Five pages list no radar at all.
- **Blank cells mean not found.** IMO and MMSI are filled only where a page gave
  them. MMSI isn't on any page found.

## Matching to AIS

The AIS data held in the repo is cell counts, not per-ship records, so the match
to AIS ships runs on the Mac. Use IMO number first (Atlantis, Ronald H. Brown,
Henry B. Bigelow), then call sign, then name. Report which of these ships fall
inside the kept AIS set and whether the length proxy keeps them.

## Next

- Add the other UNOLS and NOAA ships (Gordon Gunter, Oscar Dyson, Reuben Lasker,
  Fairweather, Rainier, Thomas Jefferson, Pisces, Healy) from operator
  handbooks; some are on sites this session can't reach.
- Add the Corps dredges from the Corps fleet listing, which a person can
  download.
- Fill lengths and tonnage for Sally Ride and Roger Revelle from the UNOLS
  vessel specifications.

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
- [NOAA Henry B. Bigelow spec sheet](https://www.omao.noaa.gov/sites/default/files/documents/HB%20SpecSheet%2002JUL2018.pdf)
- [NOAA Ronald H. Brown specs (WHOI copy)](https://science.whoi.edu/users/olga/SPIROPA/data/meetings/2019%20Cruise%20Planning/NOAA%20Brown%20Specs.pdf)
- [Sikuliaq scientific equipment](https://ops.sikuliaq.alaska.edu/shipboard-services/equipment-and-instrumentation/scientific-equipment),
  [Sikuliaq specifications](https://www.sikuliaq.alaska.edu/ops/skq_specs.html)
- [Langseth specs](https://lamont.columbia.edu/research-divisions/marine-large-programs/office-marine-operations/langseth)
- [WHOI R/V Atlantis navigation equipment](https://whoi.edu/what-we-do/explore/ships/ships-atlantis/ships-atlantis-scientific-equipment/ships-atlantis-scientific-equipment-navigation-equipment)
- [R/V Neil Armstrong fact sheet](https://www.whoi.edu/wp-content/uploads/2026/09/RVArmstrong-fact-sheetV2.pdf)
