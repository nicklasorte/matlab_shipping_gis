function [mask_sub,row_range,col_range]=rasterize_polygon_crop_rev1(lat,lon,R)
%rasterize_polygon_crop_rev1  Rasterize one lat/lon polygon onto a crop of raster R.
%
%   [mask_sub,row_range,col_range]=rasterize_polygon_crop_rev1(lat,lon,R)
%   fills the polygon (NaN-separated parts allowed) on the part of R that
%   covers its bounding box and returns the logical crop and the rows and
%   columns of R it covers. Cells on the edge count as inside. Empty
%   outputs mean the polygon misses R.
%
%   Built-in: vec2mtx(...,'filled') does the fill. Cropping first keeps a
%   small polygon from paying for a fill of the whole CONUS grid.

arguments
    lat (:,1) double
    lon (:,1) double
    R (1,1) map.rasterref.GeographicCellsReference
end

mask_sub=false(0,0);
row_range=[];
col_range=[];
dlat=R.CellExtentInLatitude;
dlon=R.CellExtentInLongitude;

%%%%%Bounding box snapped outward to grid edges, plus one cell of margin
lat_lo=max(R.LatitudeLimits(1),R.LatitudeLimits(1)+dlat*(floor((min(lat)-R.LatitudeLimits(1))/dlat)-1));
lat_hi=min(R.LatitudeLimits(2),R.LatitudeLimits(1)+dlat*(ceil((max(lat)-R.LatitudeLimits(1))/dlat)+1));
lon_lo=max(R.LongitudeLimits(1),R.LongitudeLimits(1)+dlon*(floor((min(lon)-R.LongitudeLimits(1))/dlon)-1));
lon_hi=min(R.LongitudeLimits(2),R.LongitudeLimits(1)+dlon*(ceil((max(lon)-R.LongitudeLimits(1))/dlon)+1));
if lat_hi<=lat_lo || lon_hi<=lon_lo
    return
end

row_first=round((lat_lo-R.LatitudeLimits(1))/dlat)+1;
row_last=round((lat_hi-R.LatitudeLimits(1))/dlat);
col_first=round((lon_lo-R.LongitudeLimits(1))/dlon)+1;
col_last=round((lon_hi-R.LongitudeLimits(1))/dlon);

%%%%%georefcells needs at least 2 cells per side, and rounding can make an
%%%%%exact 2-cell span fail its check, so widen small crops to 3 cells inside R.
[row_first,row_last]=widen_to_three(row_first,row_last,R.RasterSize(1));
[col_first,col_last]=widen_to_three(col_first,col_last,R.RasterSize(2));
row_range=row_first:row_last;
col_range=col_first:col_last;
lat_lo=R.LatitudeLimits(1)+dlat*(row_first-1);
lat_hi=R.LatitudeLimits(1)+dlat*row_last;
lon_lo=R.LongitudeLimits(1)+dlon*(col_first-1);
lon_hi=R.LongitudeLimits(1)+dlon*col_last;

%%%%%Give the raster size, not the cell extent, so the crop size matches the index ranges exactly.
R_sub=georefcells([lat_lo lat_hi],[lon_lo lon_hi],[numel(row_range) numel(col_range)]);
Z=vec2mtx(lat,lon,zeros(R_sub.RasterSize),R_sub,'filled');
mask_sub=Z<=1;
end

function [first,last]=widen_to_three(first,last,num)
%%%%%Grow [first,last] to at least 3 indices without leaving 1..num.
if last-first+1>=3
    return
end
first=max(1,min(first,num-2));
last=first+2;
end
