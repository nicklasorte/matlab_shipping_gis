function [mask_sub,row_range,col_range]=rasterize_polygon_crop_rev1(lat,lon,R)
%rasterize_polygon_crop_rev1  Rasterize one lat/lon polygon onto a crop of raster R.
%
%   [mask_sub,row_range,col_range]=rasterize_polygon_crop_rev1(lat,lon,R)
%   fills the polygon (NaN-separated parts and holes allowed) on the part
%   of R that covers its bounding box and returns the logical crop and the
%   rows and columns of R it covers. Cells on the edge count as inside.
%   Empty outputs mean the polygon misses R.
%
%   Built-ins: polyshape sets the ring orientation (vec2mtx 'filled' fills
%   clockwise rings and treats counterclockwise rings as holes), and
%   vec2mtx(...,'filled') does the fill. The fill runs on a window one
%   cell larger than the polygon on every side, even past the edge of R,
%   so the flood fill always starts outside the polygon; the window is
%   then cut back to R. Cropping keeps a small polygon from paying for a
%   fill of the whole CONUS grid.

arguments
    lat (:,1) double
    lon (:,1) double
    R (1,1) map.rasterref.GeographicCellsReference
end

mask_sub=false(0,0);
row_range=[];
col_range=[];
if all(isnan(lat))
    return
end
dlat=R.CellExtentInLatitude;
dlon=R.CellExtentInLongitude;
num_row=R.RasterSize(1);
num_col=R.RasterSize(2);

%%%%%Clockwise outer rings, counterclockwise holes (polyshape convention, x = lon).
warn_state=warning('off','MATLAB:polyshape:repairedBySimplify');
cleanup_warn=onCleanup(@() warning(warn_state));
[lon_cw,lat_cw]=boundary(polyshape(lon,lat));
if isempty(lon_cw)
    return
end

%%%%%Window on R's grid, 2 cells of margin, not clamped to R
row_first=floor((min(lat_cw)-R.LatitudeLimits(1))/dlat)-1;    %%%%%0-based edge index
row_last=ceil((max(lat_cw)-R.LatitudeLimits(1))/dlat)+1;
col_first=floor((min(lon_cw)-R.LongitudeLimits(1))/dlon)-1;
col_last=ceil((max(lon_cw)-R.LongitudeLimits(1))/dlon)+1;
if row_last<1 || row_first>num_row || col_last<1 || col_first>num_col
    return
end

win_rows=row_last-row_first;
win_cols=col_last-col_first;
lat_lim=R.LatitudeLimits(1)+dlat*[row_first row_last];
lon_lim=R.LongitudeLimits(1)+dlon*[col_first col_last];
%%%%%Give the raster size, not the cell extent, so the window size is exact.
R_win=georefcells(lat_lim,lon_lim,[win_rows win_cols]);
Z=vec2mtx(lat_cw,lon_cw,zeros(R_win.RasterSize),R_win,'filled');
win_mask=Z<=1;

%%%%%Cut the window back to R (window row k is R row row_first+k)
row_all=row_first+(1:win_rows);
col_all=col_first+(1:win_cols);
keep_row=row_all>=1 & row_all<=num_row;
keep_col=col_all>=1 & col_all<=num_col;
row_range=row_all(keep_row);
col_range=col_all(keep_col);
mask_sub=win_mask(keep_row,keep_col);
end
