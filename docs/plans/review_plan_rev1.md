# Review plan: 2.7 GHz large-ship routes and zones working paper

DRAFT//PRE-DECISIONAL

Date: November 12, 2026

This plan sets out how to review the working paper
(`docs/2.7GHz_Routes_and_Zones_Sections_DRAFT.docx`) and the code and data
behind it before the paper goes to anyone outside the team. It covers
Sections 1 and 3 through 6 and Appendix A. Section 2 (EMC analysis) is empty
and is out of scope.

## Summary

- The review has five stages: reproduce, trace the numbers, attack the
  method, expert review, and sign-off. Stages 1 through 3 can run without
  outside reviewers. Stages 4 and 5 need people.
- The paper changed a lot in one day: the analysis years moved to
  2024–2025, and Hawaii, Alaska, and Puerto Rico and the U.S. Virgin
  Islands were added. Checks that passed on the earlier version don't
  automatically cover the new one.
- Thirteen known gaps are listed below. The three to fix before any
  reviewer reads the paper were worked on November 12, 2026: two are
  closed, and one (data validity) is closed except for one Alaska day.
  See "Pre-review fixes."
- The review ends when every exit criterion in this plan is met and Nick
  signs off. Automated checks and agent reviews don't count as approval.

## What the review must answer

1. **Is every number right?** Each number in the paper matches a file in
   the repo, and the file comes from the code as committed.
2. **Is the method sound?** The filter, the route rules, and the zone
   method do what the paper says, and the choices hold up against
   alternatives.
3. **Are the data valid?** The AIS inputs are good enough for each area,
   and the limits are stated.
4. **Is the paper honest about uncertainty?** Each limit that could change
   a zone is stated where the reader will see it.
5. **Is it ready for its audience?** A non-specialist can follow it, and it
   meets NTIA style, marking, and Section 508 rules.

## Known gaps to fix or disclose

These are the weak points known today, ranked by how much they could change
a conclusion or embarrass the paper.

### Fix before any reviewer reads the paper

| # | Gap | Why it matters | Status |
| --- | --- | --- | --- |
| 1 | The MATLAB versions of the Appendix A figures weren't rerun after the move to 2024–2025. | Appendix A says each figure was computed twice. | **Closed.** Rerun and compared; the sentence now names the two corridors where the implementations differ. |
| 2 | The MATLAB test suite wasn't rerun after four code changes. | A regression in shared code would affect every area. | **Closed.** 18 of 18 tests pass, including the parallel and two-session tests and 7 new tests. |
| 3 | The data-validity checks hadn't run on 2025, Alaska, or Puerto Rico. | The gate requires two passing days per area. | **Closed except Alaska.** Lower 48, Hawaii, and Puerto Rico pass on four days each. Alaska passes on one of three days; see below. |

### Investigate during the review

| # | Gap | Action |
| --- | --- | --- |
| 4 | Flagged reports (position jumps and shared ship IDs) are rising in the lower 48: ships with a jump went from 0.5% on 2024-01-10 to 14.2% on 2025-07-09, and route cells made only by flagged reports from 21 to 915 a day. Alaska shows the same on 2019-07-10. | Rebuild the routes with flagged reports removed, for every area, and count the cells that drop out. Find out whether the 2025 rise comes from the data provider (for example, merged receiver feeds) or from real errors. |
| 5 | Great Lakes ports rank low on ship counts against tonnage. Lakers without IMO numbers may be filtered out. | Count ships 100 m or longer with no IMO number on the Great Lakes. |
| 6 | Sampling stability hasn't been tested within a year. | Rebuild the routes from 52 of the 104 days and report the overlap. |
| 7 | Hawaii routes shift between years: 56–63% of the held-out years' routes fall inside the 2024–2025 network. | Compare the zones, not the cells, across years. If the zones are stable, say so in Section 4. |
| 8 | Alaska's satellite cutoff matches the shore-based routes only moderately (Jaccard index 0.57), and the hexagons are about 27 km across. | **Done.** At half the cutoff, land in the 25, 50, and 100 km zones grows by 4.2%, 3.4%, and 2.0%; at double, it shrinks by 8.0%, 7.3%, and 5.7%. All five ports stay in the 25 km zone. Added to Section 5.3. Table: `outputs/2018_2019/alaska/sensitivity/alaska_cutoff_sensitivity.csv`. |
| 9 | Alaska's ship-days rule and the satellite cutoff rule were analyst choices, not decisions Nick made in advance. | Nick confirms or changes them. |
| 10 | NOAA returned no charted lanes or racons for the Puerto Rico grid, and no racons for Hawaii or Alaska. | Confirm against the charts that none exist, so an empty download isn't mistaken for no features. |
| 11 | On Mobile Bay, more ships are counted at the head port than at the entrance (104%). | Check whether the entrance window is too narrow, and whether other corridors' shares are biased the same way. |
| 12 | The Word copy is assembled by matching figures to alt text. | Check each of the 56 figures against its caption in the Word file. |
| 13 | On the James River and the Calcasieu Ship Channel, the MATLAB and Python least-cost paths differ by about 1 km in length, and the entrance and head counts differ by up to 9% (Calcasieu ships entering: 661 against 608). The continuation curves differ more near the entrance (James, 10% of the way up: 78% of ships continue in MATLAB against 36% in Python). | Find which cells the paths split at and why (a tie in cost, or a one-ship difference in a cell). Decide whether the paths should be fixed by hand for these two corridors. |

### Disclosed limits (confirm the wording is strong enough)

- Alaska uses 2018–2019 data; the rest of the paper uses 2024–2025.
- Shore receivers reach about 40 nautical miles.
- Navy ships often turn AIS off.
- The zone distances are examples until the EMC analysis sets them.
- The western Aleutians, Guam, and American Samoa aren't analyzed.

## Pre-review fixes (November 12, 2026)

### Gap 1: MATLAB Appendix A rerun

The four MATLAB scripts ran on the Mac on the 2024–2025 caches
(`outputs/2024_2025/viz_matlab/appendix_a_run.log`), and
`python/compare_matlab_python_appA.py` compared the 13 tables with the
Python ones. A value counts as different only when it differs by more than
half a unit in the last digit Python printed, because Python rounds some
columns for the paper.

| Result | Tables |
| --- | --- |
| Identical | `geo_ports`, `geo_hex_types`, `port_share`, `port_share_complex`, `viz_mississippi` |
| One grid-cell boundary difference (one ship on one row or day) | `geo_hex` (1 hexagon), `geo_profile` (1 bin), `viz_daily` (one ship on 4 of 104 days), `viz_sites` (one route distance) |
| Different on two corridors | `corridor_summary`, `corridor_profile`, `corridor_continuation`, `corridor_marks`: James River and Calcasieu Ship Channel only (gap 13). Three other corridors place a landmark up to 0.9 km apart along the path, with the same counts. |

The one-cell differences are the known boundary difference between the
two implementations (658,865 against 658,867 AIS route cells). The working
paper's Appendix A sentence now says the two agree to within one grid cell
except on those two corridors, and that the paper reports the Python
values. The doc and the Word copy were both updated.

### Gap 2: MATLAB test suite

`runtests('test_shipping_zone_rev1')` on the Mac with a two-worker pool:
18 passed, 0 failed, 0 filtered (`outputs/2024_2025/viz_matlab/test_suite_run.log`).
The route rule and the extra-cell reader moved into their own functions
(`route_source_mask_rev1.m`, `read_extra_cells_rev1.m`) so they can be
tested without a full run; `shipping_zone_rev1.m` calls them and its
behavior is unchanged. New tests:

- The default and explicit `unique_ships` rule, and the `ship_days` rule on
  both sides of each cutoff.
- An unknown rule name and mismatched array sizes raise errors.
- The extra-cell CSV: first cell, last cell, and a repeat are read
  correctly; an index past the last cell, zero, or a fraction raises
  `shipgis:extra`.
- An empty NOAA fairway download returns an empty mask.
- The fairway cache is read per grid, not from the lower-48 file, and the
  rasterized square covers the polygon plus at most one ring of edge cells.

Code Analyzer reports no messages on the changed files.

### Gap 3: data-validity checks

`python/ais_qc_day.py` now runs every check in every area, including the
on-land check in each area's own equal-area projection (EPSG:5070 for the
lower 48, ESRI:102007 for Hawaii, EPSG:32161 for Puerto Rico and the USVI,
EPSG:3338 for Alaska), and tests flagged reports against each area's own
route cells. `python/qc_summary.py` turns the checks into rates and applies
the gate: each rate no worse than the worst lower-48 day.

| Area | Days checked | Result |
| --- | --- | --- |
| Lower 48 | 2024-01-10, 2024-07-10, 2025-01-08, 2025-07-09 | Reference for the gate. Error rates rise in 2025 (gap 4). |
| Hawaii | Same four days | Pass on all four; no errors of any kind. |
| Puerto Rico and USVI | Same four days | Pass on all four. |
| Alaska to 180° | 2018-07-11, 2019-01-09, 2019-07-10 | Pass on 2018-07-11. On 2019-01-09, one ship of 40 fails the IMO check digit (no route cell affected). On 2019-07-10, 17 of 93 ships have a position jump and 12 route cells (0.044%) come only from flagged reports, the same share as the lower 48 on 2024-07-10. |

Full table: `outputs/2024_2025/qc/qc_summary.md`.

Alaska therefore meets the gate's two-day rule only if Nick accepts a
one-ship IMO error on 2019-01-09 as a pass (it doesn't change any route
cell, because the filter needs an IMO number but doesn't use it). The
2019-07-10 jumps should be folded into gap 4's rebuild. Disclose in
Section 5 that Alaska's error rates on one summer day were above the lower
48's.

On-land reports on route cells (Hawaii: about 450 a day; lower 48: about
160,000 to 190,000 a day) are ships in harbors and rivers that the
1:500,000 shoreline closes, not errors. No area has reports inland off the
routes except the lower 48 (0.4% to 0.7% of reports, 9 to 19 ships a day).

## Stages

### Stage 1: Reproduce (about half a day, automated)

Goal: a clean copy of the repo produces the same outputs.

1. Clone `main` to a clean folder. Record the commit.
2. Run the MATLAB test suite and the Code Analyzer on every `.m` file. Run
   `pyflakes` on every Python file.
3. Rebuild from the committed day caches: the four zone runs (lower 48,
   Hawaii, Alaska, Puerto Rico), then the Python products and figures.
4. Compare every rebuilt CSV and JSON file with the committed copy. Report
   any difference.
5. Spot-check the caches against raw data: rebuild three randomly chosen
   days per area from the MarineCadastre files and compare the cell and
   ship pairs.

Pass: no differences in step 4 beyond the known one-or-two-cell boundary
difference between MATLAB and Python; step 5 matches exactly.

### Stage 2: Trace the numbers (about one day)

Goal: every number in the paper has a source.

1. Build a numbers ledger (`docs/review/numbers_ledger.csv`): one row per
   number in the paper, with the section, the value as printed, the source
   file and field, the exact value, and the rounding.
2. Fill the ledger by script where possible, so it can be rerun after
   edits. Flag numbers that appear in more than one place and check that
   they agree.
3. Check each figure title, caption, and alt text against the ledger.
4. Check each table total and each percentage by recomputing it.
5. Check cross-references: every figure and table is cited before it
   appears, and the numbering is in order.

Pass: every row has a source and matches; no orphan numbers.

Tables were renumbered in order of appearance on November 12, 2026 (old
Tables 5–7 are now 4–6; the zone-distance table is now Table 7). Check the
new numbers in the ledger.

### Stage 3: Attack the method (about one day)

Goal: reviewers who didn't build the work try to break it.

Run three separate agent reviews, each given only the paper and the repo,
not this session's history:

- **Method reviewer:** reads the code and the paper side by side and lists
  every place where they disagree.
- **Data reviewer:** reruns the validity checks and the cross-checks
  against outside sources, and tries to find an area or year where the
  routes are wrong.
- **Opposing reader:** writes the strongest technical objections a
  skeptical outside party would raise, ranked by how hard each is to
  answer.

Then close gaps 4 through 12 above and record the result of each.

Pass: every finding is fixed, or disclosed in the paper with its effect on
the zones.

### Stage 4: Expert review (people; about one week elapsed)

Agents can't substitute for these.

| Reviewer | What to review | Questions to ask |
| --- | --- | --- |
| Maritime operations (for example, a Coast Guard or NOAA Coast Survey contact) | Sections 1.1, 1.4, 1.5, 4, 5, 6 | Do the routes match where large ships sail? Is anything missing, such as Navy areas or anchorages? Are the Alaska lanes right? |
| RF engineer on the 2.7 GHz study | Sections 1.1 and 3 | Does a 100 m ship stand in for an S-band radar well enough? Does the zone method give the EMC analysis what it needs? |
| GIS or data analyst | Sections 1.5 and 3.1, and the code | Are the distance method, the projections, and the land and coastline layers right, including in Alaska? |
| NTIA style and Section 508 reviewer | Whole paper | Plain language, marking on every page, alt text, table headers, color contrast. |
| Counsel or data-use reviewer | Data sources | Are the MarineCadastre terms and the CC BY 4.0 attribution for the satellite dataset met? Is 2018–2019 Alaska data acceptable to cite? |

Give each reviewer the paper, the one-page list of disclosed limits, and
the specific questions above. Ask for comments in the working paper doc.

### Stage 5: Sign-off (Nick)

1. Nick reads the ledger summary, the stage 3 findings, and the expert
   comments.
2. Nick decides the open choices below.
3. Nick approves the paper for its next audience, or sends it back.

## Decisions for Nick

Each decision has a recommendation. Nick asked on November 12, 2026, to
apply them; what was done is under "Applied" in each decision.

### 1. Alaska route rule and satellite cutoff (gaps 8 and 9)

Options:

- **A. Keep both as they are** (six ship-days; satellite cutoff of 272
  cargo and tanker operating days over 24 months), and report the zones at
  two other satellite cutoffs.
- B. Use the lower-48 rule (four distinct ships in one year) for Alaska.
- C. Drop the satellite lanes and show only shore-based routes, with the
  gap disclosed.

**Recommendation: A.** The ship-days rule is the same one Hawaii uses, and
it was calibrated against the lower-48 network rather than tuned to Alaska
(Jaccard index 0.81 for 2023–2024 and 0.80 for 2024–2025). Option B drops
lanes that a few dedicated ships run every week, which is the Alaska
pattern (19,142 cells under four ships against 26,983 under six ship-days).
Option C leaves most of the Gulf of Alaska and Bering Sea great-circle
traffic out: 83% of the busiest satellite hexagons hold no shore-based
route, and 95% of those are more than 74 km from shore. The satellite
cutoff is the weakest link (Jaccard index 0.57), so the paper should show
how much the Alaska zones change at a lower and a higher cutoff (for
example, half and double) before reviewers see it. Against A: the cutoff
was chosen by best fit to the shore routes, which a reviewer may see as
circular; the sensitivity table answers that.

**Applied:** both rules kept; the half and double runs are in Section 5.3
(zones change by 2–8%).

### 2. Stage 4 reviewers and outside agencies

Options:

- **A. Internal reviewers first** (RF engineer on the study, a GIS
  analyst, the NTIA style and Section 508 reviewer, and counsel for data
  use), then one maritime contact at the Coast Guard or NOAA Coast Survey
  once internal comments are resolved.
- B. Send to internal and outside reviewers at the same time.
- C. Internal review only at this stage.

**Recommendation: A.** The internal reviewers can fix the problems that
would cost credibility outside, such as data-use terms and marking, at no
risk. The maritime check is the one no internal reviewer can do (are the
routes where ships sail, and what does AIS miss), so it should come before
the paper is used, but with a cleaner draft. Ask the maritime contact for
a technical check of Sections 4–6 and the route maps only, under the
DRAFT//PRE-DECISIONAL marking. Against A: it adds about a week. Option C
leaves the routes unchecked by anyone who knows the waters.

**Applied:** stage 4 order set as above. Names still to be filled in by
Nick.

### 3. MATLAB and Python agreement statement (gap 1)

Options:

- **A. Rerun the MATLAB Appendix A products** for 2024–2025 and keep the
  sentence if they agree.
- B. Narrow the sentence to the products that were rerun.

**Recommendation: A, done.** The four MATLAB scripts were rerun on
2024–2025 before the review (see "Pre-review fixes" below), so the sentence
can stay as written if the comparison holds. Two independent
implementations that agree are one of the strongest checks the paper has,
and narrowing the sentence would give it up.

**Applied:** the sentence names the two corridors where the two differ
(gap 13).

### 4. Table numbering (stage 2)

Options:

- **A. Renumber the tables** in order of appearance: Tables 5–7 (ports and
  corridors) become Tables 4–6, and the current Table 4 (zone distance for
  each frequency range) becomes Table 7.
- B. Keep the numbers.

**Recommendation: A.** NTIA and Section 508 practice is to number tables
in the order they appear, and a reader who meets Table 5 before Table 4
will look for a missing table. It is a mechanical change; do it in the
numbers-ledger pass so every cross-reference is checked at the same time.

**Applied:** renumbered in the doc and the Word copy (12 references).

### 5. Alaska data-validity gate (gap 3)

Options:

- **A. Accept Alaska as passing,** counting the one-ship IMO error on
  2019-01-09 as a pass, disclose the 2019-07-10 jump rate in Section 5,
  and include Alaska in gap 4's rebuild without flagged reports.
- B. Hold the Alaska numbers out of the paper until a rebuild without
  flagged reports shows the routes don't change.

**Recommendation: A.** The IMO error touches one ship and no route cell.
The 2019-07-10 flagged reports make 12 route cells (0.044%), the same share
as the lower 48 on a day that passed. Holding Alaska out would drop the
only area where the zones depend on satellite data, which reviewers most
need to see. Against A: the gate was written as a strict two-day rule, and
accepting a near-miss loosens it after the fact; the disclosure and the
gap 4 rebuild are the safeguard.

**Applied:** Alaska accepted. The disclosure goes into Section 5.3 with the
gap 4 rebuild result, which is running (`python/flagged_pairs_day.py` on
all 208 sample days, then `python/ship_flagged_rebuild.py`).

## Exit criteria

The review is done when all of these are true:

- Gaps 1 through 3 are fixed (done November 12, 2026, with decision 5
  open for Alaska).
- Stage 1 passes on a clean clone of the reviewed commit.
- The numbers ledger has no open rows.
- Every stage 3 finding and every gap from 4 through 12 is fixed or
  disclosed.
- Each stage 4 reviewer's comments are resolved or answered in writing.
- The paper is marked DRAFT//PRE-DECISIONAL on every page and passes the
  Section 508 check.
- Nick has signed off.

## Outputs of the review

- `docs/review/numbers_ledger.csv`: the ledger.
- `docs/review/findings_rev1.md`: each finding, who raised it, and how it
  was resolved.
- An updated working paper and Word copy, tagged in the repo with the
  reviewed commit.

## What this plan doesn't cover

- The EMC analysis (Section 2) and the real zone distances.
- Policy judgment on how the zones are used. That needs human review.
- Data that isn't public or cleared.
