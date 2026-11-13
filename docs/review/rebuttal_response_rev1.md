**DRAFT//PRE-DECISIONAL — RESPONSE TO A MOCK FILING FOR INTERNAL REVIEW**

# Analysts' response to the mock reply comments of the "Coastal Spectrum Coalition"

*This document answers a practice filing, `docs/review/mock_rebuttal_rev1.md`. The filing party is fictional. The response uses only the working paper (`docs/review/paper_under_review.md`), the code and outputs in this repository, and the review results in `docs/review/`. All paths are relative to the repository root.*

## Summary

The filing is careful, and most of its facts check out. We confirmed its code citations, its counts, and the numbers it took from repository outputs. Two review agents (`agent_opposing.md`, `agent_opposing2.md`) reached the filing's central numbers on their own. So this response rebuts little. It mostly says what the paper must disclose or change.

The record does answer three parts of the filing's case:

- **The zones aren't drawn far from where ships actually go.** On held-out days in 2023 and 2026, 98% of lower-48 large-ship cell visits lie within 25 km of the 2024–2025 route cells, and more than 99% lie within 100 km. Only 77–78% fall on a route cell itself (`docs/review/heldout_capture_rev1.csv`). The 25 km band of "ship water" is close to where the ships went, even though the paper never says so.
- **Not every method choice enlarges the zones.** Some choices shrink them. The lower-48 run uses a NOAA fairway cache with 28 features instead of the 291 in the live layer (`agent_method.md`, `agent_uscg.md`). The filter drops fishing vessels and Coast Guard cutters under 100 m that may carry S-band radar (`agent_rf.md` rf-4, `agent_fedops.md` fedops-5). Where lanes run more than 25 km offshore, shore mode gives no credit for ship water, which leaves the Olympic coast and much of the Oregon coast outside the 25 km zone (`agent_fedops.md` fedops-2).
- **The route threshold matters little.** The filing's own sweep shows this, and the filing says so.

The record doesn't answer the filing's strongest points. The paper labels a shore-mode zone as a distance from ships, but land in the "25 km" zone reaches up to about 50 km from any route cell. The paper has no source for S-band carriage or use. The stability evidence uses a different base network and reports one direction only. Section 2 is empty, so no distance has a basis yet.

Of the 20 arguments below, we classify 1 as Rebutted, 13 as Partly valid, and 6 as Valid.

## How we classified each argument

| Class | Meaning |
| --- | --- |
| Rebutted | The record answers the claim. The answer cites files and numbers. |
| Partly valid | Part of the claim holds. The answer says which part and what the paper should change or disclose. |
| Valid | The claim holds. The answer says what must change. |

We split the filing's sections into 20 arguments. Each heading below gives the filing's section number.

## Evidence notes

Read these before you rely on any answer below.

- **The clean-room test doesn't confirm the pair count.** `docs/review/agent_cleanroom.md` rebuilt the Section 1.4 filter from the paper's text alone. It matched every report count and ship count in Table 1 exactly, on both days. It didn't match the Section 1.6 pair count: it found 195,951 cell and ship pairs on 2024-01-03, against 166,382 in the paper (18% more). No choice it tested explains the gap. This response doesn't cite the clean-room test as a match at the pair level.
- **The MATLAB and Python appendix products agree.** `outputs/2024_2025/viz_matlab/compare_python.json` shows equal row counts and relative differences under 0.3% for the hexagon, port, and daily files. The corridor files differ more near the entrance, as Appendix A discloses.
- **Some filing numbers come from review scratch scripts, not repository outputs.** The ships-mode areas (filing Section 1.2) and the threshold sweep (filing Section 2.2) were computed on a 0.05° grid by review agents. The repository has no ships-mode or shore-link sensitivity outputs. `init_shipping_zone_rev1.m`, lines 130–132, supports a `shore_link_override` run, but no output from it is committed.
- **Reported land areas run high.** Raster land areas run 2% to 8% above the shipped land polygons, because edge cells count as land (`agent_opposing2.md` opposing2-7; `rasterize_polygon_crop_rev1.m`, line 7). Hawaii's 100 km zone is reported as 17,573 km², but the polygon is 16,717 km². Any area quoted in a revision should use the corrected method.

## Responses by argument

### Argument 1 (filing Section 1): Shore mode inflates every zone

**Claim.** "A '25 km zone' isn't 25 km from the ships," because land distance is measured from coastline within 25 km of a route cell, so land in the 25 km zone can sit up to about 50 km from any ship.

**Class: Partly valid.**

The geometry claim is correct. `shipping_zone_rev1.m`, lines 207–216, sets water within `p.shore_link_km` of a route cell to distance 0. The code then measures land distance from Census coastline cells within that same distance. `init_shipping_zone_rev1.m`, line 74, sets `p.shore_link_km=25`. Two review agents found that about one fifth of the 25 km land zone (about 84,000 km²) lies more than 25 km from every route cell. The maximum is 49.1 km (`agent_opposing.md` opposing-1; `agent_opposing2.md` opposing2-1). The port checks agree. Mayaguez is 29.7 km from a route cell but inside the 25 km zone (`outputs/2024_2025/prusvi/shipping_zone_prusvi_2024_2025_port_check.csv`). The paper never says what the link adds, so Table 7 and the Figure 4 caption mislead. Two parts of the claim don't hold. First, the 25 km link has an empirical basis that the filing misses. On held-out 2023 and 2026 days, only 77.1% and 78.1% of lower-48 large-ship cell visits fell on a route cell, but 98.0% and 97.9% fell within 25 km of one (`docs/review/heldout_capture_rev1.csv`). Ships spill well beyond the route cells, and a 25 km band captures almost all of them. A ships-mode zone measured from route cells alone would start from a source that misses about 22% of where large ships were seen. Second, shore mode doesn't inflate every zone. Where a lane runs more than 25 km offshore, no coastline counts as facing, so land distance falls back to the route cells. This leaves the Olympic coast and much of the Oregon coast outside the 25 km zone (`agent_fedops.md` fedops-2). The effect also shrinks with distance: by the filing's own figures, shore mode adds 26%, 10%, and 3% at 25, 50, and 100 km. **Paper changes:** In Section 3.1, state that the zone distance is measured from the shoreline that faces ship water, and that land in the 25 km zone can lie up to about 50 km from a route cell. Rename the zones to match. Report ships-mode land areas beside shore-mode areas at 0.01°. Give the held-out capture result as the reason for the 25 km link. State that the EMC analysis sets the link, or tell the reader to subtract it, when it delivers a radar-to-receiver distance. Note the offshore-lane exception.

### Argument 2 (filing Section 2.1): The route rule tests presence, not interference

**Claim.** "A cell that four ships crossed in a year gets the same zone as a cell that 3,000 ships crossed," and no metric links the threshold to harm.

**Class: Partly valid.**

The rule is a presence test, as the filing says. Appendix A.1 confirms the skew: 344,850 of 658,867 route cells saw fewer than 10 distinct large ships, and the busiest 6% carry half the traffic. The route product holds distinct ships per cell per day. It holds no dwell time, no count of ships present at once, no antenna height, and no radar state (`agent_rf.md` rf-5; `ais_large_ship_cells_rev1.m`, header). So the routes can't feed an aggregate interference analysis as they stand. The paper should say this. Two parts of the claim go too far. The paper doesn't claim that the route rule measures harm: it reserves that for Section 2, and the zone distances are examples. And the filing's own sweep (Argument 3) shows that the threshold has little effect on land area. The concern that the EMC analysis will "inherit a network that it had no part in defining" is fair. But the per-cell ship counts the EMC analysis would need to weight cells already exist (`outputs/2024_2025/viz/viz_cells.npz`). **Paper changes:** In Section 1.10, add that route cells mark presence, not radar exposure. In Section 3, state that the EMC analysis may weight or cut route cells by traffic, and list the inputs it would need (dwell, simultaneity, antenna height). Consider saving report counts per cell and day, which gives ship-minutes.

### Argument 3 (filing Section 2.2): The paper should show a route-threshold sweep

**Claim.** "The paper should show this sweep, so decision makers can see which choices matter and which don't."

**Class: Valid.**

The paper tests the Alaska satellite cutoff (Section 5.3) but gives no sweep for the lower-48 threshold. The sweep is cheap and helps the paper. By the filing's figures, which match `agent_opposing.md` opposing-2 and `agent_opposing2.md` opposing2-5, a 10-ship rule halves the AIS route cells (658,867 to 314,017) but cuts land within 25 km of route cells by only 8% (286,109 to 262,222 km²). A 20-ship rule cuts it by 20%, and a 50-ship rule by 35%. These figures are ships-mode land areas on a 0.05° grid, built from review scratch scripts. They aren't repository outputs. **Paper changes:** Add a threshold sweep to Section 1.5 or Appendix A.1 for 4, 10, 20, and 50 ships and for a both-years rule. Give route cells and land area at each distance, computed at 0.01° with committed code.

### Argument 4 (filing Section 2.3): The union of years contradicts its rationale

**Claim.** Section 1.3 says two years "keep one unusual year from setting the routes," but the union rule lets one unusual year add cells on its own.

**Class: Partly valid.**

The wording conflict is real. Under the union rule in Section 1.5, either year alone can add a cell, and 322,498 of 658,867 route cells (49%) pass in only one year (Appendix A.6). But the rationale does hold in the other direction: the union keeps one unusual year from removing routes. The paper's own example shows why that matters. The Key Bridge collapse closed Baltimore's main channel for part of 2024, and 2025 restores those cells. A both-years rule would let the unusual year delete routes. The cost of the union is also small: by the review agents' figures, a both-years rule cuts land area by about 6%, 5%, and 3% at 25, 50, and 100 km (`agent_opposing.md` opposing-3). **Paper changes:** Rewrite the Section 1.3 bullet to say what the union does: "Using either year keeps one unusual year from removing routes, such as Baltimore in 2024." Report the both-years land area in the threshold sweep (Argument 3).

### Argument 5 (filing Section 3): The stability evidence is weaker than presented

**Claim.** The stability shares in Appendix A.6 come from a different base network, measure overlap in one direction only, hide a Jaccard index of 0.762 between the 2023–2024 and 2024–2025 networks, and come from a script that can't reproduce them.

**Class: Valid.**

Each fact checks out. `outputs/2024_2025/stability/year_stability.json` lists 53 sampled days in 2025 and a base of 661,901 cells, against 52 days and 658,867 cells in the paper. Hawaii's base is 7,358 cells, against 7,310. The reverse shares are 0.57 for 2023 and 0.328 for January to June 2026. The Jaccard index between the base and the earlier 2023–2024 network is 0.762, with 89,556 cells added and 88,792 dropped. In `python/ship_year_stability.py`, lines 44–51, `all_days()` appends 2025 and 2026 to `vp.days()`. `vp.days()` now returns `ship_period.days()` (`python/ship_viz_products.py`, lines 54–56), and `python/ship_period.py`, line 12, sets the years to 2024 and 2025. A rerun would load 2025 twice and never load 2023. Some context limits the damage. The 53-day base differs from the paper's network by about 0.5% of cells, too little to move the shares. A single year will always reproduce less of a two-year union, and 2026 has only 25 days, so the 33% isn't comparable to the 57%. Most important, edge movement doesn't mean the zones miss traffic. The held-out capture test asks the question that matters for zones: 98% of held-out lower-48 visits lie within 25 km of the 2024–2025 routes, and 99.5% to 99.6% lie within 100 km (`docs/review/heldout_capture_rev1.csv`). **Paper changes:** Fix `all_days()` so that it doesn't depend on `ship_period`. Rerun on the paper's 52-day network. In Appendix A.6, report both directions, the 2023–2024 to 2024–2025 Jaccard index, and the held-out capture shares. State that the network edges move from year to year while the zones still capture almost all held-out traffic.

### Argument 6 (filing Section 4, item 1): The two Alaska datasets barely agree

**Claim.** The repository's check finds a Spearman rank correlation of only 0.231 between shore-receiver ship-days and Kapsar cargo and tanker operating days.

**Class: Partly valid.**

The number is correct (`outputs/2018_2019/alaska/kapsar_check.json`), and the paper doesn't report it. But the same file explains most of it. The correlation runs over 5,751 hexagons with traffic in either dataset, including far offshore, where the shore receivers can't see. Of the busiest 10% of Kapsar hexagons, only 16.9% hold a shore-receiver route cell. The rest lie a median of 171.2 km from shore, and 94.8% of them lie beyond 74 km. That gap is what the satellite lanes are meant to fill. Where both datasets can see, they agree on presence: 99.9% of the shore-receiver route cells in the Kapsar area sit in hexagons with Kapsar cargo or tanker traffic. Still, the near-shore Jaccard index of 0.571 is only moderate. `agent_uscg.md` also reports that the shore data miss the Bering Strait lanes even close to shore, so the near-shore reference isn't complete either. **Paper changes:** In Section 5.1 or 5.3, report the Spearman value with the explanation above. If possible, give a near-shore Spearman value, which the record doesn't hold.

### Argument 7 (filing Section 4, item 2): The satellite cutoff isn't resolved

**Claim.** The best cutoff, 272 operating days, is the next-to-last candidate, the next one is 659, and "the true peak could lie anywhere from about 272 to 544."

**Class: Partly valid.**

The search grid is coarse at the top. `python/alaska_satellite_lanes.py`, line 79, takes 37 quantiles from the 5th to the 95th percentile. The Jaccard curve in `outputs/2018_2019/alaska/satellite_lanes.json` reads 0.486 at 163, 0.543 at 211, 0.571 at 272, and 0.447 at 659, with no candidate in between. So the peak isn't located. But the effect on the zones is bounded. `outputs/2018_2019/alaska/sensitivity/alaska_cutoff_sensitivity.csv` shows that doubling the cutoff (544 operating days, Jaccard 0.464, 304 hexagons) shrinks the land in the 25, 50, and 100 km zones by 8.0%, 7.3%, and 5.7%. Halving it (136 operating days, Jaccard 0.463, 633 hexagons) grows them by 4.2%, 3.4%, and 2.0%. All five ports stay inside the 25 km zone at every cutoff. Because the Jaccard index at 544 is already lower than at 272, the true peak most likely lies between 272 and 544. The zone change would then be less than 8%. **Paper changes:** Search the cutoff on a finer grid between 211 and 659 operating days, report the peak, and keep the half-and-double sensitivity in Section 5.3.

### Argument 8 (filing Section 4, item 3): Most kept hexagons hold no observed route

**Claim.** 283 of the 400 kept hexagons contain no shore-receiver route cell, and "some of these lie within 74 km of shore."

**Class: Rebutted.**

The count is right, but it's the expected result, not a flaw. `outputs/2018_2019/alaska/satellite_lanes.json` reports 400 kept hexagons, of which 290 lie beyond shore-receiver range (74 km). The satellite lanes exist to add traffic the shore receivers can't see, so hexagons without a shore route are the point of the method. Because 290 of the kept hexagons lie beyond range, as few as zero of the 283 need to lie within 74 km. The record doesn't show that any do, so the filing's "some" is unsupported. And where a near-shore hexagon does lack a shore route, `agent_uscg.md` gives a reason to trust the satellite data there: the shore data miss the Bering Strait lanes even close to shore. **Paper changes:** In Section 5.1, report how many kept hexagons lie within 74 km of shore and lack a shore route, so the reader doesn't have to infer it.

### Argument 9 (filing Section 4, item 4): Whole hexagons become ship water

**Claim.** Each hexagon is about 27 km across, and "the 25 km shore link and the zone distance are then added on top of it."

**Class: Valid.**

Section 5.3 concedes that the added ship water is wider than a lane and makes the zones larger. The paper offers no run without satellite lanes, so the reader can't see how much they add. The satellite hexagons add 334,651 water cells by `satellite_lanes.json` (Section 5.1 says 318,134, which needs reconciling), against 26,983 ship-track cells. They are the largest source of Alaska ship water (`agent_opposing2.md` opposing2-10). Two facts limit the effect on land: 290 of the 400 hexagons lie beyond 74 km from shore, and the zone distance is measured from shoreline, not from hexagon edges. The record has no number for the land these hexagons add. **Paper changes:** In Section 5, add a run without satellite lanes and report the change in land area. Consider a lane-centerline version. Reconcile 318,134 with 334,651.

### Argument 10 (filing Section 4, item 5): The satellite data have no size filter

**Claim.** "Kapsar has no length cut," and its type and dimension fields "are manually entered" and can be wrong.

**Class: Partly valid.**

The paper already says this in Section 5.3, so the filing adds the point about manual entry. The cutoff partly absorbs the size gap: it was set to match the shore-receiver routes, which do apply the 100 m and IMO tests, so hexagons kept on small-ship traffic alone would lower the match. That defense is indirect, and the record doesn't measure the share of Kapsar operating days from ships under 100 m. **Paper changes:** In Section 5.3, add that the cutoff was tuned against length-filtered routes, which limits but doesn't remove the effect of small ships. Add the Kapsar caveat on manually entered fields.

### Argument 11 (filing Section 4.1): Alaska charted lanes and older data

**Claim.** NOAA charted lanes add 23,444 cells with no traffic test, the Alaska fairway cache isn't committed, and the paper offers "no evidence that 2018–2019 traffic stands for current traffic."

**Class: Partly valid.**

Two parts hold. The Alaska fairway cache isn't in the repository. `load_shipping_fairways_rev1.m`, line 29, names it by grid limits, and `data/` holds only the lower-48 file, `fairways_rev1.geojson`. So a reader can't check the 23,444 cells (26,546 fairway cells, of which 23,444 aren't already AIS cells, per `outputs/2018_2019/alaska/shipping_zone_alaska_2018_2019_run.log`). And the paper gives no evidence that 2018–2019 traffic represents traffic today. The "no traffic test" point doesn't hold. Charted fairways and routing measures are where the Coast Guard and NOAA direct ships to sail. `agent_uscg.md` confirmed that the routes cover the charted Bering Strait two-way route from 58.75° N north. Charted lanes need no AIS count to count as ship water. **Paper changes:** Commit the Alaska fairway cache. In Section 5.1, list the layers the 23,444 cells come from, and report a run without them. In Section 5.3, add a check of 2018–2019 against a newer public source, such as the later years of the Kapsar dataset, or state the age as an open limit. Correct the shore-receiver range: `agent_uscg.md` gives 50 nautical miles from the Coast Guard, against 40 in the paper.

### Argument 12 (filing Section 5): The ship-days rule enlarges the sparse-traffic networks

**Claim.** The ship-days rule gives far more cells than the lower-48 rule where it's used (84% more in Hawaii, 41% more in Alaska), the port test is an outcome test, Hawaii's low stability goes unmentioned, and small islands become whole-island zones.

**Class: Partly valid.**

The cell counts are correct (Table 8; Section 5.1). Three points hold. Table 8's port column is an outcome test, as the filing says. Hawaii's year-to-year stability, 56% to 63% (`year_stability.json`), isn't in Section 4. And the calibration base for the Jaccard index of 0.80 is the 53-day network from Argument 5. The claim that the rule "enlarges" Hawaii's network beyond its traffic doesn't hold. The cutoff of 6 is a real calibration: the Jaccard curve in `year_stability.json` peaks at 0.804 at 6 and falls on both sides (0.772 at 5, 0.762 at 7). And the held-out test shows that Hawaii's routes, if anything, miss traffic. Only 82.4% and 81.4% of held-out Hawaii visits lie within 25 km of the routes, and 4.4% and 5.6% lie beyond 100 km (`docs/review/heldout_capture_rev1.csv`). The lower-48 rule, with 3,965 cells, would likely miss more; the record doesn't test this. The whole-island result comes from island size and distance, not from the route rule. Every Hawaii and Puerto Rico port is already within 30 km of a route cell. Hawaii's reported areas also run high: the 100 km zone is reported as 17,573 km², but Census land for the whole state is 16,724 km² (`agent_opposing2.md` opposing2-7). **Paper changes:** In Section 4.1, report the held-out capture for Hawaii and the stability shares. Drop the port column as a reason for choosing the rule, or label it as a check. Report zone areas under both rules. Correct the Hawaii, Alaska, and Puerto Rico land areas to polygon values.

### Argument 13 (filing Section 6.1): Carriage of an S-band radar isn't use of one

**Claim.** The sentence "In practice, large merchant ships carry the 3 GHz (S-band) radar" has no citation, and the paper doesn't show that the radar operates near the coast.

**Class: Valid.**

The record has no source for the share of large ships that fit an S-band radar rather than a second 9 GHz radar. Review agents found none (`agent_rf.md` rf-13; `agent_opposing2.md` opposing2-17). SOLAS Chapter V, Regulation 19.2.7.1 allows a second 9 GHz radar where the flag state agrees, and the paper says so in the preceding sentence. Nothing in the record shows radar status near the coast: AIS reports neither band nor status, and the filter keeps ships at any speed, including at anchor (`init_shipping_zone_rev1.m`, line 46, `min_sog_kn=0`). The README's reason, "Radars often stay on at anchor," has no source (`README.md`, line 41). Section 1.10 already says "Carriage, not use," so the paper is candid about the gap but doesn't close it. One public source supports wide S-band use: the NTIA band compendium for 2900–3100 MHz describes S-band radars on commercial ships and on "thousands of non-SOLAS vessels" (https://www.ntia.gov/files/ntia/publications/compendium/2900.00-3100.00_01SEP14.pdf, cited in `agent_rf.md`). It gives no share. **Paper changes:** In Section 1.1, cite a source for S-band fit rates, or restate the sentence as an assumption: "The zones assume that every ship of 3,000 GT or more carries an S-band radar." In Section 1.4, state that speed isn't filtered and why. In Section 1.10, say that the routes show where carrying ships go, not where radars transmit.

### Argument 14 (filing Section 6.2): The Great Lakes zones rest on an unsourced claim

**Claim.** The README says domestic Great Lakes freighters "carry S-band radars anyway" and gives no source.

**Class: Valid.**

`README.md`, lines 47–49, makes the claim with no source, and the paper's 33 CFR 164.35 citation names no band. The point is stronger than the filing states. SOLAS Chapter V doesn't apply to ships that sail only on the Great Lakes (Regulation 1.1), so the SOLAS rule that Section 1.1 rests on doesn't reach them (`agent_rf.md` rf-12). Part 164 applies to self-propelled vessels of 1,600 GT or more and adds a second radar at 10,000 GT, but neither section names a band (`agent_rf.md` rf-14). **Paper changes:** In Section 1.1, state that Great Lakes-only ships fall under 33 CFR 164, not SOLAS, and cite evidence of S-band fits on Great Lakes freighters. If no source exists, say that the Great Lakes routes assume S-band carriage, and flag the Great Lakes zones as resting on that assumption.

### Argument 15 (filing Section 6.3): The proxy check doesn't cover all kept ship types

**Claim.** The length-proxy check covers cargo, tanker, and passenger ships only, while 309 of 1,980 kept ships (16%) on July 10, 2024, were towing, other, dredging, military, or law enforcement ships.

**Class: Partly valid.**

The count is correct: Table 2 gives 237 towing, 47 other and unknown, 8 dredging, and 17 military and law enforcement ships, or 15.6% of 1,980. `init_check_gt_proxy_rev1.m`, line 17, checks types 60–89 only. The paper quotes 99.6% and 98.1% without that limit, which overstates what the check covers. But the effect on the routes is small and partly known. Tug-barges add 9,130 route cells, about 1.4% of the 658,865 AIS route cells, all within 25 km of the coastline (Appendix A.5). Tug-barges are a deliberate addition, not SOLAS 3 GHz ships, and warships fall outside SOLAS Chapter V. The record doesn't size the effect of the 47 "other and unknown" ships or the 8 dredges. **Paper changes:** In Sections 1.4 and 1.6, state that the proxy check covers only passenger, cargo, and tanker ships, 84% of those kept. Describe tug-barges and military ships as deliberate additions, with the Appendix A.5 cell count. Report the route-cell share from "other and unknown" and dredging ships.

### Argument 16 (filing Section 7.1): The example distances anchor an unanalyzed decision

**Claim.** Band-named zone files, a Table 7 pattern that isn't monotone in frequency, and missing lower-48 land areas will lead readers to treat the examples as proposals.

**Class: Valid.**

Section 2 is empty, and Section 3 says the distances are examples. Yet the repository writes band-named files (`outputs/2024_2025/shipping_zone_2024_2025_band_zones.csv`), and Figure 4 maps them. The paper never explains why 100 km applies only at 3030–3070 MHz. `agent_rf.md` rf-1 adds that IMO-category radars transmit from 3020 to 3080 MHz (ITU-R M.1313), so even as an example, the band edges don't match the radars. The lower-48 land areas appear in the README (404,668, 730,157, and 1,335,776 km², `README.md`, lines 171–173) but not in Section 3. Hawaii, Alaska, and Puerto Rico areas do appear. **Paper changes:** Until Section 2 exists, relabel the example rows as Distance A, B, and C with no frequency, and rename the band-named files to match. Mark every zone figure as a placeholder with no interference basis. Add the lower-48 land areas to Section 3, corrected to polygon values.

### Argument 17 (filing Section 7.2): Distance alone ignores terrain

**Claim.** Uniform great-circle distance ignores terrain, antenna heights, and clutter, and the paper should state that final zones will be propagation-based contours.

**Class: Partly valid.**

The paper uses uniform distance on a sphere (Section 3.1) and doesn't say how the final zones will be drawn. A reader could take the buffers as final. But the filing assumes that terrain only shrinks zones. At S-band over water, ducting and other anomalous propagation can carry signals beyond the line-of-sight range, and Recommendation ITU-R P.452, which the filing cites, models those modes. Uniform distance isn't conservative or generous by design. It is a placeholder. Whether the EMC analysis will use terrain-based contours is a method decision for the study, not something this paper can commit to. **Paper changes:** In Section 3, state that uniform-distance zones are placeholders and that the EMC analysis will decide how to account for terrain, clutter, and anomalous propagation.

### Argument 18 (filing Section 7.3): Every sampled day is a Wednesday

**Claim.** A fixed-weekday sample "can catch or miss the same services every week."

**Class: Partly valid.**

Every sampled day is a Wednesday (`period_rev1.m`; `python/ship_period.py`), and no other weekday was tested. The held-out years also use weekly samples, so the held-out capture test doesn't address weekday bias. The concern is fair and unmeasured. But the filing's example isn't a weekday artifact. At Mobile, the sample catches ships at the berth that it never sees crossing the entrance (Section 1.9). That reflects one-day snapshots, not the choice of weekday. Long transits also span more than one day, which limits how much a weekly liner can hide from a fixed weekday. The record doesn't test this. **Paper changes:** In Section 1.10, name the fixed weekday as a limit. If time allows, rebuild one year on a second weekday and report the Jaccard index and the change in land area.

### Argument 19 (filing Section 7.4): AIS errors rose in 2025 and aren't reported

**Claim.** Position jumps and shared IDs rose in 2025, 915 route cells came only from flagged reports on July 9, 2025, and the rebuild without flagged reports isn't reported.

**Class: Partly valid.**

The facts are correct (`outputs/2024_2025/qc/qc_summary.md`). On 2025-07-09, 14.2% of lower-48 ships had position jumps and 11.1% shared an MMSI. Section 1.6 doesn't mention this, and the rebuild hasn't been reported: `data/flagged/` holds per-day flag files, but no rebuilt network or zone output exists. The size is small on the days checked. Route cells from flagged reports alone were 21 (0.003%), 291 (0.044%), 547 (0.083%), and 915 (0.139%) on the four lower-48 days, and every lower-48 day passed the QC gate. Hawaii was clean, and Puerto Rico had at most 1 such cell. Over 104 days these cells could add up, so the rebuild still matters. **Paper changes:** In Section 1.6, add the QC check with its error rates and flagged-cell shares. Report the rebuild result, as route cells and land area, before any zone is used.

### Argument 20 (filing Section 7.5): The port-approach rule adds cells where people live

**Claim.** The two-ship rule within 50 km of 73 deep-draft ports adds 15,782 cells, the shore link adds 25 km around them, and "a 50 km disk is a blunt tool for a thin approach channel."

**Class: Partly valid.**

The rule adds 15,782 cells, 2.3% of the 675,763 route cells (Table 3). Panama City and Searsport still don't connect (Section 1.6), although both lie inside the 25 km zone (Table 5). The record supports the "blunt tool" point with a case the filing missed. The route above Baton Rouge rests on cells with at most 2 distinct ships, which enter through the port rule. Those vessels also sail the upper Mississippi, which suggests river traffic that the filter was meant to exclude (`agent_opposing2.md` opposing2-4; `agent_method.md`). The filing gives no land area for the rule's effect, and the record has none. At 2.3% of cells, mostly at ports already inside the zones, the effect is likely small. That estimate is unverified. **Paper changes:** In Section 1.5, report the land area with and without the port rule. Consider limiting the rule to cells that connect to the open-water network. Fix the Baton Rouge extension, and reconcile Section 1.7 ("about 35 km past the city") with Appendix A.4 ("about 5 km above Baton Rouge").

## Paper changes implied by this response

| Section | Change | Argument | Filing request |
| --- | --- | --- | --- |
| 1.1 | Cite a source for S-band fit rates, or restate as an assumption that every ship of 3,000 GT or more carries one. | 13 | 8 |
| 1.1 | State that Great Lakes-only ships fall under 33 CFR 164, not SOLAS. Cite S-band evidence for Great Lakes freighters, or flag the Great Lakes zones as resting on an assumption. | 14 | 8 |
| 1.3 | Rewrite the two-year rationale: the union keeps one unusual year from removing routes. | 4 | 4 |
| 1.4 | State that speed isn't filtered and why. | 13 | — |
| 1.4, 1.6 | State that the proxy check covers passenger, cargo, and tanker ships only (84% of kept ships). Describe tug-barges and military ships as deliberate additions. | 15 | 8 |
| 1.5 or A.1 | Add a threshold sweep (4, 10, 20, 50 ships; both years) with route cells and land areas at 0.01°. | 3, 4 | 4 |
| 1.5 | Report land area with and without the port-approach rule. Fix the Baton Rouge extension. | 20 | — |
| 1.6 | Add the AIS QC check, error rates, flagged-cell shares, and the rebuild result. | 19 | 11 |
| 1.6 | Define the daily cell and ship pair file so a reader can rebuild 166,382 pairs, or correct the figure. | Evidence notes | — |
| 1.7, A.4 | Reconcile "about 35 km past the city" with "about 5 km above Baton Rouge." | 20 | — |
| 1.10 | Add that route cells mark presence of carrying ships, not radar exposure or transmission. Name the fixed weekday as a limit. | 2, 13, 18 | 11 |
| 2, 3 | List the inputs the EMC analysis needs from the routes (dwell, simultaneity, antenna height). | 2 | — |
| 3 | Relabel the example rows as Distance A, B, and C with no frequency. Rename band-named files. Mark every zone figure as a placeholder. | 16 | 9 |
| 3 | Add lower-48 land areas at each distance, corrected to polygon values. | 16 | 3 |
| 3 | State that uniform-distance zones are placeholders and that the EMC analysis will decide how to treat terrain, clutter, and anomalous propagation. | 17 | 10 |
| 3.1 | State that zone distance runs from the shoreline that faces ship water, and that the 25 km zone reaches up to about 50 km from a route cell. Rename the zones to match. | 1 | 2 |
| 3.1 | Report ships-mode land areas beside shore-mode areas for every area and distance. | 1 | 1 |
| 3.1 | Give the held-out capture result (98% of visits within 25 km) as the reason for the 25 km link, and note the offshore-lane exception. | 1 | 2 |
| 4.1 | Report Hawaii held-out capture and stability. Treat the port column as a check, not a reason. Report zone areas under both rules. | 12 | 7 |
| 4.2, 5.2, 6.1 | Correct land areas to polygon values (raster areas run 2% to 8% high). | 12 | — |
| 5.1 | Search the satellite cutoff on a finer grid between 211 and 659 operating days. | 7 | 6 |
| 5.1 | Report how many kept hexagons lie within 74 km of shore and lack a shore route. | 8 | — |
| 5.1 | Reconcile 318,134 satellite water cells with 334,651 in `satellite_lanes.json`. | 9 | — |
| 5.1 | List the charted-lane layers. Commit the Alaska fairway cache. Report a run without charted lanes. | 11 | 6 |
| 5.1 | Correct the shore-receiver range to the Coast Guard's 50 nautical miles, or cite the 40. | 11 | — |
| 5 | Add a run without satellite lanes, and consider a lane-centerline version. | 9 | 6 |
| 5.1, 5.3 | Report the Spearman value of 0.231 with the coverage explanation. | 6 | — |
| 5.3 | Add the Kapsar caveat on manually entered fields, and say the cutoff was tuned against length-filtered routes. | 10 | — |
| 5.3 | Check 2018–2019 against newer public data, or state the age as an open limit. | 11 | — |
| A.6 | Rerun stability on the 52-day network. Report both directions, the 0.762 Jaccard index, and held-out capture. Fix `python/ship_year_stability.py`. | 5 | 5 |

Filing request 11 also asks for a second sampling weekday. We list it as optional under Argument 18.

## Arguments that remain hardest to answer

1. **Carriage and use (Arguments 13 and 14).** No source in the record gives the share of large ships, or of Great Lakes freighters, that fit and run an S-band radar near the coast. The routes rest on this assumption, and new analysis can't supply it. Only a citation can.
2. **No basis for any distance (Argument 16).** Until Section 2 exists, every zone area is a placeholder. The best the paper can do now is make that impossible to miss.
3. **The zone label (Argument 1).** The held-out capture result justifies a 25 km band of ship water, but it doesn't make a "25 km zone" 25 km from the ships. The label must change, and ships-mode areas must appear beside it.
4. **Stability and reproducibility (Argument 5).** The facts are against the paper until the script is fixed and the check is rerun on the paper's network.
5. **Alaska added lanes (Arguments 9 and 11).** Satellite hexagons and charted lanes supply most of Alaska's ship water. No run without them exists, and the charted-lane cache isn't committed.

**DRAFT//PRE-DECISIONAL — RESPONSE TO A MOCK FILING FOR INTERNAL REVIEW**

## Note added after this response was written

The clean-room pairs were compared with the repo caches after this response was drafted (`cleanroom_comparison_rev1.md`): they agree on 99.94%–99.96% of (cell, ship) pairs on all four days. This supports answering the argument that the method is undocumented or irreproducible. The 166,382 figure in Section 1.6 is stale and should be corrected.
