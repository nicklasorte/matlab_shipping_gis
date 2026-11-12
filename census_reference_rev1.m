function [land_mask,land_poly,coast_mask,coast_gt]=census_reference_rev1(R,data_dir,census_year)
%census_reference_rev1  Census land and coastline references on raster R.
%
%   [land_mask,land_poly,coast_mask,coast_gt]=census_reference_rev1(R,data_dir,census_year)
%   downloads (once, into DATA_DIR) and rasterizes two Census Bureau files:
%
%     Land:      cartographic boundary states, 1:500,000
%                https://www2.census.gov/geo/tiger/GENZ<yyyy>/shp/cb_<yyyy>_us_state_500k.zip
%                Clipped to the shoreline, so the ocean, bays, and the
%                Great Lakes are not land.
%     Coastline: TIGER/Line national coastline (MTFCC L4150)
%                https://www2.census.gov/geo/tiger/TIGER<yyyy>/COASTLINE/tl_<yyyy>_us_coastline.zip
%
%   OUTPUTS
%     land_mask   logical, U.S. land cells in the grid
%     land_poly   planar polyshape of U.S. land in the grid (x = lon, y = lat)
%     coast_mask  logical, cells the coastline passes through
%     coast_gt    geotable of the coastline lines inside R

arguments
    R (1,1) map.rasterref.GeographicCellsReference
    data_dir (1,:) char
    census_year (1,1) double = 2023
end

if ~isfolder(data_dir)
    mkdir(data_dir);
end

state_shp=fetch_census_zip(data_dir,sprintf('cb_%d_us_state_500k',census_year), ...
    sprintf('https://www2.census.gov/geo/tiger/GENZ%d/shp/cb_%d_us_state_500k.zip',census_year,census_year));
coast_shp=fetch_census_zip(data_dir,sprintf('tl_%d_us_coastline',census_year), ...
    sprintf('https://www2.census.gov/geo/tiger/TIGER%d/COASTLINE/tl_%d_us_coastline.zip',census_year,census_year));

%%%%%%%%%%Land: the states and territories whose outline touches the grid
%%%%%(lower 48 plus DC on the lower-48 grid; Hawaii on the Hawaii grid)
S=readgeotable(state_shp);
T=geotable2table(S,["Lat","Lon"]);
lat_lo=cellfun(@min,T.Lat); lat_hi=cellfun(@max,T.Lat);
lon_lo=cellfun(@min,T.Lon); lon_hi=cellfun(@max,T.Lon);
in_grid=lat_hi>=R.LatitudeLimits(1) & lat_lo<=R.LatitudeLimits(2) & ...
    lon_hi>=R.LongitudeLimits(1) & lon_lo<=R.LongitudeLimits(2);
T=T(in_grid,:);

warn_state=warning('off','MATLAB:polyshape:repairedBySimplify');
cleanup_warn=onCleanup(@() warning(warn_state));
land_mask=false(R.RasterSize);
state_polys=repmat(polyshape(),height(T),1);
for k=1:height(T)
    lat=T.Lat{k}(:);
    lon=T.Lon{k}(:);
    [Z_sub,row_range,col_range]=rasterize_polygon_crop_rev1(lat,lon,R);
    if ~isempty(Z_sub)
        land_mask(row_range,col_range)=land_mask(row_range,col_range) | Z_sub;
    end
    state_polys(k)=polyshape(lon,lat);
end
land_poly=union(state_polys);

%%%%%%%%%%Coastline: keep lines that touch the grid, then mark the cells they cross.
coast_gt=readgeotable(coast_shp);
[lat_lim,lon_lim]=bounds_of_lines(coast_gt);
in_box=lat_lim(:,2)>=R.LatitudeLimits(1) & lat_lim(:,1)<=R.LatitudeLimits(2) & ...
    lon_lim(:,2)>=R.LongitudeLimits(1) & lon_lim(:,1)<=R.LongitudeLimits(2);
coast_gt=coast_gt(in_box,:);
Tc=geotable2table(coast_gt,["Lat","Lon"]);
coast_lat=cellfun(@(v) [v(:);NaN],Tc.Lat,'UniformOutput',false);
coast_lon=cellfun(@(v) [v(:);NaN],Tc.Lon,'UniformOutput',false);
%%%%%vec2mtx without 'filled' returns 1 on cells the lines cross, 0 elsewhere.
Zc=vec2mtx(vertcat(coast_lat{:}),vertcat(coast_lon{:}),zeros(R.RasterSize),R);
coast_mask=Zc>0;
end

function shp_path=fetch_census_zip(data_dir,stem,url)
%%%%%Download and unzip a Census shapefile once; return the .shp path.
shp_path=fullfile(data_dir,stem,[stem '.shp']);
if isfile(shp_path)
    return
end
zip_path=fullfile(data_dir,[stem '.zip']);
num_try=3;
for try_idx=1:num_try
    try
        websave(zip_path,url,weboptions('Timeout',600));
        break
    catch err
        if try_idx==num_try
            error('shipgis:census','Census download failed: %s (%s)',url,err.message);
        end
    end
end
unzip(zip_path,fullfile(data_dir,stem));
delete(zip_path);
if ~isfile(shp_path)
    error('shipgis:census','%s not found after unzipping %s',shp_path,url);
end
end

function [lat_lim,lon_lim]=bounds_of_lines(GT)
%%%%%Per-feature lat/lon bounds of a line geotable.
T=geotable2table(GT,["Lat","Lon"]);
lat_lim=zeros(height(T),2);
lon_lim=zeros(height(T),2);
for k=1:height(T)
    [lat_lim(k,1),lat_lim(k,2)]=bounds(T.Lat{k});
    [lon_lim(k,1),lon_lim(k,2)]=bounds(T.Lon{k});
end
end
