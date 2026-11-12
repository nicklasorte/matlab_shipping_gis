%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%init_ship_corridors_rev1
%%%%%
%%%%%How far up each river and ship channel large ships go: distinct ships
%%%%%along every corridor in config/corridors_rev1.csv, from the entrance
%%%%%to the head port (the Mississippi profile, generalized). Writes the
%%%%%tables to output/viz_matlab/corridor_*.csv and the figures to
%%%%%output/viz_matlab/corr*.png.
%%%%%
%%%%%The settings below must match init_shipping_zone_rev1.m. The Python
%%%%%versions are python/ship_corridor_products.py and
%%%%%python/ship_corridor_figures.py.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; clc;

p.latlim=[22 50];
p.lonlim=[-130 -66];
p.cells_per_degree=100;
per=period_rev1();         %%%%%analysis years: 2024-2025 (period_rev1.m)
p.ais_days=per.days;       %%%%%the first 52 Wednesdays of each year
p.filt=struct('vessel_types',[0 33 35 55 60:89 90:99],'min_length_m',100,'require_imo',true, ...
    'no_imo_types',[35 55],'min_sog_kn',0);
p.filt_towing=struct('vessel_types',[31 32 52],'min_length_m',100,'require_imo',true, ...
    'no_imo_types',[],'min_sog_kn',0);
p.towing_coast_km=25;
p.min_unique_ships=4;
p.census_year=2023;
p.data_dir=fullfile(pwd,'data');
p.out_dir=fullfile(pwd,'outputs',per.tag);
p.out_name=['shipping_zone_' per.tag];
p.zstd_exe='/opt/homebrew/bin/zstd';      %%%%%only used if a day cache is missing
p.delete_csv=true;
p.prefilter_min_length=100;
p.ais_read_rows=1e6;

viz_dir=fullfile(pwd,'output','viz_matlab');
if ~isfolder(viz_dir)
    mkdir(viz_dir);
end

tic;
prod=viz_products_rev1(p);
cor=corridor_products_rev1(prod,fullfile(pwd,'config','corridors_rev1.csv'));
fprintf('Products: %.0f s\n',toc);
writetable(cor.summary,fullfile(viz_dir,'corridor_summary.csv'));
writetable(cor.profile,fullfile(viz_dir,'corridor_profile.csv'));
writetable(cor.marks,fullfile(viz_dir,'corridor_marks.csv'));
writetable(cor.continuation,fullfile(viz_dir,'corridor_continuation.csv'));
disp(cor.summary)

titles=plot_ship_corridors_rev1(cor,prod,viz_dir,fullfile(p.data_dir,'cb_2023_us_state_500k','cb_2023_us_state_500k.shp'));
disp(titles)
