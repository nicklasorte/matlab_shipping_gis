function run_nexrad_ship_rev1(opts)
%RUN_NEXRAD_SHIP_REV1 Pulsed radar-to-radar thresholds between NEXRAD and shipborne S-band radars.
%   run_nexrad_ship_rev1() runs four studies with radar_to_radar_sim_rev2 and writes CSVs to ../results:
%     ref_wx    Reference check for the weather-radar victim: the C-band radar tested in Rep. ITU-R M.2136,
%               Annex 2 (Rec. ITU-R M.1849-3 radar 12 class: 2 us pulse, 330 Hz average PRF), against the
%               unmodulated pulses of M.2136 Table 12. Measured mode-2 thresholds are converted to I/N with the
%               report's -113.8 dBm noise level.
%     ref_ship  Reference check for the ship-radar victim (asr processing with median-of-3 interference
%               rejection as the stand-in for pulse-to-pulse correlators): Rec. ITU-R M.1460-2 Radars B and C
%               (Tables 6 and 7) against 1 and 2 us pulses at 0.1 % and 1 % duty cycle (Annex 3, no effect up to
%               +40 dB for B and +30 dB for C, the highest levels tested).
%     ship2wx   Ship radars (M.1460-2 Tables 4 to 7 and Table 1 Radar No. 3B) into NEXRAD (M.1849-3 Radar 1,
%               short and long pulse, IF bandwidth 636 and 212 kHz from the NOAA ROC NEXRAD Technical
%               Information sheet), both tuned to 3050 MHz (assumption of the EMC working paper). Compared with
%               the M.1849-3 section 8.4.2 formula.
%     wx2ship   NEXRAD (short pulse at 1,304 Hz and long pulse at 452 Hz, the highest duty cycles on the ROC
%               sheet) into the ship radar modes of M.1460-2 Tables 5 to 7, with pulses per dwell from beamwidth,
%               scan rate, and PRF.
%   Every I/N is peak, single interferer, at the victim IF output, co-channel (as in radar_to_radar_sim_rev2).
%   Antenna coupling is main beam to main beam for the whole dwell (assumption in the EMC working paper), so
%   no scan-coincidence factor is applied.
arguments
    opts.n_trials (1,1) double {mustBeInteger, mustBePositive} = 60
    opts.in_peak_db (1,:) double = -20:5:70
    opts.studies (1,:) string = ["ref_wx", "ref_ship", "ship2wx", "wx2ship"]
    opts.seed (1,1) double = 1
end
this_dir = fileparts(mfilename("fullpath"));
out_dir = fullfile(this_dir, "..", "results");
if ~isfolder(out_dir), mkdir(out_dir); end
params = load_radar_params_rev1();
f_hz = 3050e6;

%% Ship radar modes, Rec. ITU-R M.1460-2 (pulse width us, PRF Hz, IF bandwidth MHz, horizontal beamwidth deg, scan rpm)
% Table 4 extremes have no IF or scan pairing; Radar C's beamwidth row reads "2.31 s" (a typo in the table),
% taken here as 2.31 deg and flagged.
ship = table( ...
    ["T4 shortest"; "T4 longest"; "A 0.08"; "A 0.30"; "A 0.60"; "A 1.2"; "B 0.070"; "B 0.175"; "B 0.85"; "B 1.0"; ...
     "C 0.050"; "C 0.25"; "C 0.80"], ...
    [0.05; 1.2; 0.08; 0.30; 0.60; 1.2; 0.070; 0.175; 0.85; 1.0; 0.050; 0.25; 0.80], ...
    [4000; 375; 2200; 2200; 1028; 600; 3100; 1550; 775; 390; 1800; 1800; 785], ...
    [NaN; NaN; 28; 3; 3; 3; 22; 22; 6; 6; 20; 20; 3], ...
    [NaN; NaN; 1.9; 1.9; 1.9; 1.9; 2.8; 2.8; 2.8; 2.8; 2.31; 2.31; 2.31], ...
    [NaN; NaN; 26; 26; 26; 26; 24; 24; 24; 24; 25; 25; 25], ...
    'VariableNames', {'mode', 'pulse_us', 'prf_hz', 'if_mhz', 'bw_deg', 'rpm'});
% Solid-state Radar No. 3B (Table 1): pulses 0.1, 5, 33 us at PRI 12, 64, 365 us; FM, 3 dB bandwidth 15 or 3 MHz.
% Run unmodulated (stricter) and with a 15 MHz linear FM sweep.
ss = table(["3B 0.1 (unmod)"; "3B 5 (unmod)"; "3B 33 (unmod)"; "3B 5 (FM 15 MHz)"; "3B 33 (FM 15 MHz)"], ...
    [0.1; 5; 33; 5; 33], 1e6 ./ [12; 64; 365; 64; 365], [0; 0; 0; 15e6; 15e6], ...
    'VariableNames', {'mode', 'pulse_us', 'prf_hz', 'chirp_bw_hz'});

for study = opts.studies
    switch study
        case "ref_wx"
            vict = make_generic_radar_rev1(2e-6, 330, 0, 5.6e9);   % M.2136 Annex 2 radar (pulse-matched IF)
            tau = [1; 1; 20; 20; 0.6];
            prf = [200; 3000; 200; 3000; 1000];
            meas_dbm = [-92.80; -92.80; -103.80; -107.00; -93.80];  % M.2136 Table 12, mode 2
            rows = table(tau, prf, meas_dbm + 113.8, 'VariableNames', {'pulse_us', 'prf_hz', 'measured_IN_db'});
            rows = add_wx_runs(rows, vict, opts, zeros(height(rows), 1));
            rows.formula_IN_db = -10 - 10*log10(min(1, rows.prf_hz .* (rows.pulse_us + 2) * 1e-6));
            writetable(rows, fullfile(out_dir, "nexrad_ship_ref_wx_rev1.csv"));
        case "ref_ship"
            out = table();
            vic = ["B 0.175"; "C 0.25"];
            for v = vic.'
                s = ship(ship.mode == v, :);
                vict = ship_victim(s, f_hz);
                tau = [1; 1; 2; 2];
                prf = [1000; 10000; 500; 5000];
                r = table(repmat(v, 4, 1), tau, prf, 'VariableNames', {'victim', 'pulse_us', 'prf_hz'});
                out = [out; add_asr_runs(r, vict, n_dwell(s), opts)]; %#ok<AGROW> two victims
            end
            out.measured_no_effect_to_db = [40; 40; 40; 40; 30; 30; 30; 30];
            writetable(out, fullfile(out_dir, "nexrad_ship_ref_ship_rev1.csv"));
        case "ship2wx"
            out = table();
            for wx_mode = ["short", "long"]
                vict = make_radar_rev1(params, "m1849_R1", wx_mode, freq_hz=f_hz);
                vict.if_bw_hz = 636e3 * (wx_mode == "short") + 212e3 * (wx_mode == "long");  % NOAA ROC sheet
                r = [table(ship.mode, ship.pulse_us, ship.prf_hz, zeros(height(ship), 1), ...
                        'VariableNames', {'interferer', 'pulse_us', 'prf_hz', 'chirp_bw_hz'}); ...
                     table(ss.mode, ss.pulse_us, ss.prf_hz, ss.chirp_bw_hz, ...
                        'VariableNames', {'interferer', 'pulse_us', 'prf_hz', 'chirp_bw_hz'})];
                r = addvars(r, repmat("NEXRAD " + wx_mode, height(r), 1), 'Before', 1, 'NewVariableNames', 'victim');
                r = add_wx_runs(r, vict, opts, r.chirp_bw_hz);
                r.formula_IN_db = -10 - 10*log10(min(1, r.prf_hz .* (r.pulse_us + vict.tau_s*1e6) * 1e-6));
                out = [out; r]; %#ok<AGROW> two NEXRAD modes
            end
            writetable(out, fullfile(out_dir, "nexrad_ship_ship2wx_rev1.csv"));
        case "wx2ship"
            out = table();
            vic = ship(~isnan(ship.if_mhz), :);
            for k = 1:height(vic)
                vict = ship_victim(vic(k, :), f_hz);
                r = table(repmat(vic.mode(k), 2, 1), ["NEXRAD short 1304 Hz"; "NEXRAD long 452 Hz"], ...
                    [1.57; 4.71], [1304; 452], 'VariableNames', {'victim', 'interferer', 'pulse_us', 'prf_hz'});
                out = [out; add_asr_runs(r, vict, n_dwell(vic(k, :)), opts)]; %#ok<AGROW> one row pair per mode
            end
            writetable(out, fullfile(out_dir, "nexrad_ship_wx2ship_rev1.csv"));
        otherwise
            error("radar_in:badStudy", "Unknown study %s.", study);
    end
    fprintf("run_nexrad_ship_rev1: %s done\n", study);
end
end

function vict = ship_victim(s, f_hz)
% Ship radar victim from one M.1460-2 mode row.
vict = make_generic_radar_rev1(s.pulse_us * 1e-6, s.prf_hz, 0, f_hz);
vict.if_bw_hz = s.if_mhz * 1e6;
end

function n = n_dwell(s)
% Pulses per main-beam dwell: PRF * beamwidth / scan rate (deg/s), at least 3 for the median-of-3 rejection.
n = max(3, round(s.prf_hz * s.bw_deg / (s.rpm * 6)));
end

function rows = add_wx_runs(rows, vict, opts, chirp)
% Weather-radar thresholds: 10 % and 1 % of volumes with |dZ| > 1 dB, 10 % with |dv| > 1 m/s.
n = height(rows);
[thr_z10, thr_z1, thr_v10, dc_eff] = deal(zeros(n, 1));
for k = 1:n
    intf = make_generic_radar_rev1(rows.pulse_us(k) * 1e-6, rows.prf_hz(k), chirp(k), vict.freq_hz);
    res = radar_to_radar_sim_rev2(intf, vict, victim_type="wx", in_peak_db=opts.in_peak_db, ...
        n_trials=opts.n_trials, seed=opts.seed);
    thr_z10(k) = find_threshold_rev1(res.in_peak_db, res.frac_dz, 0.10);
    thr_z1(k) = find_threshold_rev1(res.in_peak_db, res.frac_dz, 0.01);
    thr_v10(k) = find_threshold_rev1(res.in_peak_db, res.frac_dv, 0.10);
    dc_eff(k) = res.dc_eff(1);
end
rows = [rows, table(dc_eff, thr_z10, thr_z1, thr_v10, 'VariableNames', ...
    {'dc_eff', 'sim_IN_z10pct_db', 'sim_IN_z1pct_db', 'sim_IN_v10pct_db'})];
end

function rows = add_asr_runs(rows, vict, n_p, opts)
% Ship-radar thresholds with median-of-3 interference rejection: Pd drop of 0.1, or 10x false alarms.
n = height(rows);
[thr_pd, thr_pfa, dc_eff] = deal(zeros(n, 1));
for k = 1:n
    intf = make_generic_radar_rev1(rows.pulse_us(k) * 1e-6, rows.prf_hz(k), 0, vict.freq_hz);
    res = radar_to_radar_sim_rev2(intf, vict, victim_type="asr", in_peak_db=opts.in_peak_db, ...
        n_trials=opts.n_trials, n_pulses=n_p, ir_on=true, seed=opts.seed);
    thr_pd(k) = find_threshold_rev1(res.in_peak_db, res.pd_base - res.pd, 0.1);
    thr_pfa(k) = find_threshold_rev1(res.in_peak_db, res.pfa ./ max(res.pfa_base, eps), 10);
    dc_eff(k) = res.dc_eff(1);
end
rows = [rows, table(repmat(n_p, n, 1), dc_eff, thr_pd, thr_pfa, 'VariableNames', ...
    {'pulses_per_dwell', 'dc_eff', 'sim_IN_pd_db', 'sim_IN_pfa_db'})];
end
