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
p.latlim=[24 50];
p.lonlim=[-125.5 -66];
p.cells_per_degree=100;   %%%%%0.01 deg, about 1.1 km by 0.8-1.0 km

%%%%%%%%%%AIS sample: one day a week for a full year covers seasonal
%%%%%%%%%%traffic (Great Lakes close Jan-Mar) at 1/7 of the download.
%%%%%%%%%%Each 2024 day is about 200 MB compressed, 750 MB as CSV.
p.ais_days=datetime(2024,1,3):caldays(7):datetime(2024,12,31);
p.delete_csv=true;        %%%%%keep only the per-day cell cache
p.zstd_exe='/opt/homebrew/bin/zstd';

%%%%%%%%%%Large-ship filter (proxy for SOLAS V/19: >= 3000 GT carries a
%%%%%%%%%%3 GHz radar or a second 9 GHz radar)
p.filt.vessel_types=[60:69 70:89];  %%%%%AIS ship type: passenger, cargo, tanker
p.filt.min_length_m=100;            %%%%%GT proxy; init_check_gt_proxy_rev1: 99.6% precision, 98.1% recall
p.filt.require_imo=true;
p.filt.min_sog_kn=0;
p.min_unique_ships=4;               %%%%%distinct ships per cell over the sampled days; 4 removes
                                    %%%%%tug/barge noise on the upper Mississippi (2024 test: 2 kept 903 such cells, 4 kept 0)

%%%%%%%%%%Fairways and Traffic Separation Schemes (NOAA ENC Direct)
p.include_fairways=true;

%%%%%%%%%%Zone definition
p.distances_km=[25 50 100];
p.zone_mode='shore';      %%%%%'shore': ship water + X km inland from the facing shoreline (default)
                          %%%%%'ships': X km from the ships themselves
p.shore_link_km=25;       %%%%%'shore' mode: water within this distance of ships counts as ship water

%%%%%%%%%%Ports the large-ship routes must reach (river and lake ports included)
p.check_ports=table( ...
    ["Baton Rouge, LA";"New Orleans, LA";"Houston, TX";"Portland, OR";"Sacramento, CA"; ...
     "Stockton, CA";"Albany, NY";"Philadelphia, PA";"Duluth, MN";"Chicago, IL"], ...
    [30.44;29.95;29.73;45.60;38.57;37.95;42.63;39.90;46.77;41.73], ...
    [-91.20;-90.06;-95.27;-122.75;-121.55;-121.33;-73.76;-75.14;-92.10;-87.53], ...
    'VariableNames',{'name','lat','lon'});

%%%%%%%%%%Zoomed maps: the lower Mississippi, Gulf to Baton Rouge
p.region_maps=struct('name','lower_mississippi','d_km',50,'latlim',[28.8 31.0],'lonlim',[-91.7 -88.8], ...
    'ports',p.check_ports(ismember(p.check_ports.name,["Baton Rouge, LA";"New Orleans, LA"]),:), ...
    'title','Large ships travel the Mississippi up to Baton Rouge (2024)');

%%%%%%%%%%Census reference layers (land mask and coastline)
p.census_year=2023;

%%%%%%%%%%Folders and names
p.data_dir=fullfile(pwd,'data');
p.out_dir=fullfile(pwd,'output');
p.out_name='shipping_zone_2024';
p.make_figure=true;

%%%%%%%%%%Output size
p.simplify_deg=0.005;     %%%%%drop polygon vertices within 0.005 deg (about 0.5 km); 0 keeps all
p.kmz=true;               %%%%%zip KML into KMZ (about 5x smaller)
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
