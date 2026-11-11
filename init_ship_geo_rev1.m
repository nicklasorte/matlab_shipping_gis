%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%init_ship_geo_rev1
%%%%%
%%%%%Draws the nine geographic figures (Appendix A, maps A-9 to A-17) from
%%%%%the AIS day caches, including the ship-type caches (cargo, tanker,
%%%%%passenger, government), and saves the tables behind them. Run
%%%%%init_shipping_zone_rev1.m first (it writes the sites and principal-port
%%%%%CSVs this script reads).
%%%%%
%%%%%The settings below must match init_shipping_zone_rev1.m. The Python
%%%%%versions are python/ship_geo_products.py and python/ship_geo_figures.py.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; clc;

p.latlim=[22 50];
p.lonlim=[-130 -66];
p.cells_per_degree=100;
p.ais_days=[datetime(2023,1,4):caldays(7):datetime(2023,12,31), ...
    datetime(2024,1,3):caldays(7):datetime(2024,12,31)];
p.filt=struct('vessel_types',[0 33 35 55 60:89 90:99],'min_length_m',100,'require_imo',true, ...
    'no_imo_types',[35 55],'min_sog_kn',0);
p.filt_towing=struct('vessel_types',[31 32 52],'min_length_m',100,'require_imo',true, ...
    'no_imo_types',[],'min_sog_kn',0);
p.towing_coast_km=25;
p.min_unique_ships=4;
p.census_year=2023;
p.data_dir=fullfile(pwd,'data');
p.out_dir=fullfile(pwd,'outputs','2023_2024');   %%%%%sites and principal-port CSVs from the zone run
p.out_name='shipping_zone_2023_2024';
p.zstd_exe='/opt/homebrew/bin/zstd';      %%%%%only used if a day cache is missing
p.delete_csv=true;
p.prefilter_min_length=100;
p.ais_read_rows=1e6;

%%%%%Ship-type groups (same length and IMO rules as p.filt)
type_filts.cargo=struct('vessel_types',70:79,'min_length_m',100,'require_imo',true,'no_imo_types',[],'min_sog_kn',0);
type_filts.tanker=struct('vessel_types',80:89,'min_length_m',100,'require_imo',true,'no_imo_types',[],'min_sog_kn',0);
type_filts.passenger=struct('vessel_types',60:69,'min_length_m',100,'require_imo',true,'no_imo_types',[],'min_sog_kn',0);
type_filts.government=struct('vessel_types',[35 55],'min_length_m',100,'require_imo',true,'no_imo_types',[35 55],'min_sog_kn',0);

geo_dir=fullfile(pwd,'output','viz_matlab');
if ~isfolder(geo_dir)
    mkdir(geo_dir);
end

tic;
prod=viz_products_rev1(p);
geo=geo_products_rev1(p,prod,type_filts);
fprintf('Products: %.0f s\n',toc);
writetable(geo.hex,fullfile(geo_dir,'geo_hex.csv'));
writetable(geo.hex_types,fullfile(geo_dir,'geo_hex_types.csv'));
writetable(geo.ports,fullfile(geo_dir,'geo_ports.csv'));
writetable(geo.profile,fullfile(geo_dir,'geo_profile.csv'));
writelines(jsonencode(geo.summary,'PrettyPrint',true),fullfile(geo_dir,'geo_summary.json'));
disp(geo.summary)

titles=plot_ship_geo_rev1(prod,geo,geo_dir,fullfile(p.data_dir,'cb_2023_us_state_500k','cb_2023_us_state_500k.shp'), ...
    fullfile(p.out_dir,sprintf('%s_sites.csv',p.out_name)));
disp(titles)
