%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%init_emc_nexrad_sweep_rev1
%%%%%
%%%%%Separation against NEXRAD tuned frequency, 2800-3100 MHz in 5 MHz steps (Nick, November 23), with each
%%%%%ship radar mode tuned as close to NEXRAD as its published range allows (radar_modes_rev1.csv columns
%%%%%f_lo_mhz, f_hi_mhz, f_step_mhz): IMO magnetron (M.1460-2 Table 4) and Radar A 3020-3080 MHz, Radars B
%%%%%and C 3040-3060 MHz (continuous), solid-state Radar No. 3B on the nearest 20 MHz channel center,
%%%%%2930-3070 MHz. The offset is the frequency distance to that closest tuning, so the result is the
%%%%%worst case over ship tuning.
%%%%%NEXRAD main-beam gain is scaled with frequency, G(f) = G(3050 MHz) + 20*log10(f/3050), in both
%%%%%directions; ITM v1.4 area mode runs at the NEXRAD frequency. FDR = OTR + OFR as in init_emc_offset_rev1
%%%%%(OFR span 600 MHz, so offsets up to 300 MHz). Both protection-level cases as in the offset run.
%%%%%Writes outputs/emc/nexrad_sweep_separation_rev1.csv (every pair and frequency),
%%%%%nexrad_sweep_envelope_rev1.csv (largest distance over pairs), nexrad_sweep_lreq_rev1.csv (required loss
%%%%%after FDR, for the Python check in python/emc_nexrad_sweep.py).
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
f_nx = (2800:5:3100).';
nf = numel(f_nx);
bpf = [nx.bpf_f1_mhz nx.bpf_f2_mhz nx.bpf_f3_mhz nx.bpf_f4_mhz];

%% Closest ship tuning and offset for every mode and NEXRAD frequency
nm = height(modes);
[f_ship, df_mode] = deal(zeros(nf, nm));
for m = 1:nm
    if modes.f_step_mhz(m) > 0
        ch = modes.f_lo_mhz(m):modes.f_step_mhz(m):modes.f_hi_mhz(m);
        [df_mode(:, m), idx] = min(abs(f_nx - ch), [], 2);
        f_ship(:, m) = ch(idx);
    else
        f_ship(:, m) = min(max(f_nx, modes.f_lo_mhz(m)), modes.f_hi_mhz(m));
        df_mode(:, m) = abs(f_nx - f_ship(:, m));
    end
end
df_u = unique(df_mode(:)).';

%% OFR at the offsets needed, every pair (row order of emc_required_loss_rev1)
T0 = emc_required_loss_rev1(P, modes);
n = height(T0);
ofr = zeros(n, numel(df_u));
pair_mode = zeros(n, 1);
nx_tau = [nx.pulse_short_us, nx.pulse_long_us];
span = 600;
r = 0;
for j = 1:2
    h_nx = @(f) emc_selectivity_rev1(f, "nexrad", tau_us=nx_tau(j), bpf=bpf);
    p_nx = @(f) emc_emission_rev1(f, nx_tau(j), nx.rise_us);
    for m = 1:nm
        chirp = modes.tx_bw_mhz(m) * (modes.otr_k(m) == 10);
        rise = P.magnetron.rise_us * (modes.system(m) == "magnetron");
        p_m = @(f) emc_emission_rev1(f, modes.pulse_us(m), rise, chirp);
        h_m = @(f) emc_selectivity_rev1(f, "ship", if_mhz=modes.if_mhz(m), floor_db=P.ship.if_floor_db, poles=P.ship.if_poles);
        r = r + 1; ofr(r, :) = emc_ofr_rev1(df_u, p_m, h_nx, span_mhz=span); pair_mode(r) = m;
        r = r + 1; ofr(r, :) = emc_ofr_rev1(df_u, p_nx, h_m, span_mhz=span); pair_mode(r) = m;
    end
end

%% Required loss and separation at each NEXRAD frequency
p_pct = [50 10 1 0.1];
d_km = [(1:0.1:10)'; (10.5:0.5:2000)'];
cases = {"pulsed", P.ship.in_db; "constant", P.ship.in_pulsed_db};
nrow = nf * n * size(cases, 1);
[c_dir, c_sys, c_int, c_vic, c_prot] = deal(strings(nrow, 1));
[c_fnx, c_fship, c_df, c_gain, c_lreq] = deal(zeros(nrow, 1));
[c_d, c_flag] = deal(zeros(nrow, 4));
r = 0;
for i = 1:nf
    L = itm_area_rev1(nx.height_m, P.ship.height_m, d_km, P.analysis.delta_h_m, f_nx(i), p_pct, ...
        climate=P.analysis.climate, N_0=P.analysis.n0, polarization=P.analysis.polarization, ...
        epsilon=P.analysis.epsilon, sigma=P.analysis.sigma, mdvar=P.analysis.mdvar, ...
        confidence=P.analysis.confidence_pct, validity="off");
    Pi = P;
    Pi.nexrad.gain_dbi = nx.gain_dbi + 20*log10(f_nx(i)/P.analysis.f_mhz);
    for c = 1:size(cases, 1)
        Tc = emc_required_loss_rev1(Pi, modes, nexrad_in=cases{c, 1}, ship_in_db=cases{c, 2});
        for k = 1:n
            m = pair_mode(k);
            q = find(df_u == df_mode(i, m), 1);
            lreq = Tc.l_req_db(k) - ofr(k, q);
            [ds, fl] = emc_separation_rev1(d_km, L, lreq);
            r = r + 1;
            c_dir(r) = Tc.direction(k); c_sys(r) = Tc.system(k); c_int(r) = Tc.interferer(k); c_vic(r) = Tc.victim(k);
            if Tc.direction(k) == "ship to NEXRAD"
                c_prot(r) = "NEXRAD " + cases{c, 1};
            else
                c_prot(r) = "ship " + string(cases{c, 2}) + " dB";
            end
            c_fnx(r) = f_nx(i); c_fship(r) = f_ship(i, m); c_df(r) = df_mode(i, m);
            c_gain(r) = Pi.nexrad.gain_dbi; c_lreq(r) = lreq;
            c_d(r, :) = ds; c_flag(r, :) = fl;
        end
    end
end
S = table(c_fnx, c_dir, c_sys, c_int, c_vic, c_prot, c_fship, c_df, c_gain, c_lreq, ...
    c_d(:, 1), c_d(:, 2), c_d(:, 3), c_d(:, 4), c_flag(:, 1), c_flag(:, 2), c_flag(:, 3), c_flag(:, 4), ...
    'VariableNames', {'f_nexrad_mhz', 'direction', 'system', 'interferer', 'victim', 'protection', 'f_ship_mhz', ...
    'df_mhz', 'nexrad_gain_dbi', 'l_req_db', 'd_km_p50', 'd_km_p10', 'd_km_p1', 'd_km_p0_1', ...
    'flag_p50', 'flag_p10', 'flag_p1', 'flag_p0_1'});
writetable(S, fullfile(out_dir, "nexrad_sweep_separation_rev1.csv"));
writetable(S(:, ["f_nexrad_mhz", "direction", "system", "interferer", "victim", "protection", "df_mhz", "l_req_db"]), ...
    fullfile(out_dir, "nexrad_sweep_lreq_rev1.csv"));

%% Envelope: largest distance over pairs for each NEXRAD frequency, direction, ship radar type, protection
[g, gf, gd, gs, gp] = findgroups(S.f_nexrad_mhz, S.direction, S.system, S.protection);
E = table(gf, gd, gs, gp, splitapply(@max, S.d_km_p50, g), splitapply(@max, S.d_km_p10, g), ...
    splitapply(@max, S.d_km_p1, g), splitapply(@max, S.d_km_p0_1, g), splitapply(@min, S.df_mhz, g), ...
    'VariableNames', {'f_nexrad_mhz', 'direction', 'system', 'protection', 'd_km_p50', 'd_km_p10', 'd_km_p1', ...
    'd_km_p0_1', 'df_min_mhz'});
writetable(E, fullfile(out_dir, "nexrad_sweep_envelope_rev1.csv"));
disp(E(ismember(E.f_nexrad_mhz, [2800 2900 2950 3000 3020 3050 3100]), :))
fprintf("init_emc_nexrad_sweep_rev1: done\n");
