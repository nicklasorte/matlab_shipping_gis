function radar = make_generic_radar_rev1(tau_s, prf_hz, chirp_bw_hz, freq_hz)
%MAKE_GENERIC_RADAR_REV1 Synthetic interferer for parameter sweeps.
%   radar = make_generic_radar_rev1(tau_s, prf_hz) builds an unmodulated
%   pulsed interferer. Pass chirp_bw_hz > 0 for a linear FM pulse and
%   freq_hz to set its tuned frequency (offset from the victim sets FDR).
arguments
    tau_s (1,1) double {mustBePositive}
    prf_hz (1,1) double {mustBePositive}
    chirp_bw_hz (1,1) double {mustBeNonnegative} = 0
    freq_hz (1,1) double {mustBePositive} = 2800e6
end
if tau_s * prf_hz >= 1
    error("radar_in:badDc", "Duty cycle tau*PRF must be below 1.");
end
radar.name = compose("generic tau=%gus PRF=%gHz BW=%gMHz", tau_s*1e6, prf_hz, chirp_bw_hz/1e6);
radar.mode = "generic";
radar.peak_w = NaN;
radar.tau_s = tau_s;
radar.prf_hz = prf_hz;
radar.chirp_bw_hz = chirp_bw_hz;
radar.if_bw_hz = NaN;
radar.nf_db = NaN;
radar.gain_dbi = NaN;
radar.freq_hz = freq_hz;
radar.dc = tau_s * prf_hz;
end
