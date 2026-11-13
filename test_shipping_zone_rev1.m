function tests=test_shipping_zone_rev1
%test_shipping_zone_rev1  Unit tests for the shipping-zone pipeline.
%
%   results=runtests('test_shipping_zone_rev1') runs offline tests on
%   synthetic inputs. The parallel and multi-session tests need a pool
%   (parpool('Processes',2)); without one they are filtered, not passed.
tests=functiontests(localfunctions);
end

function setupOnce(tc)
tc.TestData.folder=tempname;
mkdir(tc.TestData.folder);
tc.TestData.R=georefcells([30 32],[-80 -78],0.02,0.02);
end

function teardownOnce(tc)
if isfolder(tc.TestData.folder)
    rmdir(tc.TestData.folder,'s');
end
end

function test_url_patterns(tc)
[url,name]=ais_day_url_rev1(datetime(2024,1,1));
verifyEqual(tc,name,'ais-2024-01-01.csv.zst');
verifyEqual(tc,url,'https://noaaocm.blob.core.windows.net/ais/csv2/csv2024/ais-2024-01-01.csv.zst');
[url,name]=ais_day_url_rev1(datetime(2023,1,1));
verifyEqual(tc,name,'AIS_2023_01_01.zip');
verifyEqual(tc,url,'https://coast.noaa.gov/htdata/CMSP/AISDataHandler/2023/AIS_2023_01_01.zip');
end

function test_filter_both_column_styles(tc)
%%%%%Row 1 passes; rows 2-5 fail on length, type, IMO, and grid extent.
lat=[31.01; 31.01; 31.01; 31.01; 40.0];
lon=[-79.01; -79.01; -79.01; -79.01; -79.0];
mmsi=[1; 2; 3; 4; 5];
vt=[70; 70; 30; 80; 70];
len=[200; 50; 200; 200; 200];
imo=["IMO1"; "IMO2"; "IMO3"; ""; "IMO5"];
new_style=table(mmsi,lon,lat,zeros(5,1),imo,vt,len,'VariableNames',{'mmsi','longitude','latitude','sog','imo','vessel_type','length'});
old_style=table(mmsi,lat,lon,zeros(5,1),imo,vt,len,'VariableNames',{'MMSI','LAT','LON','SOG','IMO','VesselType','Length'});
filt=struct('vessel_types',[60:69 70:89],'min_length_m',100,'require_imo',true,'min_sog_kn',0);
R=tc.TestData.R;
[r_exp,c_exp]=geographicToDiscrete(R,31.01,-79.01);
for T={new_style,old_style}
    f=fullfile(tc.TestData.folder,'ais_test.csv');
    writetable(T{1},f);
    [pairs,num_row,num_mmsi]=ais_large_ship_cells_rev1(f,R,filt);
    verifyEqual(tc,pairs,[sub2ind(R.RasterSize,r_exp,c_exp) 1]);
    verifyEqual(tc,[num_row num_mmsi],[2 2]);  %%%%%row 5 passes the filter but is off the grid
end
end

function test_chunked_read_matches_single_read(tc)
[p,R]=synthetic_days(tc,'chunk');
[~,name]=ais_day_url_rev1(p.ais_days(1));
f=fullfile(p.data_dir,erase(name,'.zst'));
[pairs_small,rows_small,mmsi_small]=ais_large_ship_cells_rev1(f,R,p.filt,777);
[pairs_one,rows_one,mmsi_one]=ais_large_ship_cells_rev1(f,R,p.filt,1e7);
verifyEqual(tc,pairs_small,pairs_one);
verifyEqual(tc,[rows_small mmsi_small],[rows_one mmsi_one]);
end

function test_distance_block_size_invariant(tc)
R=tc.TestData.R;
src=false(R.RasterSize);
src([10 60],[20 80])=true;
verifyEqual(tc,distance_to_mask_km_rev1(src,R,150,7),distance_to_mask_km_rev1(src,R,150,1000));
end

function test_distance_edge_sources_match_brute_force(tc)
%%%%%A random blob with interior cells: edge-only search must equal a brute-force minimum.
R=georefcells([30 31],[-80 -79],0.02,0.02);
stream=RandStream('mrg32k3a','Seed',7);
src=rand(stream,R.RasterSize)>0.97;
src(20:35,10:30)=true;
dist_km=distance_to_mask_km_rev1(src,R,500);
[lat_grid,lon_grid]=geographicGrid(R);
lat_s=lat_grid(src);
lon_s=lon_grid(src);
ref_km=zeros(R.RasterSize);
for k=1:numel(lat_grid)
    ref_km(k)=min(deg2km(distance(lat_grid(k),lon_grid(k),lat_s,lon_s),6371.0088));
end
verifyEqual(tc,dist_km,ref_km,'AbsTol',1e-6);
end

function test_distance_matches_geodesic(tc)
R=tc.TestData.R;
src=false(R.RasterSize);
src(50,50)=true;
dist_km=distance_to_mask_km_rev1(src,R,300);
[lat_grid,lon_grid]=geographicGrid(R);
ref_km=deg2km(distance(lat_grid(50,50),lon_grid(50,50),lat_grid,lon_grid),6371.0088);
verifyEqual(tc,dist_km,ref_km,'AbsTol',1e-6);  %%%%%same sphere, same great circle
end

function test_contour_area_of_disk(tc)
%%%%%Distance field from one cell; the 50 km contour should enclose about pi*50^2 km^2.
R=georefcells([29 33],[-81 -77],0.01,0.01);
src=false(R.RasterSize);
[r,c]=geographicToDiscrete(R,31,-79);
src(r,c)=true;
dist_km=distance_to_mask_km_rev1(src,R,100);
zone_poly=field_to_zone_polyshape_rev1(dist_km,R,50);
[lon_b,lat_b]=boundary(zone_poly);
area_km2=areaint(lat_b,lon_b,wgs84Ellipsoid('km'));
verifyEqual(tc,area_km2,pi*50^2,'RelTol',0.01);
end

function test_rasterize_crop_square(tc)
R=tc.TestData.R;
lat=[30.5 30.5 31.5 31.5 30.5]';
lon=[-79.5 -78.5 -78.5 -79.5 -79.5]';
[mask_sub,row_range,col_range]=rasterize_polygon_crop_rev1(lat,lon,R);
mask=false(R.RasterSize);
mask(row_range,col_range)=mask_sub;
[lat_grid,lon_grid]=geographicGrid(R);
inside=lat_grid>30.52 & lat_grid<31.48 & lon_grid>-79.48 & lon_grid<-78.52;
outside=lat_grid<30.48 | lat_grid>31.52 | lon_grid<-79.52 | lon_grid>-78.48;
verifyTrue(tc,all(mask(inside)));
verifyFalse(tc,any(mask(outside)));
end

function test_routes_polygons_cover_cells(tc)
%%%%%Rings from routes_polygons_rev1 cover the route cells across tile edges:
%%%%%a block that spans four 1-degree tiles, a block with a hole, and one
%%%%%isolated cell. Cell centers inside the rings must equal the mask.
R=georefcells([30 32],[-80 -78],0.02,0.02);
mask=false(R.RasterSize);
mask(40:60,40:60)=true;            %%%%%spans the tile corner at (31, -79)
mask(10:20,70:90)=true;
mask(14:16,78:82)=false;           %%%%%hole
mask(85,15)=true;                  %%%%%isolated cell
tile_rings=routes_polygons_rev1(mask,R,1,0);
rings=cell2mat(cellfun(@(c) [c; NaN NaN],tile_rings,'UniformOutput',false));
[lat_grid,lon_grid]=geographicGrid(R);
inside=inpolygon(lon_grid,lat_grid,rings(:,2),rings(:,1));
verifyEqual(tc,inside,mask);   %%%%%covers the hole correctly, no seams between tiles

%%%%%The KML holds every ring: kmlwrite once dropped multi-part features
out_dir=tempname;
cleanup_dir=onCleanup(@() rmdir(out_dir,'s'));
files=write_zone_outputs_rev1(tile_rings,out_dir,'routes_test','routes test',false);
kml_text=fileread(files(endsWith(files,'.kml')));
S=shaperead(char(files(endsWith(files,'.shp'))),'UseGeoCoords',true);
num_ring=sum(arrayfun(@(s) sum(isnan(s.Lat))+~isnan(s.Lat(end)),S));
verifyGreaterThanOrEqual(tc,count(kml_text,'<coordinates'),num_ring);   %%%%%one coordinates element per ring
end

function test_parallel_equals_serial(tc)
pool=gcp('nocreate');
assumeNotEmpty(tc,pool,'No parallel pool; start parpool(''Processes'',2) to run this test.');
[p,R]=synthetic_days(tc,'par');
serial_out=cell(numel(p.ais_days),1);
for k=1:numel(p.ais_days)
    S=ais_cache_day_rev1(p.ais_days(k),R,p);
    serial_out{k}=S.pairs;
end
delete(fullfile(p.data_dir,'ais_cells_*.mat'));
par_out=cell(numel(p.ais_days),1);
days=p.ais_days;
parfor k=1:numel(days)
    S=ais_cache_day_rev1(days(k),R,p);
    par_out{k}=S.pairs;
end
verifyEqual(tc,par_out,serial_out);
end

function test_two_sessions_same_cache(tc)
pool=gcp('nocreate');
assumeNotEmpty(tc,pool,'No parallel pool; start parpool(''Processes'',2) to run this test.');
[p,R]=synthetic_days(tc,'multi');
day=p.ais_days(1);
cache_file=ais_cache_name_rev1(day,R,p);
f1=parfeval(pool,@ais_cache_day_rev1,1,day,R,p);
f2=parfeval(pool,@ais_cache_day_rev1,1,day,R,p);
num_bad=0;
while ~(strcmp(f1.State,'finished') && strcmp(f2.State,'finished'))
    if isfile(cache_file)
        try
            S_read=load(cache_file,'pairs'); %#ok<NASGU> the read itself is the test
        catch
            num_bad=num_bad+1;
        end
    end
    pause(0.05);
end
S1=fetchOutputs(f1);
S2=fetchOutputs(f2);
verifyEqual(tc,S1,S2);
verifyEqual(tc,num_bad,0);
verifyTrue(tc,isfile(cache_file));
verifyEmpty(tc,dir(fullfile(p.data_dir,'*.part.*')));
end

function test_route_rule_unique_ships_default(tc)
%%%%%No p.route_rule: the busiest single year must reach p.min_unique_ships.
[ship_days,max_year_ships]=rule_counts();
p=struct('min_unique_ships',4,'min_ship_days',6);
verifyEqual(tc,route_source_mask_rev1(ship_days,max_year_ships,p),max_year_ships>=4);
p.route_rule='unique_ships';
verifyEqual(tc,route_source_mask_rev1(ship_days,max_year_ships,p),max_year_ships>=4);
end

function test_route_rule_ship_days(tc)
%%%%%Two ships crossing the same cell every week make a route under ship_days
%%%%%but not under unique_ships (the Hawaii neighbor-island case).
[ship_days,max_year_ships]=rule_counts();
p=struct('route_rule','ship_days','min_unique_ships',4,'min_ship_days',6);
mask=route_source_mask_rev1(ship_days,max_year_ships,p);
verifyEqual(tc,mask,ship_days>=6);
verifyTrue(tc,mask(2,1));         %%%%%2 ships, 104 ship-days
verifyFalse(tc,mask(3,1));        %%%%%5 ships, 5 ship-days
verifyFalse(tc,mask(1,2));        %%%%%5 ship-days, one below the cutoff
verifyTrue(tc,mask(2,2));         %%%%%exactly 6 ship-days
end

function test_route_rule_rejects_unknown(tc)
[ship_days,max_year_ships]=rule_counts();
p=struct('route_rule','ship_day','min_unique_ships',4,'min_ship_days',6);
verifyError(tc,@() route_source_mask_rev1(ship_days,max_year_ships,p),'shipgis:rule');
verifyError(tc,@() route_source_mask_rev1(ship_days,max_year_ships(1,:),p),'shipgis:size');
end

function test_extra_source_cells(tc)
R=tc.TestData.R;
csv_path=fullfile(tc.TestData.folder,'extra_ok.csv');
idx=[1; 57; prod(R.RasterSize); 57];   %%%%%first, last, and a repeat
writematrix(idx,csv_path);
mask=read_extra_cells_rev1(csv_path,R);
verifyEqual(tc,size(mask),R.RasterSize);
verifyEqual(tc,nnz(mask),3);
verifyEqual(tc,find(mask),unique(idx));
end

function test_extra_source_rejects_other_grid(tc)
R=tc.TestData.R;
bad={prod(R.RasterSize)+1, 0, 12.5};   %%%%%past the last cell, zero, not whole
for k=1:numel(bad)
    csv_path=fullfile(tc.TestData.folder,sprintf('extra_bad_%d.csv',k));
    writematrix([1; bad{k}],csv_path);
    verifyError(tc,@() read_extra_cells_rev1(csv_path,R),'shipgis:extra');
end
end

function test_fairways_empty_download(tc)
%%%%%NOAA returns no features for the Hawaii and Puerto Rico grids; a cached
%%%%%empty download must give an empty mask (and no new download).
R=tc.TestData.R;
data_dir=fullfile(tc.TestData.folder,'fairways_empty');
mkdir(data_dir);
GT=table.empty; num_expected=0;
save(fullfile(data_dir,sprintf('fairways_rev2_%g_%g_%g_%g.mat',R.LatitudeLimits,R.LongitudeLimits)),'GT','num_expected');
[mask,GT_out]=load_shipping_fairways_rev1(R,data_dir);
verifyEqual(tc,size(mask),R.RasterSize);
verifyFalse(tc,any(mask,'all'));
verifyEqual(tc,height(GT_out),0);
end

function test_fairways_cache_is_per_grid(tc)
%%%%%The cache for this grid is read, not another grid's, and a kept theme is
%%%%%rasterized: the mask covers the square plus at most one ring of edge cells.
R=tc.TestData.R;
data_dir=fullfile(tc.TestData.folder,'fairways_grid');
mkdir(data_dir);
square=['{"type":"FeatureCollection","features":[{"type":"Feature","properties":' ...
    '{"THEMELAYER":"Traffic Separation Schemes","OBJNAM":"test"},"geometry":' ...
    '{"type":"Polygon","coordinates":[[[-79.5,30.5],[-78.5,30.5],[-78.5,31.5],[-79.5,31.5],[-79.5,30.5]]]}}]}'];
gj=fullfile(data_dir,'square.geojson');
writelines(square,gj);
GT=readgeotable(gj); num_expected=1;
save(fullfile(data_dir,sprintf('fairways_rev2_%g_%g_%g_%g.mat',R.LatitudeLimits,R.LongitudeLimits)),'GT','num_expected');
GT=table.empty; num_expected=0;   %%%%%another grid's cache, empty
save(fullfile(data_dir,'fairways_rev2_22_50_-130_-66.mat'),'GT','num_expected');
mask=load_shipping_fairways_rev1(R,data_dir);
cell_area=areamat(mask,R,wgs84Ellipsoid('km'));
square_area=areaquad(30.5,-79.5,31.5,-78.5,wgs84Ellipsoid('km'));
ring_area=areaquad(30.5-R.CellExtentInLatitude,-79.5-R.CellExtentInLongitude, ...
    31.5+R.CellExtentInLatitude,-78.5+R.CellExtentInLongitude,wgs84Ellipsoid('km'));
verifyGreaterThanOrEqual(tc,cell_area,square_area);   %%%%%"Traffic Separation Schemes" is kept (review CA-2)
verifyLessThanOrEqual(tc,cell_area,ring_area*(1+1e-9));
end

function test_polygon_area_matches_quadrangle(tc)
%%%%%The land areas come from polygons in an equal-area projection; a 1 by 1
%%%%%degree quadrangle with a 0.5 by 0.5 degree hole must match areaquad.
outer=polyshape([-80 -79 -79 -80],[30 30 31 31]);
hole=polyshape([-79.75 -79.25 -79.25 -79.75],[30.25 30.25 30.75 30.75]);
donut=subtract(outer,hole);
want=areaquad(30,-80,31,-79,wgs84Ellipsoid('km'))-areaquad(30.25,-79.75,30.75,-79.25,wgs84Ellipsoid('km'));
%%%%%Straight edges in the projection differ slightly from parallels; 0.1% is enough here.
verifyEqual(tc,polyshape_area_km2_rev1(donut),want,'RelTol',1e-3);
verifyEqual(tc,polyshape_area_km2_rev1(polyshape()),0);
end

function [ship_days,max_year_ships]=rule_counts()
%%%%%Rows: cells; values chosen to sit on both sides of each cutoff.
ship_days     =[0 5 ; 104 6 ; 5 40];
max_year_ships=[0 3 ; 2   4 ; 5  1];
end

function [p,R]=synthetic_days(tc,tag)
%%%%%Two synthetic daily CSVs under the shared names, so no download happens.
R=tc.TestData.R;
p.data_dir=fullfile(tc.TestData.folder,tag);
mkdir(p.data_dir);
p.ais_days=[datetime(2024,1,1) datetime(2024,1,2)];
p.zstd_exe='/opt/homebrew/bin/zstd';
p.delete_csv=false;
p.ais_read_rows=1000;   %%%%%small chunks so every day is read in several pieces
p.filt=struct('vessel_types',[60:69 70:89],'min_length_m',100,'require_imo',true,'min_sog_kn',0);
stream=RandStream('mrg32k3a','Seed',1);
for k=1:numel(p.ais_days)
    n=5000;
    T=table(randi(stream,50,n,1),-80+2*rand(stream,n,1),30+2*rand(stream,n,1),zeros(n,1), ...
        repmat("IMO1",n,1),70*ones(n,1),150*ones(n,1), ...
        'VariableNames',{'mmsi','longitude','latitude','sog','imo','vessel_type','length'});
    [~,name]=ais_day_url_rev1(p.ais_days(k));
    writetable(T,fullfile(p.data_dir,erase(name,'.zst')));
end
end
