%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%check_known_answer_rev1
%%%%%
%%%%%Known-answer test for the MATLAB pipeline (review stage 4): runs the
%%%%%synthetic day tests/known_answer/ais-2030-01-02.csv (written by
%%%%%python/test_known_answer.py) through ais_cache_day_rev1 on the lower-48
%%%%%and Alaska grids, and compares the (cell, MMSI) pairs with the
%%%%%hand-computed tests/known_answer/expected.json. Errors on any mismatch.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
src_dir=fullfile(pwd,'tests','known_answer');
expected=jsondecode(fileread(fullfile(src_dir,'expected.json')));
work_dir=tempname;
mkdir(work_dir);
cleanup_dir=onCleanup(@() rmdir(work_dir,'s'));
copyfile(fullfile(src_dir,'ais-2030-01-02.csv'),work_dir);

p.data_dir=work_dir;
p.zstd_exe='/opt/homebrew/bin/zstd';
p.delete_csv=false;
p.ais_read_rows=1e6;
p.prefilter_min_length=100;
p.filt.vessel_types=[0 33 35 55 60:89 90:99];   %%%%%same as init_shipping_zone_rev1.m
p.filt.min_length_m=100;
p.filt.require_imo=true;
p.filt.no_imo_types=[35 55];
p.filt.min_sog_kn=0;

grids={'conus',georefcells([22 50],[-130 -66],0.01,0.01); ...
       'alaska180',georefcells([51 72],[-180 -129],0.01,0.01)};
for k=1:size(grids,1)
    R=grids{k,2};
    p.rasterref=R;
    S=ais_cache_day_rev1(datetime(2030,1,2),R,p);
    got=sortrows(unique(S.pairs,'rows'));
    want=sortrows(expected.(grids{k,1}));
    if ~isequal(got,want)
        error('shipgis:known','%s: MATLAB gives %d pairs, expected %d.',grids{k,1},size(got,1),size(want,1));
    end
    fprintf('%s: %d pairs, exact match\n',grids{k,1},size(got,1));
end
