function tests = test_emc_coupling_rev1
%TEST_EMC_COUPLING_REV1 Checks of the beyond-horizon coupling (run init_emc_coupling_rev1 first for the file tests).
tests = functiontests(localfunctions);
end
function testTakeoffAngle(tc)
% Two 30 m antennas, N0 301: horizon 45.2 km, horizon ray -0.152 deg; inside the horizon the direct ray.
[e1, e2, d_los, ae] = emc_takeoff_angle_rev1([20 100], 30, 30, 301);
verifyEqual(tc, ae, 8492.5, 'AbsTol', 0.5);
verifyEqual(tc, d_los, 45.15, 'AbsTol', 0.01);
verifyEqual(tc, e1, e2);
verifyEqual(tc, e1(2), -rad2deg(sqrt(2*0.03/ae)), 'AbsTol', 1e-12);
verifyEqual(tc, e1(1), -rad2deg(20/(2*ae)), 'AbsTol', 1e-12);
end
function testPeakMatchesPython(tc)
% Peak coupling change from MATLAB (mutual_antenna_gain max on path) and the Python closed form agree to 0.01 dB.
here = fileparts(mfilename('fullpath'));
M = readtable(fullfile(here, 'outputs', 'emc', 'coupling_levels_rev1.csv'), 'TextType', 'string');
Y = readtable(fullfile(here, 'outputs', 'emc', 'coupling_peak_py_rev1.csv'), 'TextType', 'string');
M = sortrows(M(M.level == "peak", :), ["f_mhz", "system"]);
Y = sortrows(Y, ["f_mhz", "system"]);
verifyEqual(tc, M.f_mhz, Y.f_mhz);
verifyEqual(tc, M.system, Y.system);
verifyEqual(tc, M.dg_db, Y.dg_db, 'AbsTol', 0.01);
end
function testLevelsOrdered(tc)
% Coupling falls from the peak through the percentiles, and never exceeds main beam to main beam.
here = fileparts(mfilename('fullpath'));
M = readtable(fullfile(here, 'outputs', 'emc', 'coupling_levels_rev1.csv'), 'TextType', 'string');
verifyLessThanOrEqual(tc, M.dg_db, 0);
for s = ["magnetron", "solid_state"]
    m = M(M.f_mhz == 3050 & M.system == s, :);
    v = [m.dg_db(m.level == "peak"), m.dg_db(m.level == "p99.9"), m.dg_db(m.level == "p99"), m.dg_db(m.level == "p90")];
    verifyTrue(tc, all(diff(v) <= 0));
end
end
function testSeparationShorterThanMainBeam(tc)
% Every coupling-level separation is at or below the main-beam separation of the same row.
here = fileparts(mfilename('fullpath'));
O = readtable(fullfile(here, 'outputs', 'emc', 'coupling_envelope_rev1.csv'), 'TextType', 'string');
S = readtable(fullfile(here, 'outputs', 'emc', 'nexrad_sweep_envelope_rev1.csv'), 'TextType', 'string');
o = O(O.coupling == "peak", :);
[tf, loc] = ismember(o(:, ["f_nexrad_mhz", "direction", "system", "protection"]), ...
    S(:, ["f_nexrad_mhz", "direction", "system", "protection"]));
verifyTrue(tc, all(tf));
verifyLessThanOrEqual(tc, o.d_km_p50, S.d_km_p50(loc) + 1e-9);
end
