function C = emc_mag_components_rev1(P, modes, f_mhz)
%EMC_MAG_COMPONENTS_REV1 Single-antenna gain distributions and their mutual antenna gain, for the paper.
%   C = EMC_MAG_COMPONENTS_REV1(P, modes, f_mhz) returns a table of exceedance curves (share of time a gain is
%   exceeded) beyond the radio horizon, both antennas at their horizon-ray takeoff angles:
%     "nexrad"           NEXRAD's gain toward the ship (worst of its 216 VCP modes at each gain)
%     "magnetron"        the IMO magnetron fan beam's gain toward NEXRAD, rotating
%     "solid_state"      Radar No. 3B's gain toward NEXRAD, rotating
%     "mag_magnetron"    mutual antenna gain NEXRAD-magnetron (the convolution of the two, worst mode)
%     "mag_solid_state"  mutual antenna gain NEXRAD-solid state
%   Gains are absolute (dBi): the ship curves add the largest mode gain of that type in radar_modes_rev1.csv
%   (28 dBi magnetron, 27.5 dBi solid state). A single antenna's distribution is the mutual antenna gain
%   against an isotropic 0 dBi antenna (offaxis_table of 0 dB), so it comes from the same mag_pair_cdf_rev1
%   code as the pair. Built-ins considered: none; this wraps nicklasorte/mutual_antenna_gain.
arguments
    P (1,1) struct
    modes table
    f_mhz (1,1) double {mustBePositive} = 3050
end
if ~exist("mag_pair_cdf_rev1", "file")
    error("emc:noMag", "mutual_antenna_gain is not on the path.");
end
A = emc_antennas_rev1(P, f_mhz);
[el_n, el_s] = emc_takeoff_angle_rev1(1e4, P.nexrad.height_m, P.ship.height_m, P.analysis.n0);
el_grid = (-0.5:0.05:0.5).';
[scans, names] = nexrad_mode_scans_rev1("all");
Tn = gain_dist_table_rev1(A.nexrad, scans, struct("name", "WSR-88D", "mode_names", names, "el_grid_deg", el_grid));
iso = struct("type", "offaxis_table", "g_max_dBi", 0, "offaxis_deg", [0; 180], "gain_dB", [0; 0], "az_bw_deg", 1);
Ti = gain_dist_table_rev1(iso, struct("type", "mech_rotating", "rate_rpm", 12, "tilt_deg", 0), ...
    struct("name", "isotropic", "el_grid_deg", el_grid));
co = struct("return_curve", true, "pct", 99);
parts = {};
R = mag_pair_cdf_rev1(Tn, Ti, el_n, el_s, co);
parts{end+1} = curve_table("nexrad", R.curve{1}, 0);
for t = ["magnetron", "solid_state"]
    g_ship = max(modes.gain_dbi(modes.system == t));
    Ts = gain_dist_table_rev1(A.(t), A.ship_scan.(t), struct("name", t, "el_grid_deg", el_grid));
    R = mag_pair_cdf_rev1(Ti, Ts, el_n, el_s, co);
    parts{end+1} = curve_table(t, R.curve{1}, g_ship); %#ok<AGROW> five curves
    R = mag_pair_cdf_rev1(Tn, Ts, el_n, el_s, co);
    parts{end+1} = curve_table("mag_" + t, R.curve{1}, g_ship); %#ok<AGROW> five curves
end
C = vertcat(parts{:});
C.f_mhz = repmat(f_mhz, height(C), 1);
C.el_nexrad_deg = repmat(el_n, height(C), 1);
C.el_ship_deg = repmat(el_s, height(C), 1);
end

function T = curve_table(name, c, offset_db)
T = table(repmat(string(name), height(c), 1), c.gain_dBi + offset_db, c.exceed_pct, ...
    'VariableNames', {'curve', 'gain_dbi', 'exceed_pct'});
end
