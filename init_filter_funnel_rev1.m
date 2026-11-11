%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%init_filter_funnel_rev1
%%%%%
%%%%%Measures how much of the raw AIS data each step of the large-ship
%%%%%filter keeps, on one full day per year (the working paper's attrition
%%%%%table). Each day is downloaded in full (no length prefilter), run
%%%%%through ais_filter_funnel_rev1, and deleted.
%%%%%
%%%%%Check: step 4 (reports) must equal num_row_kept in the day's AIS cache,
%%%%%which ais_cache_day_rev1 or ais_cells_py_rev1.py built independently.
%%%%%
%%%%%The ship types below are p.filt.vessel_types plus p.filt_towing.vessel_types
%%%%%from init_shipping_zone_rev1.m (towing also needs an IMO number). The
%%%%%coastal rule for towing is applied later, in shipping_zone_rev1. The
%%%%%step-4 check runs only when a cache for these combined types exists.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; clc;

f.days=[datetime(2023,7,12) datetime(2024,7,10)];   %%%%%mid-year Wednesdays (in the weekly sample)
f.latlim=[22 50];
f.lonlim=[-130 -66];
f.cells_per_degree=100;
f.filt.vessel_types=[0 31 32 33 35 52 55 60:89 90:99];
f.filt.min_length_m=100;
f.filt.require_imo=true;
f.filt.no_imo_types=[35 55];
f.filt.min_sog_kn=0;
f.data_dir=fullfile(pwd,'data');
f.out_dir=fullfile(pwd,'output');
f.zstd_exe='/opt/homebrew/bin/zstd';
f.read_rows=1e6;

if ~isfolder(f.out_dir)
    mkdir(f.out_dir);
end
R=georefcells(f.latlim,f.lonlim,1/f.cells_per_degree,1/f.cells_per_degree);
cache_p.data_dir=f.data_dir;     %%%%%only what ais_cache_name_rev1 needs
cache_p.filt=f.filt;

num_day=numel(f.days);
funnel_all=cell(num_day,1);
type_all=cell(num_day,1);
for day_idx=1:num_day
    day=f.days(day_idx);
    [csv_path,tf_private]=download_ais_day_rev1(day,f.data_dir,f.zstd_exe,false,0);
    [funnel,by_type]=ais_filter_funnel_rev1(csv_path,R,f.filt,f.read_rows);
    if tf_private
        delete(csv_path);
    end
    funnel.day=repmat(day,height(funnel),1);
    by_type.day=repmat(day,height(by_type),1);
    funnel_all{day_idx}=funnel;
    type_all{day_idx}=by_type;
    disp(funnel);
    disp(by_type);

    %%%%%Cross-check against the independently built cache
    cache_file=ais_cache_name_rev1(day,R,cache_p);
    if isfile(cache_file)
        S=load(cache_file,'num_row_kept');
        if S.num_row_kept~=funnel.reports(4)
            error('shipgis:funnel','%s: funnel step 4 has %d reports, cache has %d', ...
                string(day,'yyyy-MM-dd'),funnel.reports(4),S.num_row_kept);
        end
        fprintf('%s: step 4 matches the cache (%d reports)\n',string(day,'yyyy-MM-dd'),S.num_row_kept);
    end
end
writetable(vertcat(funnel_all{:}),fullfile(f.out_dir,'ais_filter_funnel.csv'));
writetable(vertcat(type_all{:}),fullfile(f.out_dir,'ais_filter_by_type.csv'));
