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
p.filt.min_length_m=100;            %%%%%TODO: GT proxy; validate against a registry
p.filt.require_imo=true;
p.filt.min_sog_kn=0;
p.min_unique_ships=2;               %%%%%drops single-ship GPS glitches over land

%%%%%%%%%%Fairways and Traffic Separation Schemes (NOAA ENC Direct)
p.include_fairways=true;

%%%%%%%%%%Zone definition
p.distances_km=[25 50 100];
p.zone_mode='ships';      %%%%%'ships': X km from the ships themselves
                          %%%%%'shore': ship water + X km inland from the facing shoreline
p.shore_link_km=25;       %%%%%'shore' mode: water within this distance of ships counts as ship water

%%%%%%%%%%Folders and names
p.data_dir=fullfile(pwd,'data');
p.out_dir=fullfile(pwd,'output');
p.out_name='shipping_zone_2024';
p.make_figure=true;

result=shipping_zone_rev1(p);

%%%%%%%%%%Example: tract centroids inside the 50 km land zone, using
%%%%%%%%%%find_points_inside_contour_two_step_rev2 from Basic_Functions:
%%%%%%%%%%  zone_latlon=result.zone([result.zone.distance_km]==50).latlon_land;
%%%%%%%%%%  inside_idx=find_points_inside_contour_two_step_rev2([],zone_latlon,tract_latlon);
