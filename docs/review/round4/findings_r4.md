# Round-four review: findings and dispositions

DRAFT//PRE-DECISIONAL

Date: November 14, 2026. Paper reviewed: doc revision 486
(`paper_rev486.md`), the full paper after plan steps P2 to P8. Four blind
agents: numbers (`agent_numbers_r4.md`, 15 findings), method and code
(`agent_method_r4.md`, 14), style and Section 508 (`agent_style_r4.md`, 26),
and an opposing reader (`agent_opposing_r4.md`, 17). Land areas in Sections 3
to 6 checked out against the November 14 rerun; no finding changes a 25 km or
50 km land area.

Dispositions: **Fixed** (plain edit, now in the doc), **Suggested** (laid in
the doc as a suggestion for Nick to accept), **Open** (needs a run, data, or
Nick's call), **Noted** (no change).

## Numbers

| ID | Disposition |
| --- | --- |
| R4NUM-1 | Fixed: Mile 232 is about 373 km, 17 to 21 km more. |
| R4NUM-2 | Fixed: charted lanes and racons add about 0.6% to 1.8%. |
| R4NUM-3 | Fixed: January 9 and July 10, 2019, fail the check; only July 10 affects route cells. |
| R4NUM-4 | Fixed: rerun logs committed (`outputs/rerun_logs_20261114/`), beyond-range row added to `alaska_satellite_sensitivity_rev1.csv`. |
| R4NUM-5 | Fixed: the unsourced 5,000 and 2,000 km² removed; the qualitative caveat stays. |
| R4NUM-6 | Open: Jacksonville coded Gulf in the port-share files; printed shares don't change. Fix the coast label and regenerate A.20. |
| R4NUM-7 | Fixed: "6% to 8% in Alaska" (the MATLAB clip that built the files). |
| R4NUM-8 | Fixed: the unsourced 11 km² dropped from the pending charted-lanes suggestion. |
| R4NUM-9 | Fixed: "6.5% of all route cells". |
| R4NUM-10 | Fixed: rerun grid land added to `census_land_in_grid_rev1.json`. |
| R4NUM-11 | Noted: Table 5 column is reached and on the network; CSV rename left for the next code pass. |
| R4NUM-12 | Fixed: 1.3 now matches A.20 (35-foot channel April 25, deepest ships about May 20). |
| R4NUM-13, 14, 15 | Noted: values check out; output files to be written in the next code pass. R4NUM-15 text is struck by a pending suggestion (R2STY-15). |

## Method and code

| ID | Disposition |
| --- | --- |
| R4MET-1 | Open: the distance field stops at 100 km, so the 100 km boundary may sit about half a cell short (reviewer's estimate 0.3% to 0.5% of the 100 km land). Needs a code change and rerun. |
| R4MET-2 | Fixed: the 2-cell MATLAB/Python gap is now attributed to the tug-barge coastline band. |
| R4MET-3 | Fixed: 5.1 says 272 is the best of a coarse search; 5.3 says 300 matches marginally better. |
| R4MET-4 | Fixed: 1.5 says tug-barge tracks more than 25 km offshore are dropped. |
| R4MET-5 | Open: add automated tests for the port-approach rule, tug-barge band, per-year union, port connectivity, and satellite selection. |
| R4MET-6 to 14 | Noted; R4MET-9 (about 2,200 km² of Alaska land west of 180° in the denominator) and R4MET-14 (funnel cross-check not run in code) go to the next code pass. |

## Style and Section 508

| ID | Disposition |
| --- | --- |
| R4STY-1, 2, 3, 5 | Fixed: alt text for Figures 2, 4, 5, A-6, A-7, and A-8 now states the takeaway; Figure 2 and Figure A-8 images regenerated with "Wikidata gross tonnage"; A-8 headline and sidecar alt text corrected (lines cross near 90 m). |
| R4STY-4, 6, 7, 9 | Suggested: Figure 4 caption colors, gross tonnage defined, "large ship" defined, the boundary sentence split. |
| R4STY-8, 10 to 26 | Open for the next style pass (link text, long sentences, jargon, duplicate headings, table headers, Table 5 names, marking placement, numbers style). |

## Opposing reader

| ID | Disposition |
| --- | --- |
| R4OPP-1 | Fixed (disclosure): 1.5 says the tug-barge rule is a protective choice, not a carriage rule, and PSIX tonnage now shows none of 159 U.S.-flag towing vessels is 3,000 GT or more (`docs/review/psix_gt_check_rev1.md`). Whether to keep the rule is Nick's call. |
| R4OPP-2 | Open: compute the Great Lakes share of the lower-48 zone land (reviewer's estimate about a quarter). |
| R4OPP-3 | Open: population in the zones (Census blocks); Nick's call whether the paper should report it. |
| R4OPP-4 | Open: zones from underway reports only (over 3 knots). |
| R4OPP-5 | Fixed in part: 5.3 states the beyond-range result and both readings; the choice is decision D2. |
| R4OPP-6 | Open: report how far a "25 km" zone reaches from a satellite lane centerline. |
| R4OPP-7 | Open: zones on both-year cells only (reviewer's estimate 6%, 6%, 3% smaller). |
| R4OPP-8 | Noted: answered. |
| R4OPP-9 | Fixed: 1.10 says half-samples always give less land, so zones from every day would likely be larger. |
| R4OPP-10 | Fixed: 1.10 no longer calls fishing vessels non-SOLAS. |
| R4OPP-11 | Fixed: 1.10 gives the ship-by-ship range (58% to 100%). |
| R4OPP-12 | Open: over half of lower-48 route cells lie beyond the Coast Guard's stated receive reach; the 2024–2025 files likely include a long-range source. Check the MarineCadastre metadata and correct 1.2 and 1.10. |
| R4OPP-13 | Open: western Aleutians (cell files for 172° E exist). |
| R4OPP-14 | Noted: Hawaii cutoff 6 against 5; disclosed. |
| R4OPP-15, 16 | Open: public Navy and VTS radar-site layers. |
| R4OPP-17 | Suggested: the racon sentence now cites the Coast Guard (most racons also work in 2900–3100 MHz). |
