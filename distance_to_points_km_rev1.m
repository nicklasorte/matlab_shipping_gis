function [dist_km]=distance_to_points_km_rev1(lat,lon,R,max_km,block_rows)
%distance_to_points_km_rev1  Great-circle distance (km) from every cell of R to the nearest of a set of points.
%
%   dist_km=distance_to_points_km_rev1(lat,lon,R,max_km) returns, for each
%   cell centre of raster R, the distance in km to the nearest point
%   (LAT, LON), for example the vertices of a coastline that runs past the
%   edge of R. Cells farther than MAX_KM from every point are set to
%   2*MAX_KM, as in distance_to_mask_km_rev1.
%
%   Method and sphere as distance_to_mask_km_rev1 (ECEF on the IUGG mean
%   radius, KDTreeSearcher, chord to arc). Points can lie outside R, so the
%   180-degree meridian and grid edges need no special case.

arguments
    lat (:,1) double
    lon (:,1) double
    R (1,1) map.rasterref.GeographicCellsReference
    max_km (1,1) double {mustBePositive}
    block_rows (1,1) double {mustBePositive,mustBeInteger} = 200
end

earth_radius_km=6371.0088; %%%%%IUGG mean Earth radius
dist_km=2*max_km*ones(R.RasterSize);
ok=~isnan(lat) & ~isnan(lon);
if ~any(ok)
    return
end
if ~strcmp(R.ColumnsStartFrom,'south') || ~strcmp(R.RowsStartFrom,'west')
    error('shipgis:orientation','Expected a raster with ColumnsStartFrom south and RowsStartFrom west.');
end
lat_vec=R.LatitudeLimits(1)+R.CellExtentInLatitude*((1:R.RasterSize(1))'-0.5);
lon_vec=R.LongitudeLimits(1)+R.CellExtentInLongitude*((1:R.RasterSize(2))-0.5);
searcher=KDTreeSearcher(sphere_xyz(lat(ok),lon(ok),earth_radius_km));
for row_start=1:block_rows:numel(lat_vec)
    rows=row_start:min(row_start+block_rows-1,numel(lat_vec));
    [lon_q,lat_q]=meshgrid(lon_vec,lat_vec(rows));
    [~,chord_km]=knnsearch(searcher,sphere_xyz(lat_q(:),lon_q(:),earth_radius_km));
    arc_km=2*earth_radius_km*asin(min(chord_km/(2*earth_radius_km),1));
    arc_km(arc_km>max_km)=2*max_km;
    dist_km(rows,:)=reshape(arc_km,numel(rows),numel(lon_vec));
end
end

function xyz=sphere_xyz(lat,lon,radius)
xyz=radius*[cosd(lat(:)).*cosd(lon(:)), cosd(lat(:)).*sind(lon(:)), sind(lat(:))];
end
