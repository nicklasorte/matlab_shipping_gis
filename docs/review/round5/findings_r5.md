# Round five findings and dispositions

DRAFT//PRE-DECISIONAL

Date: November 17, 2026. Paper reviewed: doc revision 616
(`paper_rev616.md`). Four blind agents, none of which saw the drafting, the
plans, or earlier review rounds:

| Report | Findings |
| --- | --- |
| `agent_numbers_r5.md` | 15 (1 High, 7 Medium, 7 Low) |
| `agent_method_r5.md` | 21 (2 High, 7 Medium, 12 Low) |
| `agent_style_r5.md` | 30 issues (cap reached) |
| `agent_opposing_r5.md` | 21 (4 Strong, 11 Moderate, 6 Weak) |

All four agree that the numbers trace: every Table 8 value, the population
totals, the PEA counts, Tables 1 to 6 and 9, and Appendix B reproduce from
committed files. The weight of the findings is on method choices and on older
numbers that predate the November 14 and 17 reruns.

Edits below went into the doc at revisions 617 to 629. Exact fixes and new
sourced content are plain edits; rewording is a suggestion for Nick.

## Fixed in the paper (plain edits)

| ID | Fix |
| --- | --- |
| R5OPP-10 | Table 8 has a "Deep-draft ports reached (of 73)" column from the run logs: base 70, no tug-barges 70, both years 66, under way 69, outside the Great Lakes 61, Great Lakes layer 9. |
| R5MET-1 (disclosure part), R5OPP-2 | Section 3.1 says the Great Lakes layer is drawn by area (41° N to 49.5° N, 92.5° W to 74.5° W), holds ocean-going SOLAS ships that enter through the Seaway, and that without it 61 of 73 deep-draft ports are on the routes. Redefining the layer is open (see Nick's calls). |
| R5MET-2, R5OPP-12 | PEA sentence now says "85 of the 412 PEAs that hold 2020 Census block groups", defines "reached" (a block group's center of population in a zone), and says the FCC list has 416 PEAs, two of the four without block groups (U.S. Virgin Islands, Gulf of Mexico) also lie partly in the zones. |
| R5MET-10 | "over 3 knots" is now "3 knots or more" (the code uses `>=`) in Section 1.10, the Section 3.1 paragraph, and Table 8. |
| R5MET-11, R5OPP-1 (label) | Table 8 row reads "Without tug-barges (rule off)". |
| R5MET-12 | Table 8 row and note say the both-years test applies to the port-approach rule too. |
| R5STY-4, R5STY-27 (part), R5MET-20 | Table 8 note says each block group counts wholly in or out, that 2.2 million and 0.8 million come from unrounded counts, and how a deep-draft port counts as reached. |
| R5NUM2-5 (rounding) | Alaska clip "6% to 8%" is now "5% to 8%" (5.37%). The rerun of the clip figures on the current zones is still open. |
| R5NUM2-8 | New York–New Jersey Atlantic share 16.5% is now 16.2%. |
| R5NUM2-9 | Receiver coverage: "17% more than 200 nautical miles, in 2024–2025 (52% and 18% in 2023–2024)". |
| R5NUM2-10 | Section 5.3: "removing every flagged report drops 11 Alaska route cells". |
| R5NUM2-13 | Table B-1: "half 12 ft (3.7 m)". |
| R5NUM2-14 | Appendix A.8: "from about 145 m". |

## Already answered by a pending suggestion

| ID | Suggestion |
| --- | --- |
| R5NUM2-1, R5MET-5 | `sg_bww1ngphb8` deletes the 318,210 sentence in 5.3 and puts the base count (245,735) in 5.1. Accepting it closes both. |
| R5NUM2-3, R5MET-11, R5OPP-18, R5STY-20 | `sg_po9t1v1de9` deletes "lost 12% of its land" and puts the Table 8 basis (10%) in 1.5. Accepting it closes all four. |

## New suggestions for Nick (revision 629, `sg_atuaoh94ds`)

- R5STY-3: Section 1.10 ships-at-anchor sentences, reason first, no repeat.
- R5STY-6 (part): Section 3.1 overlap sentence split in two.

## Fixed in the repo

| ID | Fix |
| --- | --- |
| R5NUM2-11, R5STY-17 (part) | `corr04`, `corr_james`, and `haw01` `.alt.txt` files now match the paper; `python/ship_hawaii_figures.py` writes the corrected Hawaii alt text. |
| R5NUM2-15 | Region folder run logs replaced with the November 17 logs (lower 48, Hawaii, Puerto Rico, Alaska D2). |

## Nick's calls (method and policy)

| ID | Question | What the reviewers found |
| --- | --- | --- |
| R5MET-1, R5OPP-2 | Redefine the Great Lakes layer by ship instead of by box? | The box holds SOLAS salties; foreign-flag ships alone support 27% of Great Lakes route cells. A by-ship layer (lakers seen only inside the box) is one rerun. The box's east edge (74.5° W) also stops short of Montreal. |
| R5OPP-1, R5MET-6 | Revisit D7 (tug-barge rule in the base)? | No carriage basis; the effect comes from the 2024 change to whole-tow length in AIS, and the rule adds nothing in Alaska. |
| R5OPP-5 | Revisit D2 (290 against 400 Alaska hexagons)? | 18 of the 110 dropped hexagons hold no ship-track cell; the 74 km reach isn't tested. |
| R5OPP-4 | Add envelope rows (all reducing choices together, all protective choices together) to Table 8? | Two more runs. |
| R5OPP-3 | Add a traffic-weighted rule row? | 52% of AIS cells saw fewer than 10 ships. |
| R5OPP-11 | Report MHz-weighted population (about 39% in the lower 48) beside the 100 km figure? | Avoids readers taking 53% as the headline. |
| R5OPP-7 | Add the carriage-rate argument (route cells fall with carriage, land barely moves)? | Needs a committed script and output. |
| R5OPP-14, R5OPP-21 | Scope statement (commercial ship radars only; 2700–2900 MHz receiver question) | Belongs with D5 (Section 2, on hold). |

## Open: reruns and code (next code pass, on the Mac)

| ID | Work |
| --- | --- |
| R5MET-3 | Log the git commit at the start of each run; rerun the base and variants on one commit. |
| R5NUM2-4 | Rerun Alaska `'_x0.5'` and `'_x2'` with current code; commit logs under `outputs/`. |
| R5NUM2-5 | Rerun the foreign-water split and nesting check on the current zones (needs Natural Earth on the Mac). |
| R5NUM2-6 | Move the stress outputs (sensitivity, random halves, held-out capture, A.8) from `docs/review/` to `outputs/` and rerun on the current routes. |
| R5NUM2-2 | Rerun the GT check on the deduplicated match set; update "half are 87–99 m" and the 0.1 m median. |
| R5NUM2-7 | Commit a per-region sites check for Red Dog pier, Lahaina, Port Allen, Vieques, and the other uncited distances. |
| R5MET-4 | St. Lawrence below Montreal has no route cells; state the coverage edge or add the reach. |
| R5MET-7 | Missing twins: Python zone polygons and land, variant runs, MATLAB PEA count. |
| R5MET-8, R5MET-15, R5MET-17 | Silent skips in the population, PEA, and decision-table scripts, empty days, and fairway themes: make them errors with identifiers. |
| R5MET-9 | Tests for the source box, `decision_variant`, `min_sog_kn`, `year_combine`, and a test that fails if `contour_margin_km` is removed. |
| R5MET-10 | Drop SOG 102.3 ("not available") from the under-way filter. |
| R5MET-13, 14, 16, 18, 19, 21 | Hexagon centroid wording, lane-test foreign land, cache key, clear `decision_variant`, shore-mode margin, result field names. |
| R5OPP-20 | Simplify zone boundaries outward only (Port Allen). |

## Open: style (to lay as suggestions in the next pass)

R5STY-1, 2, 5, 7 to 25, 27 to 30. R5STY-13 (minus signs in Table 8 and B-1)
and R5STY-12 and 22 (abbreviations) are exact fixes for the next pass.
R5STY-15 (B-1 and B-2 caption styles) needs a change to `word_copy_rev1.py`.

Kept: R5STY-26. "Under way" (adverb, as in "ships under way") and "underway"
(adjective) are both standard; the paper uses each in its own role.
