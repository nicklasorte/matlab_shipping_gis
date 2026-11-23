%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%init_emc_statistics_rev1
%%%%%
%%%%%Separation for a share of time with interference, with no main beam to main beam assumption (Nick,
%%%%%November 23): the antenna coupling is the statistic of NEXRAD scanning its VCPs and the ship antenna
%%%%%rotating (mutual_antenna_gain, M.2069-0 Annex 1 random mode), combined with ITM area-mode time
%%%%%variability (emc_joint_rev1). For each pair the separation is the largest distance at which the received
%%%%%I/N exceeds the victim's criterion more than q% of the time, q = 10, 1 and 0.1%.
%%%%%Inputs (required loss after FDR with peak gains): outputs/emc/offset_separation_rev1.csv (3050 MHz, every
%%%%%offset) and nexrad_sweep_separation_rev1.csv (every NEXRAD frequency; 3050 MHz rows are co-channel).
%%%%%Writes outputs/emc/stat_separation_offset_rev1.csv, stat_envelope_offset_rev1.csv,
%%%%%stat_separation_sweep_rev1.csv, stat_envelope_sweep_rev1.csv, and the Python check inputs
%%%%%stat_itm_3050_rev1.csv and stat_mag_3050_rev1.csv.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars -except itm_dir mag_dir
here = fileparts(mfilename("fullpath"));
if isempty(here), here = pwd; end
if ~exist("itm_dir", "var"), itm_dir = fullfile(here, "..", "matlab_itm"); end
if ~exist("mag_dir", "var"), mag_dir = fullfile(here, "..", "mutual_antenna_gain"); end
if ~isfile(fullfile(itm_dir, "itm_area_rev1.m")), error("emc:noItm", "matlab_itm not found at %s.", itm_dir); end
if ~isfile(fullfile(mag_dir, "mag_pair_cdf_rev1.m")), error("emc:noMag", "mutual_antenna_gain not found at %s.", mag_dir); end
addpath(itm_dir, mag_dir);
out_dir = fullfile(here, "outputs", "emc");
cm = @(d) strtrim(evalc(sprintf('system(''git -C "%s" rev-parse --short HEAD'');', d)));
fprintf("COMMIT %s (matlab_itm %s, mutual_antenna_gain %s)\n", cm(here), cm(itm_dir), cm(mag_dir));

P = emc_params_rev1();
q = [10 1 0.1];
qn = "d_km_q" + replace(string(q), ".", "_");
S = readtable(fullfile(out_dir, "nexrad_sweep_separation_rev1.csv"), "TextType", "string");
O = readtable(fullfile(out_dir, "offset_separation_rev1.csv"), "TextType", "string");
O.f_nexrad_mhz = repmat(P.analysis.f_mhz, height(O), 1);
O.nexrad_gain_dbi = repmat(P.nexrad.gain_dbi, height(O), 1);
key = ["f_nexrad_mhz", "direction", "system", "interferer", "victim", "protection", "df_mhz", "l_req_db", "nexrad_gain_dbi"];
f_nx = unique(S.f_nexrad_mhz);
[dS, fS] = deal(zeros(height(S), numel(q)));
[dO, fO] = deal(zeros(height(O), numel(q)));
for i = 1:numel(f_nx)
    J = emc_joint_rev1(P, f_nx(i));
    rs = find(S.f_nexrad_mhz == f_nx(i));
    [dS(rs, :), fS(rs, :)] = rows_sep(J, S(rs, :), q);
    if f_nx(i) == P.analysis.f_mhz
        [dO, fO] = rows_sep(J, O, q);
        write_check_inputs(J, out_dir);
    end
end
[~, ~, d_los] = emc_takeoff_angle_rev1(100, P.nexrad.height_m, P.ship.height_m, P.analysis.n0);

for src = ["offset", "sweep"]
    if src == "offset", T = O; dd = dO; ff = fO; else, T = S; dd = dS; ff = fS; end
    T = T(:, key);
    T.x_db = T.l_req_db - T.nexrad_gain_dbi;
    T = [T, array2table(dd, 'VariableNames', qn), array2table(ff, 'VariableNames', "flag_" + extractAfter(qn, "d_km_"))]; %#ok<AGROW> two sources
    writetable(T, fullfile(out_dir, "stat_separation_" + src + "_rev1.csv"));
    if src == "offset"
        [g, a1, a2, a3, a4] = findgroups(T.direction, T.system, T.protection, T.df_mhz);
        E = table(a1, a2, a3, a4, 'VariableNames', {'direction', 'system', 'protection', 'df_mhz'});
    else
        [g, a1, a2, a3, a4] = findgroups(T.f_nexrad_mhz, T.direction, T.system, T.protection);
        E = table(a1, a2, a3, a4, 'VariableNames', {'f_nexrad_mhz', 'direction', 'system', 'protection'});
    end
    for k = 1:numel(q)
        E.(qn(k)) = splitapply(@max, T.(qn(k)), g);
    end
    writetable(E, fullfile(out_dir, "stat_envelope_" + src + "_rev1.csv"));
    fprintf("%s: %d rows; envelope distances inside the radio horizon (%.2f km): %d; beyond 2,000 km flags: %d\n", ...
        src, height(T), d_los, sum(E{:, qn} < d_los, "all"), sum(ff == 1, "all"));
    if src == "offset"
        disp(E(ismember(E.df_mhz, [0 10 30 60]), :))
    else
        disp(E(ismember(E.f_nexrad_mhz, [2800 2900 2950 3000 3050]), :))
    end
end
fprintf("init_emc_statistics_rev1: done\n");

function [d_sep, flag] = rows_sep(J, T, q)
% Separation for each row and time share q (%): largest distance where pexc > q.
x = T.l_req_db - T.nexrad_gain_dbi;
if any(x < J.x_db(1) | x > J.x_db(end))
    error("emc:xRange", "Required loss outside the x grid (%.1f to %.1f dB).", min(x), max(x));
end
d_sep = zeros(height(T), numel(q)); flag = d_sep;
for k = 1:height(T)
    pe = J.(T.system(k)).pexc;
    kx = (x(k) - J.x_db(1)) / (J.x_db(2) - J.x_db(1)) + 1;
    k0 = min(floor(kx), numel(J.x_db) - 1);
    w = kx - k0;
    p = (1 - w)*pe(:, k0) + w*pe(:, k0 + 1);
    [ds, fl] = emc_separation_rev1(J.d_km, -10*log10(max(p, 1e-15)), -10*log10(q(:)/100));
    d_sep(k, :) = ds(:, 1).'; flag(k, :) = fl(:, 1).';
end
end

function write_check_inputs(J, out_dir)
% ITM time-variability table and MAG exceedance curves at 3050 MHz, for python/emc_statistics.py.
I = array2table([J.d_km, J.itm_loss_db], 'VariableNames', ["d_km", "q" + replace(compose("%g", J.q_itm), ".", "_")]);
writetable(I, fullfile(out_dir, "stat_itm_3050_rev1.csv"));
rows = {};
for t = ["magnetron", "solid_state"]
    for u = 1:numel(J.(t).mag_curve)
        c = J.(t).mag_curve{u};
        rows{end+1} = table(repmat(t, height(c), 1), repmat(J.(t).el_u(u, 1), height(c), 1), ...
            repmat(J.(t).el_u(u, 2), height(c), 1), c.gain_dBi, c.exceed_pct, 'VariableNames', ...
            {'system', 'el_nexrad_deg', 'el_ship_deg', 'gain_dbi', 'exceed_pct'}); %#ok<AGROW> one per angle
    end
end
writetable(vertcat(rows{:}), fullfile(out_dir, "stat_mag_3050_rev1.csv"));
end
