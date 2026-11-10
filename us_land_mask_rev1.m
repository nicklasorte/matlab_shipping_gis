function [land_mask,land_poly]=us_land_mask_rev1(R)
%us_land_mask_rev1  U.S. land cells on raster R, from usastatehi.shp.
%
%   [land_mask,land_poly]=us_land_mask_rev1(R) rasterizes the Mapping
%   Toolbox state polygons (usastatehi.shp, ships with the toolbox) onto R.
%   The Great Lakes, bays, and the ocean are outside the state polygons,
%   so they are false. Canada and Mexico are also false.
%
%   land_poly is a planar polyshape (x=lon, y=lat) of the lower-48 land,
%   for clipping zone polygons to land.

arguments
    R (1,1) map.rasterref.GeographicCellsReference
end

S=readgeotable('usastatehi.shp');
S=S(~ismember(S.Name,["Alaska","Hawaii"]),:);
T=geotable2table(S,["Lat","Lon"]);

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

%%%%%States share edges; union them into one land polygon.
land_poly=union(state_polys);
end
