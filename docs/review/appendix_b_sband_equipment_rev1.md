## Appendix B. S-band radar equipment on large ships

This appendix gives the technical parameters of the S-band navigation radars that large ships carry, for use in the EMC analysis. It draws on manufacturer data sheets for 23 S-band ship radar models from seven manufacturers, and on [Recommendation ITU-R M.1460-1](https://www.itu.int/dms_pubrec/itu-r/rec/m/R-REC-M.1460-1-200603-S!!PDF-E.pdf), which gives the characteristics and protection criterion of radiodetermination radars in 2900-3100 MHz. Each model, its parameters, and the link to its source are in `data/ship_radar_models.csv`. The performance standard for these radars is IMO Resolution MSC.192(79).

### B.1 Two kinds of transmitter

S-band ship radars use one of two transmitters, and the two differ by more than a factor of 100 in peak power:

- **Magnetron radars** transmit short, high-power pulses on one frequency that the magnetron sets, anywhere within a tolerance around 3050 MHz. Of the 23 models, 12 use a magnetron; for 5 of them the data sheet doesn't name the transmitter, and the type follows from the peak power and pulses.
- **Solid-state radars** transmit at less than 1% of a magnetron's peak power. They make up for it with long pulses of 4.6 µs to 18.3 µs, against 1.2 µs at most for magnetron radars, and a frequency sweep inside each long pulse (pulse compression). They work on two to eight channels, fixed by option or selectable. Of the 23 models, 9 are solid-state. Two models don't state a transmitter.

No public source gives the share of ships fitted with each kind. ITU-R M.1460-1 (2006) describes magnetron radars only.

Table B-1 summarizes the parameters by transmitter type. Ranges cover the models that state a value; Table B-2 lists each model.

**Table B-1. S-band ship radar parameters by transmitter type**

| Parameter | Magnetron radars (12 models) | Solid-state radars (9 models) | ITU-R M.1460-1 range |
| --- | --- | --- | --- |
| Frequency | 3050 MHz ± 20 MHz or ± 30 MHz, one frequency per magnetron | 3035 MHz to 3074 MHz nominal, on two channels; one model 2900 MHz to 3100 MHz on eight | 3020 MHz to 3080 MHz |
| Peak power | 30 kW (one model 60 kW) | 200 W to 250 W | 30 kW to 75 kW |
| Pulse length | 0.06 µs to 1.2 µs | 0.07 µs to 1.14 µs short pulse, plus a 4.6 µs to 18.3 µs long pulse swept over 8 MHz | 0.05 µs to 1.2 µs |
| Pulse repetition frequency | 500 Hz to 3,000 Hz | 640 Hz to 2,280 Hz | 375 Hz to 4,000 Hz |
| Maximum duty cycle | 0.065% to 0.075% | 2.1% | Not given |
| Average power | About 20 W (30 kW at 0.065% to 0.075%, computed) | 5.8 W or less (data sheet) | Not given |
| Antenna length | 12 ft (3.7 m); 9 ft and 10 ft options | 8 ft (2.4 m) to 12.8 ft (3.9 m); most 12 ft (3.7 m) | Not given |
| Horizontal beamwidth | 1.8° to 2.3° | 1.8° to 2.7° | 1.0° to 4.0° |
| Vertical beamwidth | 25° to 26° | 25° | 24° to 30° |
| Sidelobes, within 10° of the main beam | -24 dB to -26 dB | -24 dB to -26 dB | -23 dB to -28 dB |
| Sidelobes, beyond 10° | -30 dB | -30 dB | -31 dB to -32 dB |
| Antenna gain | 28 dBi (one model states it) | Not stated | 26 dBi to 28 dBi |
| Rotation rate | 21 rpm to 27 rpm; 42 rpm to 45 rpm for fast craft | 24 rpm; 42 rpm to 48 rpm for fast craft | 20 rpm to 60 rpm |
| Polarization | Horizontal | Horizontal | Horizontal (predominant) |
| Receiver IF bandwidth | 3 MHz to 40 MHz, narrower for longer pulses | 20 MHz to 30 MHz | 6 MHz to 28 MHz short pulse; 2.5 MHz to 6 MHz medium and long pulse |
| Receiver noise figure | 4 dB to 7.5 dB | 4 dB or less | 3 dB to 8.5 dB |
| Protection criterion | I/N of -6 dB, aggregate (ITU-R M.1460-1) | Same | I/N of -6 dB |

Source: manufacturer data sheets in `data/ship_radar_models.csv`; ITU-R M.1460-1. Average power for magnetron radars is peak power times the stated maximum duty cycle.

### B.2 What the parameters mean for the zones

- **Frequency.** Every model with a stated frequency transmits between 3020 MHz and 3080 MHz except the eight-channel model, which can use the whole band. The EMC analysis sets the zone distance for each frequency range.
- **Antenna.** The vertical beam is about 25° wide and the antenna rotates through 360° about every 2 to 3 seconds, so the main beam sweeps any direction briefly on each turn. The IMO performance standard assumes an antenna height of 15 m for its detection tests; real mast heights vary by ship.
- **Receiver.** Magnetron and solid-state receivers have different bandwidths and noise figures, so the same interfering signal gives a different I/N in each. An EMC analysis can treat the two kinds as separate victim classes.
- **Open items.** Ten models don't state their frequency, and only one states its antenna gain. The radar models list is incomplete for Furuno solid-state models (NXT and SSD) and Wärtsilä (see the review notes in `docs/review/sband_radar_models_rev1.md`).

**Table B-2. S-band radar models in the data set**

| Manufacturer | Model | Transmitter | Frequency | Peak power | Antenna length | Horizontal beamwidth | Rotation rate | Source confidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Furuno | FAR-2238S | Magnetron | 3050 MHz ± 30 MHz | 30 kW | 12 ft | 1.8° | 24 rpm; 42 rpm fast craft | High |
| Furuno | FAR-2238S-NXT | Solid-state | 3043.75 MHz and 3063.75 MHz, or 3053.75 MHz and 3073.75 MHz (± 5 MHz) | 250 W | 12 ft | 1.8° | 24 rpm; 42 rpm fast craft | High |
| Furuno | FAR-2338S | Magnetron | Not stated | 30 kW | 12 ft | Not stated | Not stated | Medium |
| Furuno | FAR-2338S-NXT | Solid-state | Not stated | 250 W | Not stated | Not stated | Not stated | Medium |
| Furuno | FAR-3230S | Magnetron | Not stated | 30 kW | 12 ft | Not stated | Not stated | Medium |
| Furuno | FAR-3230S-SSD | Solid-state | Not stated | 250 W | 12 ft | Not stated | Not stated | Medium |
| Furuno | FAR-2137S | Magnetron | 3050 MHz ± 30 MHz | 30 kW | 10 ft or 12 ft | 2.3° (10 ft); 1.8° (12 ft) | 21 rpm or 26 rpm; 45 rpm option | High |
| Furuno | FAR-2837S | Magnetron | 3050 MHz ± 30 MHz | 30 kW | 10 ft or 12 ft | 2.3° (10 ft); 1.8° (12 ft) | 21 rpm or 26 rpm; 45 rpm fast craft | High |
| Furuno | FR-2135S | Magnetron | 3050 MHz ± 30 MHz | 30 kW | 9 ft or 12 ft | 2.3° (9 ft); 1.9° (12 ft) | 24 rpm | High |
| Furuno | FAR-2268DS | Magnetron | Not stated | 60 kW | 10 ft or 12 ft | Not stated | Not stated | Medium |
| JRC | JMR-9230-S | Magnetron (from power and pulses) | 3050 MHz ± 20 MHz | 30 kW | 12 ft | 1.9° | 24 rpm | High |
| JRC | JMR-9230-S3 | Magnetron (from power and pulses) | 3050 MHz ± 20 MHz | 30 kW | Not stated | 1.9° | 24 rpm | High |
| JRC | JMR-9272-S | Solid-state | 3035 MHz, and 3060 MHz or 3065 MHz (± 4 MHz) | 250 W | 12 ft | 1.9° | 24 rpm | High |
| JRC | JMR-9282-S | Solid-state | 3035 MHz, and 3060 MHz or 3065 MHz (± 4 MHz) | 250 W | 8 ft | 2.7° | 24 rpm | High |
| JRC | JMR-9282-SH | Solid-state | 3035 MHz, and 3060 MHz or 3065 MHz (± 4 MHz) | 250 W | 8 ft | 2.7° | 48 rpm | High |
| JRC | JMR-9330-S | Not stated | Not stated | Not stated | Not stated | Not stated | Not stated | Medium |
| JRC | JMR-9372-S | Solid-state | Not stated | 250 W | Not stated | Not stated | Not stated | Medium |
| JRC | JMR-9382-S | Solid-state | Not stated | 250 W | Not stated | Not stated | Not stated | Medium |
| Kelvin Hughes (Hensoldt) | SharpEye S-band | Solid-state | 2900 MHz to 3100 MHz, eight selectable channels | 200 W | 12.8 ft | Not stated | Not stated | High |
| Kongsberg | K-Bridge S-band radar | Magnetron (from power and pulses) | 3050 MHz ± 20 MHz | 30 kW | 12 ft | 1.9° | 27 rpm | High |
| Raytheon Anschutz | Synapsis Radar S-band | Magnetron (from power and pulses) | Not stated | 30 kW | 12 ft | 1.9° | 22 rpm | Medium |
| Sperry Marine | VisionMaster FT S-band | Magnetron (from power) | Not stated | 30 kW | 12 ft | Not stated | Not stated | Medium |
| Wärtsilä (Transas) | NAVI-RADAR 4000 S-band | Not stated | 3050 MHz ± 20 MHz | Not stated | 12 ft | Not stated | Not stated | Low |

Source: manufacturer data sheets and product pages linked in `data/ship_radar_models.csv`. "Source confidence" is the rating recorded in that file for how directly its sources state the values.
