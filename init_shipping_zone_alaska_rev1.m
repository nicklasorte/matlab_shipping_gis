%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%init_shipping_zone_alaska_rev1
%%%%%
%%%%%Zones within X km of where large ships operate around Alaska, east of
%%%%%180 degrees, for the 2.7 GHz study. Same ship filter, zone method, and
%%%%%band distances as the lower 48, with two differences:
%%%%%
%%%%%  1. Years: 2018 and 2019. MarineCadastre filtered Alaska out of its
%%%%%     2021 and later files; 2018-2020 still hold it with IMO numbers and
%%%%%     standard ship types. 2020 is left out (pandemic schedules).
%%%%%  2. Route rule: ship-days (the Hawaii rule), because Alaska traffic is
%%%%%     sparse (median 54 large ships a day against about 1,800 in the
%%%%%     lower 48). The cutoff of 6 is the lower-48 calibration.
%%%%%
%%%%%The grid stops at 180 degrees so polygons and KML don't split at the
%%%%%date line (the western Aleutians are out of scope). The day caches come
%%%%%from python/alaska_grid_to_180.py.
%%%%%
%%%%%Coverage: the Coast Guard receivers are on shore, so busy lanes far
%%%%%offshore are missing (python/check_alaska_kapsar.py). The satellite-based
%%%%%North Pacific and Arctic dataset (Kapsar and others, 2022) fills them
%%%%%(p.extra_source_csv below).
%%%%%
%%%%%Maps are drawn in Python (python/ship_alaska_figures.py).
%%%%%
%%%%%Sensitivity to the satellite cutoff: set lane_suffix before running,
%%%%%for example  matlab -batch "lane_suffix='_x0.5'; init_shipping_zone_alaska_rev1"
%%%%%reads satellite_lane_cells_x0.5.csv (half the cutoff) and adds the
%%%%%suffix to the output names.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars -except lane_suffix
clc;
if ~exist('lane_suffix','var')
    lane_suffix='';
end

%%%%%%%%%%Grid: Alaska east of 180 degrees
p.latlim=[51 72];
p.lonlim=[-180 -129];
p.cells_per_degree=100;

%%%%%%%%%%AIS sample: the first 52 Wednesdays of 2018 and of 2019
p.ais_days=[datetime(2018,1,3)+caldays(7*(0:51)), datetime(2019,1,2)+caldays(7*(0:51))];
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

%%%%%%%%%%Route rule (as for Hawaii)
p.route_rule='ship_days';
p.min_ship_days=6;
p.min_unique_ships=4;     %%%%%not used by the ship_days rule
p.port_relax_km=0;

%%%%%%%%%%Satellite-AIS lanes beyond shore-receiver range (Kapsar and others,
%%%%%%%%%%2022), added as ship water: hexagons whose cargo plus tanker operating
%%%%%%%%%%days reach the cutoff that best matches the shore-receiver routes near
%%%%%%%%%%shore (python/alaska_satellite_lanes.py). '' leaves them out.
p.extra_source_csv=fullfile(pwd,'outputs','2018_2019','alaska',['satellite_lane_cells' lane_suffix '.csv']);

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
    ["Valdez, AK";"Port of Alaska (Anchorage), AK";"Nikiski, AK";"Unalaska (Dutch Harbor), AK";"Kivalina, AK"], ...
    [61.12473;61.23778;60.74793;53.89419;67.72677], ...
    [-146.3464;-149.895;-151.3144;-166.54992;-164.52689], ...
    'VariableNames',{'name','lat','lon'});
p.principal_ports=true;
p.principal_ports_gap_km=5;
p.check_vts=table(strings(0,1),zeros(0,1),zeros(0,1),'VariableNames',{'name','lat','lon'});

%%%%%%%%%%Census reference layers
p.census_year=2023;

%%%%%%%%%%Folders and names
p.data_dir=fullfile(pwd,'data');
p.out_dir=fullfile(pwd,'output_alaska');
p.out_name=['shipping_zone_alaska_2018_2019' lane_suffix];
p.make_figure=false;

%%%%%%%%%%Output size
p.simplify_deg=0.005;
p.routes_simplify_deg=0;
p.kmz=true;
p.save_grids=true;
p.png_dpi=200;
p.parallel_flag=0;

%%%%%%%%%%Memory
p.ais_read_rows=1e6;
p.block_rows=200;

result=shipping_zone_rev1(p);
