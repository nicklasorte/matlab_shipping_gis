%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%init_port_share_rev1
%%%%%
%%%%%How large-ship port visits split among the 73 deep-draft ports: ten
%%%%%figures (treemap, circle packing, Pareto bars, concentration curve,
%%%%%waffle, Marimekko by ship type, sunburst, Dorling map, 100% bars by
%%%%%coast, 2023 against 2024). Writes output/viz_matlab/port_share*.csv
%%%%%and output/viz_matlab/share*.png.
%%%%%
%%%%%The settings below must match init_shipping_zone_rev1.m. The Python
%%%%%versions are python/ship_port_share_products.py and
%%%%%python/ship_port_share_figures.py.
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
p.config_dir=fullfile(pwd,'config');
p.out_dir=fullfile(pwd,'outputs',per.tag);
p.out_name=['shipping_zone_' per.tag];
p.zstd_exe='/opt/homebrew/bin/zstd';      %%%%%only used if a day cache is missing
p.delete_csv=true;
p.prefilter_min_length=100;
p.ais_read_rows=1e6;

%%%%%Ship-type groups (same length and IMO rules as p.filt)
type_filts.cargo=struct('vessel_types',70:79,'min_length_m',100,'require_imo',true,'no_imo_types',[],'min_sog_kn',0);
type_filts.tanker=struct('vessel_types',80:89,'min_length_m',100,'require_imo',true,'no_imo_types',[],'min_sog_kn',0);
type_filts.passenger=struct('vessel_types',60:69,'min_length_m',100,'require_imo',true,'no_imo_types',[],'min_sog_kn',0);
type_filts.government=struct('vessel_types',[35 55],'min_length_m',100,'require_imo',true,'no_imo_types',[35 55],'min_sog_kn',0);

viz_dir=fullfile(pwd,'output','viz_matlab');
if ~isfolder(viz_dir)
    mkdir(viz_dir);
end

tic;
prod=viz_products_rev1(p);
ps=port_share_products_rev1(p,prod,type_filts);
fprintf('Products: %.0f s\n',toc);
writetable(ps.ports,fullfile(viz_dir,'port_share.csv'));
writetable(ps.complex,fullfile(viz_dir,'port_share_complex.csv'));
disp(head(ps.ports,12))

titles=plot_port_share_rev1(ps,viz_dir,fullfile(p.data_dir,'cb_2023_us_state_500k','cb_2023_us_state_500k.shp'));
disp(titles)
