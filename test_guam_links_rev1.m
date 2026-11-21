function tests = test_guam_links_rev1
tests = functiontests(localfunctions);
end
function testMatchesPythonCsv(tc)
% The MATLAB twin must give the same cells as python/guam_cnmi_links.py (exact).
here=fileparts(mfilename('fullpath'));
ref=readmatrix(fullfile(here,'outputs','guam','guam_cnmi_links_cells_rev1.csv'));
got=guam_cnmi_links_rev1();
verifyEqual(tc,got(:),ref(:));
verifyEqual(tc,numel(got),231);
end
