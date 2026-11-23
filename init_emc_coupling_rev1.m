%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%init_emc_coupling_rev1
%%%%%
%%%%%Separation with the antenna coupling beyond the horizon instead of main beam to main beam (Nick,
%%%%%November 23: fix 1, using nicklasorte/mutual_antenna_gain). Beyond the radio horizon (45 km for two
%%%%%30 m antennas) energy leaves each antenna along its horizon ray, about 0.15 deg below horizontal, so
%%%%%NEXRAD couples through its lowest cut (0.5 deg) about 0.65 deg off its beam axis. The ship's fan beam is
%%%%%24-30 deg tall, so its loss there is negligible.
%%%%%Coupling levels (emc_coupling_rev1): "peak" = both beams aimed along the path in azimuth, NEXRAD at its
%%%%%lowest tilt (the elevation-corrected main beam to main beam case); "pNN" = mutual antenna gain exceeded
%%%%%(100-NN)% of the time with NEXRAD scanning its VCPs (216 modes, worst-mode envelope) and the ship antenna
%%%%%rotating (M.2069-0 Annex 1 random mode).
%%%%%Inputs: outputs/emc/nexrad_sweep_separation_rev1.csv (required loss after FDR at every NEXRAD frequency,
%%%%%with the main-beam gains; 3050 MHz rows are co-channel). Each row's required loss changes by dg_db.
%%%%%Writes outputs/emc/coupling_levels_rev1.csv, coupling_separation_rev1.csv, coupling_envelope_rev1.csv,
%%%%%coupling_sensitivity_rev1.csv.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars -except itm_dir mag_dir
here = fileparts(mfilename("fullpath"));
if isempty(here), here = pwd; end
if ~exist("itm_dir", "var"), itm_dir = fullfile(here, "..", "matlab_itm"); end
if ~exist("mag_dir", "var"), mag_dir = fullfile(here, "..", "mutual_antenna_gain"); end
if ~isfile(fullfile(itm_dir, "itm_area_rev1.m"))
    error("emc:noItm", "matlab_itm not found at %s; set itm_dir.", itm_dir);
end
if ~isfile(fullfile(mag_dir, "mag_pair_cdf_rev1.m"))
    error("emc:noMag", "mutual_antenna_gain not found at %s; set mag_dir.", mag_dir);
end
addpath(itm_dir, mag_dir);
out_dir = fullfile(here, "outputs", "emc");
cm = @(d) strtrim(evalc(sprintf('system(''git -C "%s" rev-parse --short HEAD'');', d)));
fprintf("COMMIT %s (matlab_itm %s, mutual_antenna_gain %s)\n", cm(here), cm(itm_dir), cm(mag_dir));

P = emc_params_rev1();
S = readtable(fullfile(out_dir, "nexrad_sweep_separation_rev1.csv"), "TextType", "string");
f_nx = unique(S.f_nexrad_mhz);
keep = ["peak", "p99.9", "p99", "p90"];

%% Coupling levels at every NEXRAD frequency
CL = cell(numel(f_nx), 1);
for i = 1:numel(f_nx)
    CL{i} = emc_coupling_rev1(P, f_nx(i));
end
CL = vertcat(CL{:});
writetable(CL, fullfile(out_dir, "coupling_levels_rev1.csv"));

%% Separation for every pair, frequency, protection case, and coupling level
p_pct = [50 10 1 0.1];
d_km = [(1:0.1:10)'; (10.5:0.5:2000)'];
[~, ~, d_los] = emc_takeoff_angle_rev1(100, P.nexrad.height_m, P.ship.height_m, P.analysis.n0);
nk = numel(keep);
n = height(S) * nk;
idx = zeros(n, 1); lvl = strings(n, 1); [dg, lreq] = deal(zeros(n, 1)); [dd, fl] = deal(zeros(n, 4));
r = 0;
for i = 1:numel(f_nx)
    L = itm_area_rev1(P.nexrad.height_m, P.ship.height_m, d_km, P.analysis.delta_h_m, f_nx(i), p_pct, ...
        climate=P.analysis.climate, N_0=P.analysis.n0, polarization=P.analysis.polarization, ...
        epsilon=P.analysis.epsilon, sigma=P.analysis.sigma, mdvar=P.analysis.mdvar, ...
        confidence=P.analysis.confidence_pct, validity="off");
    rows = find(S.f_nexrad_mhz == f_nx(i));
    for q = 1:nk
        for k = rows.'
            c = CL.dg_db(CL.f_mhz == f_nx(i) & CL.system == S.system(k) & CL.level == keep(q));
            if numel(c) ~= 1
                error("emc:coupling", "No unique coupling level for %s %s at %g MHz.", S.system(k), keep(q), f_nx(i));
            end
            r = r + 1;
            idx(r) = k; lvl(r) = keep(q); dg(r) = c; lreq(r) = S.l_req_db(k) + c;
            [dd(r, :), fl(r, :)] = emc_separation_rev1(d_km, L, lreq(r));
        end
    end
end
O = [S(idx, ["f_nexrad_mhz", "direction", "system", "interferer", "victim", "protection", "df_mhz"]), ...
    table(lvl, dg, lreq, dd(:, 1), dd(:, 2), dd(:, 3), dd(:, 4), fl(:, 1), fl(:, 2), fl(:, 3), fl(:, 4), ...
    dd(:, 1) > d_los, 'VariableNames', {'coupling', 'dg_db', 'l_req_db', 'd_km_p50', 'd_km_p10', 'd_km_p1', ...
    'd_km_p0_1', 'flag_p50', 'flag_p10', 'flag_p1', 'flag_p0_1', 'beyond_horizon_p50'})];
writetable(O, fullfile(out_dir, "coupling_separation_rev1.csv"));
fprintf("Rows with the 50%% separation inside the radio horizon (%.1f km), where the horizon-ray takeoff angle " + ...
    "understates the coupling: %d of %d (levels: %s)\n", d_los, sum(~O.beyond_horizon_p50), height(O), ...
    strjoin(unique(O.coupling(~O.beyond_horizon_p50)), ", "));

%% Envelope over pairs
[g, gf, gd, gs, gp, gc] = findgroups(O.f_nexrad_mhz, O.direction, O.system, O.protection, O.coupling);
E = table(gf, gd, gs, gp, gc, splitapply(@max, O.d_km_p50, g), splitapply(@max, O.d_km_p10, g), ...
    splitapply(@max, O.d_km_p1, g), splitapply(@max, O.d_km_p0_1, g), 'VariableNames', ...
    {'f_nexrad_mhz', 'direction', 'system', 'protection', 'coupling', 'd_km_p50', 'd_km_p10', 'd_km_p1', 'd_km_p0_1'});
writetable(E, fullfile(out_dir, "coupling_envelope_rev1.csv"));
disp(E(E.f_nexrad_mhz == 3050, :))
disp(E(ismember(E.f_nexrad_mhz, [2800 2950 3000]) & E.coupling == "peak", :))

%% Sensitivity of the peak coupling at 3050 MHz (one input at a time)
sens = {"base", struct(), []
        "NEXRAD beamwidth 0.85 deg at 2850 MHz", struct("beamwidth_deg", 0.85), []
        "NEXRAD beamwidth 0.95 deg at 2850 MHz", struct("beamwidth_deg", 0.95), []
        "Lowest cut 0.0 deg (site option)", struct(), 0.0
        "Lowest cut -0.2 deg (site option)", struct(), -0.2
        "Antennas 50 m", struct("h", 50), []};
rows = cell(size(sens, 1), 1);
for s = 1:size(sens, 1)
    Ps = P;
    fn = fieldnames(sens{s, 2});
    for j = 1:numel(fn)
        if fn{j} == "h"
            Ps.nexrad.height_m = sens{s, 2}.h; Ps.ship.height_m = sens{s, 2}.h;
        else
            Ps.nexrad.(fn{j}) = sens{s, 2}.(fn{j});
        end
    end
    c = emc_coupling_rev1(Ps, P.analysis.f_mhz, low_el_deg=sens{s, 3});
    c = c(c.level == "peak", :);
    rows{s} = [table(repmat(string(sens{s, 1}), height(c), 1), 'VariableNames', {'case'}), c];
end
SN = vertcat(rows{:});
writetable(SN, fullfile(out_dir, "coupling_sensitivity_rev1.csv"));
disp(SN(:, ["case", "system", "dg_db", "el_nexrad_deg", "lowest_tilt_deg"]))
fprintf("init_emc_coupling_rev1: done\n");
