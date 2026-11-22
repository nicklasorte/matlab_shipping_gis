function T = emc_pulsed_in_rev1(out_csv)
%EMC_PULSED_IN_REV1 Peak I/N protection levels for pulsed interference into NEXRAD (MATLAB twin of python/emc_pulsed_in.py).
%   Rec. ITU-R M.1849-3 section 8.4.2: I/N_pulse = I/N_constant - 10*log10(f_c), I/N_constant = -10 dB,
%   f_c = PRF_i*(tau_i + tau_g) (Rec. ITU-R RS.1280 section 3.2, Case II), NEXRAD gate tau_g = its pulse width.
%   Interferers: M.1460-2 Table 4 magnetron (0.05 us at 4,000 Hz; 1.2 us at 375 Hz) and Table 1 Radar No. 3B
%   (0.1, 5, 33 us at PRI 12, 64, 365 us, treated as unmodulated). Returns a table; writes it if out_csv is given.
%   Must agree with the Python version to 0.05 dB (both round to 0.1 dB).
arguments
    out_csv (1,1) string = ""
end
in_const_db=-10;
gate_us=[1.57 4.71];
gate_name=["NEXRAD short pulse (1.57 us gate)" "NEXRAD long pulse (4.71 us gate)"];
ship_name=["Ship magnetron, shortest pulse" "Ship magnetron, longest pulse" ...
    "Solid-state 3B, short (unmodulated)" "Solid-state 3B, medium (unmodulated)" "Solid-state 3B, long (unmodulated)"];
tau_us=[0.05 1.2 0.1 5 33];
prf_hz=[4000 375 1e6/12 1e6/64 1e6/365];
[g,s]=ndgrid(1:numel(gate_us),1:numel(tau_us));
g=g'; s=s'; g=g(:); s=s(:);
fc=min(1,prf_hz(s).*(tau_us(s)+gate_us(g))*1e-6);
peak_in_db=round(in_const_db-10*log10(fc),1);
T=table(gate_name(g)',ship_name(s)',tau_us(s)',prf_hz(s)',100*prf_hz(s)'.*tau_us(s)'*1e-6,fc',peak_in_db', ...
    'VariableNames',{'victim_mode','interferer','pulse_us','prf_hz','duty_cycle_pct','f_c','peak_IN_dB'});
if out_csv~=""
    writetable(T,out_csv);
end
end
