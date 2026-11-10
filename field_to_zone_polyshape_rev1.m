function [zone_poly,zone_latlon]=field_to_zone_polyshape_rev1(field,R,level)
%field_to_zone_polyshape_rev1  Polygon of the region where a gridded field is <= level.
%
%   [zone_poly,zone_latlon]=field_to_zone_polyshape_rev1(field,R,level)
%   contours FIELD (size R.RasterSize, values at cell centers) at LEVEL and
%   returns the region FIELD<=LEVEL.
%
%   OUTPUTS
%     zone_poly    planar polyshape, x = longitude, y = latitude (deg),
%                  holes included
%     zone_latlon  N-by-2 [lat lon], NaN between rings, holes included.
%                  Works with inpolygon and find_points_inside_contour_*.
%
%   Built-ins: contourc traces the boundary with sub-cell interpolation;
%   polyshape resolves nesting into solids and holes. The field is padded
%   with a value above LEVEL so every contour closes at the grid edge.
%   bwboundaries would trace a mask, but Image Processing is not installed.

arguments
    field (:,:) double
    R (1,1) map.rasterref.GeographicCellsReference
    level (1,1) double
end

%%%%%Cell-center vectors; no full-size coordinate matrices
dlat=R.CellExtentInLatitude;
dlon=R.CellExtentInLongitude;
lat_vec=R.LatitudeLimits(1)+dlat*((1:R.RasterSize(1))'-0.5);
lon_vec=R.LongitudeLimits(1)+dlon*((1:R.RasterSize(2))-0.5);

pad_value=level+max(1,abs(level));
field_pad=pad_value*ones(size(field)+2);
field_pad(2:end-1,2:end-1)=field;
lat_pad=[lat_vec(1)-dlat; lat_vec; lat_vec(end)+dlat];
lon_pad=[lon_vec(1)-dlon, lon_vec, lon_vec(end)+dlon];

C=contourc(lon_pad,lat_pad,field_pad,[level level]);

%%%%%Parse the contour matrix: each ring is a [level; n] header then n points.
num_ring=0;
col=1;
while col<size(C,2)
    num_ring=num_ring+1;
    col=col+C(2,col)+1;
end
x_cell=cell(num_ring,1);
y_cell=cell(num_ring,1);
col=1;
for ring_idx=1:num_ring
    n=C(2,col);
    x_cell{ring_idx}=C(1,col+1:col+n);
    y_cell{ring_idx}=C(2,col+1:col+n);
    col=col+n+1;
end

if num_ring==0
    zone_poly=polyshape();
    zone_latlon=zeros(0,2);
    return
end

warn_state=warning('off','MATLAB:polyshape:repairedBySimplify');
cleanup_warn=onCleanup(@() warning(warn_state));
zone_poly=polyshape(x_cell,y_cell);

[x_b,y_b]=boundary(zone_poly);
zone_latlon=[y_b x_b];
end
