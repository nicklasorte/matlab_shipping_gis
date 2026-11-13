# S-band ship radar models (first pass)

DRAFT//PRE-DECISIONAL

Date: November 13, 2026. Data: `data/sband_radar_models.csv`. Plan step A2 of
`docs/plans/ship_data_sources_plan_rev1.md`. Public manufacturer and dealer
pages only; each row cites its source.

## What's in the table

The table has 22 S-band (3 GHz, 10 cm) navigation radar models or model
families from seven makers: Furuno (9), JRC (8), Kongsberg, Sperry Marine,
Raytheon Anschütz, Kelvin Hughes (Hensoldt), and Wärtsilä (Transas). It
includes current and legacy models. The 19-inch and 26-inch display versions of
one radar share a row (for example, JRC JMR-9230-S and JMR-7230-S).

Confidence:

- **High:** frequency and power quoted from the maker's own specifications.
- **Medium:** band and power confirmed, but frequency or antenna not stated.
- **Low:** from a dealer page with figures that conflict.

Koden's MDC-7900/7000 series appears to be X-band only. No S-band model was
found, so Koden isn't in the table.

## Findings

1. **Every S-band model found transmits inside 2900–3100 MHz, and most inside
   3020–3080 MHz.**
   - Magnetron models: 3050 MHz ±30 MHz (Furuno) or ±20 MHz (JRC, Kongsberg,
     Wärtsilä).
   - Solid-state models: fixed channels, 3035–3075 MHz (Furuno NXT and JRC).
   - Kelvin Hughes SharpEye: eight selectable channels across the whole
     2900–3100 MHz band.

   So the 3030–3070 MHz example band in Table 7 holds most ship radars' center
   frequencies, but not the ±30 MHz magnetron tolerance or SharpEye's channels.
   This bears on review item CA-18.
2. **Solid-state S-band radars run at 200–250 W peak, against 30 kW for
   magnetrons.** The makers rate the two as performing alike. The EMC analysis
   needs both emitter types, because their spectra and peak powers differ.
3. **Antenna length doesn't separate the bands cleanly.**
   - Most S-band antennas are 12 ft (3.7 m), and SharpEye's is 12 ft 9 in
     (3.9 m).
   - Some aren't: JRC's solid-state JMR-9282-S uses an 8 ft antenna, and
     Furuno's older FR-2135S offered 9 ft.
   - X-band antennas run 4–9 ft (Furuno 4, 6.5, and 8 ft; JRC and others up to
     9 ft).

   So the photo-coding step (A3) can count a 12 ft or longer antenna as S-band.
   An 8–9 ft antenna can't be coded from length alone, and A3's protocol must
   allow "unclear". The plan's line "about 3.7 m against 1.8–2.4 m" is
   corrected below.
4. **Makers share scanners.** Kongsberg's S-band scanner carries JRC's code
   (NKE-1130-12S/KM), so counting by brand overstates the number of distinct
   radar designs.

## Gaps for the next pass

- Frequencies for Furuno FAR-2338S, FAR-3230S, and FAR-3230S-SSD, JRC
  JMR-9300, Sperry VisionMaster FT and BridgeMaster E, and Raytheon Anschütz
  Synapsis. The Furuno brochures and manuals are on hosts this session can't
  reach (furuno.com/files); a person can download them, or dealer copies may
  be found.
- Wärtsilä NAVI-RADAR 4000 S-band power, from a Wärtsilä source.
- Type-approval lists (Coast Guard approved equipment and the EU Marine
  Equipment Directive database), to check that the list is complete. These
  lists are the authority for which models are approved for SOLAS ships.
- Other makers to check: Hensoldt's other Kelvin Hughes lines (Manta, Nucleus),
  Simrad and Raymarine (likely X-band only), Tokyo Keiki, and Chinese makers
  (for example, CETC). Navy and Coast Guard ships also carry military S-band
  radars, such as the AN/SPS-48 (2900–3100 MHz), which are out of scope for
  this commercial list.

## Sources

- [Furuno radar index](https://www.furuno.com/en/products/radar/index.html),
  [FAR-2xx8](https://www.furuno.com/en/products/radar/far-2xx8/index.html),
  [FAR-30x5](https://www.furuno.com/en/products/radar/far-30x5/index.html)
- [Furuno FAR-22x8 brochure (Radio Holland copy)](https://www.radioholland.com/pon-data/uploads/2020/11/FAR-22x8series_EN.pdf)
- [Furuno Norway IMO radar overview](https://furuno.no/Userfiles/Sites/files/radaroversikt%2c%20IMO%20godkjent(5).pdf)
- [Furuno FAR-2137S](https://www.psicompany.com/man-prod-info/furuno/prodweb/radar/far2137s.pdf),
  [FR-2135S](https://www.psicompany.com/man-prod-info/furuno/prodweb/radar/fr2135sbbbr.pdf),
  [FAR-2837S](https://www.manualslib.com/manual/55721/Furuno-Far-2817.html?page=6)
- [JRC JMR-9200/7200 brochure (Radio Holland copy)](https://www.radioholland.com/pon-data/uploads/2022/08/jmr-9200_7200_e.pdf),
  [JRC JMR-9300](https://www.jrc-world.com/en/product/jmr-9300-radar-619/)
- [Kongsberg S-band radar](https://www.kongsberg.com/contentassets/4faa073f15f34c74b5a32806a41d898a/463225b-s-band-radar.pdf)
- [Sperry VisionMaster FT (Radio Holland copy)](https://www.radioholland.com/pon-data/uploads/2022/08/VMFT-Radar.pdf)
- [Raytheon Anschütz Synapsis Radar (Mackay copy)](https://mackaycomm.com/wp-content/uploads/2016/12/Raytheon_Anschutz_Synapsis_Radar_Chartradar_Aug2012__Mackay.pdf)
- [Kelvin Hughes SharpEye S-band (Mackay copy)](https://static.mackaycomm.com/wp-content/uploads/2021/08/Kelvin-Hughes-CMS-navigation-radar-s-band.pdf),
  [Hensoldt commercial S-band radar](https://hensoldt.net/products/92/commercial-s-band-radar-kelvin-hughes-sharpeye-radar)
- [NAVI-RADAR 4000 S-band (dealer page)](https://cirspb.ru/en/equipment-and-service/rls/Navi-Radar-4000S)
