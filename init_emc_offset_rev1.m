%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%init_emc_offset_rev1
%%%%%
%%%%%Separation against frequency offset, NEXRAD and shipborne S-band radars (magnetron and solid state),
%%%%%both directions, main beam to main beam, ITM v1.4 area mode. FDR = OTR + OFR (Rec. ITU-R SM.337-6
%%%%%eqs. 3-6): OTR is in emc_required_loss_rev1; OFR from emc_ofr_rev1 with emc_emission_rev1 and
%%%%%emc_selectivity_rev1. Both protection levels for each victim (Nick, November 22): NEXRAD M.1849-3
%%%%%pulsed level and -10 dB; ship radar -6 dB and +30 dB.
%%%%%Writes outputs/emc/offset_ofr_rev1.csv, offset_separation_rev1.csv (every pair), offset_envelope_rev1.csv
%%%%%(largest distance over the pairs of each direction, ship radar type, and protection level).
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
[~, c1] = system(sprintf('git -C "%s" rev-parse --short HEAD', here));
[~, c2] = system(sprintf('git -C "%s" rev-parse --short HEAD', itm_dir));
fprintf("COMMIT %s (matlab_itm %s)\n", strtrim(c1), strtrim(c2));

[P, modes] = emc_params_rev1();
nx = P.nexrad;
df = [0:0.25:9.75, 10:1:59, 60:2:150];
bpf = [nx.bpf_f1_mhz nx.bpf_f2_mhz nx.bpf_f3_mhz nx.bpf_f4_mhz];

%% OFR for every pair (same order as emc_required_loss_rev1)
T0 = emc_required_loss_rev1(P, modes);
n = height(T0);
ofr = zeros(n, numel(df));
nx_tau = [nx.pulse_short_us, nx.pulse_long_us];
r = 0;
for j = 1:2
    h_nx = @(f) emc_selectivity_rev1(f, "nexrad", tau_us=nx_tau(j), bpf=bpf);
    p_nx = @(f) emc_emission_rev1(f, nx_tau(j), nx.rise_us);
    for m = 1:height(modes)
        chirp = modes.tx_bw_mhz(m) * (modes.otr_k(m) == 10);
        rise = P.magnetron.rise_us * (modes.system(m) == "magnetron");
        p_m = @(f) emc_emission_rev1(f, modes.pulse_us(m), rise, chirp);
        h_m = @(f) emc_selectivity_rev1(f, "ship", if_mhz=modes.if_mhz(m), floor_db=P.ship.if_floor_db, poles=P.ship.if_poles);
        r = r + 1; ofr(r, :) = emc_ofr_rev1(df, p_m, h_nx);    % ship mode -> NEXRAD
        r = r + 1; ofr(r, :) = emc_ofr_rev1(df, p_nx, h_m);    % NEXRAD -> ship mode
    end
end
O = [T0(:, ["direction", "system", "interferer", "victim"]), array2table(ofr, 'VariableNames', "df_" + string(df))];
writetable(O, fullfile(out_dir, "offset_ofr_rev1.csv"));

%% Required loss and separation for the four protection-level cases
p_pct = [50 10 1 0.1];
d_km = [(1:0.1:10)'; (10.5:0.5:2000)'];
L = itm_area_rev1(nx.height_m, P.ship.height_m, d_km, P.analysis.delta_h_m, P.analysis.f_mhz, p_pct, ...
    climate=P.analysis.climate, N_0=P.analysis.n0, polarization=P.analysis.polarization, epsilon=P.analysis.epsilon, ...
    sigma=P.analysis.sigma, mdvar=P.analysis.mdvar, confidence=P.analysis.confidence_pct, validity="off");
cases = {"NEXRAD pulsed level, ship -6 dB", "pulsed", P.ship.in_db
         "NEXRAD -10 dB, ship +30 dB", "constant", P.ship.in_pulsed_db};
% The NEXRAD level only affects ship -> NEXRAD rows and the ship level only NEXRAD -> ship rows, so two runs
% cover all four victim levels.
rows = cell(0, 11);
for c = 1:size(cases, 1)
    Tc = emc_required_loss_rev1(P, modes, nexrad_in=cases{c, 2}, ship_in_db=cases{c, 3});
    for k = 1:n
        lreq = Tc.l_req_db(k) - ofr(k, :).';
        [ds, fl] = emc_separation_rev1(d_km, L, lreq);
        if Tc.direction(k) == "ship to NEXRAD"
            lvl = "NEXRAD " + cases{c, 2};
        else
            lvl = "ship " + string(cases{c, 3}) + " dB";
        end
        for q = 1:numel(df)
            rows(end+1, :) = {Tc.direction(k), Tc.system(k), Tc.interferer(k), Tc.victim(k), lvl, df(q), lreq(q), ...
                ds(q, 1), ds(q, 2), ds(q, 3), ds(q, 4)}; %#ok<SAGROW>
            fl_all(size(rows, 1), :) = fl(q, :); %#ok<SAGROW>
        end
    end
end
S = cell2table(rows, 'VariableNames', {'direction', 'system', 'interferer', 'victim', 'protection', 'df_mhz', ...
    'l_req_db', 'd_km_p50', 'd_km_p10', 'd_km_p1', 'd_km_p0_1'});
S = [S, array2table(fl_all, 'VariableNames', {'flag_p50', 'flag_p10', 'flag_p1', 'flag_p0_1'})];
writetable(S, fullfile(out_dir, "offset_separation_rev1.csv"));

%% Envelope: largest distance over pairs for each direction, ship radar type, protection level, offset
[g, gd, gs, gp, gf] = findgroups(S.direction, S.system, S.protection, S.df_mhz);
E = table(gd, gs, gp, gf, splitapply(@max, S.d_km_p50, g), splitapply(@max, S.d_km_p10, g), ...
    splitapply(@max, S.d_km_p1, g), splitapply(@max, S.d_km_p0_1, g), 'VariableNames', ...
    {'direction', 'system', 'protection', 'df_mhz', 'd_km_p50', 'd_km_p10', 'd_km_p1', 'd_km_p0_1'});
writetable(E, fullfile(out_dir, "offset_envelope_rev1.csv"));
disp(E(ismember(E.df_mhz, [0 10 20 30 60 100 150]), :))
fprintf("init_emc_offset_rev1: done\n");
