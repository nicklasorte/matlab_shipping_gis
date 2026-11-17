function in_box=box_mask_rev1(R,boxes)
%box_mask_rev1  Raster mask of the cells whose centers lie inside any box.
%
%   in_box=box_mask_rev1(R,boxes) returns a logical array of size R.RasterSize
%   that is true where the cell center falls inside at least one row of BOXES
%   (N-by-4: [lat_min lat_max lon_min lon_max], limits included).
%
%   Built-ins considered: inpolygon and geographicToDiscrete would work but
%   cost far more on a 2,800-by-6,400 grid; the boxes are axis-aligned, so
%   implicit expansion of the row and column centers is exact.

arguments
    R (1,1) map.rasterref.GeographicCellsReference
    boxes (:,4) double {mustBeFinite}
end
if any(boxes(:,1)>boxes(:,2)) || any(boxes(:,3)>boxes(:,4))
    error('shipgis:box','Each box must be [lat_min lat_max lon_min lon_max] with min <= max.');
end
lat_c=R.LatitudeLimits(1)+R.CellExtentInLatitude*((1:R.RasterSize(1))'-0.5);
lon_c=R.LongitudeLimits(1)+R.CellExtentInLongitude*((1:R.RasterSize(2))-0.5);
in_box=false(R.RasterSize);
for k=1:size(boxes,1)
    in_box=in_box | ((lat_c>=boxes(k,1) & lat_c<=boxes(k,2)) & (lon_c>=boxes(k,3) & lon_c<=boxes(k,4)));
end
end
