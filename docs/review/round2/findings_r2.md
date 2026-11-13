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
| R2NUM-4 | Open: Lahaina, Port Allen, Sonda de Vieques, and Red Dog distances come from first-round notes; add them to the site checks on the next run. |
| R2NUM-5 | Open: the flagged-rebuild land change (0.13–0.19%) isn't in an output file. |
| R2NUM-6 | Open: 761 towboats, 15 river ports, and 166,382 pairs are earlier-run numbers with no output. |
| R2NUM-7, R2NUM-8, R2NUM-9 | Fixed: 76% to 84%; "about 2%"; 99.5% to 99.6% and 99.95% to 99.98%. |
| R2NUM-10 | Fixed: 54 a day throughout. |
| R2NUM-11, R2NUM-12 | Open (figure-level): A.3 range from MATLAB vs Python; Figure A-18 Mississippi label. |
| R2MET-1 | Disclosed (Section 3). Clipping water to U.S. jurisdiction needs an EEZ layer; Nick decides. |
| R2MET-2 | Code fixed (`load_foreign_land_rev1.m` uses `ne_10m_admin_0_countries_lakes`); disclosed; files change on the next Mac run. |
| R2MET-3 | Fixed: 3.1 says the comparison includes the route fixes. |
| R2MET-5 | Disclosed: "land" includes inland lakes (3.1 item 4). |
| R2MET-6 | Open: share numerator and denominator use different polygon treatments (Puerto Rico 9,278 of 9,275). |
| R2MET-7, R2MET-9, R2MET-12 | Fixed or disclosed (cache wording; Russia and Canada; lanes west of 180°). |
| R2MET-10 | Fixed: README results heading and table, init comments. |
| R2MET-11 | Fixed: `word_copy_rev1.py` refuses tied prefix matches and logs fallbacks. |
| R2OPP-1 | Disclosed (5.1); rerun without satellite lanes and the cutoff test in ships mode on the next Mac run. |
| R2OPP-2, R2STY-10 | Fixed: the S-band share is stated as an assumption; Great Lakes flagged. |
| R2OPP-5 | Fixed: 1.9 gives the Coast Pilot Mile 232 gap (18–22 km). |
| R2OPP-7 | Nick decides: band-named zone files (kept; the paper calls the distances examples). |
| R2OPP-8, R2OPP-9, R2OPP-10, R2OPP-11, R2OPP-12, R2OPP-14, R2OPP-15, R2OPP-16 | Fixed in the text. |
| R2OPP-13 | Partly: Hawaii held-out capture added to 4.2; Spearman 0.231 and the Kapsar caveat not added. |
| R2STY-1, R2STY-2 | Fixed: Word copy rebuilt, captions styled with SEQ fields. |
| R2STY-3, R2STY-9, R2STY-11, R2STY-16, R2STY-19, R2STY-24 | Fixed in the text. R2STY-20 partly (NEXRAD, U.S. Table of Frequency Allocations). |
| R2STY-4 to R2STY-8, R2STY-12 to R2STY-15, R2STY-17, R2STY-18, R2STY-20 to R2STY-23, R2STY-25 | Left for Nick's human edit pass: alt-text takeaways, byline and table dates, Section 5 intro list, paragraph splits, acronyms, long sentences, headings, and voice. |

## Next Mac zone run

1. Rerun all four zone runs (foreign outlines without boundary lakes, R2MET-2).
2. Alaska without satellite lanes, and at half and double the cutoff, in ships
   mode (R2OPP-1).
3. Add the R2NUM-4 sites to the site checks.
