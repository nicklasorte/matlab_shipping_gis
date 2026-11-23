# 2.7 GHz study: NEXRAD and shipborne S-band radar EMC analysis

Nov 22, 2026 · @Nick LaSorte

**DRAFT//PRE-DECISIONAL**

## 1. Purpose and scope

This paper finds how far a NEXRAD weather radar (WSR-88D) and a shipborne S-band radar must be apart before neither interferes with the other, on the same frequency and at frequency offsets. It is a companion to the large-ship routes and zones working paper, which shows where these ships operate.

The analysis runs both directions: NEXRAD into the ship radar, and the ship radar into NEXRAD. For each direction it computes the path loss each pair needs, then finds the distance at which ITM area mode gives that loss. It reports distances at several time percentiles, for main beam to main beam coupling, and for frequency offsets from 0 MHz (co-channel) up to the point where no separation is needed.

**Assumption: NEXRAD tunes 3020-3080 MHz.** NEXRAD's published tuning range is 2700-3000 MHz, and shipborne navigation radars in ITU-R M.1460 tune 3020-3080 MHz. This paper assumes NEXRAD can tune anywhere in 3020-3080 MHz, so the two radars can be co-channel. The analysis uses 3050 MHz as the base frequency and 3020 and 3080 MHz as the band edges. Only ITM area mode is used. All inputs are public; the analysis is done in MATLAB.

## 2. NEXRAD (WSR-88D) characteristics

NEXRAD is a 750 kW klystron radar with a 45.5 dBi pencil beam and a receiver about 636 kHz wide. The NOAA Radar Operations Center (ROC) publishes its specifications; Radar 1 in ITU-R M.1849-3 is the same system, and the two agree within 0.5 dB where both give a value. The analysis uses the ROC values and keeps the M.1849 values as a check.

| Parameter | ROC value | ITU-R M.1849-3, Radar 1 |
| --- | --- | --- |
| Tuning range | 2700-3000 MHz | 2700-3000 MHz |
| Peak power | 650-750 kW at the transmitter port | 500 kW into the antenna |
| Transmitter-to-antenna loss | 1.5-2.5 dB (10-35 m tower) | Not given |
| Pulse width | 1.52-1.62 µs (short); 4.61-4.81 µs (long) | 1.6 µs; 4.7 µs |
| Pulse repetition frequency | 318-1,304 Hz (short); 318-452 Hz (long) | Same |
| Emission bandwidth | 40 dBc at ±7.26 MHz; 80 dBc at ±62 MHz, or ±19.6 MHz with the spectral filter (short pulse) | 0.6 MHz at -3 dB; 4.6 MHz at -20 dB |
| Antenna | 8.53 m parabolic dish, dual polarization | Parabolic reflector, pencil beam |
| Main-beam gain | 45.5 dB at 2850 MHz, with radome loss | 45.0 dBi |
| Beamwidth | 0.925° | 0.92° |
| Sidelobes | 29 dBc beyond the main beam; 40 dBc beyond 10° | 20 dB |
| Antenna height | 10-35 m above ground | 2.5-30 m |
| Scan | 360° at 5-30 °/s; elevation 0.5-19.5° (0.2° at one coastal site) | 360°; 0.5-20° in fixed steps |
| Receiver bandwidth | 636 kHz matched filter (short pulse); 212 kHz (long pulse) | 0.714 MHz IF at -3 dB |
| Noise figure | 2.6 dB | 2.7 dB |
| Minimum discernible signal | Below -112 dBm (short pulse); below -116 dBm (long pulse) | -112 dBm |
| Front-end filter rejection | 0.5 dB at ±0.35 MHz; 3 dB at ±10 MHz; 30 dB at ±25 MHz; 60 dB at ±100 MHz | RF bandwidth 18 MHz at -3 dB |
| Protection criterion | Stricter than -6 dB (see note) | I/N = -10 dB, aggregate |

The noise power follows from kTBF: -174 dBm/Hz + 10 log10(636 kHz) + 2.6 dB = -113.4 dBm for the short pulse, and -118.1 dBm for the long pulse. The ROC sheet states an interference-to-noise ratio stricter than -6 dB; following this project's convention, the paper quotes values below -6 dB only from ITU-R documents, so it uses the M.1849-3 levels in Section 4.

The ROC gain is at 2850 MHz. For a dish of fixed size, gain rises with 20 log10(f), so at the assumed 3050 MHz it is 0.6 dB higher (46.1 dB); the analysis uses the scaled value and carries 45.5 dB as a check. The front-end filter matters for the ship-to-NEXRAD direction: it passes a ship radar 10 MHz away with 3 dB of loss, so most of the rejection must come from the 636 kHz matched filter and from the ship radar's own spectrum.

## 3. Shipborne S-band radar characteristics

The representative ship radar is the IMO-category magnetron radar in ITU-R M.1460-2, Table 4: 30-75 kW peak, a 26-28 dBi fan beam, and a receiver 2.5-28 MHz wide. Table 3 of the same Recommendation counts more than 300,000 IMO and fishing radars worldwide at 75 kW. The analysis also carries the solid-state Radar No. 3B from Table 1, which the Recommendation says meets the IMO requirements and IEC 62388, because solid-state radars transmit longer, compressed pulses with a narrower spectrum.

| Parameter | IMO category (M.1460-2, Table 4), minimum-maximum | Solid-state Radar No. 3B (M.1460-2, Table 1) |
| --- | --- | --- |
| Frequency | 3020-3080 MHz | 2900-3100 MHz, 8 channels |
| Output device | Magnetron | Solid state |
| Peak power | 30-75 kW | 170 kW; can be reduced to 0.033 kW |
| Pulse width | 0.05-1.2 µs | 0.1, 5, and 33 µs |
| Pulse repetition frequency | 375-4,000 Hz | Not given as a frequency |
| Maximum duty cycle | 7.5 × 10^-4 | Not given |
| Rise and fall time | 0.015 and 0.067 µs | Not given |
| Emission bandwidth | 8 MHz at -3 dB and 43 MHz at -20 dB (shortest pulse) | 15 or 3 MHz at -3 dB; 18-22 MHz at -20 dB |
| Pulse compression | None | Up to 400 |
| Antenna | Slotted waveguide array, fan beam, horizontal polarization | Not given |
| Gain | 26-28 dBi | 27.5 dBi |
| Beamwidth | 1.0-4.0° horizontal; 24-30° vertical | 2° azimuth; 26.5° elevation |
| Sidelobes | 23-28 dB within ±10°; 31-32 dB outside | At least 28 dB |
| Rotation | 20-60 rpm | 5 or 2.5 s per scan |
| Antenna height | 10-50 m above the sea | Not given |
| IF bandwidth | 6-28 MHz (short pulse); 2.5-6 MHz (medium and long pulse) | 15, 0.3, and 0.045 MHz |
| Noise figure | 3-8.5 dB | Not given |
| Minimum discernible signal | -126 dBm | Not given |
| Protection criterion | I/N = -6 dB | I/N = -6 dB |

M.1460-2 recommends I/N = -6 dB for these radars, even with several interferers. Its Annex 3 adds that tested ship radars withstood low-duty-cycle pulsed interference at high I/N, because their scan-to-scan and pulse-to-pulse correlators remove asynchronous pulses (ITU-R M.1372). NEXRAD's pulses are low duty cycle (0.21% at most), so the analysis also reports the distance at the pulsed tolerance the trials measured, as a sensitivity case.

The Recommendation's trials didn't include pleasure-craft radars, which lack that processing; this analysis doesn't model them.

## 4. Protection levels for pulsed interference

Both radars send short pulses with low duty cycles, so each tolerates the other's pulses better than noise-like interference. By the method in ITU-R M.1849-3, NEXRAD tolerates a magnetron ship radar's pulses at a peak I/N of +7 to +20 dB, and a solid-state ship radar's longer pulses at -6 to 0 dB. Ship radars tested for ITU-R M.1460-2 showed no effect from 1-2 µs pulses at 0.1% and 1% duty cycle up to +30 to +40 dB peak I/N. Every I/N in this section is the peak interference power in the victim's receiver bandwidth over its noise power, for one interferer.

### 4.1 NEXRAD as the victim

M.1849-3 (Section 8.4.2) sets the pulsed-interference level so that it degrades the radar's averaged estimates as much as constant interference at -10 dB does:

```latex
I/N_{pulse} = I/N_{constant} - 10\log_{10}(f_c), \qquad f_c = PRF_i\,(\tau_i + \tau_g)
```

Here f\_c is the fraction of NEXRAD range gates an interfering pulse lands in (ITU-R RS.1280, Section 3.2, for pulse rates that aren't integer multiples), PRF\_i and τ\_i are the interferer's pulse rate and width, and τ\_g is NEXRAD's gate width, taken as its pulse width. When the interfering pulse is much longer than the gate, f\_c is close to the interferer's duty cycle.

| Interferer (M.1460-2) | Pulse width | Pulse rate | Duty cycle | Peak I/N, NEXRAD short pulse (1.57 µs gate) | Peak I/N, NEXRAD long pulse (4.71 µs gate) |
| --- | --- | --- | --- | --- | --- |
| Magnetron, shortest pulse (Table 4) | 0.05 µs | 4,000 Hz | 0.02% | +11.9 dB | +7.2 dB |
| Magnetron, longest pulse (Table 4) | 1.2 µs | 375 Hz | 0.045% | +19.8 dB | +16.5 dB |
| Solid-state No. 3B, short (Table 1) | 0.1 µs | 83,333 Hz | 0.83% | -1.4 dB | -6.0 dB |
| Solid-state No. 3B, medium (Table 1) | 5 µs | 15,625 Hz | 7.8% | -0.1 dB | -1.8 dB |
| Solid-state No. 3B, long (Table 1) | 33 µs | 2,740 Hz | 9.0% | +0.2 dB | -0.1 dB |

The solid-state rows treat its pulses as unmodulated. They are frequency-modulated over 3-15 MHz, so each pulse spends only part of its length in NEXRAD's 636 kHz filter, and the true f\_c is smaller and the tolerable I/N higher. The rows here are the stricter case. Data: `outputs/emc/pulsed_in_criteria_rev1.csv` (Python and MATLAB agree to 0.05 dB).

Tests support the method's direction but not its exact values. In Report ITU-R M.2136, Annex 2, a C-band weather radar with -113.8 dBm noise first showed 0.6-1 µs pulses at 200 Hz to 3 kHz at -92.8 to -93.8 dBm, an I/N of about +20 dB, and 20 µs pulses at -103.8 to -107 dBm, about +7 to +10 dB. The report notes these differ from the formula, likely because that radar's pulse rate varies. Annex 1 of the same report tested a 750 kW, 630 kHz S-band radar of the NEXRAD class with noise-like signals only, which supports -10 dB for that kind of interference. M.1849-3 itself calls the formula not fully validated.

The formula ignores antenna scanning: a ship's fan beam sweeps past NEXRAD for a few milliseconds each rotation. This analysis assumes main beam to main beam coupling throughout, so it takes no credit for scanning.

### 4.2 The ship radar as the victim

NEXRAD's duty cycle is 0.05-0.21% (1.57 µs pulses at 318-1,304 Hz; 4.71 µs at 318-452 Hz), and its pulses are longer than a ship receiver's 2.5-28 MHz filter needs, so they arrive unstretched. That sits inside the range M.1460-2 Annex 3 tested: 1 and 2 µs pulses at 0.1% and 1% duty cycle had no effect on Radar B up to +40 dB and on Radar C up to +30 dB (Table 10; the text gives 40 dB for Radar C). Those were the highest levels tested, so the true tolerance may be higher.

The tolerance comes from the scan-to-scan and pulse-to-pulse correlators in ITU-R M.1372, which drop pulses that don't repeat in step with the radar's own. M.1460-2 still recommends -6 dB as the protection level, and says radars without that processing, such as pleasure-craft radars, may need more protection. Report ITU-R M.2414 found the same pattern in an air traffic control radar: interference at 0.2-0.3% duty cycle had no effect up to +40 dB (from the radar\_in candidate criterion).

### 4.3 Proposed levels for this analysis

These are proposals for Nick's decision:

| Victim | Base case | Sensitivity cases |
| --- | --- | --- |
| NEXRAD | M.1849-3 pulsed level for each interferer mode: +7.2 dB for a magnetron, -6.0 dB for a solid-state radar (the lowest row of each type) | -10 dB (constant-interference level); the highest row of each type (+19.8 dB; +0.2 dB) |
| Ship radar | -6 dB (M.1460-2 recommends 3) | +30 dB (lowest no-effect level measured for pulsed interference) |

No level used is stricter than -6 dB except -10 dB, which comes from ITU-R M.1849-3.

### 4.4 Simulation check

A Monte Carlo simulation of each radar's processing supports the NEXRAD levels and finds no loss of detection in the ship radars. The simulation is `radar_to_radar_sim_rev2` from the radar\_in repository (code at commit 6694e30, results at 509f7a4). It sends asynchronous pulses through the victim's IF and matched filters, then scores NEXRAD's reflectivity and velocity estimates (16 pulses each) or a ship radar's detections, with median-of-3 pulse rejection standing in for the ship's correlators. Coupling is main beam to main beam for the whole dwell. Each case runs 50 trials at peak I/N from -20 to +70 dB in 5 dB steps.

**Reference checks.** Before the new cases, the simulation and the formula were run against published measurements:

- **Weather radar.** Against the five unmodulated pulse trains measured in M.2136 Annex 2, the M.1849-3 formula is off by -10.5 to +3.6 dB (RMS error 5.8 dB). The simulation, scored as 1% of range cells with a reflectivity error over 1 dB, is 3 to 18 dB below the measurements in every case (RMS error 11.4 dB), so it is a conservative bound. Scored at 10% of cells, it doesn't reach the criterion in two of the five cases.
- **Ship radar.** For M.1460-2 Radars B and C hit by 1 and 2 µs pulses at 0.1% and 1% duty cycle, the simulation shows no drop in detection up to +70 dB, which agrees with the trials' no-effect result to +30 and +40 dB. At 1% duty cycle it shows false alarms rising tenfold from +9 to +33 dB, an effect the trials didn't score.

**Ship radars into NEXRAD.** Peak I/N at which NEXRAD's estimates degrade, over all modes of each interferer type:

| Interferer | NEXRAD pulse | M.1849-3 formula | Simulation, 10% of cells | Simulation, 1% of cells |
| --- | --- | --- | --- | --- |
| Magnetron, 13 modes (Tables 4-7) | Short | +11.8 to +19.9 dB | +13.7 dB to above +70 dB | +1.8 to +13.3 dB |
| Magnetron, 13 modes (Tables 4-7) | Long | +7.2 to +16.6 dB | +7.5 to +51.0 dB | +0.4 to +8.1 dB |
| Solid-state No. 3B, unmodulated | Short | -1.5 to +0.2 dB | -1.4 to +0.5 dB | ≤ -6 dB |
| Solid-state No. 3B, unmodulated | Long | -6.0 to -0.1 dB | -4.7 to +1.2 dB | ≤ -6 to -4.9 dB |
| Solid-state No. 3B, 15 MHz FM | Short | -0.1 to +0.2 dB | +5.9 to +16.6 dB | -3.8 to +2.6 dB |
| Solid-state No. 3B, 15 MHz FM | Long | -1.8 to -0.1 dB | +1.9 to +9.5 dB | -4.6 to +1.0 dB |

Simulated values below -6 dB are shown as "≤ -6 dB", following this project's convention for values not from ITU-R documents.

- At the degradation level M.1849-3 assumes (10% of cells), the simulation is never stricter than the formula for magnetrons: it is 0.3 to 34 dB higher, with a median of 8.9 dB. In the case that sets the base level, the shortest magnetron pulse into NEXRAD's long pulse, the two agree: +7.5 dB simulated against +7.2 dB.
- Scored at 1% of cells, the simulation sits 6.6 to 10.3 dB below the formula in every magnetron case. Given the reference check, the paper treats that as a lower bound, not an estimate.
- For the solid-state radar, the simulation is within 1.5 dB of the formula when the pulses are unmodulated. A 15 MHz frequency sweep raises the tolerable level by 2 to 16 dB, so the unmodulated rows are the strict case.

**NEXRAD into ship radars.** Across the 11 ship radar modes of M.1460-2 Tables 5-7 and NEXRAD's short and long pulses, the simulation shows no loss of detection up to +70 dB. False alarms rose tenfold in only one case: Radar A's 1.2 µs mode, with 7 pulses per dwell, at +13.7 dB.

The simulation supports the base levels in Section 4.3. Data: `results/nexrad_ship_*_rev1.csv` in radar\_in, copied to `outputs/emc/radar_in_sim/` in matlab\_shipping\_gis.

## 5. Method

The separation distance is the distance at which the ITM area-mode loss equals the loss the pair needs. For each direction, frequency offset, and coupling case, the needed loss is:

```latex
L_{req}(\Delta f) = P_t - L_t + G_t + G_r - L_r - FDR(\Delta f) - \left(N + I/N\right)
```

Here P\_t is peak transmitter power (dBm), L\_t and L\_r are transmit and receive line losses (dB), G\_t and G\_r are the antenna gains toward each other (dBi), FDR is the frequency-dependent rejection (dB), N is the victim's noise power (dBm), and I/N is its protection criterion (dB). The analysis solves ITM area loss L(d, p) = L\_req for the distance d at time percentage p.

1. **Frequency-dependent rejection.** FDR follows ITU-R SM.337: the interferer's emission spectrum, weighted by the victim's selectivity, integrated over frequency. Emission spectra come from pulse width and rise time (the NTIA Manual radar emission envelope), checked against the published -3, -20, and -40 dB points. Selectivity comes from the published IF bandwidths and NEXRAD's filter points. FDR at 0 MHz includes on-tune rejection, which is large when a wide magnetron pulse meets NEXRAD's 636 kHz filter.
2. **Antenna coupling.** Main beam to main beam (decided November 22): each radar's peak gain toward the other, NEXRAD 46.1 dB at 3050 MHz and the ship radar 26-28 dBi (27.5 dBi for No. 3B). Sidelobe coupling and scan statistics aren't used. NEXRAD's 0.5° lowest tilt and the ship's 24-30° fan beam both reach the horizon, so main-beam coupling is possible.
3. **Propagation.** ITM v1.4 area mode from `matlab_itm` (`itm_area_rev1`), which matches the NTIA C++ code to within 4 × 10^-13 dB. Base settings: 3050 MHz (3020 and 3080 MHz as checks); NEXRAD 10-35 m and ship 10-50 m antenna heights; terrain irregularity 0 m (sea path); sea-water ground; maritime temperate over sea climate; horizontal polarization; 50% confidence. Time percentages 50%, 10%, 1%, and 0.1%, because short-term ducting over water sets the long distances.
4. **Distance.** The distance at which L(d, p) = L\_req, by root finding over 1-2,000 km, ITM's valid range. Above 2,000 km, the paper reports "beyond 2,000 km".
5. **Frequency sweep.** Repeat from 0 MHz to the offset at which the needed separation falls to the 1 km minimum, for both directions.

Sensitivity cases vary one input at a time: the protection levels in Section 4.3; the parameter ranges in Sections 2 and 3; and coastal land paths with terrain irregularity of 30 and 90 m.

## 6. Results

Co-channel and main beam to main beam, every pair of a NEXRAD and a ship radar needs hundreds of kilometers of separation: 382 to 1,125 km for 50% of the time, and up to 1,615 km for 0.1% of the time. NEXRAD interfering with the ship radar sets the longer distance for both ship radar types, at the ship radar's -6 dB protection level. Frequency offset inside 3020-3080 MHz shortens the distances but doesn't remove them (Section 6.2).

### 6.1 Co-channel separation

The analysis computes the required loss for every ship radar mode (13 magnetron modes from M.1460-2 Tables 4-7 and the 3 solid-state No. 3B modes) against NEXRAD's short and long pulses, in both directions: 64 pairs. On-tune rejection follows ITU-R SM.337-6, equation 6. The NEXRAD protection levels are the pulsed levels in Section 4.1; the ship radar level is -6 dB. ITM area mode uses the base settings in Section 5 at 3050 MHz, with 30 m antennas on both radars.

The table gives the pair with the largest required loss for each direction and ship radar type:

| Direction | Ship radar | Pair that sets the distance | Required loss | 50% of time | 10% | 1% | 0.1% |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Ship into NEXRAD | Magnetron | 1.2 µs, 375 Hz, 75 kW pulse into NEXRAD short pulse | 244.0 dB | 606 km | 746 km | 926 km | 1,061 km |
| Ship into NEXRAD | Solid state | No. 3B 5 µs FM pulse into NEXRAD long pulse | 264.3 dB | 872 km | 1,021 km | 1,209 km | 1,349 km |
| NEXRAD into ship | Magnetron | NEXRAD short pulse into the IMO radar's 2.5 MHz, 3 dB noise figure receiver | 273.9 dB | 1,003 km | 1,155 km | 1,346 km | 1,487 km |
| NEXRAD into ship | Solid state | NEXRAD long pulse into No. 3B's 0.3 MHz receiver | 282.6 dB | 1,125 km | 1,279 km | 1,472 km | 1,615 km |

Over all modes, the 50% distance is 382-606 km for magnetrons into NEXRAD, 639-872 km for the solid-state radar into NEXRAD, 840-1,003 km for NEXRAD into magnetron radars, and 889-1,125 km for NEXRAD into the solid-state radar. Distances are rounded to the nearest kilometer; no pair reached ITM's 1 km or 2,000 km limits.

The solid-state radar needs more separation than a magnetron in both directions. Into NEXRAD, its 170 kW peak power and 8-9% duty cycle leave NEXRAD only -2 to 0 dB of pulsed tolerance, against +7 to +20 dB for a magnetron. As a victim, its 0.3 MHz receiver has low noise and passes all of NEXRAD's long pulse.

### 6.2 Separation against frequency offset

Frequency separation inside 3020-3080 MHz shortens the distances but doesn't remove them. At 60 MHz, the widest offset in the band, the separation for 50% of the time is still 91 km for a magnetron into NEXRAD and 465 km for the solid-state radar into NEXRAD, at NEXRAD's pulsed protection level. NEXRAD into a ship radar still needs 433-533 km at the ship's -6 dB level, or 78-166 km at +30 dB.

The frequency-dependent rejection follows ITU-R SM.337-6 (equations 3 to 6): FDR = OTR + OFR. The on-tune part is the one in Section 6.1; the off-frequency part is the integral of the interferer's emission spectrum against the victim's selectivity at each offset. Each curve is the largest distance over every mode pair of that radar type.

&#91;image: Two line charts of separation distance for 50% of the time against frequency offset from 0 to 150 MHz, main beam to main beam. Left, ship radar into NEXRAD: magnetron radars fall from 606 km co-channel to 91 km at 60 MHz with NEXRAD's pulsed protection level (1,003 to 302 km at -10 dB); the solid-state radar falls only from 872 to 465 km (984 to 564 km at -10 dB). Right, NEXRAD into ship radar: from 1,003 to 533 km (magnetron) and 1,125 to 433 km (solid state) at the ship's -6 dB level, and from 531 to 166 km and 638 to 78 km at +30 dB. A dotted line marks 60 MHz, the widest offset inside 3020-3080 MHz.\]

**Figure 1. Separation for 50% of the time against frequency offset, main beam to main beam, ITM area mode.** Solid lines use each victim's base protection level (NEXRAD's M.1849-3 pulsed level; the ship radar's -6 dB); dashed lines use the other level (NEXRAD -10 dB; the ship radar +30 dB). Source: `outputs/emc/offset_envelope_rev1.csv`; figure code `python/emc_offset_figure.py`.

| Direction | Ship radar | Victim protection level | 0 MHz | 10 MHz | 30 MHz | 60 MHz | 60 MHz, 0.1% of time |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Ship into NEXRAD | Magnetron | Pulsed level (M.1849-3) | 606 km | 399 km | 212 km | 91 km | 447 km |
| Ship into NEXRAD | Magnetron | -10 dB | 1,003 km | 661 km | 428 km | 302 km | 699 km |
| Ship into NEXRAD | Solid state | Pulsed level (M.1849-3) | 872 km | 657 km | 537 km | 465 km | 901 km |
| Ship into NEXRAD | Solid state | -10 dB | 984 km | 767 km | 639 km | 564 km | 1,014 km |
| NEXRAD into ship | Magnetron | -6 dB | 1,003 km | 846 km | 682 km | 533 km | 979 km |
| NEXRAD into ship | Magnetron | +30 dB | 531 km | 398 km | 273 km | 166 km | 521 km |
| NEXRAD into ship | Solid state | -6 dB | 1,125 km | 807 km | 575 km | 433 km | 862 km |
| NEXRAD into ship | Solid state | +30 dB | 638 km | 368 km | 197 km | 78 km | 431 km |

Three modeling choices shape the curves at large offsets:

- **Solid-state emission skirts.** M.1460-2 gives no rise time for Radar No. 3B, so its frequency-modulated spectrum falls only 20 dB per decade outside its 3 MHz sweep. That keeps the solid-state curves into NEXRAD high; a measured spectrum would likely lower them.
- **Ship receiver floor.** Each ship receiver's selectivity stops at 60 dB, the spurious response rejection in M.1460-2 Table 5. That caps the off-frequency rejection, so NEXRAD into the solid-state radar flattens at 380 km (-6 dB) beyond about 80 MHz, and both radar types flatten near 72-74 km at +30 dB.
- **Radio horizon.** With 30 m antennas, ITM's loss rises steeply near 70 km, so several curves level off there.

The NEXRAD receiver uses its matched filter and the ROC front-end filter points; the emissions use the trapezoidal-pulse envelope checked against the published spectrum points (Section 5). Data: `outputs/emc/offset_ofr_rev1.csv`, `offset_separation_rev1.csv` (every pair, offset, and time percentage), and `offset_envelope_rev1.csv`; run log `outputs/rerun_logs_20261122/emc_offset.log` (code at 8109a4e).

### 6.3 Sensitivity

For the four co-channel pairs in the Section 6.1 table, one input changed at a time:

| Change | Effect on the 50% distance |
| --- | --- |
| Ship radar protection +30 dB (pulsed tolerance) instead of -6 dB | NEXRAD into ship: 1,003 to 531 km (magnetron); 1,125 to 638 km (solid state) |
| NEXRAD protection -10 dB (constant interference) instead of the pulsed level | Magnetron into NEXRAD: 606 to 1,003 km; solid state: 872 to 984 km |
| Continental temperate climate instead of maritime over sea | 46-50 km shorter at 50% of time; 293-314 km shorter at 0.1% |
| Surface refractivity 350 instead of 301 N-units | 44-60 km longer |
| Antennas 10 m and 10 m, or 35 m and 50 m | Within 9 km |
| 3020 or 3080 MHz instead of 3050 MHz | Within 2 km |
| Coastal path, terrain irregularity 30 or 90 m | Within 3 km |
| NEXRAD 650 kW, 2.5 dB line loss, 45.5 dB gain | 8-24 km shorter |
| Ship line losses of 2 dB each way (assumed) | 25-28 km shorter |

The protection levels move the distances far more than any propagation or equipment input does. The +30 dB ship tolerance comes from trials that found no effect at the highest level tested (Section 4.2); if accepted as the base, it roughly halves the distance in the direction that sets it.

### 6.4 Checks

- MATLAB and Python required losses agree to 0.01 dB for all 64 pairs (`test_emc_cochannel_rev1.m`), and a hand calculation of one pair (NEXRAD short pulse into the IMO radar's 2.5 MHz receiver, 273.87 dB) matches. MATLAB and Python off-frequency rejection agree to 0.01 dB for all 64 pairs at all 136 offsets (`test_emc_offset_rev1.m`). The emission envelopes meet NEXRAD's published points (-20 dB at 2.3 MHz, -40 dB at 7.26 MHz, -80 dB at 62 MHz) and the magnetron's -20 dB point within 3 dB.
- ITM area-mode loss falls below free-space loss by at most 0.4 dB at 50% of time and 3.2 dB at 0.1%, near 36 km, where the path passes from line of sight to diffraction. All separation distances are beyond 380 km, so this doesn't affect them.
- matlab\_itm matches the NTIA C++ ITM to within 4 × 10^-13 dB (its own test suite); run at commit a59880a.

Data: `outputs/emc/cochannel_required_loss_rev1.csv`, `cochannel_separation_rev1.csv`, `cochannel_sensitivity_rev1.csv`, and `cochannel_itm_check_rev1.csv` in matlab\_shipping\_gis; run log `outputs/rerun_logs_20261122/emc_cochannel.log` (code at 736171e). Parameters: `data/emc/radar_params_rev1.csv` and `radar_modes_rev1.csv`, each value with its source.

## 7. Limits and open questions

- **Area mode, not real paths.** Area mode uses no terrain profile, so the distances apply to a generic sea or coastal path, not to a particular NEXRAD site. Point-to-point paths are out of scope for this paper.
- **Representative, not measured, characteristics.** Ship radar emission spectra and selectivity curves come from ITU-R tables, not measurements. A measured spectrum for a common S-band magnetron radar would tighten the FDR.
- **Protection criteria for pulsed interference.** The M.1849-3 pulsed formula isn't fully validated, and the ship radar trials stopped at +30 to +40 dB without finding a limit (Section 4). Measurements of NEXRAD with magnetron pulses would settle the NEXRAD side.
- **One interferer.** The analysis treats one ship and one NEXRAD; several ships near a coastal NEXRAD would add.
- **Navy and other radiolocation radars** in 2900-3100 MHz are outside this paper.
- **Open:** a published reference case to reproduce before the first new run.

## Sources

- NOAA Radar Operations Center, [NEXRAD Technical Information](https://roc.noaa.gov/public-documents/wsr88d/NEXRAD-Technical-Information.pdf).
- [Recommendation ITU-R M.1849-3](https://www.itu.int/dms_pubrec/itu-r/rec/m/R-REC-M.1849-3-202302-I!!PDF-E.pdf) (02/2023), Technical and operational aspects of ground-based meteorological radars.
- [Recommendation ITU-R M.1460-2](https://www.itu.int/dms_pubrec/itu-r/rec/m/R-REC-M.1460-2-201502-I!!PDF-E.pdf) (02/2015), Technical and operational characteristics and protection criteria of radiodetermination radars in the frequency band 2900-3100 MHz.
- [Report ITU-R M.2136](https://www.itu.int/dms_pub/itu-r/opb/rep/R-REP-M.2136-2009-PDF-E.pdf) (2009 edition), Theoretical analyses and testing results pertaining to the determination of relevant interference protection criteria of ground-based meteorological radars.
- Recommendation ITU-R RS.1280 (fraction of coinciding pulses, Section 3.2), as cited in M.1849-3.
- Report ITU-R M.2414, Table 4, as summarized in the radar\_in candidate criterion (`docs/candidate_criterion_rev0.md`).
- [matlab\_itm](https://github.com/nicklasorte/matlab_itm), MATLAB port of NTIA ITM v1.4 (area mode: `itm_area_rev1.m`).
- Recommendations ITU-R SM.337 (frequency-dependent rejection), M.1851 (radar antenna patterns), and M.1372 (radar-to-radar interference suppression), cited for method; values to be taken from them during the analysis.
