function res = radar_to_radar_sim_rev2(intf, vict, opts)
%RADAR_TO_RADAR_SIM_REV2 Monte Carlo of one radar's pulses in another radar's receiver.
%   res = radar_to_radar_sim_rev2(intf, vict, victim_type="asr")
%   res = radar_to_radar_sim_rev2(intf, vict, victim_type="wx")
%
%   Rev 2 change: peak I/N and effective duty cycle are referenced at the
%   victim IF output, before pulse compression, as in Rep. ITU-R M.2414 and
%   Rec. ITU-R RS.1280. The receive chain is IF filter -> matched filter
%   (pulse compression) -> processing. Rev 1 referenced both after the
%   matched filter, which smears short pulses in a long-pulse victim.
%
%   Transmit side: the interferer emits pulses (rectangular or linear FM)
%   at its own PRF, asynchronous with the victim (random start time, random
%   phase per pulse), tuned intf.freq_hz.
%   Receive side: the victim matched-filters each range window that follows
%   its own transmissions, adds unit-power thermal noise, then processes:
%     "asr" - target echo, optional median-of-3 pulse-to-pulse interference
%             rejection (IR), noncoherent integration, calibrated CA-CFAR.
%             Metric: probability of detection (Pd) and false-alarm rate.
%     "wx"  - distributed weather echo with Gaussian Doppler spectrum,
%             noise-corrected power (reflectivity) and pulse-pair velocity.
%             Metric: fraction of resolution volumes whose reflectivity
%             moves by more than 1 dB or velocity by more than 1 m/s
%             (accuracy requirements in Rec. ITU-R M.1849-3, Table 5).
%
%   Peak I/N is defined at the victim IF output for a co-channel pulse. A frequency offset (intf.freq_hz - vict.freq_hz)
%   then lowers the in-band level, which is the frequency-dependent
%   rejection. Each trial reuses one noise and interference realization
%   across all I/N levels and compares with the same trial without
%   interference (paired), so curves are smooth and differences are causal.
%
%   Output table columns: in_peak_db, in_avg_db, dc_eff, prf_ratio, and the
%   victim metrics (pd, pd_base, pfa, pfa_base) or (frac_dz, frac_dv, mean_dz_db).
arguments
    intf (1,1) struct
    vict (1,1) struct
    opts.victim_type (1,1) string {mustBeMember(opts.victim_type, ["asr", "wx"])} = "asr"
    opts.in_peak_db (1,:) double = -20:5:60
    opts.n_trials (1,1) double {mustBeInteger, mustBePositive} = 100
    opts.n_pulses (1,1) double {mustBeInteger, mustBePositive} = 16  % M.1849-3 worked example uses Ns = 16
    opts.ir_on (1,1) logical = true
    opts.pfa (1,1) double {mustBePositive} = 1e-3
    opts.target_snr_db (1,1) double = NaN   % NaN: albersheim for Pd = 0.9 plus 3 dB CFAR/IR margin
    opts.wx_snr_db (1,1) double = 3         % M.1849-3 worked example S/N
    opts.wx_vel_mps (1,1) double = 10       % TODO: representative radial velocity
    opts.wx_width_mps (1,1) double = 2      % TODO: representative spectrum width
    opts.window_s (1,1) double {mustBePositive} = 200e-6
    opts.fs_hz (1,1) double = NaN           % NaN: 4x the widest bandwidth in play
    opts.seed (1,1) double = 1
end

%% Sample rate and waveforms
bw_list = [1/intf.tau_s, intf.chirp_bw_hz, 1/vict.tau_s, vict.chirp_bw_hz, abs(intf.freq_hz - vict.freq_hz)];
fs = opts.fs_hz;
if isnan(fs)
    fs = 1e5 * ceil(4 * max(bw_list) / 1e5);
end
[p_v, h_mf] = radar_pulse_rev1(vict, fs);
p_i = radar_pulse_rev1(intf, fs);

% Victim IF filter: linear-phase FIR lowpass (fir1) with two-sided 3 dB
% bandwidth equal to the victim IF bandwidth, or the pulse bandwidth when
% the table gives none.
b_if = vict.if_bw_hz;
if isnan(b_if) || b_if <= 0
    b_if = max(1/vict.tau_s, vict.chirp_bw_hz);
end
n_if = 2 * ceil(2 * fs / b_if);
h_if = fir1(n_if, min(0.99, b_if / fs)).';
g = conv(h_if, h_mf);                       % full receive chain to detector input
h_v = g / norm(g);                          % unit noise power at the detector input
n_h = numel(h_v);

% Interferer: scale so a co-channel pulse has peak I/N = 0 dB at the IF output.
t_i = (0:numel(p_i)-1).' / fs;
df = intf.freq_hz - vict.freq_hz;
p_off = p_i .* exp(1j*2*pi*df*t_i);
y_if_co = conv(p_i, h_if);
y_if_off = conv(p_off, h_if);
amp = sqrt(sum(abs(h_if).^2) / max(abs(y_if_co))^2);
y_tpl = amp * conv(p_off, g) / norm(g);
n_tpl = numel(y_tpl);
% Effective duty cycle at the IF output (pulse energy / peak power x PRF),
% and the average-to-peak(co-channel) ratio used for average I/N.
dc_eff_if = min(1, sum(abs(y_if_off).^2) / max(abs(y_if_off))^2 / fs * intf.prf_hz);
avg_ratio = sum(abs(y_if_off).^2) / max(abs(y_if_co))^2 / fs * intf.prf_hz;

% Own echo through the receive chain, unit peak at the detector input.
e_tpl = conv(p_v, g);
e_tpl = e_tpl / max(abs(e_tpl));
[~, e_pk] = max(abs(e_tpl));

%% Range window and CFAR geometry
res_cells = ceil(fs / max(1/vict.tau_s, vict.chirp_bw_hz)); % resolution in samples
n_guard = 2 * max(2, res_cells);
n_train = 2 * max(16, 4 * res_cells);
n_win = max(round(opts.window_s * fs), 2*numel(e_tpl) + 2*(n_guard + n_train));
tgt_bin = round(n_win / 2);
n_p = opts.n_pulses;
pri_v = 1 / vict.prf_hz;
pri_i = 1 / intf.prf_hz;
n_in = numel(opts.in_peak_db);
in_amp = sqrt(10.^(opts.in_peak_db / 10));

%% Victim-specific setup
lam = physconst("LightSpeed") / vict.freq_hz;
if opts.victim_type == "asr"
    snr_db = opts.target_snr_db;
    if isnan(snr_db)
        % albersheim (Phased Array System Toolbox) gives the single-pulse SNR for
        % Pd and Pfa with noncoherent integration; add margin for CFAR and IR loss.
        snr_db = albersheim(0.9, opts.pfa, n_p) + 3;
    end
    tgt_col = zeros(n_win, 1);
    idx0 = tgt_bin - e_pk + 1;
    w_idx = max(1, idx0):min(n_win, idx0 + numel(e_tpl) - 1);
    tgt_col(w_idx) = e_tpl(w_idx - idx0 + 1);
    tgt_col = sqrt(10^(snr_db/10)) * tgt_col;
    cut_all = (n_train/2 + n_guard/2 + 1):(n_win - n_train/2 - n_guard/2);
    cut_fa = cut_all(abs(cut_all - tgt_bin) > (n_guard + n_train));
    alpha = calibrate_cfar(n_win, n_p, n_h, h_v, n_guard, n_train, cut_all, opts);
    cfar = phased.CFARDetector(Method="CA", NumGuardCells=n_guard, NumTrainingCells=n_train, ...
        ThresholdFactor="Custom", CustomThresholdFactor=alpha);
    det_tgt = false(opts.n_trials, n_in + 1);
    fa_rate = zeros(opts.n_trials, n_in + 1);
else
    lag = (0:n_p-1).' - (0:n_p-1);
    rho = exp(-8 * (pi * opts.wx_width_mps * lag * pri_v / lam).^2) ...
        .* exp(1j * 4*pi * opts.wx_vel_mps * lag * pri_v / lam);
    l_chol = chol(rho + 1e-12*eye(n_p), "lower");
    frac_dz = zeros(opts.n_trials, n_in);
    frac_dv = zeros(opts.n_trials, n_in);
    mean_dz = zeros(opts.n_trials, n_in);
end
dc_eff_t = zeros(opts.n_trials, 1);
in_avg_lin = zeros(opts.n_trials, 1);

%% Monte Carlo
rs = RandStream("mrg32k3a", Seed=opts.seed);
for t = 1:opts.n_trials
    rs.Substream = t;
    noise = filtered_noise(rs, n_win, n_p, h_v);
    iu = place_interferer(rs, y_tpl, n_tpl, n_win, n_p, pri_v, pri_i, fs);
    dc_eff_t(t) = dc_eff_if;
    in_avg_lin(t) = avg_ratio;

    if opts.victim_type == "asr"
        sig = noise + tgt_col .* exp(1j*2*pi*rand(rs));
        x_int = zeros(n_win, n_in + 1);
        for k = 1:n_in + 1
            if k == 1
                y = sig;                        % baseline: no interference
            else
                y = sig + in_amp(k-1) * iu;
            end
            pw = abs(y).^2;
            if opts.ir_on
                % movmedian over 3 pulses removes single-PRI asynchronous pulses (Rec. ITU-R M.1372).
                pw = movmedian(pw, 3, 2);
            end
            x_int(:, k) = sum(pw, 2);          % noncoherent integration after IR
        end
        d_tgt = cfar(x_int, tgt_bin);
        d_fa = cfar(x_int, cut_fa);
        det_tgt(t, :) = d_tgt;
        fa_rate(t, :) = mean(d_fa, 1);
    else
        s = sqrt(10^(opts.wx_snr_db/10)) * (l_chol * complex_randn(rs, n_p, n_win)).';
        y0 = s + noise;
        [p0, r0] = moments(y0);
        for k = 1:n_in
            [p1, r1] = moments(y0 + in_amp(k) * iu);
            floor_p = 1e-3 * 10^(opts.wx_snr_db/10);
            dz = 10*log10(max(p1, floor_p) ./ max(p0, floor_p));
            dv = lam / (4*pi*pri_v) * angle(r1 .* conj(r0));
            frac_dz(t, k) = mean(abs(dz) > 1);
            frac_dv(t, k) = mean(abs(dv) > 1);
            mean_dz(t, k) = 10*log10(mean(max(p1, floor_p)) / mean(max(p0, floor_p)));
        end
    end
end

%% Assemble output
in_peak_db = opts.in_peak_db(:);
in_avg_db = in_peak_db + 10*log10(mean(in_avg_lin));
dc_eff = repmat(mean(dc_eff_t), n_in, 1);
prf_ratio = repmat(intf.prf_hz / vict.prf_hz, n_in, 1);
if opts.victim_type == "asr"
    pd = mean(det_tgt(:, 2:end), 1).';
    pd_base = repmat(mean(det_tgt(:, 1)), n_in, 1);
    pfa = mean(fa_rate(:, 2:end), 1).';
    pfa_base = repmat(mean(fa_rate(:, 1)), n_in, 1);
    res = table(in_peak_db, in_avg_db, dc_eff, prf_ratio, pd, pd_base, pfa, pfa_base);
else
    frac_dz = mean(frac_dz, 1).';
    frac_dv = mean(frac_dv, 1).';
    mean_dz_db = mean(mean_dz, 1).';
    res = table(in_peak_db, in_avg_db, dc_eff, prf_ratio, frac_dz, frac_dv, mean_dz_db);
end
res.Properties.UserData = struct(fs_hz=fs, n_win=n_win, n_guard=n_guard, n_train=n_train, ...
    intf=intf, vict=vict, opts=opts);
end

%% Local functions
function z = complex_randn(rs, m, n)
z = (randn(rs, m, n) + 1j*randn(rs, m, n)) / sqrt(2);
end

function noise = filtered_noise(rs, n_win, n_p, h_v)
% Unit-power white noise through the unit-energy matched filter; drop the
% filter transient so every kept sample is stationary.
n_h = numel(h_v);
w = complex_randn(rs, n_win + n_h - 1, n_p);
noise = filter(h_v, 1, w);
noise = noise(n_h:end, :);
end

function iu = place_interferer(rs, y_tpl, n_tpl, n_win, n_p, pri_v, pri_i, fs)
% Interferer pulse train on an absolute time axis, sampled in each victim
% range window. Random start time t0 makes the two radars asynchronous;
% each pulse gets a random phase. No built-in places an arbitrary pulse
% train into gated windows (pulstran works on one continuous vector), so
% the overlap is indexed directly.
iu = complex(zeros(n_win, n_p));
t0 = pri_i * rand(rs);
t_win = n_win / fs;
t_tpl = n_tpl / fs;
for k = 1:n_p
    tk = (k - 1) * pri_v;
    m_lo = ceil((tk - t_tpl - t0) / pri_i);
    m_hi = floor((tk + t_win - t0) / pri_i);
    for m = m_lo:m_hi
        d = round((t0 + m*pri_i - tk) * fs);
        w_idx = max(1, d+1):min(n_win, d + n_tpl);
        if isempty(w_idx), continue; end
        iu(w_idx, k) = iu(w_idx, k) + exp(1j*2*pi*rand(rs)) * y_tpl(w_idx - d);
    end
end
end

function [p, r1] = moments(y)
% Noise-corrected power (noise power is 1) and lag-1 autocorrelation per
% range bin; rows are bins, columns are pulses.
p = mean(abs(y).^2, 2) - 1;
r1 = mean(y(:, 2:end) .* conj(y(:, 1:end-1)), 2);
end

function alpha = calibrate_cfar(n_win, n_p, ~, h_v, n_guard, n_train, cut_all, opts)
% Set the CA-CFAR threshold factor empirically on noise-only trials with the
% same IR and integration, so the measured false-alarm rate matches opts.pfa.
% The 'Auto' factor assumes single-pulse exponential noise and doesn't hold
% after noncoherent integration or median filtering.
cfar1 = phased.CFARDetector(Method="CA", NumGuardCells=n_guard, NumTrainingCells=n_train, ...
    ThresholdFactor="Custom", CustomThresholdFactor=1, ThresholdOutputPort=true);
n_cal = max(50, ceil(20 / (opts.pfa * numel(cut_all))));
rs = RandStream("mrg32k3a", Seed=opts.seed + 7919);
ratio = zeros(numel(cut_all), n_cal);
for c = 1:n_cal
    rs.Substream = c;
    pw = abs(filtered_noise(rs, n_win, n_p, h_v)).^2;
    if opts.ir_on, pw = movmedian(pw, 3, 2); end
    x = sum(pw, 2);
    [~, th] = cfar1(x, cut_all.');
    ratio(:, c) = x(cut_all) ./ th;
end
alpha = quantile(ratio(:), 1 - opts.pfa);
end
