# radar_in simulation code for the EMC paper (copy)

DRAFT//PRE-DECISIONAL

These files are copied unchanged from
[nicklasorte/radar_in](https://github.com/nicklasorte/radar_in) at commit
`6694e30`, so the simulation in Section 4.4 of the EMC working paper can be
rerun from this repo. The results it made are in `outputs/emc/radar_in_sim/`
(radar_in commit `509f7a4`).

| File | What |
| --- | --- |
| `matlab/run_nexrad_ship_rev1.m` | Driver: reference checks (`ref_wx`, `ref_ship`), ship radar into NEXRAD (`ship2wx`), NEXRAD into ship radar (`wx2ship`) |
| `matlab/radar_to_radar_sim_rev2.m` | Pulsed radar-to-radar simulation, I/N at the victim IF output |
| `matlab/make_radar_rev1.m`, `make_generic_radar_rev1.m`, `radar_pulse_rev1.m` | Radar structs and pulse waveforms |
| `matlab/load_radar_params_rev1.m` | Reads `data/radar_params.csv` |
| `matlab/find_threshold_rev1.m` | I/N at which a metric crosses its criterion |
| `data/radar_params.csv` | Sourced radar parameters (ITU-R and NOAA ROC) |

To rerun (MATLAB R2025b with the Phased Array System and Signal Processing
Toolboxes), from this folder:

```matlab
addpath("matlab")
run_nexrad_ship_rev1(n_trials=50)   % writes results/ here
```

Unit tests for these functions are in radar_in (`matlab/tests/`); they aren't
copied, because they also cover radar_in functions that the EMC paper doesn't
use. If radar_in changes, recopy at the new commit and update this file.
