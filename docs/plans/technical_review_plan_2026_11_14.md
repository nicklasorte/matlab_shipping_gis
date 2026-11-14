# Technical review plan for the routes and zones draft

DRAFT//PRE-DECISIONAL

Prepared November 14, 2026. Inspection baseline: `903e86dde45971061f40c6bc777aafeb8d1f688e` on main. Target: `docs/2.7GHz_Routes_and_Zones_Sections_DRAFT.docx`.

Review whether the draft accurately describes the implemented route model, whether its geographic outputs follow from documented inputs, and whether its conclusions remain defensible under the stated uncertainty. Preserve the DOCX during this work. This document plans the technical review; it does not certify the analysis or repeat earlier claims of successful execution as new results.

## Repository context and priorities

The draft contains Sections 1–6 and Appendix A. Section 1 describes route construction, Section 2 reserves the EMC analysis, Section 3 applies illustrative distances, and Sections 4–6 extend the analysis to Hawaii, Alaska, and Puerto Rico and the U.S. Virgin Islands. Appendix A contains traffic, corridor, and port statistics and figures.

The repository already contains `docs/plans/review_plan_rev1.md`, `next_steps_rev1.md`, a source register, a numbers ledger, and four rounds of review under `docs/review/`. Use these records as leads and preserve their identifiers. Reassess closure against the current DOCX and code instead of starting a competing issue history. The earlier plan's agent calibration and human sign-off arrangements remain historical context; this plan assigns no new reviewers or deadlines.

Two implementation facts need particular attention. `period_rev1.m` selects the first 52 Wednesdays of 2024 and 2025, while README passages and archived products still describe 2023–2024. `route_source_mask_rev1.m` supports both maximum annual distinct ships and summed daily distinct ships. Those are different quantities, and a regional rule change must remain visible in every result and comparison.

The current DOCX distinguishes assumed S-band carriage from regulatory requirements, discusses weekly sampling bias, and labels the zone distances as examples. Verify that these qualifications survive the executive narrative, figures, tables, and exported files. The 2.7 GHz study scope is 2700–3100 MHz; the ship-route contribution covers 2900–3100 MHz.

## 1. Freeze and inventory the evidence

1. Record the review commit, DOCX SHA-256, package metadata, MATLAB release, toolboxes, Python environment, configuration, and input/output checksums. Keep generated evidence in a separate review workspace.
2. Read the complete DOCX XML, tables, captions, relationships, alt text, comments, and tracked changes. Distinguish displayed text from field instructions and deleted text. Render a read-only copy for page and figure inspection; record any rendering limitations.
3. Compare the current draft with `docs/review/round4/paper_rev486.md` and earlier review snapshots. Inventory every section, table, figure, equation, numeric assertion, and source citation using stable paragraph excerpts and captions; add page numbers only after rendering.
4. Reconcile findings from all four rounds and `next_steps_rev1.md`. For each claimed closure, identify the fixing commit, affected paragraph, supporting output, and whether a later change invalidates the evidence.

Deliverable: a baseline manifest and a current-draft coverage index. Gate: no previous result is treated as current without matching its period, configuration, inputs, and implementation.

## 2. Build claim-to-source traceability

Extend the existing `docs/review/numbers_ledger.csv` during the later review, preserving its schema where practical. For each substantive claim, record its location, reported value and units, region, years, population, denominator, generator and configuration, output file and field, independently checked value, tolerance, and disposition.

Trace the main pipeline through regional `init_shipping_zone_*` scripts, `shipping_zone_rev1.m`, `ais_large_ship_cells_rev1.m`, `route_source_mask_rev1.m`, distance functions, polygon construction, and `write_zone_outputs_rev1.m`. Trace Appendix A separately through geographic, corridor, and port-share products and their Python counterparts. Inspect callers and actual configuration values before concluding that a default was used.

Prioritize route-cell totals, source overlaps, land areas at 25/50/100 km, port reach, fixed-site coverage, proxy accuracy, held-out coverage, and regional sensitivity results. Reconcile the README's 658,865 AIS cells with the appendix's explicitly identified Python count of 658,867; determine the reason before calling either wrong. Similarly reconcile differing port-visit totals by period and assignment rule. Counts of distinct ships, daily ship counts, reports, cells, and visits must never share an unexplained denominator.

Gate: each decision-relevant number has reproducible evidence or an explicit unresolved status. Do not hide disagreement by rounding.

## 3. Audit inputs, sampling, and vessel selection

| Review area | Checks and evidence | Acceptance basis |
| --- | --- | --- |
| AIS coverage | Check all 104 selected days per applicable region, raw-file availability, decompression, row counts, geographic coverage, and cache keys. Inspect `period_rev1.m` and `python/ship_period.py` together. | Missing or partial days and cache substitutions are identified; calendar and region agree. |
| Data quality | Inspect MMSI reuse, jumps, invalid coordinates, ship-attribute changes, whole-meter lengths, and AVIS/AVID effects. Revisit flagged-report rebuilds and their zone-area consequences. | Quality checks test the relevant years and regions; exclusions have a documented effect. |
| Filter | Compare MATLAB and Python type, length, IMO-presence, location, and towing tests at boundary values. Test missing, zero, and malformed fields against the documented meaning. | Implementation matches the described proxy, including military and law-enforcement exceptions. |
| Proxy validity | Reproduce length-versus-GT precision and recall from the matched registry population; inspect duplicates, missing matches, and selection bias. Review research-ship truth records and Great Lakes ships without IMO numbers. | Report accuracy applies only to the tested population; observed radar carriage is distinguished from inferred carriage. |
| Sampling | Revisit half-sample stability and held-out comparisons, keeping directional capture distinct from Jaccard overlap. Add an alternative-weekday test if source availability permits. | Wednesday-only validation is not described as testing weekday bias; unequal exposure in half-year 2026 is disclosed. |

Verify regulatory statements against current primary sources during execution: SOLAS V/1 and V/19, 33 CFR 164.01, 164.02, 164.35, and 164.46, and the applicable allocation table and footnotes. Record access dates and the exact provisions used. Review both alternative radar carriage and scope exceptions; infer neither radar band nor actual emissions from an AIS track alone.

## 4. Audit route rules and geographic construction

1. Rebuild annual cell/ship pairs and confirm that the lower-48 rule uses four distinct ships in either individual year, rather than four pooled across years. Check the two-ship port exception, 50 km port radius, and 25 km coastline restriction in the actual code.
2. Verify towing additions independently of ordinary vessel cells. Check source union order and account for AIS, port approaches, charted lanes, racons, and satellite cells without double counting.
3. Audit grid indexing, latitude/longitude order, degrees versus kilometers, spherical distances, edge-cell nearest-neighbor acceleration, and geographic limits. Compare selected points with an independent distance calculation and include a high-latitude case.
4. Verify `ships` versus `shore` behavior with synthetic points. In ships mode, the intended reference is route cells; in shore mode, coastline linkage changes the effective reach. Audit contour interpolation and simplification separately from the distance calculation.
5. Check foreign-land removal and the foreign-water equidistance approximation, including the 200-nautical-mile cap, high seas, Great Lakes, islands, and sources across borders. Establish that water clipping does not silently remove foreign route sources or change the intended U.S. land result. Describe equidistance as a modeling approximation, not an authoritative boundary.
6. Recompute clipped land areas in the stated equal-area projection and quantify rasterization, polygon repair, and simplification effects. Verify nesting of 25, 50, and 100 km products, holes, disconnected pieces, and empty geometries.

Gate: units and coordinate conventions are explicit; discrepancies are bounded with evidence. Choose any numeric tolerance before evaluating the affected comparison, explain its geometric basis, and report both absolute and relative errors.

## 5. Review regional departures

| Region | Required investigation |
| --- | --- |
| Lower 48 | Separate proximity to port reference points from continuous network reach and berth coverage. Check inland-river exclusions, the Mississippi endpoint, and edge truncation at 130° W. |
| Hawaii | Reproduce the ship-days threshold of six and its calibration. Compare zone areas across years as well as route-cell overlap; check disconnected island approaches and unexplained empty chart queries. |
| Alaska | Confirm 2018–2019 source coverage, the 180° grid boundary, and excluded western Aleutians. Audit Kapsar cargo/tanker aggregation, time units, hexagon selection, conversion to water cells, and source licensing. Revisit half/double cutoffs and the 110 near-shore versus 290 offshore hexagons. Track the unresolved choice of satellite-source scope to its effects on each zone area. |
| Puerto Rico and USVI | Verify grid coverage, port exceptions, Mayaguez separation, foreign-water clipping, and the basis for empty fairway or racon results. |

Do not interpret a zero-feature response as proof that no relevant infrastructure exists. Check query extent, service layers, response errors, and chart evidence. Carry unresolved coverage forward in the conclusions.

## 6. Reproduce outputs and diagnose cross-language differences

First run the offline synthetic checks in `test_shipping_zone_rev1.m`, `test_water_clip_rev1.m`, and the existing known-answer fixtures. Inspect prerequisites before invoking Python known-answer and radar-carriage tests. Record exact commands, versions, logs, failures, and skips. Parallel and multi-session MATLAB cases require their stated pool setup; filtered cases are not passes.

Then reproduce one complete current lower-48 configuration and each regional configuration in isolated output folders using the pinned caches. Use production outputs only as comparison targets. Rebuild raw-day caches for representative schema/year/region cases where source files are available. If full downloads are unavailable, state which provenance links remain untested.

Use `python/compare_matlab_python_appA.py` and the corresponding MATLAB products to compare intermediate arrays, source masks, counts, geometry, and final statistics. Diagnose James and Calcasieu path differences at the first divergent cell and compare tie-breaking, costs, route population, and resulting entrance/head counts. Explain why continuation curves differ from entrance-window shares; test whether shares above 100% arise from incompatible populations. Port proximity counts must not be presented as observed port calls without qualification.

Gate: no unexplained consequential difference remains. Existing review records that claim passing tests are supporting history, not execution evidence for this baseline.

## 7. Review uncertainty, figures, and the EMC handoff

Evaluate length thresholds, route thresholds, weekday sampling, flagged reports, regional route rules, satellite cutoff and coverage, source resolution, and polygon simplification. Measure effects on land areas, port coverage, and boundaries, not just cell overlap. Separate sensitivity to analyst choices from evidence about real-world completeness. Mark unavailable experiments as pending rather than assigning assumed outcomes.

Inspect every embedded figure against its actual image relationship, caption, period, legend, scale, units, source product, and alt text. Check numbering and cross-references in a rendered copy. Test readability at intended print size and inspect maps for misleading clipping or color-only distinctions. Review tables and narrative together after any figure regeneration.

For Section 2, document the interface that a later EMC analysis must provide: frequency interval, separation distance, interference criterion, propagation assumptions, antenna and radar parameters, duty and activity assumptions, aggregation method, and applicable uncertainty. Identify which are absent. Do not derive protection distances from traffic density, declare compliance, or present the example frequency-distance pairs as validated EMC results. Check exported band-named files for the same limitation.

## Findings, sequence, and completion criteria

Execute baseline capture and closure reconciliation first, then numeric traceability and source checks, then implementation and regional audits, reproduction, sensitivity, and document presentation. Use independent spot checks for the highest-impact conclusions. Existing records determine what can be reused; changed evidence determines what must be rerun.

Each finding should contain an existing or new unique ID, severity, exact draft locator, expected and observed behavior, supporting code/data/output references, consequence, proposed resolution, verification step, and status. Use critical for a result invalidating the proposed use, major for a material unresolved claim or method error, and minor for a bounded presentation or traceability defect. Record substantive decisions separately from demonstrable defects, retaining who actually made a decision only when supported by evidence.

The later review package should include a coverage matrix, updated numbers ledger, reproducibility logs, reconciled finding dispositions, sensitivity comparisons, and a short list of decisions still needed. Completion requires coverage of every section and result-bearing figure/table, traceable consequential claims, verified closures, explained implementation differences, and clearly stated coverage and EMC limits. Critical and major issues must be resolved or explicitly accepted with their consequences documented. Technical review completion does not itself constitute human approval or regulatory clearance.

## Inspection performed for this plan

Inspected the current DOCX paragraph and table text through its XML package, README, repository layout, existing review-plan and next-steps records, review artifact inventory through round four, period selection, route-rule implementation, and synthetic-test entry point. No MATLAB analysis, full reproduction, regulatory verification, or rendered-page inspection was performed while preparing this plan. These activities are specified above for the review itself.
