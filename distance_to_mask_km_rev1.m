function [dist_km]=distance_to_mask_km_rev1(source_mask,R,max_km)
%distance_to_mask_km_rev1  Great-circle distance (km) from every cell to the nearest source cell.
%
%   dist_km=distance_to_mask_km_rev1(source_mask,R,max_km) returns, for
%   each cell of raster R, the distance in km from the cell center to the
%   nearest cell center where SOURCE_MASK is true. Cells farther than
%   MAX_KM from every source are set to 2*MAX_KM, so contours at or below
%   MAX_KM are unaffected.
%
%   Method: cell centers go to ECEF on a sphere of the IUGG mean Earth
%   radius (6371.0088 km); a KDTreeSearcher finds the nearest source by
%   chord length, and the chord converts exactly to arc length. A sphere
%   instead of WGS84 changes a 50 km distance by under 0.5 percent.
%   Built-ins considered: bwdist (Image Processing, not installed, and
%   planar); distance() per pair (exact on WGS84 but O(N*M)).

arguments
    source_mask (:,:) logical
    R (1,1) map.rasterref.GeographicCellsReference
    max_km (1,1) double {mustBePositive}
end

earth_radius_km=6371.0088; %%%%%IUGG mean Earth radius
if ~isequal(size(source_mask),R.RasterSize)
    error('shipgis:size','source_mask size does not match R.RasterSize');
end

dist_km=2*max_km*ones(R.RasterSize);
if ~any(source_mask(:))
    return
end

[lat_grid,lon_grid]=geographicGrid(R);
xyz_src=sphere_xyz(lat_grid(source_mask),lon_grid(source_mask),earth_radius_km);
searcher=KDTreeSearcher(xyz_src);

%%%%%Only query cells inside the source bounding box grown by max_km
pad_lat=max_km/111.0;  %%%%%km per degree of latitude, rounded down so the pad is generous
src_rows=find(any(source_mask,2));
src_cols=find(any(source_mask,1));
lat_min=lat_grid(src_rows(1),1)-pad_lat;
lat_max=lat_grid(src_rows(end),1)+pad_lat;
cos_min=cosd(max(abs([lat_min lat_max]))); %%%%%smallest cosine gives the widest longitude pad
pad_lon=max_km/(111.0*max(cos_min,0.05));
lon_min=lon_grid(1,src_cols(1))-pad_lon;
lon_max=lon_grid(1,src_cols(end))+pad_lon;
query_rows=find(lat_grid(:,1)>=lat_min & lat_grid(:,1)<=lat_max);
query_cols=find(lon_grid(1,:)>=lon_min & lon_grid(1,:)<=lon_max);

%%%%%Query in row blocks to bound memory
block_rows=200;
for row_start=1:block_rows:numel(query_rows)
    rows=query_rows(row_start:min(row_start+block_rows-1,numel(query_rows)));
    lat_q=lat_grid(rows,query_cols);
    lon_q=lon_grid(rows,query_cols);
    [~,chord_km]=knnsearch(searcher,sphere_xyz(lat_q(:),lon_q(:),earth_radius_km));
    arc_km=2*earth_radius_km*asin(min(chord_km/(2*earth_radius_km),1));
    arc_km(arc_km>max_km)=2*max_km;
    dist_km(rows,query_cols)=reshape(arc_km,numel(rows),numel(query_cols));
end
end

function xyz=sphere_xyz(lat,lon,radius)
%%%%%Spherical ECEF; geodetic2ecef would use WGS84, which the chord-to-arc step does not model.
xyz=radius*[cosd(lat).*cosd(lon), cosd(lat).*sind(lon), sind(lat)];
end
