# Round-three code review

DRAFT//PRE-DECISIONAL

Date: November 13, 2026. Reviewer: independent code agent (did not write the
code). Scope: `git diff 82ed1a5..HEAD -- '*.m' '*.py'`: the foreign-side water
clip in `shipping_zone_rev1.m`, `distance_to_points_km_rev1.m`,
`load_foreign_land_rev1.m`, `foreign_water_split_rev1.m`,
`init_foreign_water_split_rev1.m`, `python/foreign_water_split.py`, the
`lane_suffix='_nosat'` switch in `init_shipping_zone_alaska_rev1.m`, and
`python/photo_sample_draw_rev1.py`. MATLAB wasn't available, so I read the
MATLAB code and checked it against the committed outputs and logs. I ran the
Python code (numpy, shapely, pyshp, scipy, pandas) on the committed zone files,
the pre-clip zone files from `a6f67af`, and Natural Earth `countries_lakes`. I
edited no other file.

## Summary

The clip is correct as coded. The sign convention, the cap handling, the
protection of U.S. land, the antimeridian handling, and the territory exclusion
all hold. The committed logs show identical U.S. land areas before and after the
clip in all four regions. Re-running the Python split on the clipped zone files
finds 0.03–0.16% foreign-side water left (cell centres). The MATLAB residual of
0.1–0.8% comes from its edge-inclusive rasterization, not from a clip failure.
I found no High-severity defect.

The main issues are about method, not code:

- With the 2,500 km cap, the clip assigns high seas to the nearest coast. In the
  lower-48 25 km zone, it removed about 189,000 km² of water more than 200 nmi
  from any land because Mexico is nearer. It kept about 498,000 km² of high seas
  because the United States is nearer (R3COD-1).
- Equidistance departs from settled boundaries. Using approximate boundary
  lines, about 2,000 km² of the Alaska 25 km zone lies on the U.S. side of the
  1990 U.S.–Russia line but was clipped. About 5,000 km² of the lower-48 25 km
  zone lies on the U.S. side of the 1984 Gulf of Maine line but was clipped
  (R3COD-2).

The photo-sample script is deterministic only for a fixed input row order. It
also drops ships silently in two cases (R3COD-3, R3COD-4). There are no unit
tests for the new functions (R3COD-5).

## Findings

| ID | Severity | File:line | Finding | Failure scenario | Suggested fix |
| --- | --- | --- | --- | --- | --- |
| R3COD-1 | Medium | `shipping_zone_rev1.m:274-284`; `init_shipping_zone*_rev1.m` (`clip_water_cap_km=2500`) | The cap is larger than 200 nmi, so high seas (beyond 200 nmi of every coast) count as "foreign-side" whenever a foreign coast is nearer. High seas nearer the United States stay in the zone. | Pre-clip lower-48 25 km zone, sampled every 0.05°: 1,457,000 km² was foreign-side. Of that, 189,000 km² was more than 370.4 km from any foreign land (180,700 km² of it nearest Mexico, off Baja California). At the same time, 498,000 km² of high seas nearest the United States was kept. If the paper calls this "foreign water", it mislabels high seas and treats them unevenly. | Choose one rule and state it: (a) a cap of 370.4 km, so water beyond 200 nmi of both coasts is never clipped (high seas stay); or (b) keep 2,500 km and describe the removed area as "nearer foreign land", not "foreign water". Report the high-seas area either way. |
| R3COD-2 | Medium | `shipping_zone_rev1.m:266-272` (comment), `:283` | Equidistance stands in for the maritime boundary but departs from settled lines. The comment in the zone code doesn't say so (only `foreign_water_split_rev1.m` mentions it). | Alaska 25 km pre-clip zone: 16,447 km² is nearer Russia. About 1,965 km² of it is east of an approximate 1990 U.S.–Russia line (1,335 km² north of Bering Strait, where the treaty follows 168°58'37"W while equidistance veers east), and the clip removed it. Gulf of Maine: about 5,000 km² is nearer Canada but on the U.S. side of the 1984 ICJ line (points A–D), and the clip removed it. About 2,800 km² on the Canadian side was kept. These are estimates from simplified lines. | Add the caveat to the zone-code comment and the paper. For Alaska and the Gulf of Maine, consider a boundary-line override, or an EEZ layer (option 3) only where a treaty or judgment line exists. |
| R3COD-3 | Medium | `python/photo_sample_draw_rev1.py:30-31` | `pool.sample(random_state=...)` depends on the input row order. The same seed on the same ships in a different order draws a different sample. | Test: shuffling the input rows with the same seed gave a different set of IMO numbers. If someone rebuilds `kept_ships.csv` with a different sort, the "recorded seed" no longer reproduces the sample. | Sort `ships` by `imo` (then `mmsi`) before drawing, and record a hash of the input file next to the seed. |
| R3COD-4 | Medium | `python/photo_sample_draw_rev1.py:24, 31, 37` | Three silent losses. (1) `drop_duplicates("imo")` merges every row with a blank IMO into one row (pandas treats NaN as equal). (2) A ship listed under two groups keeps only its first row. (3) A group smaller than its quota is filled short without a message, and a group of 1–2 ships gets `round(0.2*n)=0` second-coder ships, so the comment "every group has second-coder ships" doesn't hold. | Test: 30 blank-IMO rows became 1 row. A group of 2 ships got 0 overlap ships. | Raise an error on a blank or duplicate `imo`, or on an IMO with conflicting `ship_group`. Print a warning for each group under quota. Use `max(1, round(...))` when the group isn't empty. |
| R3COD-5 | Medium | `distance_to_points_km_rev1.m`, `foreign_water_split_rev1.m`, the clip block in `shipping_zone_rev1.m` | `test_shipping_zone_rev1.m` has no test for the new code. | A future change to the sign or the cap would pass the test suite. | Add tests: distance from a known point to two vertices (compare with `distance`); a synthetic grid with U.S. land on the west, foreign land on the east, and a check that the clip boundary is at the midpoint; a cell beyond the cap of both staying U.S.-side; and a grid on [-180 -170] with foreign vertices at +179.9 (antimeridian). |
| R3COD-6 | Low | `shipping_zone_rev1.m:273` | The clip runs only when foreign land lies inside the grid (`foreign_poly.NumRegions>0`). It also does nothing, without a message, when `p.clip_foreign=false`. That contradicts the comment that land beyond the grid edge counts. | Hawaii is skipped (harmless today: Kiritimati is about 1,700 km from the grid and Hawaii is nearer). A future grid with foreign land just past its edge would be skipped silently. | Gate on `~isempty(f_lat)`, or call `error` or `warning` when `clip_water_foreign_side` is true and the clip can't run. |
| R3COD-7 | Low | `distance_to_points_km_rev1.m:25-27` | With no valid points, the function returns `2*max_km` everywhere and doesn't say so. The caller then marks every cell as U.S.-side. | Today the gate at line 273 protects it. A new caller wouldn't be protected. | `warning('shipgis:nopoints',...)`, or an error, when `~any(ok)`. |
| R3COD-8 | Low | `shipping_zone_rev1.m:183-189` vs `:278-284`; `foreign_water_split_rev1.m:74` | The fairway rule and the water clip use different foreign-land references and tie rules. The fairway rule uses a grid-clipped foreign mask, a 400 km cap, and drops only `d_foreign<d_us` (ties go to the U.S.). The clip uses outline vertices past the grid, a 2,500 km cap, and `side<=0` (ties go to the foreign side). The split also sends ties to the U.S. | In Alaska, a charted-lane cell nearer Russian land west of 180° stays a source (the fairway mask can't see that land), but the clip removes its water. Ties have no practical effect because the contour boundary has zero area. | Use `distance_to_points_km_rev1` in the fairway rule too, and use one tie rule everywhere. |
| R3COD-9 | Low | `shipping_zone_rev1.m:281`; `census_reference_rev1.m` | `d_us` counts only U.S. land inside the grid, but `d_foreign` counts foreign land up to 2,500 km past the grid. | Alaska grid [-180 -129]: the Aleutians west of 180° (Semisopochnoi to Attu) are left out. I found no flipped cell, because Russia is more than 900 km from the in-grid water there. A different grid edge could flip cells. | Add the Census outline vertices beyond the grid to `d_us` (the same approach as `d_foreign`), or note the asymmetry. |
| R3COD-10 | Low | `distance_to_points_km_rev1.m:36-38`; `foreign_water_split*.{m,py}` | Distances go to outline vertices, not to segments. This overestimates distance to land by up to half a segment. | Natural Earth coastal segments near U.S. waters have a median of 1.5–2.3 km. The longest is 48 km (Tamaulipas barrier coast at 24–25°N), which shifts the line by under 3 km at 100 km offshore. Natural Earth 1:10m also omits Cay Sal Bank (Bahamas), which moves the Florida Straits line toward Cuba and the Bahamas, so less water is clipped. | Note both in the method text. Optional: densify foreign rings to 1 km before building the KD-tree. |
| R3COD-11 | Low | `shipping_zone_rev1.m:286-287` | `foreign_side_poly` is simplified at 0.005° before U.S. land is subtracted. A U.S. islet smaller than the tolerance can drop out of the simplified `land_poly` and lose its protection. In border rivers (Detroit, St. Clair, Niagara, St. Marys), the 0.01° grid and the 0.5 km simplification are as wide as half the river. | Zone water in the border rivers is clipped unevenly. Land area doesn't change (the logs confirm this), because `zone_land` uses the same simplified `land_poly`. | Accept it and note it, or simplify after the subtraction with a smaller tolerance near land. |
| R3COD-12 | Low | `load_foreign_land_rev1.m:25, 39-45` | `pad_km` has no `mustBeNonnegative` check. When the caller asks for vertices, the function still builds and unions every foreign polygon. The zone run calls it three times (fairway mask, foreign land, vertices). | A negative pad silently drops vertices. The repeated unions cost time (the lower-48 clip took about 82 s in total, which is acceptable). | Add `{mustBeNonnegative}`. Return the vertices from the call at line 260, or skip the union when `nargout>1` and the first output is ignored. |
| R3COD-13 | Low | `init_shipping_zone_alaska_rev1.m:32, 70, 102` | `clearvars -except lane_suffix` keeps `lane_suffix` in the workspace. A plain run after a `'_nosat'` run in the same MATLAB session runs `_nosat` again. A string `"_nosat"`, as opposed to a char vector, turns `p.out_name` into a 1-by-2 string array and breaks the output names. A misspelled suffix (`'_noSat'`) fails loudly through `mustBeFile`. That's correct. | An interactive base run overwrites nothing, but it silently produces `_nosat` outputs again. | `lane_suffix=char(lane_suffix)`, then `clear lane_suffix` after building `p`, or print the active suffix at the start. |
| R3COD-14 | Low | `init_foreign_water_split_rev1.m:9-12` | The input paths are hard-coded to the committed copies in `outputs/...`, but the zone runs write to `output*/`. The after-clip CSV names `output/...`, so it came from an edited run. | Running the init script right after a new zone run reads stale zone files without a message. | Take the folders as a variable at the top of the script, or check that each zone file is newer than its `.mat` in the run's `out_dir`. |
| R3COD-15 | Low | `python/photo_sample_draw_rev1.py:41-42`; `docs/protocols/photo_coding_protocol_rev1.md` | The comment "shuffle so the sheet order doesn't reveal the group" doesn't help, because `ship_group` is a column on both sheets. Coder A also sees `second_coder`, so coder A knows which ships are double-coded. The protocol says the coder fills "the last six" columns, but there are five blank columns. The protocol's "re-draw a fresh 20%" has no script option. | Coders aren't blind to group or overlap, which can affect the kappa check. | Drop `ship_group` and `second_coder` from the coder sheets and keep a separate key file. Fix "six" to "five". Add a `--redraw-overlap` option that excludes earlier overlap ships. |
| R3COD-16 | Low | `foreign_water_split_rev1.m:39`; `python/foreign_water_split.py` (file name) | In `foreign_water_split_rev1.m`, `R` is the Earth radius, while everywhere else in the repo `R` is the raster reference. The Python twin lacks the `_rev1` suffix that its sibling `photo_sample_draw_rev1.py` and its MATLAB twin use. | This hurts readability and lookup only. | Rename the variable to `earth_radius_km`. Optionally rename the file to `foreign_water_split_rev1.py`. |

## Checked and found correct

- **Sign convention.** `side_km=d_foreign-d_us`. `field_to_zone_polyshape_rev1`
  returns the region `side_km<=0`, which is water nearer foreign land. The pad
  value at level 0 is `0+max(1,0)=1`, so the pad is outside the region and every
  ring closes. A field that is negative over large areas (inland Mexico and
  Canada) only moves the edge contour half a cell past the grid, and the zones
  share that edge.
- **Cap handling.** Each distance is either at most the cap or exactly twice the
  cap. A cell within the cap of one side only is classified exactly. A cell
  beyond the cap of both sides is set to 1 (U.S.-side). The jump at the cap
  moves the contour by at most one cell.
- **U.S. land.** U.S. land is subtracted from both `foreign_poly` and
  `foreign_side_poly`, after simplification. On U.S. land, `d_us=0`. Land areas
  in all four regions are identical before and after the clip in
  `docs/review/round2/rerun/clip/*.log` and `rerun/*.log`.
- **Routes and land areas.** The clip runs after `dist_field_km` and
  `source_mask` are final. Routes, port checks, `land_cells_area_km2`, and the
  saved grids don't change. Band files use the clipped `zone(k).poly`. The routes
  file now extends past the zone polygons in foreign-side water, which is
  expected.
- **Foreign land outside the grid.** It's used. Vertices are filtered only by
  latitude with a generous pad (111.0 km/deg against 111.19), so no vertex
  within the cap is missed. The PR/USVI clip picks up the Dominican Republic past
  68.5°W and Venezuela's Aves Island. Lower 48 uses 356,429 vertices, Alaska
  266,434, and PR/USVI 201,971.
- **Antimeridian.** The clip uses spherical ECEF with a KD-tree, so Russian
  vertices at +179° are correctly near the Alaska cells at -179.9°. Russia's
  artificial vertices along -180° lie on Chukotka and Wrangel Island land, so
  they're valid foreign-land points.
- **U.S. territories.** In Natural Earth, Puerto Rico, the USVI, Guam, American
  Samoa, the Northern Mariana Islands, and the U.S. Minor Outlying Islands all
  have `SOVEREIGNT="United States of America"`, so the zone code drops them.
  That set is exactly the `US_ADM0` list in both split implementations. "USNB
  Guantanamo Bay" has `SOVEREIGNT=Cuba`, so all three treat it as foreign, which
  is consistent. Census `cb_2023_us_state_500k` includes PR and USVI, so they
  are in `land_mask` and `land_poly`.
- **Memory and time on the 18-million-cell grid.** Lower-48 log: the clip took
  about 82 s (19:55:00 to 19:56:22). `distance_to_points_km_rev1` queries in
  blocks of 200 rows (about 1.3 million points per block). Extra peak memory is
  about four full double grids (about 0.6 GB). The temporary arrays are cleared.
- **Split implementations.** `foreign_water_split_rev1.m` and
  `python/foreign_water_split.py` use the same method: Census vertices for U.S.
  land, Natural Earth vertices with the same seven ADM0 codes removed, a 0.02°
  grid aligned with `floor`, an 800 km latitude pad (exact for any distance up to
  800 km), conversion from chord to arc, ties to the U.S., and the 370.4 km flag.
  Their pre-clip results agree within 1–4% of each component, and the
  difference matches the edge-inclusive and cell-centre rasterization
  difference. On the clipped files, the Python split gives a foreign share of
  0.16% (PR/USVI), 0.03% (Alaska), and 0.15% (lower 48), against 0.76%, 0.10%,
  and 0.41% from MATLAB. That confirms the residual is the edge-inclusive
  rasterization.
- **`'_nosat'` switch.** `p.extra_source_csv=''` skips step 2a
  (`strlength('')==0`). `alaska_nosat.log` has no "Extra source" line, and its
  outputs carry the suffix. Nothing downstream reads `result.extra_cells`.
- **Photo-sample draw.** It's deterministic for a fixed input, seed, and order,
  because pandas `sample` uses NumPy `RandomState`. The quotas (100/100/50/50)
  and the 20% overlap within each group (60 of 300) are correct. Missing columns
  and unknown groups raise errors.
- **Conventions.** The new MATLAB files use `_rev1` and snake_case, have
  `arguments` blocks, use `shipgis:` error IDs, and use the `%%%%%` comment
  style. A missing `p.clip_water_cap_km` fails with MATLAB's unrecognized-field
  error. A missing shapefile fails in `readgeotable`. A bad extra-cells CSV fails
  in `read_extra_cells_rev1`. The silent paths are listed in R3COD-4, R3COD-6,
  R3COD-7, and R3COD-14.

Scratch scripts (not in the repo; session scratchpad, may be cleared):
`/tmp/claude-0/-home-claude/0fbc8e62-ca92-5ab2-a790-43caebffdfdc/scratchpad/hs.py` (high-seas split),
`/tmp/claude-0/-home-claude/0fbc8e62-ca92-5ab2-a790-43caebffdfdc/scratchpad/ru.py` (Bering),
`/tmp/claude-0/-home-claude/0fbc8e62-ca92-5ab2-a790-43caebffdfdc/scratchpad/gom.py` (Gulf of Maine),
`/tmp/claude-0/-home-claude/0fbc8e62-ca92-5ab2-a790-43caebffdfdc/scratchpad/ps.py` (photo sample),
`/tmp/claude-0/-home-claude/0fbc8e62-ca92-5ab2-a790-43caebffdfdc/scratchpad/seg.py` (vertex spacing).
