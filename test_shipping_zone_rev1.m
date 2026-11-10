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
            load(cache_file,'pairs');
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

function [p,R]=synthetic_days(tc,tag)
%%%%%Two synthetic daily CSVs under the shared names, so no download happens.
R=tc.TestData.R;
p.data_dir=fullfile(tc.TestData.folder,tag);
mkdir(p.data_dir);
p.ais_days=[datetime(2024,1,1) datetime(2024,1,2)];
p.zstd_exe='/opt/homebrew/bin/zstd';
p.delete_csv=false;
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
