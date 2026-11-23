function tests = test_emc_offset_rev1
tests = functiontests(localfunctions);
end
function testEmissionMatchesPublishedPoints(tc)
% NEXRAD short pulse envelope against NOAA ROC (40 dBc at 7.26 MHz, 80 dBc at 62 MHz) and ITU-R M.1849-3
% (-20 dB bandwidth 4.6 MHz); magnetron 0.05 us against M.1460-2 Table 4 (-20 dB bandwidth 43 MHz). Within 3 dB.
p = 10*log10(emc_emission_rev1([2.3 7.26 62], 1.57, 0.12));
verifyEqual(tc, p, [-20 -40 -80], 'AbsTol', 3);
verifyEqual(tc, 10*log10(emc_emission_rev1(21.5, 0.05, 0.041)), -20, 'AbsTol', 3);
end
function testSelectivity(tc)
% Ship IF: 3 dB at half its bandwidth, floored at 60 dB; NEXRAD front end adds 30 dB at 25 MHz.
verifyEqual(tc, 10*log10(emc_selectivity_rev1(1.25, "ship", if_mhz=2.5)), -10*log10(2), 'AbsTol', 1e-9);
verifyEqual(tc, 10*log10(emc_selectivity_rev1(500, "ship", if_mhz=2.5)), -60, 'AbsTol', 1e-9);
mf = 10*log10(min(1, (1/(pi*25*1.57))^2));
verifyEqual(tc, 10*log10(emc_selectivity_rev1(25, "nexrad", tau_us=1.57)), mf - 30, 'AbsTol', 1e-9);
end
function testOfrZeroOnTune(tc)
o = emc_ofr_rev1([0 5 20], @(f) emc_emission_rev1(f, 1.57, 0.12), @(f) emc_selectivity_rev1(f, "ship", if_mhz=2.5));
verifyEqual(tc, o(1), 0, 'AbsTol', 1e-9);
verifyTrue(tc, all(diff(o) > 0));
end
function testMatchesPython(tc)
% MATLAB and Python OFR agree to 0.01 dB for every pair and offset.
here = fileparts(mfilename('fullpath'));
M = readcell(fullfile(here, 'outputs', 'emc', 'offset_ofr_rev1.csv'));
Y = readcell(fullfile(here, 'outputs', 'emc', 'offset_ofr_py_rev1.csv'));
verifyEqual(tc, size(M), size(Y));
verifyEqual(tc, cell2mat(M(2:end, 5:end)), cell2mat(Y(2:end, 5:end)), 'AbsTol', 0.01);
end
