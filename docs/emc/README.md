# EMC working paper: NEXRAD and shipborne S-band radars

DRAFT//PRE-DECISIONAL

A separate working paper from the routes and zones paper. It finds the
separation a NEXRAD (WSR-88D) and a shipborne S-band radar need, co-channel
(NEXRAD assumed to tune 3020-3080 MHz) and at frequency offsets, with ITM area
mode and main beam to main beam coupling.

| Item | Where |
| --- | --- |
| Working paper (Claude Doc, the editable source) | https://claude.ai/artifact/Dcc1nD6zP3u6KuDejA6B2d |
| Word copy | `docs/emc/2.7GHz_EMC_NEXRAD_Ship_Radar_DRAFT.docx` |
| Markdown copy (for diffs) | `docs/emc/emc_working_paper_DRAFT.md` |
| Plan, steps E1-E10, decisions | `docs/plans/emc_nexrad_ship_plan_rev1.md` |
| Pulsed-interference protection levels (M.1849-3 8.4.2) | `python/emc_pulsed_in.py`, `emc_pulsed_in_rev1.m`, test `test_emc_pulsed_in_rev1.m`, output `outputs/emc/pulsed_in_criteria_rev1.csv` |
| Simulation check (paper Section 4.4) | `outputs/emc/radar_in_sim/` (results, logs, and a copy of `run_nexrad_ship_rev1.m`; the core simulation `radar_to_radar_sim_rev2.m` is in nicklasorte/radar_in at 6694e30) |
| Propagation | nicklasorte/matlab_itm, `itm_area_rev1.m` |

Copies are taken from the Claude Doc at revision 27 (November 22, 2026).
Re-export both copies after each paper edit.
