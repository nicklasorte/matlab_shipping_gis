# Plan: more data on ships that use 2900–3100 MHz radars

DRAFT//PRE-DECISIONAL

Date: November 13, 2026. Public and cleared sources only.

## The question

The paper wants the ships that operate a maritime radionavigation radar in
2900–3100 MHz (S-band). The current method uses a proxy for SOLAS carriage
(Section 1.4):

- AIS ship type, a length of 100 m or more, and an IMO number together stand in
  for a ship of 3,000 GT or more.
- The analysis assumes every such ship carries an S-band radar.

That leaves four gaps, from biggest to smallest:

1. **Carriage.** SOLAS lets a ship of 3,000 GT or more fit a second 9 GHz radar
   instead of the S-band radar. No public source gives the split (Section 1.1).
2. **Use.** A ship that carries an S-band radar may not run it. Many ships run
   S-band offshore and in rain, and X-band in port.
3. **Ships outside the proxy.** These include smaller ships that fit S-band by
   choice (research, offshore supply, large fishing vessels), government ships,
   and ships with AIS off.
4. **Coverage.** Shore receivers miss traffic far offshore and in parts of
   Alaska (Sections 1.10 and 5).

Each data source below is ranked by which gap it closes and whether it can be
used.

## Sources

Status:

- **Confirmed** means checked on November 13, 2026.
- **Verify** means it must be checked before use.
- **Not usable** means it isn't public or cleared. Its value is noted, but it isn't
  requested or reconstructed.

### A. Carriage: which ships have an S-band radar

| # | Source | What it adds | Status |
| --- | --- | --- | --- |
| A1 | Research-fleet spec sheets: UNOLS vessels, the NOAA fleet, and USACE hopper dredges | Radar make and model by ship, often with the band (for example, "S-band"). This is a small, exact truth set for non-SOLAS and government ships. | Verify: public PDFs; coverage varies by ship |
| A2 | Radar models by band from type-approval lists: the U.S. Coast Guard approved-equipment list (CGMIX) and the EU Marine Equipment Directive database | Which radar models are S-band. These lists hold models, not ships, so they make A1 and A3 usable. | Verify: both online; bulk export unknown |
| A3 | Public ship photos (port and spotter photos), coded by a person | Most S-band antennas are 12 ft (3.7 m) or longer; most X-band antennas run 4–9 ft. Some S-band antennas are 8–10 ft (JRC JMR-9282-S, Furuno non-IMO radiators) and one Furuno fishing X-band antenna is 10 ft, so 8–11.9 ft is coded "unclear" (`docs/review/sband_radar_models_rev1.md`). A coder marks "S-band antenna seen: yes, no, or unclear" for a random sample. This is the only public route to a per-ship carriage rate for merchant ships. | Verify: viewing to code only, no republishing; needs a coding protocol and a second coder |
| A4 | ITU MARS (List V of ship stations) | MMSI, call sign, and IMO links. It may hold station equipment. It's free to search, but the bulk download is restricted. | Confirmed free search; Verify which fields it holds |
| A5 | FCC ULS ship station licenses (bulk public-access files) | U.S. compulsory ships hold a license; voluntary domestic ships with radar need none. The license doesn't list radar bands, but it confirms U.S. compulsory status and gives the MMSI. | Confirmed license rules; Verify the fields in the bulk file |
| A6 | U.S. Coast Guard PSIX (XLSX export and XML web service) | Gross tonnage for U.S.-documented vessels. It replaces the length proxy with real tonnage for U.S.-flag ships, including Great Lakes and Jones Act ships. | Confirmed export exists; Verify the gross tonnage field |
| A7 | Equasis (free registration) | Gross tonnage, flag, and type for most SOLAS ships, plus port state control records. It's a stronger tonnage check than Wikidata. | Verify: the terms of use may bar bulk extraction; use only for a sample check |
| A8 | Classification-society registers (public vessel lookups) | Class notations. Some notations imply bridge equipment but not the radar band. | Low value; check one register before investing |

### B. Use: which ships transmit at S-band

| # | Source | What it adds | Status |
| --- | --- | --- | --- |
| B1 | Published NTIA/ITS and ITU-R measurement reports on maritime radars (for example, ITU-R M.1460 for 2900–3100 MHz radar characteristics, and IMO MSC.192(79) radar performance standards) | Emission and operating characteristics. These give no ship counts, but they bound duty cycles and when S-band is used. | Public; Verify which reports report the share of time radars are in use |
| B2 | A cleared spectrum measurement at one busy port or channel (for example, Houston, the lower Mississippi, or New York) | A count of distinct S-band sweeps, matched to the AIS ships present. It measures the share of ships passing that radiate S-band. This is the one dataset that would turn "carriage assumed" into a measured rate. | New collection; needs approval, equipment, and a site |
| B3 | Commercial satellite RF geolocation (HawkEye 360 and similar) | Detects maritime radar emissions, even from ships with AIS off. | Not usable: commercial. The band coverage isn't stated publicly. |

### C. Ships outside the proxy

| # | Source | What it adds | Status |
| --- | --- | --- | --- |
| C1 | AIS fishing (type 30), research, and offshore ships of 60–100 m, tested against A1 and A3 | Whether large non-SOLAS ships, such as Alaska factory trawlers and offshore supply ships, fit S-band often enough to count | Uses data already held; needs A1 and A3 for truth |
| C2 | Naval Vessel Register and the Coast Guard cutter list, with homeports | Government ships that don't show in AIS. Gives homeports and ship classes; public class descriptions name some radars. | Public; Verify per class |
| C3 | Military operating areas and Part 334 danger areas (MarineCadastre and NOAA charts) | Where government ships operate offshore, as context layers rather than routes | Verify the dataset name and currency |

### D. Coverage: traffic the shore receivers miss

| # | Source | What it adds | Status |
| --- | --- | --- | --- |
| D1 | IMF PortWatch (satellite AIS, public) | Daily port calls and chokepoint transits by vessel type. Cross-checks port traffic and the satellite-lane cutoff, including in Alaska. | Verify the U.S. port coverage and terms |
| D2 | USACE Waterborne Commerce entrances and clearances | Foreign-trade vessel trips by port, with draft and net tonnage. An independent check that the routes reach every deep-draft port in proportion. | Public; Verify the latest year |
| D3 | MARAD U.S.-flag fleet and vessel-call data | Calls by ship size at U.S. ports. Cross-checks Tables 4 and 5. | Verify currency |
| D4 | Global Fishing Watch vessel presence (non-commercial license) | Satellite-AIS presence. Mostly fishing, so it bears on C1 more than on cargo. | Verify license terms |
| D5 | NOAA AIS Vessel Transit Counts | Already used as a cross-check (Table 8) | In use |
| D6 | Satellite AIS from commercial providers | Full offshore coverage | Not usable: commercial |

## Work plan

### Phase 1: Truth sets (2 to 3 days)

1. Build the S-band model list (A2) as a table of make, model, and band, with
   sources.
2. Pull spec sheets for UNOLS, NOAA, and USACE ships (A1). Record each ship's IMO
   number, MMSI, length, gross tonnage, and radar models and bands.
3. Write the photo-coding protocol (A3). Code a stratified random sample of 300
   kept ships from the 2024–2025 AIS set: 100 cargo, 100 tanker, 50 passenger,
   and 50 other. A second coder repeats 20% of the sample, and Cohen's kappa
   is reported.
4. Pull PSIX gross tonnage for every U.S.-flag ship in the kept set (A6).

**Check:** two coders must agree (kappa ≥ 0.7). A1 ships with a known radar
serve as planted answers for the photo coders.

### Phase 2: Measure the carriage rate and test the proxy (2 days)

1. From the photo sample, estimate the share of kept ships with an S-band
   antenna, by type, with a 95% interval (Wilson).
2. Rerun the length-proxy check (Figure 2) with PSIX and Equasis tonnage in
   place of Wikidata, where they're available.
3. Test C1: what share of 60–100 m fishing, research, and offshore ships carry
   S-band.

**Decision for Nick:** whether the zones should:

- weight ships by the carriage rate;
- add a class of non-SOLAS ships;
- or keep the presence rule and report the rate as an uncertainty.

### Phase 3: Coverage cross-checks (2 days)

1. Compare port calls from PortWatch (D1) and USACE (D2) with the route
   network's port counts (Tables 4 and 5, Appendix A.20). Report rank
   correlation and any port where the routes undercount.
2. Compare PortWatch Alaska transits with the satellite-lane cells (R2OPP-1).

**Check:** reproduce one published PortWatch figure before using its data.

### Phase 4: Use rate (optional; needs approval)

1. Design the measurement (B2): site, receiver, antenna, the 2900–3100 MHz sweep
   detector, and a match to AIS by time and bearing.
2. Run it for one week at one port. Report the share of AIS ships passing that
   radiated S-band, by type and by distance from port.

**Check:** a known S-band source, such as a VTS radar or a racon, must appear
in the data.

## Outputs

- `data/ship_radar_models.csv` (A2), `data/sband_truth_ships.csv` (A1 and A3),
  and `data/psix_gt_kept_ships.csv` (A6).
- `python/sband_carriage_rate.py` and `sband_carriage_rate_rev1.m`, in both
  languages per the repo convention.
- `docs/review/sband_carriage_rev1.md`, with results, intervals, and the coding
  protocol.
- Paper changes: Section 1.1 replaces "no public source gives the share" with the
  measured rate and its interval. Section 1.10 updates "Carriage, not use".

## Risks

- **Photo coding:** photos show only an antenna, not whether it radiates. The
  rate is a carriage rate, not a use rate. Antenna length can mislead on small
  ships.
- **Terms of use:** Equasis and some photo sites restrict bulk use. Keep to
  sample checks and don't republish images.
- **Spec sheets:** they skew toward research ships. Use them for C1 and as
  planted answers, not for merchant-ship rates.
- **Government ships:** radar details for these may not be cleared. Use only
  published class descriptions.
