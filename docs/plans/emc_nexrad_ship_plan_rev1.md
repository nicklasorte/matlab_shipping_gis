# Plan: NEXRAD and shipborne S-band radar EMC analysis

DRAFT//PRE-DECISIONAL

Date: November 22, 2026. A separate working paper (Claude Doc "2.7 GHz study:
NEXRAD and shipborne S-band radar EMC analysis",
https://claude.ai/artifact/Dcc1nD6zP3u6KuDejA6B2d) finds how far a NEXRAD
(WSR-88D) and a shipborne S-band radar must be apart, on the same frequency
and at frequency offsets, so that neither interferes with the other. The
analysis is in MATLAB (R2025b) with ITM area mode from
[matlab_itm](https://github.com/nicklasorte/matlab_itm).

## Question and outputs

For each direction (NEXRAD into ship, ship into NEXRAD):

1. The path loss each pair needs, by frequency offset and antenna coupling case.
2. The separation distance at which ITM area mode gives that loss, at 50%,
   10%, 1%, and 0.1% of time.
3. The frequency offset at which no separation is needed (distance at or
   below ITM's 1 km minimum).

Outputs: a needed-loss table, a distance-against-offset chart for both
directions, and the distribution of distance over antenna rotation. Every
number in the paper traces to a committed output or run log.

## Inputs (public only)

| Input | NEXRAD source | Ship radar source |
| --- | --- | --- |
| Power, pulse, emission bandwidth | NOAA ROC, NEXRAD Technical Information; ITU-R M.1849-3 Radar 1 (check) | ITU-R M.1460-2 Table 4 (IMO magnetron); Table 1 Radar No. 3B (solid state) |
| Antenna gain, beamwidth, sidelobes, height, scan | Same | Same |
| Receiver bandwidth, noise figure, filter points | Same (636 kHz matched filter, 2.6 dB, front-end points) | Same (IF 2.5-28 MHz, noise figure 3-8.5 dB) |
| Protection criterion | ITU-R M.1849-3: I/N = -10 dB (aggregate); -6 dB sensitivity | ITU-R M.1460-2: I/N = -6 dB; Annex 3 pulsed tolerance as sensitivity |
| Antenna patterns | ITU-R M.1851 fitted to gain, beamwidth, sidelobes | Same (fan beam) |
| FDR method | ITU-R SM.337; NTIA Manual radar emission envelope | Same |

Parameter values live in one file, `data/emc/radar_params_rev1.csv`, one row
per parameter, with columns `system, parameter, value, unit, low, high,
source, table_or_page`. The code reads only this file, so a changed value is
one edit with its source. Following the project convention, I/N values
stricter than -6 dB are used only when they come from ITU-R documents.

## Steps

| Step | Work | Output |
| --- | --- | --- |
| E1 | Write `data/emc/radar_params_rev1.csv` from the paper's Tables 2 and 3; a reader `emc_params_rev1.m` that errors on a missing or out-of-range value | CSV, reader, test |
| E2 | Emission spectra `emc_emission_rev1.m` (pulse width, rise and fall time, NTIA Manual envelope) and selectivity `emc_selectivity_rev1.m` (IF bandwidth; NEXRAD front-end points). Check each spectrum against the published -3, -20, -40 dB points | Spectrum figures; test that the published points are met within 1 dB |
| E3 | FDR `emc_fdr_rev1.m` per ITU-R SM.337 (numeric integration on a common frequency grid, `trapz`); FDR against offset 0-150 MHz for both directions | FDR curves; tests: FDR(0) of identical rectangular spectra = 0 dB, on-tune rejection = 10 log10(B_tx/B_rx) for a wide rectangular emission into a narrow rectangular filter |
| E4 | Antenna gains `emc_antenna_gain_rev1.m` (ITU-R M.1851 patterns, horizontal and vertical); coupled gain at the horizon for NEXRAD's 0.5 deg tilt and the ship's fan beam; scan statistic by Monte Carlo over rotation phases (`RandStream`, one substream per draw) | Gain cases: main-main, main-side, distribution |
| E5 | Needed loss `emc_link_budget_rev1.m` (equation in the paper, Section 4), peak power in the victim's bandwidth | Needed-loss table by case |
| E6 | Separation `emc_separation_rev1.m`: solve `itm_area_rev1(h_tx, h_rx, d, 0, f, p, ...) = L_req` for d with `fzero` on 1-2,000 km (sea water: epsilon 81, sigma 5 S/m; climate 7, maritime temperate over sea; horizontal polarization; confidence 50%). Report "beyond 2,000 km" when the loss is not reached | Distance table and distance-against-offset curves |
| E7 | Driver `init_emc_nexrad_ship_rev1.m` (cases, sensitivity loops, writes `outputs/emc/` CSVs and a run log with the commit of this repo and of matlab_itm) | Outputs, `outputs/rerun_logs_<date>/emc_*.log` |
| E8 | Python twin of E2, E3, and E5 (`python/emc_fdr.py`, `python/emc_link_budget.py`); agree with MATLAB within 0.01 dB. ITM itself is covered by matlab_itm's C++ match tests | Twin, comparison log |
| E9 | Figures (MATLAB, NTIA style; alt text) and paper Section 5 | Figures, paper text |
| E10 | Blind review (numbers, method, code, style and Section 508, opposing reader) as in earlier rounds | `docs/review/emc_round1/` |

## Checks before any number goes in the paper

- matlab_itm self-test (`itm_selftest_rev1`) passes on the machine that runs the analysis.
- ITM loss is at or above free-space loss at every distance computed.
- Reproduce a published reference case first (open: find a public NEXRAD or
  S-band radar-to-radar separation result, for example in an NTIA report or
  an ITU-R M.1461 worked example).
- Needed loss and distance by hand for one case (main beam to main beam, co-channel, 50% of time), logged.
- MATLAB and Python FDR and needed loss agree within 0.01 dB.
- `checkcode` clean; tests in `test_emc_rev1.m` pass.

## Sensitivity cases

One input at a time: NEXRAD I/N -10 and -6 dB; ship I/N -6 dB and the pulsed
tolerance (M.1460-2 Annex 3); parameter low and high values from the CSV;
antenna heights; time percentage; climate 5 and 3; refractivity 301 and 350
N-units; coastal land paths with terrain irregularity 30 and 90 m.

## Later steps (not in this plan)

- ITM point-to-point from each coastal NEXRAD to the shipping route cells in
  this repo, so the distances become a list of NEXRAD sites with route cells
  inside the needed separation.
- Several ships near one NEXRAD (aggregate).
- Feed the distance-against-offset curves to the retuning work
  (`2dot7_agent_retuning`).

## Decisions for Nick

- NEXRAD protection criterion for the base case: -10 dB (M.1849-3, aggregate) or -6 dB.
- Whether the ship radar's pulsed tolerance (M.1460-2 Annex 3) is a base case or a sensitivity case.
- Representative ship radar: the IMO magnetron range (Table 4) as base, solid-state Radar No. 3B as a second case.

## Sources

- NOAA Radar Operations Center, NEXRAD Technical Information:
  https://roc.noaa.gov/public-documents/wsr88d/NEXRAD-Technical-Information.pdf
- Recommendation ITU-R M.1849-3 (02/2023):
  https://www.itu.int/dms_pubrec/itu-r/rec/m/R-REC-M.1849-3-202302-I!!PDF-E.pdf
- Recommendation ITU-R M.1460-2 (02/2015):
  https://www.itu.int/dms_pubrec/itu-r/rec/m/R-REC-M.1460-2-201502-I!!PDF-E.pdf
- matlab_itm: https://github.com/nicklasorte/matlab_itm
