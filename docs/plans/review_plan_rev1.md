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
- Twelve known gaps are listed below. Three should be fixed before any
  reviewer reads the paper, because they are claims the paper makes that
  haven't been re-verified.
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

| # | Gap | Why it matters | Action |
| --- | --- | --- | --- |
| 1 | The MATLAB versions of the Appendix A figures (`init_ship_viz_rev1`, `init_ship_geo_rev1`, `init_ship_corridors_rev1`, `init_port_share_rev1`) weren't rerun after the move to 2024–2025. | Appendix A says each figure was computed twice, in MATLAB and in Python. For 2024–2025 that is true only for the routes, zones, and filter tables. | Rerun the four scripts on the Mac and compare with the Python products, or change the sentence. |
| 2 | The MATLAB test suite (`test_shipping_zone_rev1.m`) wasn't rerun after four code changes: the route-rule option, the extra ship-water input, the grid-aware land mask, and the fairway loader. | A regression in shared code would affect every area. | Run the suite. Add tests for the ship-days rule, the extra-source input, and an empty fairway file. |
| 3 | The data-validity checks (`python/ais_qc_day.py`) ran on one 2023 day and one 2024 day in the lower 48, and one day in Hawaii. They haven't run on 2025, Alaska 2018–2019, or Puerto Rico. | The gate in `alaska_hawaii_plan_rev1.md` requires two passing days per area before numbers go in the paper. Alaska and Puerto Rico numbers are in the paper without it. | Run two days per area and year. Extend the on-land check beyond the lower 48. |

### Investigate during the review

| # | Gap | Action |
| --- | --- | --- |
| 4 | On 2024-07-10, 288 route cells came only from reports flagged as position jumps or shared ship IDs, and 99 ships had a possible shared ID. | Rebuild the routes with flagged reports removed and count the cells that drop out. |
| 5 | Great Lakes ports rank low on ship counts against tonnage. Lakers without IMO numbers may be filtered out. | Count ships 100 m or longer with no IMO number on the Great Lakes. |
| 6 | Sampling stability hasn't been tested within a year. | Rebuild the routes from 52 of the 104 days and report the overlap. |
| 7 | Hawaii routes shift between years: 56–63% of the held-out years' routes fall inside the 2024–2025 network. | Compare the zones, not the cells, across years. If the zones are stable, say so in Section 4. |
| 8 | Alaska's satellite cutoff matches the shore-based routes only moderately (Jaccard index 0.57), and the hexagons are about 27 km across. | Report the zones at two other cutoffs to show how sensitive they are. |
| 9 | Alaska's ship-days rule and the satellite cutoff rule were analyst choices, not decisions Nick made in advance. | Nick confirms or changes them. |
| 10 | NOAA returned no charted lanes or racons for the Puerto Rico grid, and no racons for Hawaii or Alaska. | Confirm against the charts that none exist, so an empty download isn't mistaken for no features. |
| 11 | On Mobile Bay, more ships are counted at the head port than at the entrance (104%). | Check whether the entrance window is too narrow, and whether other corridors' shares are biased the same way. |
| 12 | The Word copy is assembled by matching figures to alt text. | Check each of the 56 figures against its caption in the Word file. |

### Disclosed limits (confirm the wording is strong enough)

- Alaska uses 2018–2019 data; the rest of the paper uses 2024–2025.
- Shore receivers reach about 40 nautical miles.
- Navy ships often turn AIS off.
- The zone distances are examples until the EMC analysis sets them.
- The western Aleutians, Guam, and American Samoa aren't analyzed.

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

Known item for this stage: Section 3 comes before Section 4, but Table 4
appears after Tables 5 through 7. Decide whether to renumber.

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

1. Confirm or change the Alaska ship-days rule and the satellite cutoff
   (gaps 8 and 9).
2. Decide who the stage 4 reviewers are, and whether outside agencies see
   the paper at this stage.
3. Decide whether the paper should state the MATLAB and Python agreement
   only for what was rerun, or wait for the full MATLAB rerun (gap 1).
4. Decide whether Table 4 keeps its number (stage 2).

## Exit criteria

The review is done when all of these are true:

- Gaps 1 through 3 are fixed.
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
