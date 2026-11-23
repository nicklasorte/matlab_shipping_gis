function tests = test_emc_cochannel_rev1
tests = functiontests(localfunctions);
end
function testOtr(tc)
% SM.337-6 eq. (6): zero when the receiver is wider; 20*log10 ratio for pulses; 10*log10 for FM.
verifyEqual(tc, emc_otr_rev1(1, 5, 20), 0);
verifyEqual(tc, emc_otr_rev1(10, 1, 20), 20, 'AbsTol', 1e-12);
verifyEqual(tc, emc_otr_rev1(10, 1, 10), 10, 'AbsTol', 1e-12);
end
function testHandCase(tc)
% NEXRAD short pulse into the ship radar T4 longest mode (IF 2.5 MHz, NF 3 dB), by hand:
% EIRP = 10*log10(750e6) - 2.0 + 46.1 = 132.8506 dBm; G_r = 28; OTR = 0 (0.6 < 2.5 MHz);
% N = -174 + 10*log10(2.5e6) + 3 = -107.0206 dBm; I/N = -6 dB; L_req = 132.8506 + 28 + 107.0206 + 6 = 273.8712 dB.
[P, modes] = emc_params_rev1();
T = emc_required_loss_rev1(P, modes);
r = T.direction == "NEXRAD to ship" & T.interferer == "NEXRAD short" & T.victim == "T4 longest";
verifyEqual(tc, T.l_req_db(r), 10*log10(750e6) - 2.0 + 46.1 + 28 - (-174 + 10*log10(2.5e6) + 3) + 6, 'AbsTol', 1e-9);
end
function testMatchesPython(tc)
% MATLAB and Python required losses agree to 0.01 dB.
here = fileparts(mfilename('fullpath'));
C = readcell(fullfile(here, 'outputs', 'emc', 'cochannel_required_loss_py_rev1.csv'));
hdr = string(C(1, :)); C = C(2:end, :);
[P, modes] = emc_params_rev1();
T = emc_required_loss_rev1(P, modes);
key_m = T.direction + "|" + T.interferer + "|" + T.victim;
key_p = string(C(:, hdr == "direction")) + "|" + string(C(:, hdr == "interferer")) + "|" + string(C(:, hdr == "victim"));
[ok, loc] = ismember(key_m, key_p);
verifyTrue(tc, all(ok));
verifyEqual(tc, T.l_req_db, cell2mat(C(loc, hdr == "l_req_db")), 'AbsTol', 0.01);
end
function testSeparation(tc)
% Synthetic loss rising 1 dB/km: separation is where it reaches the requirement; flags at both ends.
d = (1:100)'; L = 100 + d;
[s, f] = emc_separation_rev1(d, L, [150.5; 50; 500]);
verifyEqual(tc, s(1), 50.5, 'AbsTol', 1e-9); verifyEqual(tc, f', [0 -1 1]);
end
