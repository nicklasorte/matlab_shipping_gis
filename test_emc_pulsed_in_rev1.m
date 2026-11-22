function tests = test_emc_pulsed_in_rev1
tests = functiontests(localfunctions);
end
function testMatchesPython(tc)
% MATLAB and Python peak I/N agree to 0.05 dB for every NEXRAD-victim row.
here=fileparts(mfilename('fullpath'));
C=readcell(fullfile(here,'outputs','emc','pulsed_in_criteria_rev1.csv'));   % readcell: mixed text and numbers
hdr=string(C(1,:)); C=C(2:end,:);
keep=string(C(:,hdr=="victim"))=="NEXRAD";
py_db=cell2mat(C(keep,hdr=="peak_IN_dB"));
M=emc_pulsed_in_rev1();
verifyEqual(tc,height(M),numel(py_db));
verifyEqual(tc,M.peak_IN_dB,py_db,'AbsTol',0.05);
end
function testDutyCycleLimit(tc)
% When the interfering pulse is much longer than the gate, f_c tends to the duty cycle (M.1849-3 note).
M=emc_pulsed_in_rev1();
r=M.interferer=="Solid-state 3B, long (unmodulated)" & contains(M.victim_mode,"short");
verifyLessThan(tc,abs(M.f_c(r)-M.duty_cycle_pct(r)/100)/M.f_c(r),0.05);
end
