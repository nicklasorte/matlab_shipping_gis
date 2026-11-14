%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%init_shipping_zone_prusvi_rev1
%%%%%
%%%%%Zones within X km of where large ships operate around Puerto Rico and
%%%%%the U.S. Virgin Islands, for the 2.7 GHz study. Same AIS sample
%%%%%(2024-2025), ship filter, route rule (4 distinct ships in one year, 2
%%%%%within 50 km of deep-draft ports), zone method, and band distances as
%%%%%the lower 48. Traffic here is dense enough for the lower-48 rule (median
%%%%%58 large ships a day); python/ship_route_rules.py compares the rules.
%%%%%
%%%%%Maps are drawn in Python (python/ship_prusvi_figures.py).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
clc;

%%%%%%%%%%Grid: Puerto Rico, the U.S. Virgin Islands, and their approaches
p.latlim=[16.5 19.5];
p.lonlim=[-68.5 -64];
p.cells_per_degree=100;

%%%%%%%%%%AIS sample (same 104 days as the lower 48)
per=period_rev1();
p.ais_days=per.days;
p.delete_csv=true;
p.prefilter_min_length=100;
p.zstd_exe='/opt/homebrew/bin/zstd';

%%%%%%%%%%Large-ship filter (same as the lower 48)
p.filt.vessel_types=[0 33 35 55 60:89 90:99];
p.filt.min_length_m=100;
p.filt.require_imo=true;
p.filt.no_imo_types=[35 55];
p.filt.min_sog_kn=0;
p.filt_towing=struct('vessel_types',[31 32 52],'min_length_m',100,'require_imo',true, ...
    'no_imo_types',[],'min_sog_kn',0);
p.towing_coast_km=25;

%%%%%%%%%%Route rule (same as the lower 48)
p.route_rule='unique_ships';
p.min_unique_ships=4;
p.port_relax_km=50;
p.port_min_unique_ships=2;
p.port_relax_coast_km=25;   %%%%%approaches only, not upriver (review CA-8)

%%%%%%%%%%Fairways, TSS lanes, and S-band racons (NOAA ENC Direct)
p.include_fairways=true;
p.include_racons=true;
p.racon_bands="S";

%%%%%%%%%%Zones (same distances and bands as the lower 48)
p.distances_km=[25 50 100];
p.zone_mode='ships';      %%%%%zone = U.S. land and water within X km of a route cell (ship water); was 'shore' before the November 2026 review (CA-4 to CA-7)
p.shore_link_km=25;
p.band_zones=table([2900;3000;3030;3070],[3000;3030;3070;3100],[25;50;100;50], ...
    'VariableNames',{'f_low_mhz','f_high_mhz','distance_km'});

%%%%%%%%%%Ports: USACE Principal Ports in Puerto Rico, plus the main U.S. Virgin
%%%%%%%%%%Islands harbors (not Principal Ports; approximate harbor positions)
p.check_ports=table( ...
    ["San Juan, PR";"Ponce, PR";"Guaynabo, PR";"Yabucoa, PR";"Mayaguez, PR"; ...
     "Charlotte Amalie (St. Thomas), VI";"Limetree Bay (St. Croix), VI";"Frederiksted (St. Croix), VI"], ...
    [18.43278;17.97861;18.43022;18.05174;18.205;18.335;17.690;17.715], ...
    [-66.09668;-66.621;-66.11114;-65.83623;-67.160;-64.930;-64.750;-64.885], ...
    'VariableNames',{'name','lat','lon'});
p.principal_ports=true;
p.principal_ports_gap_km=5;
p.check_vts=table(strings(0,1),zeros(0,1),zeros(0,1),'VariableNames',{'name','lat','lon'});

%%%%%%%%%%Census reference layers
p.census_year=2023;

%%%%%%%%%%Folders and names
p.data_dir=fullfile(pwd,'data');
p.out_dir=fullfile(pwd,'output_prusvi');
p.out_name=['shipping_zone_prusvi_' per.tag];
p.make_figure=false;

%%%%%%%%%%Output size
p.simplify_deg=0.005;
p.clip_water_foreign_side=true; %%%%%drop zone water nearer foreign land than U.S. land (review R2MET-1, option 2); routes stay sources
p.clip_water_cap_km=2500;      %%%%%distances out to 2,500 km so far-offshore water is judged; farther from both counts as U.S.-side
p.routes_simplify_deg=0;
p.kmz=true;
p.save_grids=true;
p.png_dpi=200;
p.parallel_flag=0;

%%%%%%%%%%Memory
p.ais_read_rows=1e6;
p.block_rows=200;

result=shipping_zone_rev1(p);
