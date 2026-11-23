function tests = test_emc_nexrad_sweep_rev1
%TEST_EMC_NEXRAD_SWEEP_REV1 Checks of init_emc_nexrad_sweep_rev1 outputs (run the driver first).
tests = functiontests(localfunctions);
end
function testMatchesPython(tc)
% MATLAB and Python required loss after FDR agree to 0.01 dB for every row.
here = fileparts(mfilename('fullpath'));
M = readcell(fullfile(here, 'outputs', 'emc', 'nexrad_sweep_lreq_rev1.csv'));
Y = readcell(fullfile(here, 'outputs', 'emc', 'nexrad_sweep_lreq_py_rev1.csv'));
verifyEqual(tc, size(M, 1), size(Y, 1));
verifyEqual(tc, string(M(2:end, 2:5)), string(Y(2:end, 2:5)));
verifyEqual(tc, cell2mat(M(2:end, [1 7])), cell2mat(Y(2:end, [1 6])), 'AbsTol', 1e-9);
verifyEqual(tc, cell2mat(M(2:end, 8)), cell2mat(Y(2:end, 7)), 'AbsTol', 0.01);
end
function testCoChannelAt3050(tc)
% At 3050 MHz every mode can tune to NEXRAD, so the pulsed-case rows equal the co-channel required loss.
here = fileparts(mfilename('fullpath'));
S = readtable(fullfile(here, 'outputs', 'emc', 'nexrad_sweep_separation_rev1.csv'), 'TextType', 'string');
C = readtable(fullfile(here, 'outputs', 'emc', 'cochannel_required_loss_rev1.csv'), 'TextType', 'string');
s = S(S.f_nexrad_mhz == 3050 & ismember(S.protection, ["NEXRAD pulsed", "ship -6 dB"]), :);
verifyEqual(tc, s.df_mhz, zeros(height(s), 1));
verifyEqual(tc, s.l_req_db, C.l_req_db, 'AbsTol', 1e-6);
end
function testTuning(tc)
% Offsets from the published ranges: at 2800 MHz the magnetrons are 220 MHz away (B and C 240 MHz) and
% Radar No. 3B is 130 MHz away (channel 2930 MHz); at 3000 MHz 3B is 10 MHz away; inside 3040-3060 MHz all 0.
here = fileparts(mfilename('fullpath'));
S = readtable(fullfile(here, 'outputs', 'emc', 'nexrad_sweep_separation_rev1.csv'), 'TextType', 'string');
pick = @(f, mode) unique(S.df_mhz(S.f_nexrad_mhz == f & (S.interferer == mode | S.victim == mode)));
verifyEqual(tc, pick(2800, "T4 shortest"), 220);
verifyEqual(tc, pick(2800, "B 1.0"), 240);
verifyEqual(tc, pick(2800, "3B 0.1"), 130);
verifyEqual(tc, pick(3000, "3B 0.1"), 10);
verifyEqual(tc, unique(S.df_mhz(S.f_nexrad_mhz >= 3040 & S.f_nexrad_mhz <= 3060)), 0);
end
function testDistanceFallsAwayFromBand(tc)
% Envelope distance at 2800 MHz is no larger than at 3050 MHz for every direction, type, and level.
here = fileparts(mfilename('fullpath'));
E = readtable(fullfile(here, 'outputs', 'emc', 'nexrad_sweep_envelope_rev1.csv'), 'TextType', 'string');
a = sortrows(E(E.f_nexrad_mhz == 2800, :), ["direction", "system", "protection"]);
b = sortrows(E(E.f_nexrad_mhz == 3050, :), ["direction", "system", "protection"]);
verifyLessThanOrEqual(tc, a.d_km_p50, b.d_km_p50);
end
