function radar = make_radar_rev1(params_tbl, radar_id, mode, overrides)
%MAKE_RADAR_REV1 Build a radar struct from a row of radar_params.csv.
%   radar = make_radar_rev1(params_tbl, "m1849_R1", "short")
%   radar = make_radar_rev1(params_tbl, "m1464_C", "long", prf_hz=1050)
%
%   Range values ("973-1040") resolve to the midpoint. Mode pairs
%   ("1.2 SP / 1.8 LP") resolve to the entry for the requested mode.
%   Name-value overrides replace any parsed field, so a sweep can vary
%   pulse width, PRF, chirp bandwidth, or tuned frequency directly.
%
%   Fields: name, mode, tau_s, prf_hz, dc, chirp_bw_hz, if_bw_hz, nf_db,
%   gain_dbi, peak_w, freq_hz.
arguments
    params_tbl table
    radar_id (1,1) string
    mode (1,1) string {mustBeMember(mode, ["short", "long"])} = "short"
    overrides.tau_s (1,1) double {mustBePositive}
    overrides.prf_hz (1,1) double {mustBePositive}
    overrides.chirp_bw_hz (1,1) double {mustBeNonnegative}
    overrides.freq_hz (1,1) double {mustBePositive}
end
row = params_tbl(params_tbl.radar_id == radar_id, :);
if height(row) ~= 1
    error("radar_in:badId", "Radar id %s not found exactly once.", radar_id);
end
is_long = mode == "long";

radar.name = radar_id + " (" + mode + ")";
radar.mode = mode;
radar.peak_w = 1e3 * pick_num(row.peak_power_kw, 1);
if is_long
    radar.tau_s = 1e-6 * pick_num(row.pulse_width_long_us, 1);
    radar.prf_hz = range_mid(row.prf_long_hz);
    if isnan(radar.prf_hz), radar.prf_hz = range_mid(row.prf_short_hz); end
else
    radar.tau_s = 1e-6 * pick_num(row.pulse_width_short_us, 1);
    radar.prf_hz = range_mid(row.prf_short_hz);
end
if isnan(radar.tau_s)
    error("radar_in:noPulse", "%s has no %s pulse width.", radar_id, mode);
end
radar.if_bw_hz = 1e6 * pick_mode(row.if_bw_3db_mhz, is_long);
radar.nf_db = pick_num(row.noise_figure_db, 1);
radar.gain_dbi = pick_num(row.antenna_gain_dbi, 1);
% Chirp applies to the long (compressed) pulse only.
radar.chirp_bw_hz = 0;
if is_long
    radar.chirp_bw_hz = 1e6 * pick_num(row.chirp_bw_mhz, 1);
    if isnan(radar.chirp_bw_hz)
        % TODO: chirp bandwidth not in the extracted M.1464-2 text; use the IF bandwidth.
        radar.chirp_bw_hz = radar.if_bw_hz;
    end
end
radar.freq_hz = 2800e6; % TODO: assigned frequency; band center as default.

% Apply overrides.
f = fieldnames(overrides);
for k = 1:numel(f)
    radar.(f{k}) = overrides.(f{k});
end
if isnan(radar.prf_hz)
    error("radar_in:noPrf", "%s has no PRF; pass prf_hz.", radar_id);
end
radar.dc = radar.tau_s * radar.prf_hz;
end

function v = pick_num(s, idx)
% First (or idx-th) number in a string. extract with a pattern handles
% "400 or 556", "<=4.0", and "1.0 SP / 60 LP" without custom parsing.
nums = str2double(extract(s, digitsPattern + optionalPattern("." + digitsPattern)));
if numel(nums) < idx || ismissing(s)
    v = NaN;
else
    v = nums(idx);
end
end

function v = range_mid(s)
% Midpoint of "a-b"; single value otherwise.
nums = str2double(extract(s, digitsPattern + optionalPattern("." + digitsPattern)));
if isempty(nums) || ismissing(s)
    v = NaN;
elseif contains(s, "-") && numel(nums) >= 2
    v = mean(nums(1:2));
else
    v = nums(1);
end
end

function v = pick_mode(s, is_long)
% "1.2 SP / 1.8 LP" -> second value for long pulse.
idx = 1;
if is_long && contains(s, "LP"), idx = 2; end
v = pick_num(s, idx);
if isnan(v), v = pick_num(s, 1); end
end
