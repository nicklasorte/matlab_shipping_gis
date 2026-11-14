# Round-two review findings and dispositions

DRAFT//PRE-DECISIONAL

Date: November 13, 2026. Reviewed paper: `../paper_under_review_r2.md` (doc
revision 329, after the open items were closed). Four AI agents, each blind to
the drafting: numbers (`agent_numbers_r2.md`, R2NUM), method and code
(`agent_method_r2.md`, R2MET), style and Section 508 (`agent_style_r2.md`,
R2STY), and an opposing reader with a NOAA and Coast Guard maritime hat
(`agent_opposing_r2.md`, R2OPP). Fixes were applied through doc revision 369.

## Summary

- **No finding changes a land area in the paper.** Two code findings affect the
  zone files' water: the zones keep foreign water and foreign-port traffic
  (R2MET-1), and the Natural Earth country outlines include boundary lakes, so
  the Canadian half of the Great Lakes is removed, route cells included
  (R2MET-2). The code now uses the outlines without boundary lakes; the files
  change on the next Mac zone run. The paper now says both.
- **The weakest remaining point is Alaska.** Under the current zone definition,
  satellite cells feed land distance directly: a reviewer's point sample puts
  about 19%, 14%, and 10% of the Alaska 25, 50, and 100 km land near satellite
  cells only, and the half and double cutoff test ran under the old definition
  (R2OPP-1). Disclosed; the rerun needs the Mac.
- **Stale or mismatched numbers were fixed:** the Alaska satellite count
  (318,028 to 318,210), the length test (rerun on the current network: 120 m now
  −0.3% to −2.2%, 80 m +11.7% to +13.0%, 76% of the 25 km gain on the Columbia
  and Snake Rivers and the Mississippi above Baton Rouge), the held-out shares,
  the Wikidata match range, and the sensitivity baseline, which the paper now
  names.
- **Maritime claims hold** against eCFR, SOLAS, NAVCEN, and MarineCadastre
  metadata, with five corrections applied (33 CFR 164.46 scope, the AVIS
  attribute history, the Berwick Bay VTS, the Key Bridge channel dates, and the
  Mississippi mile gap against the Coast Pilot).
- **The Word copy was out of date** (R2STY-1, R2STY-2); it was rebuilt from the
  revised doc with `python/word_copy_rev1.py`.

Of the 20 mock-rebuttal arguments, the opposing reviewer counts 9 answered, 7
partly answered, and 4 still standing (6, 9, 10, 13); after the fixes below, 13
(S-band share) is answered as an assumption.

## Dispositions

| ID | Disposition |
| --- | --- |
| R2NUM-1, R2OPP-4, R2MET-4 | Fixed: 318,210, "not already AIS or charted-lane cells" (5.1, 5.3). |
| R2NUM-2, R2OPP-6 | Fixed: length test rerun on the current network (`length_sensitivity_rev1.csv`); 1.4 and A.8 updated. |
| R2NUM-3, R2MET-8, R2OPP-3 | Fixed: 1.5 names the sensitivity baseline (AIS and port-approach cells) and quotes the 25 km column. |
| R2NUM-4 | Closed on the Mac rerun: site distances and zone tests in `rerun/r2num4_site_distances.csv` (see below). |
| R2NUM-5 | Closed: `flagged_land_change.json` gives −0.137%, −0.193%, −0.128%. |
| R2NUM-6 | Open: 761 towboats, 15 river ports, and 166,382 pairs are earlier-run numbers with no output. |
| R2NUM-7, R2NUM-8, R2NUM-9 | Fixed: 76% to 84%; "about 2%"; 99.5% to 99.6% and 99.95% to 99.98%. |
| R2NUM-10 | Fixed: 54 a day throughout. |
| R2NUM-11, R2NUM-12 | Open (figure-level): A.3 range from MATLAB vs Python; Figure A-18 Mississippi label. |
| R2MET-1 | Disclosed (Section 3). Measured for the decision: foreign-side water is 36–42% of lower-48 zone water, 20% in Puerto Rico and USVI, 5–8% in Alaska, 0 in Hawaii (`foreign_water_decision_rev1.md`); land is unaffected by any clipping option. Nick decides. |
| R2MET-2 | Closed on the Mac rerun: land unchanged in all regions; Canadian Great Lakes water now inside the lower-48 zones (+1.3% to +1.5% zone area). |
| R2MET-3 | Fixed: 3.1 says the comparison includes the route fixes. |
| R2MET-5 | Disclosed: "land" includes inland lakes (3.1 item 4). |
| R2MET-6 | Open: share numerator and denominator use different polygon treatments (Puerto Rico 9,278 of 9,275). |
| R2MET-7, R2MET-9, R2MET-12 | Fixed or disclosed (cache wording; Russia and Canada; lanes west of 180°). |
| R2MET-10 | Fixed: README results heading and table, init comments. |
| R2MET-11 | Fixed: `word_copy_rev1.py` refuses tied prefix matches and logs fallbacks. |
| R2OPP-1 | Measured on the Mac rerun: without satellite lanes −19.1%, −14.1%, −10.4%; half cutoff +10.0%, +5.1%, +3.8%; double −11.0%, −8.6%, −6.6%. Paper Section 5 updated. |
| R2OPP-2, R2STY-10 | Fixed: the S-band share is stated as an assumption; Great Lakes flagged. |
| R2OPP-5 | Fixed: 1.9 gives the Coast Pilot Mile 232 gap (18–22 km). |
| R2OPP-7 | Nick decides: band-named zone files (kept; the paper calls the distances examples). |
| R2OPP-8, R2OPP-9, R2OPP-10, R2OPP-11, R2OPP-12, R2OPP-14, R2OPP-15, R2OPP-16 | Fixed in the text. |
| R2OPP-13 | Partly: Hawaii held-out capture added to 4.2; Spearman 0.231 and the Kapsar caveat not added. |
| R2STY-1, R2STY-2 | Fixed: Word copy rebuilt, captions styled with SEQ fields. |
| R2STY-3, R2STY-9, R2STY-11, R2STY-16, R2STY-19, R2STY-24 | Fixed in the text. R2STY-20 partly (NEXRAD, U.S. Table of Frequency Allocations). |
| R2STY-4 to R2STY-8, R2STY-12 to R2STY-15, R2STY-17, R2STY-18, R2STY-20 to R2STY-23, R2STY-25 | Left for Nick's human edit pass: alt-text takeaways, byline and table dates, Section 5 intro list, paragraph splits, acronyms, long sentences, headings, and voice. |

## Mac zone rerun (November 13, 2026)

All seven runs finished on the Mac (MATLAB R2025b), from a clean clone of main
at `2be4d4e`, with the foreign outlines without boundary lakes. Logs and the
check tables are in `rerun/`.

**R2MET-2: no land area changes.** U.S. land in every zone is identical to the
paper in all four regions:

| Region | 25 km | 50 km | 100 km |
| --- | ---: | ---: | ---: |
| Lower 48 | 301,168 km² | 638,688 km² | 1,261,529 km² |
| Hawaii | 7,869 km² | 14,132 km² | 16,717 km² |
| Puerto Rico and USVI | 7,211 km² | 9,278 km² | 9,278 km² |
| Alaska | 112,426 km² | 210,895 km² | 353,639 km² |

The route polygons don't change. What changes is foreign water: the lower-48
zones grow 1.3% to 1.5% in total area, and nearly all of it is the Canadian half
of the Great Lakes, now inside the zones (zone area in a 41–49.5° N, 75–93° W box
grows 29%, 24%, and 18% at 25, 50, and 100 km; `rerun/lower48_zone_area_change.csv`).
One Canadian racon in Lake Superior now falls inside the zones. This makes
R2MET-1 (zones keep foreign water) larger in the Great Lakes, and it's still
Nick's decision whether to clip water to U.S. jurisdiction. The updated zone
files are committed in `outputs/2024_2025/` and `outputs/2018_2019/alaska/`.

**R2OPP-1: Alaska sensitivity in ships mode.** Land in the zone, and the change
against the zones with the 272-day satellite cutoff:

| Run | 25 km | 50 km | 100 km |
| --- | ---: | ---: | ---: |
| Satellite lanes at 272 days (paper) | 112,426 km² | 210,895 km² | 353,639 km² |
| No satellite lanes | 90,923 km² (−19.1%) | 181,070 km² (−14.1%) | 316,800 km² (−10.4%) |
| Half the cutoff (136 days) | 123,628 km² (+10.0%) | 221,715 km² (+5.1%) | 367,178 km² (+3.8%) |
| Double the cutoff (544 days) | 100,013 km² (−11.0%) | 192,746 km² (−8.6%) | 330,144 km² (−6.6%) |

The no-satellite run confirms the reviewer's point-sample estimate (about 19%,
14%, and 10%). All five Alaska ports stay inside the 25 km zone in every run
(`outputs/2018_2019/alaska/sensitivity/`). R2OPP-1 moves from disclosed to
measured; the paper's Section 5 numbers need the update (the earlier 4%, 3%, 2%
and 8%, 7%, 6% were under the old zone definition).

**R2NUM-4: site distances.** Distance from each site to the nearest route
polygon vertex, and whether the site is inside the 25 km zone polygon
(`rerun/r2num4_site_distances.csv`):

| Site | Point used | To route | Inside 25 km zone |
| --- | --- | ---: | --- |
| Lahaina harbor | 20.87114, −156.6784 (port listing) | 18.2 km | yes |
| Port Allen | 21° 54.2′ N, 159° 35.5′ W (NOAA tide station) | 24.6 km | no |
| Vieques Sound | 18° 11′ 48″ N, 65° 26′ 06″ W (33 CFR 110.245 Area 2 center) | 18.6 km | yes |
| Red Dog Dock | 67.57581, −164.06439 (NOAA benchmark) | 0 km (5.8 km on ship tracks alone) | yes |

The zone tests agree with the paper: Lahaina inside, Port Allen just outside,
Vieques Sound off the network but inside the 25 km zone, and Red Dog on a route.
The distances differ from the first-round notes (18.9, 25.3, 19.5, 0.2 km)
because of the points and the method (vertex distance here). The paper can keep
its statements; if it quotes distances, use these with their points.

**R2NUM-5: closed.** `outputs/2024_2025/flagged/flagged_land_change.json`:
dropping the 4,474 flagged route cells cuts land in the lower-48 zones by
0.137%, 0.193%, and 0.128% (25, 50, 100 km; direct-distance metric), which
matches the paper's 0.13–0.19%.

Still open: R2NUM-6 (the 2025 funnel comparison needs a full raw day on the
Mac), R2NUM-11 and R2NUM-12 (figure level), R2MET-6, and Nick's decisions
(R2MET-1, R2OPP-7).
