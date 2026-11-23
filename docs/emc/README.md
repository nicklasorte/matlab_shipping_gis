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
| Co-channel separation (paper Section 6) | `init_emc_cochannel_rev1.m` with `emc_params_rev1.m`, `emc_otr_rev1.m`, `emc_required_loss_rev1.m`, `emc_separation_rev1.m`; Python twin `python/emc_link_budget.py`; test `test_emc_cochannel_rev1.m`; parameters `data/emc/`; outputs `outputs/emc/cochannel_*_rev1.csv`; log `outputs/rerun_logs_20261122/emc_cochannel.log` |
| Frequency offset with FDR (paper Section 6.2) | `init_emc_offset_rev1.m` with `emc_emission_rev1.m`, `emc_selectivity_rev1.m`, `emc_ofr_rev1.m`; Python twin `python/emc_fdr.py`; test `test_emc_offset_rev1.m`; outputs `outputs/emc/offset_*_rev1.csv`; figure `docs/emc/fig_offset_separation_rev1.png` (`python/emc_offset_figure.py`); log `outputs/rerun_logs_20261122/emc_offset.log` |
| NEXRAD frequency sweep, 2800-3100 MHz | `init_emc_nexrad_sweep_rev1.m` (ship modes at their closest published tuning, columns `f_lo_mhz`, `f_hi_mhz`, `f_step_mhz` in `data/emc/radar_modes_rev1.csv`); Python twin `python/emc_nexrad_sweep.py`; test `test_emc_nexrad_sweep_rev1.m`; outputs `outputs/emc/nexrad_sweep_*_rev1.csv`; figure `docs/emc/fig_nexrad_sweep_rev1.png`; logs `outputs/rerun_logs_20261123/` |
| Antenna coupling beyond the horizon (paper Section 6.3) | `init_emc_coupling_rev1.m` with `emc_coupling_rev1.m`, `emc_antennas_rev1.m`, `emc_takeoff_angle_rev1.m`; uses nicklasorte/mutual_antenna_gain (`gain_dist_table_rev1`, `mag_pair_cdf_rev1`, `nexrad_mode_scans_rev1`; run at 091b6b0, set `mag_dir`); Python twin of the peak level `python/emc_coupling.py`; test `test_emc_coupling_rev1.m`; outputs `outputs/emc/coupling_*_rev1.csv`; figure `docs/emc/fig_nexrad_sweep_peak_rev1.png` (peak coupling, no longer in the paper); log `outputs/rerun_logs_20261123/emc_coupling.log` |
| Time-share statistics, the base case (paper Sections 6.1-6.4) | `init_emc_statistics_rev1.m` with `emc_joint_rev1.m` (mutual antenna gain distribution from mutual_antenna_gain combined with ITM time variability); Python twin `python/emc_statistics.py`; test `test_emc_statistics_rev1.m`; outputs `outputs/emc/stat_*_rev1.csv`; figures `docs/emc/fig_offset_separation_q1_rev1.png` (Figure 1) and `fig_nexrad_sweep_q1_rev1.png` (Figure 3); log `outputs/rerun_logs_20261123/emc_statistics.log` |
| Mutual antenna gain explained (paper Section 6.3, Figure 2) | `emc_mag_components_rev1.m` (single-antenna gain distributions and the pair's MAG at 3050 MHz beyond the horizon), `plot_emc_mag_rev1.m`; output `outputs/emc/mag_components_3050_rev1.csv`; figure `docs/emc/fig_mag_distribution_rev1.png`; log `outputs/rerun_logs_20261123/emc_mag_components.log` |
| MATLAB figure code | `plot_emc_offset_rev1.m` (Figure 1, MATLAB copy `fig_offset_separation_matlab_rev1.png`), `plot_emc_nexrad_sweep_rev1.m` (sweep figure); helpers `emc_fig_color_rev1.m`, `emc_fig_axes_rev1.m`, `emc_fig_end_labels_rev1.m` |
| Simulation check (paper Section 4.4) | Code: `emc_radar_in_sim/` (radar_in functions copied at 6694e30, with `data/radar_params.csv`, so it reruns from this repo). Results and logs: `outputs/emc/radar_in_sim/` |
| Propagation | nicklasorte/matlab_itm, `itm_area_rev1.m` |

Copies are taken from the Claude Doc at revision 51 (November 23, 2026).
Re-export both copies after each paper edit.
