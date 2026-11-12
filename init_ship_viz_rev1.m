%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%init_ship_viz_rev1
%%%%%
%%%%%Draws the ten ship-data figures (MATLAB versions) from the AIS day
%%%%%caches and the outputs of init_shipping_zone_rev1.m, and saves the
%%%%%tables behind them. Run init_shipping_zone_rev1.m first (it writes the
%%%%%sites and principal-port CSVs this script reads).
%%%%%
%%%%%The settings below must match init_shipping_zone_rev1.m. The Python
%%%%%versions are python/ship_viz_products.py and python/ship_viz_figures.py.
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
p.out_dir=fullfile(pwd,'outputs',per.tag);   %%%%%sites and principal-port CSVs from the zone run
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
fprintf('Products: %.0f s\n',toc);
writetable(prod.daily,fullfile(viz_dir,'viz_daily.csv'));
writetable(prod.river,fullfile(viz_dir,'viz_mississippi.csv'));
writetable(prod.sites,fullfile(viz_dir,'viz_sites.csv'));
summary=prod.summary;
summary.river_km_new_orleans=prod.river_km.new_orleans;
summary.river_km_baton_rouge=prod.river_km.baton_rouge;
summary.river_km_last=prod.river_km.last;
writelines(jsonencode(summary,'PrettyPrint',true),fullfile(viz_dir,'viz_summary.json'));
disp(summary)

titles=plot_ship_viz_rev1(prod,viz_dir,fullfile(p.data_dir,'cb_2023_us_state_500k','cb_2023_us_state_500k.shp'), ...
    fullfile(pwd,'outputs','2024','gt_proxy_sweep_2024.csv'), ...
    fullfile(pwd,'outputs','2023_2024','ais_filter_funnel.csv'));
disp(titles)
