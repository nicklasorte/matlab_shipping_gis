%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%init_emc_cochannel_rev1
%%%%%
%%%%%Co-channel separation between NEXRAD and shipborne S-band radars (magnetron and solid state, equal
%%%%%cases), both directions, main beam to main beam, ITM v1.4 area mode (matlab_itm itm_area_rev1).
%%%%%EMC working paper, docs/emc; plan docs/plans/emc_nexrad_ship_plan_rev1.md (steps E1, E5, E6).
%%%%%Writes outputs/emc/cochannel_required_loss_rev1.csv, cochannel_separation_rev1.csv,
%%%%%cochannel_sensitivity_rev1.csv, cochannel_itm_check_rev1.csv.
%%%%%Needs matlab_itm on the path (itm_dir below, or set before running).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars -except itm_dir
here = fileparts(mfilename("fullpath"));
if isempty(here), here = pwd; end
if ~exist("itm_dir", "var"), itm_dir = fullfile(here, "..", "matlab_itm"); end
if ~isfile(fullfile(itm_dir, "itm_area_rev1.m"))
    error("emc:noItm", "matlab_itm not found at %s; set itm_dir.", itm_dir);
end
addpath(itm_dir);
out_dir = fullfile(here, "outputs", "emc");
if ~isfolder(out_dir), mkdir(out_dir); end
[~, c1] = system(sprintf('git -C "%s" rev-parse --short HEAD', here));
[~, c2] = system(sprintf('git -C "%s" rev-parse --short HEAD', itm_dir));
fprintf("COMMIT %s (matlab_itm %s)\n", strtrim(c1), strtrim(c2));

[P, modes] = emc_params_rev1();
p_pct = [50 10 1 0.1];
d_km = [(1:0.1:10)'; (10.5:0.5:2000)'];

%% Base case
T = emc_required_loss_rev1(P, modes);
writetable(T, fullfile(out_dir, "cochannel_required_loss_rev1.csv"));
L = itm_grid(P, P.nexrad.height_m, P.ship.height_m, P.analysis.f_mhz, P.analysis.climate, P.analysis.n0, ...
    P.analysis.delta_h_m, d_km, p_pct);
[d_sep, flag] = emc_separation_rev1(d_km, L, T.l_req_db);
S = T(:, ["direction", "system", "interferer", "victim", "l_req_db"]);
for p = 1:numel(p_pct)
    S.("d_km_p" + strrep(string(p_pct(p)), ".", "_")) = round(d_sep(:, p), 1);
    S.("flag_p" + strrep(string(p_pct(p)), ".", "_")) = flag(:, p);
end
writetable(S, fullfile(out_dir, "cochannel_separation_rev1.csv"));

%% ITM checks: loss against free space, and monotone trend
lfs = 32.45 + 20*log10(P.analysis.f_mhz) + 20*log10(d_km);
C = table(p_pct', min(L - lfs)', d_km(arrayfun(@(p) find(L(:, p) - lfs == min(L(:, p) - lfs), 1), 1:numel(p_pct)))', ...
    L(end, :)', 'VariableNames', {'time_pct', 'min_loss_minus_free_space_db', 'at_km', 'loss_at_2000km_db'});
writetable(C, fullfile(out_dir, "cochannel_itm_check_rev1.csv"));
disp(C)

%% Sensitivity: governing (largest required loss) pair for each direction and radar type
gov = strings(0); key = strings(0);
for dirn = ["ship to NEXRAD", "NEXRAD to ship"]
    for sys = ["magnetron", "solid_state"]
        sel = find(T.direction == dirn & T.system == sys);
        [~, i] = max(T.l_req_db(sel));
        gov(end+1) = dirn + " | " + sys; key(end+1) = T.interferer(sel(i)) + " -> " + T.victim(sel(i)); %#ok<SAGROW>
    end
end
cases = {
    "base", P, "pulsed", NaN, P.analysis.f_mhz, P.nexrad.height_m, P.ship.height_m, P.analysis.climate, P.analysis.n0, P.analysis.delta_h_m
    "NEXRAD I/N -10 dB (constant)", P, "constant", NaN, P.analysis.f_mhz, P.nexrad.height_m, P.ship.height_m, P.analysis.climate, P.analysis.n0, P.analysis.delta_h_m
    "ship I/N +30 dB (pulsed tolerance)", P, "pulsed", P.ship.in_pulsed_db, P.analysis.f_mhz, P.nexrad.height_m, P.ship.height_m, P.analysis.climate, P.analysis.n0, P.analysis.delta_h_m
    "3020 MHz", P, "pulsed", NaN, 3020, P.nexrad.height_m, P.ship.height_m, P.analysis.climate, P.analysis.n0, P.analysis.delta_h_m
    "3080 MHz", P, "pulsed", NaN, 3080, P.nexrad.height_m, P.ship.height_m, P.analysis.climate, P.analysis.n0, P.analysis.delta_h_m
    "low antennas (NEXRAD 10 m, ship 10 m)", P, "pulsed", NaN, P.analysis.f_mhz, 10, 10, P.analysis.climate, P.analysis.n0, P.analysis.delta_h_m
    "high antennas (NEXRAD 35 m, ship 50 m)", P, "pulsed", NaN, P.analysis.f_mhz, 35, 50, P.analysis.climate, P.analysis.n0, P.analysis.delta_h_m
    "continental temperate climate", P, "pulsed", NaN, P.analysis.f_mhz, P.nexrad.height_m, P.ship.height_m, 5, P.analysis.n0, P.analysis.delta_h_m
    "N0 = 350", P, "pulsed", NaN, P.analysis.f_mhz, P.nexrad.height_m, P.ship.height_m, P.analysis.climate, 350, P.analysis.delta_h_m
    "coastal path, delta h 30 m", P, "pulsed", NaN, P.analysis.f_mhz, P.nexrad.height_m, P.ship.height_m, P.analysis.climate, P.analysis.n0, 30
    "coastal path, delta h 90 m", P, "pulsed", NaN, P.analysis.f_mhz, P.nexrad.height_m, P.ship.height_m, P.analysis.climate, P.analysis.n0, 90
    };
P2 = P; P2.nexrad.peak_power_kw = 650; P2.nexrad.tx_line_loss_db = 2.5; P2.nexrad.gain_dbi = 45.5;
cases(end+1, :) = {"NEXRAD 650 kW, 2.5 dB loss, 45.5 dB gain", P2, "pulsed", NaN, P.analysis.f_mhz, P.nexrad.height_m, P.ship.height_m, P.analysis.climate, P.analysis.n0, P.analysis.delta_h_m};
P3 = P; P3.ship.tx_line_loss_db = 2; P3.ship.rx_line_loss_db = 2;
cases(end+1, :) = {"ship line losses 2 dB (assumed)", P3, "pulsed", NaN, P.analysis.f_mhz, P.nexrad.height_m, P.ship.height_m, P.analysis.climate, P.analysis.n0, P.analysis.delta_h_m};
rows = {};
for c = 1:size(cases, 1)
    Tc = emc_required_loss_rev1(cases{c, 2}, modes, nexrad_in=cases{c, 3}, ship_in_db=cases{c, 4});
    Lc = itm_grid(cases{c, 2}, cases{c, 6}, cases{c, 7}, cases{c, 5}, cases{c, 8}, cases{c, 9}, cases{c, 10}, d_km, p_pct);
    for g = 1:numel(gov)
        parts = split(gov(g), " | "); kk = split(key(g), " -> ");
        i = find(Tc.direction == parts(1) & Tc.system == parts(2) & Tc.interferer == kk(1) & Tc.victim == kk(2));
        [ds, fl] = emc_separation_rev1(d_km, Lc, Tc.l_req_db(i));
        rows(end+1, :) = {cases{c, 1}, parts(1), parts(2), key(g), Tc.l_req_db(i), ds(1), ds(2), ds(3), ds(4), fl(1), fl(2), fl(3), fl(4)}; %#ok<SAGROW>
    end
end
Z = cell2table(rows, 'VariableNames', {'case', 'direction', 'system', 'pair', 'l_req_db', 'd_km_p50', 'd_km_p10', ...
    'd_km_p1', 'd_km_p0_1', 'flag_p50', 'flag_p10', 'flag_p1', 'flag_p0_1'});
writetable(Z, fullfile(out_dir, "cochannel_sensitivity_rev1.csv"));
disp(S(:, 1:9))
fprintf("init_emc_cochannel_rev1: done\n");

function L = itm_grid(P, h_nx, h_ship, f_mhz, climate, n0, delta_h, d_km, p_pct)
% ITM area-mode basic transmission loss on the distance grid, one column per time percentage.
% validity="off": every grid distance is inside ITM's 1-2,000 km range; "warn" would print a caution for
% each of the ~4,000 grid points near the limits without changing the loss.
L = itm_area_rev1(h_nx, h_ship, d_km, delta_h, f_mhz, p_pct, climate=climate, N_0=n0, ...
    polarization=P.analysis.polarization, epsilon=P.analysis.epsilon, sigma=P.analysis.sigma, ...
    mdvar=P.analysis.mdvar, confidence=P.analysis.confidence_pct, validity="off");
end
