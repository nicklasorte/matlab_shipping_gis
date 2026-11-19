%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%init_shipping_zone_guam_rev1
%%%%%
%%%%%Zones within X km of where large ships operate around Guam and the
%%%%%Northern Mariana Islands (one region, decision D13, November 19, 2026),
%%%%%for the 2.7 GHz study (docs/plans/guam_plan_rev1.md). Same AIS sample, ship filter, zone method, and band
%%%%%distances as init_shipping_zone_rev1 (lower 48), with one change: the
%%%%%route rule counts ship-days instead of distinct ships per year.
%%%%%
%%%%%The route rule starts from the Hawaii choice (ship-days, at least 6);
%%%%%step G3 of the plan compares it with the lower-48 rule and NOAA transit
%%%%%counts before the paper uses it. Hawaii's reasoning:
%%%%%a few dedicated ships serve the neighbor islands. Under the
%%%%%lower-48 rule (4 distinct ships in one year) the inter-island lanes
%%%%%break and only three ports connect (route_rules.json). Ship-days (distinct ships
%%%%%per sampled day, summed over the 104 days, at least 6) connects
%%%%%Kahului and Nawiliwili too. The value 6 best reproduces the lower-48
%%%%%network (Jaccard 0.80 for 2024-2025); see python/ship_route_rules.py and
%%%%%docs/plans/alaska_hawaii_plan_rev1.md.
%%%%%
%%%%%Maps are drawn in Python (to be written, plan step G6) because the
%%%%%MATLAB map functions are set up for the lower-48 Albers projection.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
clc;

%%%%%%%%%%Grid: Guam and the Northern Mariana Islands (13.2 to 20.6 N, 144.6 to 146.1 E,
%%%%%%%%%%Census 2023) with about 1 degree of approaches. East longitudes are positive.
p.latlim=[12 21.5];
p.lonlim=[143.5 147];
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
%%%%%%%%%%Ports. Saipan: Natural Earth ports (1:10m). Apra Harbor, Tinian, and Rota:
%%%%%%%%%%TODO confirm against the NGA World Port Index (step G2) before the paper uses
%%%%%%%%%%the port check; these are harbor positions read from charts.
p.check_ports=table( ...
    ["Apra Harbor (Port of Guam), GU";"Saipan, MP";"Tinian, MP";"Rota, MP"], ...
    [13.4437;15.2258;14.9580;14.1400], ...
    [144.6667;145.7349;145.6200;145.1380], ...
    'VariableNames',{'name','lat','lon'});
p.principal_ports=false;  %%%%%the USACE Principal Ports file in data/ has no Guam or CNMI port
p.principal_ports_gap_km=5;
p.check_vts=table(strings(0,1),zeros(0,1),zeros(0,1),'VariableNames',{'name','lat','lon'});

%%%%%%%%%%Census reference layers
p.census_year=2023;

%%%%%%%%%%Folders and names
p.data_dir=fullfile(pwd,'data');
p.out_dir=fullfile(pwd,'output_guam');
p.out_name=['shipping_zone_guam_' per.tag];
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
