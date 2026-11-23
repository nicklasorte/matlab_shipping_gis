function A = emc_antennas_rev1(P, f_mhz)
%EMC_ANTENNAS_REV1 Antenna models of NEXRAD and the ship radars for the mutual antenna gain code.
%   A = EMC_ANTENNAS_REV1(P, f_mhz) returns antenna_prepare_rev1 input structs (nicklasorte/mutual_antenna_gain):
%     A.nexrad       pencil beam ("offaxis_table"): Gaussian main beam -12*(theta/bw)^2 dB until it meets the
%                    ROC sidelobe envelope (P.nexrad.sidelobe_db to 10 deg, far_sidelobe_db beyond), the form of
%                    pencil_table in nexrad_asr11_mag_rev1 (roc_spec). Peak gain P.nexrad.gain_dbi +
%                    20*log10(f/3050) and beamwidth P.nexrad.beamwidth_deg*2850/f (fixed aperture).
%     A.magnetron    fan beam, M.1851-2 rectangular aperture ("rect", peak envelope), M.1460-2 Table 4 values
%     A.solid_state  fan beam, M.1851-2 rectangular aperture, M.1460-2 Table 1 Radar No. 3B values
%     A.ship_scan    struct with one scan per ship type ("mech_rotating" at P.<type>.tilt_deg); the rotation
%                    rate does not change the random-mode distribution
%   Ship peak gain: the largest mode gain of that type in radar_modes_rev1.csv is applied separately in the
%   link budget; here g_max_dBi is 0 so the gains are relative to peak.
arguments
    P (1,1) struct
    f_mhz (1,1) double {mustBePositive}
end
nx = P.nexrad;
bw = nx.beamwidth_deg * 2850 / f_mhz;
th = unique([(0:0.005:5)'; (5:0.05:180)'; 10; 10.001]);
env = nx.sidelobe_db*(th <= 10) + nx.far_sidelobe_db*(th > 10);
g = -12*(th/bw).^2;
x = find(g < env, 1);
g(x:end) = env(x:end);
A.nexrad = struct("type", "offaxis_table", "g_max_dBi", nx.gain_dbi + 20*log10(f_mhz/P.analysis.f_mhz), ...
    "offaxis_deg", th, "gain_dB", g, "az_bw_deg", bw);
A.nexrad_bw_deg = bw;
for t = ["magnetron", "solid_state"]
    s = P.(t);
    A.(t) = struct("type", "rect", "g_max_dBi", 0, "az_bw_deg", s.az_bw_deg, "az_sll_dB", s.sidelobe_db, ...
        "el_bw_deg", s.el_bw_deg, "el_pattern", "rect", "el_sll_dB", s.sidelobe_db, "envelope", "peak", ...
        "floor_dB", s.far_sidelobe_db);
    A.ship_scan.(t) = struct("type", "mech_rotating", "rate_rpm", 24, "tilt_deg", s.tilt_deg);
end
end
