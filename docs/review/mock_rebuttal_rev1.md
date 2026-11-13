**MOCK FILING FOR INTERNAL REVIEW — FICTIONAL PARTY — DRAFT//PRE-DECISIONAL**

*This document is a practice exercise. It imitates the reply comments that a skeptical outside party might file. The "Coastal Spectrum Coalition" is fictional and stands for no real company, association, or person. The proceeding is hypothetical. Every statement about the working paper cites its section, table, figure, or a file in the `matlab_shipping_gis` repository. Statements about the outside world cite public sources.*

---

**Before the [Hypothetical] Federal Spectrum Proceeding**

In the Matter of: Large-Ship Routes and Frequency-Dependent Zones for the 2900–3100 MHz Maritime Radionavigation Band (2.7 GHz Study Working Paper, Rev. 1, November 10, 2026)

**Reply Comments of the Coastal Spectrum Coalition**

---

## Summary

The Coastal Spectrum Coalition (the "Coalition") supports careful protection of maritime radionavigation. Ships that carry S-band radar need to see the coast, the channel, and each other. We don't ask anyone to weaken that protection. We ask that the zones protect the radars where they really operate, at distances that an interference analysis supports, and no farther.

The working paper's route data are careful. The authors filter public AIS data, check their length proxy against registry tonnage, compare two independent programs, and test whether the routes reach 73 deep-draft ports. We credit that work, and we don't dispute that large ships use the coasts, the Great Lakes, and a few deep rivers.

Our concern is the step from routes to zones. Five problems, taken together, make the example zones much larger than the routes alone justify:

1. **A "25 km zone" isn't 25 km from the ships.** The paper treats all water within 25 km of a route cell as "ship water." It then measures land distance from the coastline next to that water (Section 3.1). Land in the "25 km" zone can sit up to about 50 km from any ship. By our check of the paper's own outputs, more than a fifth of the land in the 25 km zone is more than 25 km from every route cell.
2. **The route rule tests presence, not interference.** A cell that four ships crossed in a year gets the same zone as a cell that 3,000 ships crossed. No metric links the threshold to harm.
3. **Alaska's offshore lanes rest on weak agreement between datasets.** Whole 625 km² satellite hexagons become ship water based on a cutoff that matches the shore-based routes at a Jaccard index of only 0.57.
4. **Carriage isn't use.** The paper assumes that ships required to carry a 3 GHz radar, or a second 9 GHz radar, operate an S-band radar near the U.S. coast. It cites no evidence for this.
5. **The example distances have no basis.** Section 2, the EMC analysis, is empty. Yet the repository already writes zone files named by frequency band, including a 100 km zone for 3030–3070 MHz.

We ask for eleven specific changes (Section 8). None requires new data. Most require only a different setting in code the authors already wrote.

## 1. The shore-mode method inflates every zone

### 1.1 What the method does

Section 3.1 describes four steps. Step 1 says: "Water within 25 km of a route cell counts as ship water." Step 2 says: "Land distance is measured from the Census coastline where it faces ship water." The code confirms both. In `shipping_zone_rev1.m`, lines 206–217, water within `p.shore_link_km` of a route cell is set to distance zero. Coastline cells within that same 25 km become the reference for land distance. `init_shipping_zone_rev1.m`, line 74, sets `p.shore_link_km=25`.

The result is a two-stage buffer. The first 25 km is added before the zone distance starts. A reader who sees "Zone distance (km): 25" in Table 7 will think the zone ends 25 km from the ships. It doesn't.

### 1.2 How large the effect is

The repository already contains a ships-mode option (`p.zone_mode='ships'`) that measures distance from the route cells themselves. The paper doesn't report it. We estimated ships-mode land area from the paper's own route shapefile (`outputs/2024_2025/shipping_zone_2024_2025_routes.shp`) and compared it with the shore-mode land shapefiles on the same 0.05° grid:

| Distance | Ships mode (km²) | Shore mode, same grid (km²) | Shore mode adds |
| --- | --- | --- | --- |
| 25 km | 305,283 | 384,584 | 26% |
| 50 km | 645,307 | 708,120 | 10% |
| 100 km | 1,271,924 | 1,312,010 | 3% |

Inside the shore-mode 25 km land zone, the median distance to the nearest route cell is 16.9 km. The 90th percentile is 32.4 km, and the maximum is 49.1 km. About 84,000 km² of that zone, more than a fifth of it, lies farther than 25 km from any route cell. (The paper's reported 25 km area, 404,668 km² in the README, is computed at 0.01°; our coarser grid gives 384,584 km² for the same shapefile, so we compare like with like.)

The paper's own port checks show the effect. Mayaguez, Puerto Rico, is 29.7 km from the nearest route cell (Section 6.1), yet it lies inside the 25 km zone (`outputs/2024_2025/prusvi/shipping_zone_prusvi_2024_2025_port_check.csv`). Kawaihae, Hawaii, is 24.8 km from the nearest route cell, and Section 4.2 notes that "Every Hawaii port lies inside even the 25 km zone."

### 1.3 Why this matters

The 25 km shore link is not an interference result. It is a fixed setting chosen before any EMC analysis. Its effect is largest at the smallest distance, which is the distance most likely to apply to the parts of the band where sharing is easiest. If the EMC analysis later finds that 25 km protects the radars, shore mode would still give a zone that reaches about 50 km.

We ask the authors to report ships-mode zones as the primary result, or at least beside shore mode with land areas. If they keep shore mode, they should rename it to describe what it is, for example "land within X km of shoreline that lies within 25 km of a route," and justify the 25 km link with the EMC analysis.

## 2. The route rule has no link to interference

### 2.1 Presence, not exposure

Section 1.5 makes a cell a route cell when at least four distinct ships report from it in one calendar year of 52 sampled days. Every route cell then counts equally. Appendix A.1 shows how uneven the traffic is: "The busiest 6% of route cells carry half of all large-ship traffic," and "344,850 saw fewer than 10" distinct ships over 104 days, out of 658,867 route cells.

So more than half of the route network saw fewer than ten different large ships in two years of sampling. Those cells get the same zone as the Houston Ship Channel.

Interference to a radar depends on whether a radar is present when a transmitter operates, and on how many radars are in view. A presence threshold measures neither. The paper reserves Section 2 for the EMC analysis but fixes the route rule now, so the EMC analysis will inherit a network that it had no part in defining.

### 2.2 What stricter thresholds would do

We tested stricter thresholds on the repository's cell file (`outputs/2024_2025/viz/viz_cells.npz`), measuring land within each distance of the remaining AIS route cells:

| Rule | AIS route cells | Land within 25 km (km²) | 50 km | 100 km |
| --- | --- | --- | --- | --- |
| Paper's rule | 658,867 | 286,109 | 620,264 | 1,245,932 |
| 10 or more ships over two years | 314,017 | 262,222 | 576,683 | 1,196,651 |
| 20 or more ships | 133,600 | 229,013 | 530,277 | 1,148,367 |
| 50 or more ships | 42,445 | 187,001 | 443,391 | 998,119 |

In candor, these results show that a modestly stricter threshold changes the land area less than the shore link does. A threshold of 10 ships halves the route cells but cuts the 25 km land area by only about 8%. The Coalition doesn't claim that the four-ship rule alone drives the zone size. We do claim that the paper should show this sweep, so decision makers can see which choices matter and which don't.

### 2.3 The union of years contradicts its own rationale

Section 1.3 says that using two years will "keep one unusual year from setting the routes." The rule in Section 1.5 does the reverse: "a cell that meets the threshold in either year counts." Under a union, one unusual year can add cells on its own.

Appendix A.6 shows how much this matters to the network: "The other 322,498 cells pass in only one year." That is 49% of the route cells. The 336,369 cells that pass in both years carry 85% of traffic. On our grid, a both-years rule cuts the land area by about 6%, 5%, and 3% at 25, 50, and 100 km. The authors should either change the rationale or change the rule.

## 3. The stability evidence is weaker than presented

Appendix A.6 reports that "81% of the cells that pass the threshold in 2023 alone, and 94% of those that pass in January to June 2026, are in the 2024–2025 network." We have three concerns.

**The base network isn't the paper's network.** The stability results in `outputs/2024_2025/stability/year_stability.json` come from a base of 661,901 cells built with 53 sampled Wednesdays in 2025 (the file lists `"2025": 53`). The paper uses 52 Wednesdays (`period_rev1.m`) and reports 658,867 AIS route cells. The Hawaii calibration in Table 8 (Jaccard 0.80) comes from the same file, and its Hawaii base has 7,358 cells against the paper's 7,310.

**The measure runs one way.** A two-year union is larger than any one year, so a single held-out year will fall mostly inside it. The same file reports the reverse measure. 2023 alone reproduces only 57% of the base network, and the first half of 2026 reproduces 33%.

**The network moved when the years moved.** The same file compares the new 2024–2025 network with the earlier 2023–2024 network that the analysis used until November 12, 2026. The Jaccard index is 0.762: 89,556 cells were added and 88,792 dropped. Moving the window by one year changed about a quarter of the network.

The script that made these numbers, `python/ship_year_stability.py`, can't reproduce them as committed. Its `all_days()` function (lines 44–51) appends 2025 and 2026 to `vp.days()`. Since commit `12b8209`, `vp.days()` returns 2024–2025 rather than 2023–2024. A rerun would load 2025 twice and never load 2023.

We don't argue that the routes are unstable where traffic is heavy. We argue that the network edges, which decide where the zones reach inland, move a lot from year to year, and that the paper should say so.

## 4. The Alaska satellite lanes are not reliable enough to set zones

Section 5.1 adds satellite lanes from Kapsar and others (2022). The dataset is a valuable public product, built from exactEarth satellite AIS in 625 km² hexagons, and it uses ship-type codes to define cargo and tanker classes ([Kapsar and others, 2022, data paper](https://pmc.ncbi.nlm.nih.gov/articles/PMC9436749/)). The way the paper uses it raises five problems.

1. **The two datasets barely agree.** The repository's own check finds a Spearman rank correlation of 0.231 between shore-receiver ship-days and Kapsar cargo and tanker operating days (`outputs/2018_2019/alaska/kapsar_check.json`).
2. **The cutoff isn't resolved.** `python/alaska_satellite_lanes.py`, line 79, searches 37 quantile values. The best value, 272 operating days, is the next-to-last candidate. The next candidate is 659. The Jaccard curve is still rising at 272 (0.543 at 211, 0.571 at 272), and at double the cutoff (544) it is 0.464 (`satellite_lanes.json`, `satellite_lanes_x2.json`). The true peak could lie anywhere from about 272 to 544. A higher cutoff means fewer hexagons; Section 5.3 shows that doubling the cutoff shrinks the land in the 25 km zone by 8%.
3. **Most kept hexagons hold no observed route.** 283 of the 400 kept hexagons contain no shore-receiver route cell (`satellite_lanes.json`). Some of these lie within 74 km of shore, where the paper says its routes are complete.
4. **Whole hexagons become ship water.** Section 5.3 concedes that "the added ship water is wider than a lane, which makes the zones near those lanes larger." Each hexagon is about 27 km across. The 25 km shore link and the zone distance are then added on top of it.
5. **No size filter.** Section 5.3 states that "Kapsar has no length cut." The Kapsar paper also notes that type and dimension fields "are manually entered" and can be wrong.

The paper offers no run without satellite lanes. The authors should provide one, refine the cutoff search, and consider lane centerlines instead of whole hexagons.

### 4.1 Charted lanes and older data

Section 5.1 adds 23,444 cells of NOAA charted lanes in Alaska, almost as many as the 26,983 cells from ship tracks. No traffic test applies to them. The repository doesn't include the Alaska fairway cache, so a reader can't check which layers these cells come from.

The Alaska routes also use 2018–2019 data, while the rest of the paper uses 2024–2025 (Section 5.3). The paper explains why, and we accept that newer MarineCadastre files exclude Alaska. But the Kapsar dataset runs through 2020 ([Kapsar and others, 2022](https://pmc.ncbi.nlm.nih.gov/articles/PMC9436749/)), and the paper offers no evidence that 2018–2019 traffic stands for current traffic.

## 5. The ship-days rule enlarges the sparse-traffic networks

Section 4.1 adopts a ship-days rule for Hawaii, later reused in Alaska. A cell counts if its daily distinct-ship counts sum to six over 104 days. One ship seen on six Wednesdays is enough.

The paper says the cutoff "was set on the lower 48" because it best matches the lower-48 network. But in the areas where it is used, the rule gives far more cells than the lower-48 rule would. In Hawaii, it gives 7,310 cells against 3,965 (Table 8), or 84% more. In Alaska, it gives 26,983 against 19,142 (Section 5.1), or 41% more.

Table 8 also scores rules by "Ports on one network with Honolulu." Choosing a rule because it connects the ports an analyst expects to see connected is an outcome test, not a calibration. Hawaii's year-to-year stability is only 56–63% (`docs/review/limits_and_questions_rev1.md`, item 5; `year_stability.json`), but Section 4 doesn't mention this.

For small islands, the method collapses into "the whole island is a zone." The 50 km zone covers 95% of Hawaii (Section 4.2), and the 25 km zone covers 96% of Puerto Rico and the U.S. Virgin Islands (Section 6.1). A distance rule can't tell a populated leeward coast from a coast that terrain shields from the shipping lanes.

## 6. Carriage of an S-band radar is not use of one

### 6.1 The rule allows a second X-band radar

Section 1.1 states the SOLAS rule correctly: ships of 3,000 GT and up must carry "a 3 GHz radar or where considered appropriate by the Administration a second 9 GHz radar" ([SOLAS Chapter V, Regulation 19.2.7.1, as published by the UK Maritime and Coastguard Agency](https://assets.publishing.service.gov.uk/media/5a7f0081ed915d74e33f3c6e/solas_v_on_safety_of_navigation.pdf)). The next sentence, "In practice, large merchant ships carry the 3 GHz (S-band) radar," has no citation. The whole analysis rests on it.

Even where a ship carries an S-band radar, the paper doesn't show that the radar operates near the coast. Section 1.10 concedes: "The filter models the SOLAS carriage rule." AIS reports neither radar band nor radar status (`README.md`, Limits).

### 6.2 The Great Lakes rest on an unsourced claim

The Great Lakes zones cover some of the most populated shoreline in the country. Section 1.1 notes that U.S. rules in [33 CFR 164.35](https://www.ecfr.gov/current/title-33/chapter-I/subchapter-P/part-164/section-164.35) require a marine radar "without naming a band." The repository README (lines 47–49) says domestic Great Lakes freighters "fall under 33 CFR 164 instead of SOLAS" and that "Many of them carry S-band radars anyway." It gives no source.

### 6.3 The proxy check doesn't cover all kept ship types

The length-proxy check in Section 1.4 covers cargo, tanker, and passenger ships only (`outputs/2024/gt_proxy_by_type_2024.csv`). On July 10, 2024, the filter also kept 237 towing ships, 47 "other and unknown," 8 dredges, and 17 military and law-enforcement ships (Table 2): 309 of 1,980, or 16%. None was checked. Section 1.4 explains that "Many towing ships report the length of the whole tow," so for a tug-barge the 100 m test says nothing about the tug's own tonnage.

## 7. The example distances, the sampling, and the data quality

### 7.1 The distances anchor a decision that hasn't been analyzed

Section 3 says the 25, 50, and 100 km distances are "examples to show the method." We accept that, but the presentation undercuts it. Table 7 assigns 100 km to 3030–3070 MHz alone, a pattern that isn't monotone in frequency and that the paper doesn't explain. The repository writes files named `shipping_zone_2024_2025_band_3030-3070MHz_100km` (`outputs/2024_2025/shipping_zone_2024_2025_band_zones.csv`), and Figure 4 maps them. Section 2 is blank. Readers outside the study team will treat band-named files as proposals.

The paper also gives land areas for Hawaii, Alaska, and Puerto Rico, but not for the lower 48, where most affected people live. The README gives them: 404,668 km² at 25 km, 730,157 km² at 50 km, and 1,335,776 km² at 100 km. Those figures belong in Section 3.

### 7.2 Distance alone ignores terrain

Section 3.1 measures great-circle distance on a sphere. It ignores terrain, antenna heights, and clutter. Interference prediction at these frequencies normally accounts for terrain, for example under [Recommendation ITU-R P.452](https://www.itu.int/rec/R-REC-P.452). A 100 km zone drawn inland from the Pacific crosses coastal mountain ranges, and a zone on the Big Island crosses high volcanic terrain. Uniform distance can't show the shielding these features provide. The paper should state that the final zones will be propagation-based contours, not uniform buffers.

### 7.3 Every sampled day is a Wednesday

Section 1.3 samples "the first 52 Wednesdays of each year." Weekly liner and ferry services follow fixed day-of-week schedules, so a fixed-weekday sample can catch or miss the same services every week. Section 1.9 already reports one sampling artifact: at Mobile, "more ships were counted at the head port than at the entrance." The authors should test a second weekday or a rotating sample and report the change in the network and the zone area.

### 7.4 AIS errors rose in 2025 and aren't reported

The read-ahead (`docs/review/limits_and_questions_rev1.md`, item 6) and `outputs/2024_2025/qc/qc_summary.md` show that on July 9, 2025, 14.2% of lower-48 ships had position jumps and 11.1% shared an MMSI, and that 915 route cells came only from flagged reports on that day. A rebuild without flagged reports "is running." Section 1.6, the paper's list of checks, doesn't mention this. The paper should report the rebuild before any zone is used.

### 7.5 The port-approach rule adds cells where people live

Section 1.5 lowers the threshold to two ships within 50 km of 73 deep-draft ports, adding 15,782 cells (Table 3). The shore link then adds 25 km of ship water around them. Two of the ports the rule was meant to help, Panama City and Searsport, still don't connect (Section 1.6). A 50 km disk is a blunt tool for a thin approach channel.

## 8. Requested changes to the analysis

The Coalition asks the study team to make these changes before the zones go to decision makers. Each one uses code or outputs already in the repository.

1. **Report ships-mode zones.** Run `p.zone_mode='ships'` and report land area beside shore mode for every distance and every area (lower 48, Hawaii, Alaska, Puerto Rico and the U.S. Virgin Islands).
2. **Justify or remove the 25 km shore link.** If shore mode stays, tie `shore_link_km` to the EMC analysis and rename the zones so the label matches the geometry.
3. **Report lower-48 land areas in Section 3.** Give area, and if possible population, for each distance.
4. **Show a route-threshold sweep.** Give route cells and zone land area for 4, 10, 20, and 50 ships, and for a both-years rule. Align the Section 1.3 rationale with the rule chosen.
5. **Redo the stability check.** Use the paper's 52-day network. Report both directions of overlap and the Jaccard index between the 2023–2024 and 2024–2025 networks. Fix `python/ship_year_stability.py` so it reproduces its outputs.
6. **Rework the Alaska satellite lanes.** Resolve the cutoff between 211 and 659 operating days. Add a no-satellite run and a centerline run. Commit the Alaska fairway cache and report a run without charted lanes.
7. **Show both route rules for Hawaii and Alaska.** Report zones under the lower-48 rule and the ship-days rule, with land areas, and state Hawaii's stability in Section 4.
8. **Document S-band carriage and use.** Cite evidence for the share of large ships, and of Great Lakes freighters, that fit and operate an S-band radar near the coast. Extend the tonnage check to towing, dredging, and other types, or report zones without them.
9. **Neutralize the example distances.** Until Section 2 exists, remove band-named zone files and maps, or relabel them as Distance A, B, and C with no frequency attached.
10. **Commit to terrain-aware final zones.** State that the EMC analysis will draw zones from propagation predictions with terrain, and that uniform-distance zones are placeholders.
11. **Finish and report the data-quality rebuild.** Add the AIS error rates and the effect on the route network to Section 1.6. Test a second sampling weekday.

## 9. Conclusion

The working paper shows where large ships go, and it does so with public data and open code. That is a good foundation. But the zones drawn from those routes stack several conservative choices: a 25 km shore link, a union of years, a low presence threshold, a relaxed rule near ports, whole satellite hexagons, and distances with no analysis behind them. Each one alone may look modest. Together they turn a map of where ships go into a map of most of the coastline, and in Hawaii and Puerto Rico, nearly all of the land.

The Coalition asks the study team to separate the route map, which we largely accept, from the zone method, which we don't. Report the zones as the code can already draw them, measured from the ships. Show how each choice changes the area. Then let the EMC analysis, not a placeholder, set the distances. Decision makers can then weigh real protection for maritime radars against real costs on land.

Respectfully submitted,

*Coastal Spectrum Coalition (fictional party for internal review)*

---

**MOCK FILING FOR INTERNAL REVIEW — FICTIONAL PARTY — DRAFT//PRE-DECISIONAL**
