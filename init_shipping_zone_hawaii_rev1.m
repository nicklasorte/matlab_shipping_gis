%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%init_shipping_zone_hawaii_rev1
%%%%%
%%%%%Zones within X km of where large ships operate around Hawaii, for the
%%%%%2.7 GHz study. Same AIS sample, ship filter, zone method, and band
%%%%%distances as init_shipping_zone_rev1 (lower 48), with one change: the
%%%%%route rule counts ship-days instead of distinct ships per year.
%%%%%
%%%%%Why: a few dedicated ships serve the neighbor islands. Under the
%%%%%lower-48 rule (4 distinct ships in one year) the inter-island lanes
%%%%%break and only three ports connect (route_rules.json). Ship-days (distinct ships
%%%%%per sampled day, summed over the 104 days, at least 6) connects
%%%%%Kahului and Nawiliwili too. The value 6 best reproduces the lower-48
%%%%%network (Jaccard 0.80 for 2024-2025); see python/ship_route_rules.py and
%%%%%docs/plans/alaska_hawaii_plan_rev1.md.
%%%%%
%%%%%Maps are drawn in Python (python/ship_hawaii_figures.py) because the
%%%%%MATLAB map functions are set up for the lower-48 Albers projection.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
clc;

%%%%%%%%%%Grid: main Hawaiian Islands and their approaches
p.latlim=[17 24];
p.lonlim=[-162 -153];
p.cells_per_degree=100;   %%%%%0.01 deg, same as the lower 48

%%%%%%%%%%AIS sample (same 104 days as the lower 48)
per=period_rev1();         %%%%%analysis years: 2024-2025 (period_rev1.m)
p.ais_days=per.days;       %%%%%the first 52 Wednesdays of each year
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

%%%%%%%%%%Route rule (the one change from the lower 48)
p.route_rule='ship_days';
p.min_ship_days=6;
p.min_unique_ships=4;     %%%%%not used by the ship_days rule; kept for the record
p.port_relax_km=0;        %%%%%off: ship-days already keeps thin port approaches

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

%%%%%%%%%%Ports (USACE Principal Ports, district reference points)
p.check_ports=table( ...
    ["Honolulu, HI";"Kalaeloa Barbers Point, HI";"Kahului, HI";"Hilo, HI";"Nawiliwili, HI";"Kawaihae, HI"], ...
    [21.31111;21.32307;20.89861;19.73062;21.95248;20.03515], ...
    [-157.8717;-158.11368;-156.4728;-155.05478;-159.35232;-155.82797], ...
    'VariableNames',{'name','lat','lon'});
p.principal_ports=true;
p.principal_ports_gap_km=5;
p.check_vts=table(strings(0,1),zeros(0,1),zeros(0,1),'VariableNames',{'name','lat','lon'});

%%%%%%%%%%Census reference layers
p.census_year=2023;

%%%%%%%%%%Folders and names
p.data_dir=fullfile(pwd,'data');
p.out_dir=fullfile(pwd,'output_hawaii');
p.out_name=['shipping_zone_hawaii_' per.tag];
p.make_figure=false;

%%%%%%%%%%Output size
p.simplify_deg=0.005;
p.clip_water_foreign_side=true; %%%%%drop zone water nearer foreign land than U.S. land (review R2MET-1, option 2); routes stay sources
p.clip_water_cap_km=370.4;     %%%%%200 nautical miles: water farther than this from both U.S. and foreign land is high seas and stays in the zone (review R3COD-1)
p.routes_simplify_deg=0;
p.kmz=true;
p.save_grids=true;        %%%%%small grid; keep it for the Python cross-check
p.png_dpi=200;
p.parallel_flag=0;

%%%%%%%%%%Memory
p.ais_read_rows=1e6;
p.block_rows=200;

result=shipping_zone_rev1(p);
