function C = emc_coupling_rev1(P, f_mhz, opts)
%EMC_COUPLING_REV1 NEXRAD-ship antenna coupling beyond the horizon, relative to main beam to main beam.
%   C = EMC_COUPLING_REV1(P, f_mhz) returns one row per ship radar type and coupling level with
%     dg_db = MAG - (G_nexrad_peak + G_ship_peak), the change to the link budget's antenna gains (dB, <= 0).
%   Levels:
%     "peak"   largest coupling over every NEXRAD scan mode, both beams aimed along the path in azimuth:
%              the NEXRAD main beam at its lowest tilt seen from the takeoff angle (EMC working paper)
%     "pNN"    mutual antenna gain exceeded (100 - NN)% of the time, NEXRAD scanning its VCPs and the ship
%              antenna rotating, M.2069-0 Annex 1 random mode, worst-mode envelope over all NEXRAD modes
%              (gain_dist_table_rev1 and mag_pair_cdf_rev1 from nicklasorte/mutual_antenna_gain)
%   Takeoff angles: emc_takeoff_angle_rev1 beyond the radio horizon (both 30 m antennas: horizon rays).
%   The pattern is the same for transmit and receive, so the coupling is the same in both directions.
%   opts.pct         percentiles (default [50 90 99 99.9])
%   opts.low_el_deg  a lower first cut for the NEXRAD site (default [], every VCP as flown)
%   opts.bin_db      gain bin of the tables (default 0.05 dB)
arguments
    P (1,1) struct
    f_mhz (1,1) double {mustBePositive}
    opts.pct (1,:) double = [50 90 99 99.9]
    opts.low_el_deg double = []
    opts.bin_db (1,1) double {mustBePositive} = 0.05
end
if ~exist("mag_pair_cdf_rev1", "file")
    error("emc:noMag", "mutual_antenna_gain is not on the path (mag_pair_cdf_rev1 not found).");
end
A = emc_antennas_rev1(P, f_mhz);
[el_n, el_s] = emc_takeoff_angle_rev1(1e4, P.nexrad.height_m, P.ship.height_m, P.analysis.n0);  % beyond horizon
el_grid = (-0.5:0.05:0.5).';
if el_n < el_grid(1) || el_s < el_grid(1)
    error("emc:elGrid", "Takeoff angle below the table grid.");
end
[scans, names] = nexrad_mode_scans_rev1("all", low_el_deg=opts.low_el_deg);
Tn = gain_dist_table_rev1(A.nexrad, scans, struct("name", "WSR-88D", "mode_names", names, ...
    "el_grid_deg", el_grid, "bin_dB", opts.bin_db));
g_nx_peak = A.nexrad.g_max_dBi;
types = ["magnetron", "solid_state"];
levels = ["peak", "p" + compose("%g", opts.pct)];
[system, level] = deal(strings(numel(types)*numel(levels), 1));
[mag_dbi, dg_db] = deal(zeros(numel(system), 1));
r = 0;
for t = types
    Ts = gain_dist_table_rev1(A.(t), A.ship_scan.(t), struct("name", t, "el_grid_deg", el_grid, "bin_dB", opts.bin_db));
    R = mag_pair_cdf_rev1(Tn, Ts, el_n, el_s, struct("pct", opts.pct));
    v = [R.pct.max_on_path_dBi, R.pct{1, 3:2+numel(opts.pct)}];
    for q = 1:numel(levels)
        r = r + 1;
        system(r) = t; level(r) = levels(q); mag_dbi(r) = v(q);
        dg_db(r) = v(q) - g_nx_peak - A.(t).g_max_dBi;
    end
end
C = table(repmat(f_mhz, r, 1), system, level, mag_dbi, dg_db, repmat(el_n, r, 1), repmat(el_s, r, 1), ...
    repmat(A.nexrad_bw_deg, r, 1), repmat(min(Tn.tilt_deg), r, 1), 'VariableNames', ...
    {'f_mhz', 'system', 'level', 'mag_dbi', 'dg_db', 'el_nexrad_deg', 'el_ship_deg', 'nexrad_bw_deg', 'lowest_tilt_deg'});
end
