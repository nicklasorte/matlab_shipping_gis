# Round-three numbers review

DRAFT//PRE-DECISIONAL

Date: November 13, 2026. Reviewer: independent numbers agent. Paper:
`paper_under_review_r3.md`. Scope: numbers changed or added since `82ed1a5`
(water clip, Alaska satellite-lane sensitivity, flagged-cell land change, land
areas in Sections 3 to 6), plus `round2/findings_r2.md` ("Mac zone rerun" and
"Water clip"), `round2/foreign_water_decision_rev1.md`, and
`sband_truth_ships_rev1.md`. All recomputation used python3 and pandas on the
committed files. No other file was edited.

## Summary

Most new numbers trace to a committed output and recompute correctly. Every land
area in Sections 3 to 6 matches the clipped-run logs exactly. The clip changes
no land. The Alaska sensitivity percentages (19/14/10, 10/5/4, 11/9/7) and the
absolute areas match the rerun logs. The flagged-cell change of 0.13–0.19%
matches its JSON file.

Problems found:

- **Water-clip shares.** The paper quotes the Python 0.02° estimate (36–42%,
  5–8%). The MATLAB clip that built the published files removed 36.8–42.2% in
  the lower 48 and 5.7–8.4% in Alaska. Those round to 37–42% and 6–8%.
- **Decision note.** Its claim that Python land matches the paper to within 0.3%
  is false outside the lower 48 (up to 0.72%).
- **Stale files.** `foreign_water_by_country_py.csv` has stale Puerto Rico rows,
  and no script in the repo writes that file.
  `outputs/2018_2019/alaska/sensitivity/alaska_cutoff_sensitivity.csv` still
  holds the superseded 4/3/2 and 8/7/6 results.
- **Racon count.** "Water clip" in the findings says three Canadian racons fell
  outside the zones. The sites table shows six.
- **R2NUM-4 distances.** The rerun site distances are inconsistent with
  themselves: Port Allen is 24.6 km from a route vertex yet outside the 25 km
  zone. The paper also still quotes the first-round distances.
- **Truth-set tonnage.** The finding that four ships are "below 3,000 GT" rests
  on GRT figures, which the note's own caution says not to use for the SOLAS
  test. Two of the figures equal displacement values elsewhere in the CSV.
- **No source.** The new lower-48 land shares (4%, 8%, 16%) have no output file.

## Findings

| ID | Type | Location | Finding | Evidence (file and value) | Suggested fix |
| --- | --- | --- | --- | --- | --- |
| R3NUM-1 | Number | Paper Sec. 3, zone-file paragraph ("36% to 42%") | The lower-48 share uses the Python estimate. The MATLAB pre-clip split (37.0%, 39.7%, 42.4%) and the water the MATLAB clip actually removed (36.8%, 39.5%, 42.2%) both round to 37–42%. The published zone files come from the MATLAB clip. | `outputs/foreign_water_split_py.csv`: 0.3648 / 0.3927 / 0.4196. `outputs/foreign_water_split_rev1.csv`: 0.3701 / 0.3973 / 0.4240. Removed share = (pre water − post water) / pre water, using `rerun/clip/foreign_water_after_clip.csv`: 36.75% / 39.50% / 42.19%. | Write "37% to 42%", or "about 37% to 42%", and name the source (MATLAB clip). |
| R3NUM-2 | Number | Paper Sec. 3 ("5% to 8% in Alaska") | Same issue. The MATLAB clip removed 5.7%, 7.0%, and 8.4%, which rounds to 6–8%. Only the Python 25 km figure (5.39%) gives 5%. | `foreign_water_split_rev1.csv` Alaska: 0.0582 / 0.0709 / 0.0844. Removed share from the after-clip CSV: 5.72% / 7.00% / 8.36%. | "6% to 8%". |
| R3NUM-3 | Wording | Paper Sec. 3 ("mostly off Mexico, the Bahamas, Cuba, and Canada") | Canada holds more foreign water than Cuba at every distance, and more than the Bahamas at 25 and 50 km. The list order implies otherwise. | `outputs/foreign_water_by_country_py.csv` lower 48: MEX 70–74%, CAN 10.4–11.8%, BHS 7.7–12.9%, CUB 6.3–6.8%. | "mostly off Mexico, then Canada, the Bahamas, and Cuba". |
| R3NUM-4 | Number | `foreign_water_decision_rev1.md`, "How much water is foreign" ("Python land ... matches the paper's land areas to within 0.3%") | True only for the lower 48 (≤0.15%). Hawaii 25 km is +0.72%, Hawaii 100 km +0.35%, Puerto Rico 25 km −0.51%, and Alaska −0.51% to −0.65%. | `foreign_water_split_py.csv` land compared with the paper's land areas: Hawaii 7,926 vs 7,869; Puerto Rico 7,174 vs 7,211; Alaska 111,693 / 209,823 / 351,830 vs 112,426 / 210,895 / 353,639. | "within 0.2% in the lower 48 and 0.8% elsewhere". |
| R3NUM-5 | Number | `outputs/foreign_water_by_country_py.csv` (Puerto Rico rows); decision note "By nearest country" | The Puerto Rico rows list PRI and VIR (U.S. territories) as foreign countries. Their foreign water sums to 66,258 km², but the split file gives 29,236 km². These rows predate the territory fix in `000d0a1`. The note's text (BVI and Dominican Republic only) is right, but the file it cites contradicts it. No script in the repo writes this CSV: `python/foreign_water_split.py` writes only the split file. | Sum of the Puerto Rico 25 km rows: 66,258. `foreign_water_split_py.csv`: 29,236. PRI 0.463 and VIR 0.097 shares of "foreign" water. The repo has no "by_country" code. | Regenerate the by-country table with US_ADM0 excluded, and commit the script that writes it. Until then, mark the Puerto Rico rows as superseded. |
| R3NUM-6 | Number | `outputs/2018_2019/alaska/sensitivity/alaska_cutoff_sensitivity.csv`, `ak_x0.5.log`, `ak_x2.log`, `*_x0.5_*` and `*_x2_*` port checks | These files are from November 12, under the old zone definition (base 179,047 km²; changes +4.2/+3.4/+2.0 and −8.0/−7.3/−5.7). They contradict the paper's 10/5/4 and 11/9/7. "Mac zone rerun" in the findings cites this folder as evidence that all five ports stay inside the 25 km zone in every run, but only the nosat files there are new. The new numbers come from `docs/review/round2/rerun/alaska_*.log`. | Last commit for the CSV and the x2 port check: Nov 12 (`7a66f5c`, `9586885`). Rerun logs: x0.5 123,628 / 221,715 / 367,178; x2 100,013 / 192,746 / 330,144. | Regenerate the CSV and port checks from the rerun, or add a note that the folder is superseded. Point the findings at the rerun logs. The port claim still holds, because every gap is ≤ 22.1 km and the zones are distance-to-route, but the cited evidence is stale. |
| R3NUM-7 | Number | `findings_r2.md` "Water clip" ("Three Canadian racons ... now fall outside the zones") | The clip moved five Salish Sea racons from inside to outside every zone, and the Lake Superior racon (47.04 N, 84.79 W) is also outside. That makes six Canadian racons outside, not three. One of them (49.075 N, 123.381 W) is S-band. | `git diff 82ed1a5..HEAD -- outputs/2024_2025/shipping_zone_2024_2025_sites.csv`: rows at 48.2346/−123.5330, 49.0752/−123.3809, 49.0381/−123.2564, 48.3754/−123.3926, and 48.8032/−123.0274 changed from 1,1,1 to 0,0,0. The 47.0375/−84.7865 row is 0,0,0. | "Six Canadian racons (five in the Strait of Juan de Fuca and Strait of Georgia, one in Lake Superior)". Check the 48.80 N, 123.03 W position against the boundary. |
| R3NUM-8 | Number | `findings_r2.md` "Mac zone rerun", R2NUM-4; paper Secs. 4.2, 5.2, 6.1 | Two problems. (a) Port Allen is 24.6 km from the nearest route vertex but flagged outside the 25 km zone. A vertex distance is an upper bound on the distance to the polygon, so the zone test or the distance is off. The 0.5 km simplification or the cell-centre basis may explain it, but nothing says so. (b) The findings say that a paper quoting distances should use the rerun values. The paper still quotes 18.9, 25.3, 19.5, and 0.2 km. | `rerun/r2num4_site_distances.csv`: Port Allen km_to_route 24.61, in_25km_zone 0; Lahaina 18.24; Vieques 18.57; Red Dog 0 (5.84 on ship tracks alone). Paper Sec. 4.2: "Lahaina is 18.9 km and Port Allen 25.3 km"; Sec. 6.1: "19.5 km"; Sec. 5.2: "0.2 km". | Explain the Port Allen result, or recompute it as a distance to cell centres. Then update the paper's distances or drop them. |
| R3NUM-9 | Unverified | Paper Sec. 3.1, last paragraph ("4% ... 8% ... 16%" of Census land in the grid) | No committed log, CSV, or JSON gives the Census land total for the lower-48 grid. The implied base is about 7.5–7.9 million km², which is plausible. | The clip logs and `outputs/2024_2025/` have no lower-48 land total. Alaska (1,518,386 km²) is computed in the Python figure scripts and isn't logged either. | Log the grid's Census land total in `shipping_zone_rev1` or a Python summary JSON, and cite it. |
| R3NUM-10 | Wording | Paper Sec. 1.6 ("reduces the land in the zones by 0.13–0.19%") | The percentages are correct, but they use a different metric from the paper's land areas: Python direct-distance land on AIS route cells only (base 286,109 km² against the paper's 301,168 km²). A relative change is still a fair estimate. | `outputs/2024_2025/flagged/flagged_land_change.json`: −0.137%, −0.193%, −0.128%; base 286,109 / 620,264 / 1,245,932. | Optional: "by about 0.13–0.19% (AIS route cells only)". |
| R3NUM-11 | Wording | Paper Sec. 3 ("0.5 to 0.7 million km² of U.S.-side water") | The figure is correct. Note that `beyond_200nmi_km2` counts all zone water beyond 370.4 km, including the 0.4% residual foreign-side cells, and that the shares and this figure come from different tools (Python and MATLAB). | `rerun/clip/foreign_water_after_clip.csv`: 505,106 / 599,823 / 676,473 km². `foreign_water_split_rev1.m` line 9: "overlay on the two water classes". | None needed. Optionally say both figures come from the MATLAB clip after R3NUM-1. |
| R3NUM-12 | Number | `sband_truth_ships_rev1.md` Finding 2 ("Four carry S-band below 3,000 GT") | The four figures are IRVSI GRT. The note's own caution says GRT and ITC GT "can differ a lot" (Kilo Moana: 1,407 GRT, 3,060 ITC) and that ITC should decide the 3,000 GT test. None of the four has an ITC figure, so "below the SOLAS threshold" isn't shown. Two values are also suspect. Henry B. Bigelow's 2,479 equals the 2,479 t displacement in the CSV note for its sister ship, Oscar Dyson. Ronald H. Brown's 3,250 equals the displacement in the WHOI spec sheet, per the CSV note. | `data/sband_truth_ships.csv`: Bigelow gross_tonnage 2479; Oscar Dyson note "displacement 2479 metric tons only"; Brown gross_tonnage 3250, Furuno-row note "displacement 3250 tons only". | Reword to "four list under 3,000 GRT; ITC tonnage not found". Check the Bigelow and Brown values against a tonnage source and mark them as possible displacement. |
| R3NUM-13 | Wording | `sband_truth_ships_rev1.md` "What's in the table" ("Ships come from the UNOLS fleet and the NOAA fleet") | Healy is a Coast Guard ship (fleet USCG). | CSV row Healy: fleet USCG, operator U.S. Coast Guard. | "the UNOLS and NOAA fleets and one Coast Guard icebreaker (Healy)". |
| R3NUM-14 | Wording | `sband_truth_ships_rev1.md` "Matching to AIS" ("IMO number first (Atlantis, Ronald H. Brown, Henry B. Bigelow)") | The CSV also has IMO numbers for Gordon Gunter (8835255, an S-band ship) and Healy (9083380). | CSV `imo` column. | Add Gordon Gunter and Healy. |
| R3NUM-15 | Unverified | Paper Sec. 3.1 ("none larger than 128 km²"); Sec. 1.5 ("about 11 km²" near Russia) | Both come from runs before the clip and the zone redefinition (`nesting_check_rev1.json`, CA-84; R2OPP-16 via `fix_results_rev1.md`). The clip reshaped the open-water edges, so the sliver sizes may have changed. | `docs/review/findings_rev1.md` CA-84; `round2/agent_opposing_r2.md` R2OPP-16. | Rerun the nesting check on the clipped zones, or drop the km² figure. Do the same for the 11 km² figure. |

## Verified as correct

- **Land areas, Sections 3 to 6.** All match `rerun/clip/*.log` exactly. Lower
  48: 301,168 / 638,688 / 1,261,529 km². Hawaii: 7,869 / 14,132 / 16,717 km².
  Puerto Rico and USVI: 7,211 / 9,278 / 9,278 km². Alaska: 112,426 / 210,895 /
  353,639 km².
- **Land shares.** Hawaii 47% and 85%. Puerto Rico 78%. Alaska 7.4%, 13.9%, and
  23.3% of 1,518,386 km², which round to 7%, 14%, and 23%.
- **Land unchanged by the clip.** The pre-clip logs (`rerun/*.log`) and the clip
  logs agree to the km² in all four regions. The MATLAB split shows land changes
  of 16 km² or less (≤0.003%). Route cells, fairway cells (45,088; 3,427 and
  6,800 dropped), and source cells are identical.
- **Other water-clip numbers.** Puerto Rico 20% (MATLAB 20.2–20.4% pre-clip,
  19.6–19.8% removed; Python 19.9–20.2%). Hawaii has no foreign water. The
  lower 48 keeps 0.5 to 0.7 million km² beyond 200 nmi.
- **Foreign-side water left after the clip** (findings): 0.4%, 0.8%, 0.1%, and
  0% (0.36–0.41%, 0.76–0.79%, 0.08–0.10%).
- **Decision note cross-checks.** Shares agree to within 0.6 percentage points
  (maximum 0.5). Lower-48 and Puerto Rico foreign-water areas agree to within 3%
  (maximum 2.3%), and Alaska to within 8% (maximum 7.5%). MATLAB lower-48 land
  is +13% (12.6%). The table's rounded shares are correct. The by-country
  shares for the lower 48 (70–74, 10–12, 8–13, 6–7%) are correct. The 1.4 to
  2.2 million km² beyond 200 nmi is correct (Python 1.41–2.19 million).
- **Alaska sensitivity, Secs. 5.1 and 5.3, and the findings table.** These match
  `rerun/alaska_*.log`. No satellite lanes: −19.13%, −14.14%, −10.42% (90,923 /
  181,070 / 316,800 km²). Half the cutoff: +9.96%, +5.13%, +3.83%. Double the
  cutoff: −11.04%, −8.61%, −6.64%. Percentages are of the base zone's area, as
  stated. Cutoffs 136 and 544, hexagons 633 and 304, and the next tested cutoff
  of 659 match `satellite_lanes*.json` (`jaccard_curve`). So do 400 hexagons,
  290 beyond shore range, 334,651 / 318,210 cells, and Jaccard 0.571. The
  "earlier 4%, 3%, 2% and 8%, 7%, 6%" match the stale CSV. All five ports have a
  25 km flag of 1 in the nosat files, and every port gap is ≤ 22.1 km in all
  runs.
- **Flagged cells.** 4,474 cells (0.679%), and 0, 1, and 11 in the other
  regions (`flagged_rebuild.json`). The land change is 0.137%, 0.193%, and
  0.128%, which gives 0.13–0.19% (`flagged_land_change.json`).
- **"Mac zone rerun."** The land table matches the logs. Total area grows 1.31%
  to 1.54% (stated as 1.3% to 1.5%). The Great Lakes box grows 29%, 24%, and
  18% (`lower48_zone_area_change.csv`).
- **Alaska median of 54 ships a day.** The median of the 104 daily counts in
  `alaska_base.log` is 53.5.
- **Truth set.** 25 rows and 18 ships. The groups of 9 S-band ships, 1 with X
  band only, and 8 with no band are correct. The eight lengths (83.5, 83.5,
  83.3, 68.3, 68.3, 63.6, 63.6, and 63.4 m) are correct, and Sally Ride has no
  length. ITC 3,304, 3,180, 3,058, and 3,060 are correct. No MMSI is filled.

## Not checked

Numbers outside the scope above that also changed in r3 and weren't
recomputed: Appendix A.8 (0.3–2%, 13.0/11.8/11.7%), "charted lanes add about 1%
to 2%", Sec. 1.10 (1.8/2.1/1.0%), Appendix A.2 distances, and "about 3% of
Alaska's and 9% of Florida's" inland water. The last has no source file found.
