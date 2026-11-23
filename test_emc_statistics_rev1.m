function tests = test_emc_statistics_rev1
%TEST_EMC_STATISTICS_REV1 Checks of the time-share separation (run init_emc_statistics_rev1 and
%   python/emc_statistics.py first for the file tests).
tests = functiontests(localfunctions);
end
function testMatchesPython(tc)
% MATLAB (FFT correlation) and Python (direct sum) co-channel separations agree to 1 km.
here = fileparts(mfilename('fullpath'));
M = readtable(fullfile(here, 'outputs', 'emc', 'stat_separation_sweep_rev1.csv'), 'TextType', 'string');
Y = readtable(fullfile(here, 'outputs', 'emc', 'stat_cochannel_py_rev1.csv'), 'TextType', 'string');
M = M(M.f_nexrad_mhz == 3050, :);
verifyEqual(tc, height(M), height(Y));
verifyEqual(tc, M.interferer, Y.interferer);
verifyEqual(tc, M.protection, Y.protection);
verifyEqual(tc, M.x_db, Y.x_db, 'AbsTol', 1e-6);
verifyEqual(tc, [M.d_km_q10, M.d_km_q1, M.d_km_q0_1], [Y.d_km_q10, Y.d_km_q1, Y.d_km_q0_1], 'AbsTol', 1);
end
function testOrderedAndBelowPeakCoupling(tc)
% Rarer interference needs more distance. The 0.1%-of-time distance is at or below the peak-coupling distance
% at 0.1% of ITM time: with MAG at most its peak, P(L - MAG < x) <= P(L < x + MAG_peak). Tolerance 3 km covers
% the pmf binning (mass at upper bin edges, up to 0.1 dB).
here = fileparts(mfilename('fullpath'));
E = readtable(fullfile(here, 'outputs', 'emc', 'stat_envelope_sweep_rev1.csv'), 'TextType', 'string');
verifyTrue(tc, all(E.d_km_q10 <= E.d_km_q1 + 1e-9 & E.d_km_q1 <= E.d_km_q0_1 + 1e-9));
C = readtable(fullfile(here, 'outputs', 'emc', 'coupling_envelope_rev1.csv'), 'TextType', 'string');
C = C(C.coupling == "peak", :);
[tf, loc] = ismember(E(:, ["f_nexrad_mhz", "direction", "system", "protection"]), ...
    C(:, ["f_nexrad_mhz", "direction", "system", "protection"]));
verifyTrue(tc, all(tf));
verifyLessThanOrEqual(tc, E.d_km_q0_1, C.d_km_p0_1(loc) + 3);
end
function testPmfSumsToOne(tc)
% The joint table is a probability: 0 to 1, falling with distance far out.
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'matlab_itm'), fullfile(here, '..', 'mutual_antenna_gain'));
P = emc_params_rev1();
J = emc_joint_rev1(P, 3050, d_km=(50:50:1500)', x_db=200:0.1:240);
p = J.magnetron.pexc;
verifyGreaterThanOrEqual(tc, p, 0);
verifyLessThanOrEqual(tc, p, 1);
verifyTrue(tc, all(diff(p(:, end)) <= 1e-9));
end
