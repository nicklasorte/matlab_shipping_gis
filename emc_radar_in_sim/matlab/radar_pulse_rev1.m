function [pulse, mf_coeff] = radar_pulse_rev1(radar, fs_hz)
%RADAR_PULSE_REV1 One transmitted pulse and its unit-energy matched filter.
%   [pulse, mf_coeff] = radar_pulse_rev1(radar, fs_hz) returns the complex
%   baseband samples of one pulse (rectangular or linear FM) and the
%   matched-filter coefficients normalized to unit energy, so filtered
%   white noise of unit power stays at unit power.
arguments
    radar (1,1) struct
    fs_hz (1,1) double {mustBePositive}
end
% The phased waveform objects need SampleRate/PRF to be an integer; only
% one pulse is used, so round the PRF to the nearest allowed value.
prf_ok = fs_hz / ceil(fs_hz / radar.prf_hz);
if radar.chirp_bw_hz > 0
    wav = phased.LinearFMWaveform(SampleRate=fs_hz, PulseWidth=radar.tau_s, ...
        PRF=prf_ok, SweepBandwidth=radar.chirp_bw_hz, SweepInterval="Symmetric");
else
    wav = phased.RectangularWaveform(SampleRate=fs_hz, PulseWidth=radar.tau_s, PRF=prf_ok);
end
x = wav();
n_pulse = round(radar.tau_s * fs_hz);
if n_pulse < 1
    error("radar_in:fsLow", "Sample rate too low for a %.3g us pulse.", radar.tau_s*1e6);
end
pulse = x(1:n_pulse);
mf_coeff = getMatchedFilter(wav);
mf_coeff = mf_coeff / norm(mf_coeff);
end
