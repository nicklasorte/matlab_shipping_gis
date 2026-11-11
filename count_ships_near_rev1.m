function [counts]=count_ships_near_rev1(p,R,lat0,lon0,radius_km)
%count_ships_near_rev1  Distinct large ships per year within radius_km of a point.
%
%   counts=count_ships_near_rev1(p,R,lat0,lon0,radius_km) loads the per-day
%   AIS caches for p.ais_days (made by ais_cache_day_rev1 or
%   ais_cells_py_rev1.py with the filter in p.filt) and counts the distinct
%   MMSI that reported from any grid cell whose center is within RADIUS_KM
%   of (LAT0, LON0). Returns a table: year, num_days, num_ships, and a last
%   row for all years together (year = NaN).
%
%   Example: ships that reached the Port of Greater Baton Rouge.
%
%   Built-ins: distance with wgs84Ellipsoid for the cell window,
%   ismember and unique for the counts. Caches must exist; a missing cache
%   is an error, not a zero.

arguments
    p (1,1) struct
    R (1,1) map.rasterref.GeographicCellsReference
    lat0 (1,1) double
    lon0 (1,1) double
    radius_km (1,1) double {mustBePositive}
end

%%%%%Cells in a small window around the point, then the exact distance test
dlat=R.CellExtentInLatitude;
dlon=R.CellExtentInLongitude;
half_lat=radius_km/111+dlat;
half_lon=radius_km/(111*cosd(lat0))+dlon;
lat_vec=R.LatitudeLimits(1)+dlat*((1:R.RasterSize(1))'-0.5);
lon_vec=R.LongitudeLimits(1)+dlon*((1:R.RasterSize(2))'-0.5);
row_win=find(abs(lat_vec-lat0)<=half_lat);
col_win=find(abs(lon_vec-lon0)<=half_lon);
[row_g,col_g]=ndgrid(row_win,col_win);
d_km=distance(lat0,lon0,lat_vec(row_g(:)),lon_vec(col_g(:)),wgs84Ellipsoid('km'));
near_cells=sub2ind(R.RasterSize,row_g(d_km<=radius_km),col_g(d_km<=radius_km));
if isempty(near_cells)
    error('shipgis:window','No grid cell within %g km of (%g, %g).',radius_km,lat0,lon0);
end

day_year=year(p.ais_days(:));
yrs=unique(day_year);
num_ships=zeros(numel(yrs)+1,1);
num_days=zeros(numel(yrs)+1,1);
mmsi_all=zeros(0,1);
for k=1:numel(yrs)
    mmsi_year=zeros(0,1);
    day_idx=find(day_year==yrs(k));
    for j=day_idx'
        cache_file=ais_cache_name_rev1(p.ais_days(j),R,p);
        if ~isfile(cache_file)
            error('shipgis:cache','Missing AIS cache: %s',cache_file);
        end
        S=load(cache_file,'pairs');
        hit=ismember(S.pairs(:,1),near_cells);
        mmsi_year=unique([mmsi_year; S.pairs(hit,2)]);
    end
    num_ships(k)=numel(mmsi_year);
    num_days(k)=numel(day_idx);
    mmsi_all=unique([mmsi_all; mmsi_year]);
end
num_ships(end)=numel(mmsi_all);
num_days(end)=numel(p.ais_days);
counts=table([yrs; NaN],num_days,num_ships,'VariableNames',{'year','num_days','num_ships'});
end
