%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%init_shipping_zone_rev1
%%%%%
%%%%%Zones within X km of where large ships (likely 2.9-3.1 GHz S-band
%%%%%radar carriers) operate in the lower 48, for the 2.7 GHz study.
%%%%%Output: polygons (polyshape, [lat lon] arrays, shapefile, KML) that
%%%%%cover the ship water and the land out to each distance.
%%%%%
%%%%%Requires: Mapping Toolbox, Statistics and Machine Learning Toolbox,
%%%%%and the zstd command-line tool for 2024+ AIS files.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
clc;

%%%%%%%%%%Grid (lower 48 plus the Great Lakes and coastal waters)
p.latlim=[22 50];        %%%%%22 N: Florida Straits and the approaches south of the Keys
p.lonlim=[-130 -66];     %%%%%130 W: room for traffic farther off Oregon and Washington
p.cells_per_degree=100;   %%%%%0.01 deg, about 1.1 km by 0.8-1.0 km

%%%%%%%%%%AIS sample: one day a week for a full year covers seasonal
%%%%%%%%%%traffic (Great Lakes close Jan-Mar) at 1/7 of the download.
%%%%%%%%%%Each 2024 day is about 200 MB compressed, 750 MB as CSV.
%%%%%%%%%%Two years (2023 and 2024) so one unusual year doesn't set the
%%%%%%%%%%routes: the Key Bridge collapse closed Baltimore's main channel
%%%%%%%%%%from March 26 to June 10, 2024. A cell counts when either year
%%%%%%%%%%meets the ship threshold. ais_cells_py_rev1.py builds the same
%%%%%%%%%%per-day caches in Python (streams each day, no CSV on disk).
p.ais_days=[datetime(2023,1,4):caldays(7):datetime(2023,12,31), ...
    datetime(2024,1,3):caldays(7):datetime(2024,12,31)];
p.delete_csv=true;        %%%%%keep only the per-day cell cache
p.prefilter_min_length=100; %%%%%stream-filter each day by length (needs /usr/bin/python3); 0 writes the full CSV
p.zstd_exe='/opt/homebrew/bin/zstd';

%%%%%%%%%%Large-ship filter (proxy for SOLAS V/19: >= 3000 GT carries a
%%%%%%%%%%3 GHz radar or a second 9 GHz radar)
p.filt.vessel_types=[0 33 35 55 60:89 90:99]; %%%%%AIS ship types: passenger, cargo, tanker, military (35),
                                    %%%%%law enforcement (55), dredging (33), other and unknown (0, 90-99).
                                    %%%%%Towing is handled by p.filt_towing below. Left out: special craft and
                                    %%%%%fishing (30, 34, 36, 37, 50-54, 56-59), which on a 2024 test day
                                    %%%%%reported mostly from inland rivers at 100 m and up.
p.filt.min_length_m=100;            %%%%%GT proxy; init_check_gt_proxy_rev1: 99.6% precision, 98.1% recall
p.filt.require_imo=true;            %%%%%IMO number required (seagoing ships), except for:
p.filt.no_imo_types=[35 55];        %%%%%military and law enforcement (Navy and Coast Guard ships have none).
                                    %%%%%Without the IMO rule, other/unknown and dredge entries added
                                    %%%%%inland river towboats above Baton Rouge (2024 test).
p.filt.min_sog_kn=0;
%%%%%Tug-barges: towing ships (31, 32, 52) 100 m or longer with an IMO number,
%%%%%counted only within p.towing_coast_km of the Census coastline (ocean,
%%%%%bays, Great Lakes). Some river towboats also carry IMO numbers and report
%%%%%the whole tow as their length (on 2024-07-10, COOPERATIVE SPIRIT and AEP
%%%%%MARINER on the Mississippi). 2023 AIS reports the tug's own length, so few
%%%%%towing ships pass the 100 m test in 2023 (15 on 2023-07-12, 761 on 2024-07-10).
%%%%%Set p.filt_towing=[] to leave tug-barges out.
p.filt_towing=struct('vessel_types',[31 32 52],'min_length_m',100,'require_imo',true, ...
    'no_imo_types',[],'min_sog_kn',0);
p.towing_coast_km=25;
p.min_unique_ships=4;               %%%%%distinct ships per cell in one year (a cell counts if either year
                                    %%%%%reaches it); 4 removes tug/barge noise on the upper Mississippi
                                    %%%%%(2024 test: 2 kept 903 such cells, 4 kept 0)
p.port_relax_km=50;                 %%%%%within this distance of a deep-draft USACE Principal Port ...
p.port_min_unique_ships=2;          %%%%%... 2 ships in one year are enough (thin approaches: Searsport, Coos Bay)

%%%%%%%%%%Fairways and Traffic Separation Schemes (NOAA ENC Direct)
p.include_fairways=true;

%%%%%%%%%%Racons (radar beacons) from NOAA charts as fixed S-band sites
p.include_racons=true;
p.racon_bands="S";        %%%%%"S": racons charted with the 0.10 m (S-band) wavelength; "all": every racon

%%%%%%%%%%Zone definition
p.distances_km=[25 50 100];
p.zone_mode='shore';      %%%%%'shore': ship water + X km inland from the facing shoreline (default)
                          %%%%%'ships': X km from the ships themselves
p.shore_link_km=25;       %%%%%'shore' mode: water within this distance of ships counts as ship water

%%%%%%%%%%Frequency-dependent zones (example distances, pending the EMC
%%%%%%%%%%analysis): each 2900-3100 MHz sub-band gets the zone for its
%%%%%%%%%%distance. Every distance here must be in p.distances_km.
p.band_zones=table([2900;3000;3030;3070],[3000;3030;3070;3100],[25;50;100;50], ...
    'VariableNames',{'f_low_mhz','f_high_mhz','distance_km'});

%%%%%%%%%%Ports the large-ship routes must reach (river and lake ports included)
p.check_ports=table( ...
    ["Baton Rouge, LA";"New Orleans, LA";"Houston, TX";"Corpus Christi, TX";"Mobile, AL"; ...
     "Tampa, FL";"Miami, FL";"Savannah, GA";"Charleston, SC";"Norfolk, VA";"Baltimore, MD"; ...
     "Philadelphia, PA";"Newark, NJ (New York/New Jersey)";"Albany, NY";"Boston, MA"; ...
     "Los Angeles/Long Beach, CA";"Oakland, CA";"Sacramento, CA";"Stockton, CA";"Portland, OR"; ...
     "Seattle, WA";"Tacoma, WA";"Duluth, MN";"Chicago, IL"], ...
    [30.44;29.95;29.73;27.81;30.70;27.92;25.77;32.12;32.84;36.92;39.25;39.90;40.68;42.63;42.35; ...
     33.75;37.80;38.57;37.95;45.60;47.58;47.27;46.77;41.73], ...
    [-91.20;-90.06;-95.27;-97.40;-88.04;-82.43;-80.17;-81.14;-79.90;-76.33;-76.55;-75.14;-74.15;-73.76;-71.04; ...
     -118.22;-122.32;-121.55;-121.33;-122.75;-122.35;-122.41;-92.10;-87.53], ...
    'VariableNames',{'name','lat','lon'});
p.principal_ports=true;       %%%%%also check every USACE Principal Port in the grid
p.principal_ports_gap_km=5;   %%%%%port points are district reference points, not berths

%%%%%%%%%%Zoomed maps. d_km=[] draws the routes alone (no zone). count_port
%%%%%%%%%%names a port in ports; the map notes how many distinct large ships
%%%%%%%%%%reported within count_radius_km of it each year, and the counts go
%%%%%%%%%%to <out_name>_<name>_ship_counts.csv.
river_ports=p.check_ports(ismember(p.check_ports.name,["Baton Rouge, LA";"New Orleans, LA"]),:);
p.region_maps=struct( ...
    'name',{'lower_mississippi','new_orleans_baton_rouge'}, ...
    'd_km',{50,[]}, ...
    'latlim',{[28.8 31.0],[29.80 30.62]}, ...
    'lonlim',{[-91.7 -88.8],[-91.40 -89.85]}, ...
    'ports',{river_ports,river_ports}, ...
    'title',{'Large ships travel the Mississippi up to Baton Rouge (2023-2024)', ...
             'Large ships use the Mississippi from New Orleans to Baton Rouge (2023-2024)'}, ...
    'count_port',{"Baton Rouge, LA","Baton Rouge, LA"}, ...
    'count_radius_km',{3,3});

%%%%%%%%%%Coast Guard Vessel Traffic Service areas (report only)
p.check_vts=table( ...
    ["VTS New York";"VTS Houston-Galveston";"VTS Port Arthur";"VTS Berwick Bay"; ...
     "VTS Lower Mississippi River";"VTS Louisville";"VTS St. Marys River";"VTS Puget Sound"; ...
     "VTS San Francisco";"VTS Los Angeles-Long Beach"], ...
    [40.62;29.35;29.87;29.69;29.95;38.26;46.50;47.60;37.81;33.72], ...
    [-74.06;-94.73;-93.93;-91.21;-90.06;-85.77;-84.35;-122.34;-122.36;-118.27], ...
    'VariableNames',{'name','lat','lon'});

%%%%%%%%%%Census reference layers (land mask and coastline)
p.census_year=2023;

%%%%%%%%%%Folders and names
p.data_dir=fullfile(pwd,'data');
p.out_dir=fullfile(pwd,'output');
p.out_name='shipping_zone_2023_2024';
p.make_figure=true;

%%%%%%%%%%Output size
p.simplify_deg=0.005;     %%%%%drop polygon vertices within 0.005 deg (about 0.5 km); 0 keeps all
p.routes_simplify_deg=0; %%%%%routes file: 0 keeps exact cell edges (single cells survive)
p.kmz=true;               %%%%%also write a KMZ next to each KML (about 5x smaller)
p.save_grids=false;       %%%%%true also saves the full-size grids in the .mat (tens of MB)
p.png_dpi=200;            %%%%%U.S. map resolution
p.parallel_flag=0;        %%%%%1: process AIS days on a parallel pool (parpool first)

%%%%%%%%%%Memory: work in pieces
p.ais_read_rows=1e6;      %%%%%AIS rows per read chunk (about 150 MB each)
p.block_rows=200;         %%%%%grid rows per distance-query block

result=shipping_zone_rev1(p);

%%%%%%%%%%Example: tract centroids inside the 50 km land zone, using
%%%%%%%%%%find_points_inside_contour_two_step_rev2 from Basic_Functions:
%%%%%%%%%%  zone_latlon=result.zone([result.zone.distance_km]==50).latlon_land;
%%%%%%%%%%  inside_idx=find_points_inside_contour_two_step_rev2([],zone_latlon,tract_latlon);
