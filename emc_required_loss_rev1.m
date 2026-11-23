function T = emc_required_loss_rev1(P, modes, opts)
%EMC_REQUIRED_LOSS_REV1 Co-channel required path loss, both directions, main beam to main beam.
%   T = EMC_REQUIRED_LOSS_REV1(P, modes) returns one row per interferer-victim pair:
%     ship mode -> NEXRAD short and long pulse, and NEXRAD short and long pulse -> ship mode.
%   L_req = P_t - L_t + G_t + G_r - L_r - OTR - (N + I/N)   (EMC working paper, Section 5)
%   OTR per Rec. ITU-R SM.337-6 eq. (6); N = -174 dBm/Hz + 10*log10(B_R) + NF.
%   NEXRAD I/N: "pulsed" = Rec. ITU-R M.1849-3 section 8.4.2, I/N_constant - 10*log10(f_c),
%   f_c = min(1, PRF_i*(tau_i + tau_g)), tau_g = NEXRAD pulse width; "constant" = -10 dB.
%   Ship I/N: opts.ship_in_db (default P.ship.in_db, -6 dB per Rec. ITU-R M.1460-2).
arguments
    P (1,1) struct
    modes table
    opts.nexrad_in (1,1) string {mustBeMember(opts.nexrad_in, ["pulsed", "constant"])} = "pulsed"
    opts.ship_in_db (1,1) double = NaN
end
ship_in = opts.ship_in_db;
if isnan(ship_in), ship_in = P.ship.in_db; end
nx = P.nexrad;
nx_pulse = ["short", "long"];
nx_tau = [nx.pulse_short_us, nx.pulse_long_us];
nx_prf = [nx.prf_short_hz, nx.prf_long_hz];
nx_bt = [nx.tx_bw_short_mhz, nx.tx_bw_long_mhz];
nx_br = [nx.rx_bw_short_khz, nx.rx_bw_long_khz] / 1e3;
nx_noise = -174 + 10*log10(nx_br*1e6) + nx.nf_db;
nx_eirp = 10*log10(nx.peak_power_kw*1e6) - nx.tx_line_loss_db + nx.gain_dbi;
nm = height(modes);
n = 4*nm;
[direction, system, interferer, victim] = deal(strings(n, 1));
[eirp_dbm, g_rx_dbi, l_rx_db, otr_db, noise_dbm, in_db, l_req_db] = deal(zeros(n, 1));
r = 0;
for j = 1:2
    for m = 1:nm
        % ship mode -> NEXRAD
        r = r + 1;
        direction(r) = "ship to NEXRAD"; system(r) = modes.system(m);
        interferer(r) = modes.mode(m); victim(r) = "NEXRAD " + nx_pulse(j);
        eirp_dbm(r) = 10*log10(modes.peak_kw(m)*1e6) - P.ship.tx_line_loss_db + modes.gain_dbi(m);
        g_rx_dbi(r) = nx.gain_dbi; l_rx_db(r) = nx.rx_line_loss_db;
        otr_db(r) = emc_otr_rev1(modes.tx_bw_mhz(m), nx_br(j), modes.otr_k(m));
        noise_dbm(r) = nx_noise(j);
        if opts.nexrad_in == "pulsed"
            fc = min(1, modes.prf_hz(m) * (modes.pulse_us(m) + nx_tau(j)) * 1e-6);
            in_db(r) = nx.in_constant_db - 10*log10(fc);
        else
            in_db(r) = nx.in_constant_db;
        end
        % NEXRAD -> ship mode
        r = r + 1;
        direction(r) = "NEXRAD to ship"; system(r) = modes.system(m);
        interferer(r) = "NEXRAD " + nx_pulse(j); victim(r) = modes.mode(m);
        eirp_dbm(r) = nx_eirp(j);
        g_rx_dbi(r) = modes.gain_dbi(m); l_rx_db(r) = P.ship.rx_line_loss_db;
        otr_db(r) = emc_otr_rev1(nx_bt(j), modes.if_mhz(m), 20);
        noise_dbm(r) = -174 + 10*log10(modes.if_mhz(m)*1e6) + modes.nf_db(m);
        in_db(r) = ship_in;
    end
end
l_req_db = eirp_dbm + g_rx_dbi - l_rx_db - otr_db - (noise_dbm + in_db);
T = table(direction, system, interferer, victim, eirp_dbm, g_rx_dbi, l_rx_db, otr_db, noise_dbm, in_db, l_req_db);
end
