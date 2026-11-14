# S-band ship radar models (first pass)

DRAFT//PRE-DECISIONAL

Date: November 13, 2026. Data: `data/ship_radar_models.csv` (S-band models plus X-band models for comparison). Plan step A2 of
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
   - Solid-state models: fixed channels, 3035–3079 MHz (Furuno NXT to
     3078.75 MHz; JRC to about 3073 MHz with its 8 MHz long-pulse deviation).
   - Kelvin Hughes SharpEye: 8 selectable channels within 2.9–3.1 GHz (the
     channel frequencies aren't published).

   So the 3030–3070 MHz example band in Table 7 holds most ship radars' center
   frequencies, but not the ±30 MHz magnetron tolerance or SharpEye's channels.
   This bears on review item CA-18.
2. **Solid-state S-band radars run at 200–250 W peak, against 30 kW for IMO
   magnetrons (60 kW for Furuno's FAR-2268DS fishing radar).** The makers rate the two as performing alike. The EMC analysis
   needs both emitter types, because their spectra and peak powers differ.
3. **Antenna length doesn't separate the bands cleanly.**
   - Most S-band antennas are 12 ft (3.7 m), and SharpEye's is 12 ft 9 in
     (3.9 m).
   - Some are shorter: JRC's solid-state JMR-9282-S uses an 8 ft antenna,
     Furuno's FR-2135S offered 9 ft, and Furuno sells 8 and 10 ft S-band
     radiators for non-IMO installations.
   - Most X-band antennas run 4–9 ft, but Furuno's FAR-2258 fishing radar
     offers a 10 ft X-band radiator (XN30AF).

   **Photo-coding rule (one rule, used in the CSV and the protocol):** 12 ft or
   longer is S-band; 8 to 11.9 ft is unclear; under 8 ft is X-band. Length here
   is the nominal radiator length; JRC's FCC filing gives swing circles a little
   longer (2.77 m for its 8 ft scanner, 4.0 m for its 12 ft scanners).
   Corrected after the round-three data review (R3DAT-1, R3DAT-2).
4. **Makers share scanners.** Kongsberg's S-band scanner carries JRC's code
   (NKE-1130-12S/KM), so counting by brand overstates the number of distinct
   radar designs.

## Gaps for the next pass

- Frequencies for Furuno FAR-2338S-NXT and FAR-3230S-SSD (the FAR-2338S and
  FAR-3230S frequencies are now inferred from the FAR-2238S, because Furuno
  Norway's tables list the same transceiver, RTR-107, and antenna; they are
  marked as inferred in the CSV), JRC
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

## Columns in `data/ship_radar_models.csv`

The file holds 36 rows: 23 S-band models, 1 ITU generic S-band row, and 12
X-band models. The X-band
rows are there so the photo coding can tell the two bands apart.

| Column | Meaning and how it helps match ship data |
| --- | --- |
| `manufacturer`, `model`, `variants` | Maker and model; `variants` lists display sizes and black-box (`-BB`) versions of the same radar |
| `band`, `in_2900_3100_mhz` | S or X; whether the radar transmits in the paper's band |
| `freq_spec` | Frequency as the source states it, quoted |
| `freq_low_mhz`, `freq_high_mhz`, `center_mhz` | Numeric range, for overlap with the zone frequency ranges (Table 7) |
| `emission_class` | ITU class of emission: P0N is a plain pulse (magnetron or solid-state); Q0N is a pulse with modulation inside it (solid-state) |
| `peak_power_w`, `transmitter` | Peak power and magnetron or solid-state, for the EMC analysis |
| `antenna_ft`, `antenna_m`, `antenna_unit` | Antenna length and part number |
| `photo_code_by_antenna` | How the photo coders (plan step A3) should code an antenna of that length: 12 ft or longer is S-band, 8–11.9 ft is unclear, and under 8 ft is X-band |
| `imo_category`, `ship_size_hint` | Radar performance category, which ties to ship size: CAT 1 for 10,000 GT or more, CAT 2 for 500 to 10,000 GT, CAT 3 for under 500 GT. Use it to match radar class to the AIS ship size. |
| `solas_role` | Which SOLAS carriage rule the radar meets |
| `status` | Current or legacy; legacy models are still found on older ships |
| `fcc_id` | FCC equipment authorization, where found (JRC NKE-2632: CKENKE2632) |
| `product_page_url`, `datasheet_url` | Maker page and the specification source (a ";" separates two sources) |
| `confidence`, `note` | High means frequency and power were quoted from the maker's specifications; medium means band and power were confirmed; low means a dealer page with conflicting figures |

### RF characteristics (added November 13, 2026)

These were filled where a source gives them; blank means not found yet. Values
are copied from the cited `rf_source_url`. The JRC values come from JRC's FCC
filing (FCC ID CKENKE2632), which gives the full specifications for each
scanner.

| Column | Meaning |
| --- | --- |
| `h_beamwidth_deg`, `v_beamwidth_deg` | Antenna 3 dB beamwidths; S-band 1.8–2.7° horizontal and 25–26° vertical |
| `sidelobe_within_10deg_db`, `sidelobe_outside_10deg_db` | Antenna sidelobe levels relative to the main beam |
| `polarization` | Horizontal for every model that states it |
| `antenna_gain_db` | Only Raytheon Anschütz states it for a model (28 dB for its 12 ft S-band antenna); ITU-R M.1460-1 gives 26–28 dB |
| `rotation_rpm` | 21–27 rpm standard; 42–48 rpm for high-speed craft |
| `pulse_prf_pairs_us_hz` | Pulse width (µs) / repetition frequency (Hz). Solid-state rows give the short pulse, the long modulated pulse in parentheses, and the PRF. |
| `pulse_compression` | Solid-state long-pulse details (JRC: 4.6–18.3 µs, 8 MHz deviation; SharpEye: 660:1) |
| `max_duty_cycle_pct` | Derived: the largest pulse width × PRF among the listed pairs. Magnetrons are about 0.065–0.075%; JRC solid-state is about 2.1%, which is consistent with its stated average power (5.8 W or lower, against 250 W peak). Some Furuno pairs are constructed from unpaired brochure lists (see `rf_note`). |
| `average_power_w` | Average power where stated |
| `if_mhz`, `if_bandwidth_mhz`, `noise_figure_db` | Receiver data, used for receiver-side interference analysis |
| `rf_source_url`, `rf_note` | Source and caveats (unmapped tables, inferred values) |

Main points for the EMC analysis:

- **Magnetron S-band radars:** 30 kW peak for IMO radars (60 kW for one
  Furuno fishing radar), about 0.07% duty cycle, about 20 W average.
- **Solid-state S-band radars:** 200–250 W peak, with long frequency-modulated
  pulses at about 2% duty cycle and about 5 W average.
- **Both:** horizontal polarization, about a 2° by 25° beam, sidelobes at
  −24 dB to −30 dB, and turning at about 24 rpm.

### Antenna and scan modes (added November 13, 2026)

| Column | Meaning |
| --- | --- |
| `antenna_type` | Slotted waveguide array. Furuno states it; ITU-R M.1460 calls it typical, and rows marked "typical" rely on that. |
| `antenna_options` | Radiators and antenna units sold for the model, and rotation options |
| `scan_mode` | All ship navigation radars found turn mechanically through 360° with a fixed fan beam about 25° tall. None scans in elevation. |
| `sector_blanking` | MSC.192(79) 7.3 calls for a facility to mute transmission over a preset sector, set up on installation; the resolution recommends that governments apply it to radars installed on or after July 1, 2008, and type approval makes it standard. Where the sector points isn't specified. Legacy models aren't confirmed. |
| `frequency_channels` | Magnetrons transmit at one frequency within their tolerance, not selectable. Solid-state radars use fixed or selectable channels: Furuno NXT two, JRC by option, SharpEye eight (frequencies not published). |
| `roll_pitch_performance` | IMO radars must detect normally at roll or pitch up to ±10°. With a 25° beam, the main beam tilts with the ship. |
| `detection_reference_height_m` | IMO detection tests assume an antenna 15 m above the sea; real masts vary. |
| `protection_criterion` | I/N of −6 dB for these radars (ITU-R M.1460, aggregate) |
| `antenna_source_url` | Sources for these columns |

A generic row, "ITU-R M.1460-1 (generic)", gives the ITU envelope for ship
radars in this band, to use where a model value is blank:

- 3020–3080 MHz, at 30–75 kW peak.
- Pulses of 0.05–1.2 µs, at a PRF of 375–4000 Hz.
- A 26–28 dB antenna gain, with a 1–4° by 24–30° beam.
- 20–60 rpm.
- A 3–8.5 dB noise figure.
- More than 300,000 units worldwide (2006).

Furuno's current installation manual also lists 8 ft and 10 ft S-band radiators
(SN24CF and SN30CF) for installations that aren't IMO type-approved, and a 10 ft
X-band radiator (XN30AF) for the FAR-2258 fishing radar. So an antenna shorter
than 12 ft is "unclear", whichever band its length suggests.
