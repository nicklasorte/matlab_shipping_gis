function [tile_rings,num_tile]=routes_polygons_rev1(route_mask,R,tile_deg,simplify_deg)
%routes_polygons_rev1  Polygon rings around the route cells, built tile by tile.
%
%   [tile_rings,num_tile]=routes_polygons_rev1(route_mask,R,tile_deg,simplify_deg)
%   traces the cells where ROUTE_MASK is true (raster R) into polygon rings.
%   The grid is cut into TILE_DEG tiles (default 1 degree) so each
%   polyshape holds a few hundred rings instead of the whole country.
%   TILE_RINGS is a cell array with one N-by-2 [lat lon] array per tile
%   that holds route cells (NaN between rings, outer rings clockwise, holes
%   counterclockwise: the shapewrite and kmlwrite order). Each tile becomes
%   one polygon feature, which keeps kmlwrite fast. num_tile is the count.
%
%   Each tile is contoured with a one-cell margin of real data and then
%   clipped at its exact edge, so polygons from neighboring tiles meet
%   without a gap. SIMPLIFY_DEG (default 0, none) drops vertices with
%   reducem before the clip, so tile edges stay straight.
%
%   Built-ins: contourc traces the cell edges (level 0.5 between route
%   and non-route cell centers), polyshape resolves holes and nesting,
%   intersect clips each tile, boundary returns the ordered rings. One
%   polyshape for the whole country (hundreds of thousands of rings) took
%   more than 4 minutes and was stopped; per tile it takes seconds.

arguments
    route_mask (:,:) logical
    R (1,1) map.rasterref.GeographicCellsReference
    tile_deg (1,1) double {mustBePositive} = 1
    simplify_deg (1,1) double {mustBeNonnegative} = 0
end

if ~isequal(size(route_mask),R.RasterSize)
    error('shipgis:size','route_mask size does not match R.RasterSize');
end
warn_state=warning('off','MATLAB:polyshape:repairedBySimplify');
cleanup_warn=onCleanup(@() warning(warn_state));

dlat=R.CellExtentInLatitude;
dlon=R.CellExtentInLongitude;
lat0=R.LatitudeLimits(1);
lon0=R.LongitudeLimits(1);
num_row=R.RasterSize(1);
num_col=R.RasterSize(2);
tile_rows=round(tile_deg/dlat);
tile_cols=round(tile_deg/dlon);

row_starts=1:tile_rows:num_row;
col_starts=1:tile_cols:num_col;
tile_rings=cell(numel(row_starts)*numel(col_starts),1);
num_tile=0;
k=0;
for r0=row_starts
    r1=min(r0+tile_rows-1,num_row);
    for c0=col_starts
        c1=min(c0+tile_cols-1,num_col);
        k=k+1;
        if ~any(route_mask(r0:r1,c0:c1),'all')
            continue
        end
        num_tile=num_tile+1;
        %%%%%One-cell margin of real data, then a zero border so every contour closes
        ra=max(r0-1,1);
        rb=min(r1+1,num_row);
        ca=max(c0-1,1);
        cb=min(c1+1,num_col);
        sub=zeros(rb-ra+3,cb-ca+3);
        sub(2:end-1,2:end-1)=route_mask(ra:rb,ca:cb);
        lat_c=lat0+dlat*((ra-1:rb+1)'-0.5);
        lon_c=lon0+dlon*((ca-1:cb+1)-0.5);
        C=contourc(lon_c,lat_c,sub,[0.5 0.5]);
        [x,y]=contour_rings(C);
        if simplify_deg>0
            [y,x]=reducem(y,x,simplify_deg);
        end
        tile_poly=polyshape(x,y);
        %%%%%Clip at the tile's exact cell edges
        x_lo=lon0+dlon*(c0-1);
        x_hi=lon0+dlon*c1;
        y_lo=lat0+dlat*(r0-1);
        y_hi=lat0+dlat*r1;
        tile_poly=intersect(tile_poly,polyshape([x_lo x_hi x_hi x_lo],[y_lo y_lo y_hi y_hi]));
        if tile_poly.NumRegions==0
            continue
        end
        %%%%%Write each region's outer ring followed by its own holes, so readers
        %%%%%that pair holes with the outer ring before them (shapely, GDAL) don't
        %%%%%find orphaned holes (review CA-96).
        regs=regions(tile_poly);
        parts=cell(numel(regs),1);
        for reg_idx=1:numel(regs)
            [xr,yr]=boundary(regs(reg_idx));
            parts{reg_idx}=[yr xr; NaN NaN];
        end
        rings=vertcat(parts{:});
        tile_rings{k}=rings(1:end-1,:);
    end
end
tile_rings=tile_rings(~cellfun(@isempty,tile_rings));
end

function [x,y]=contour_rings(C)
%%%%%contourc matrix to NaN-separated vectors (one ring per level block)
num_ring=0;
idx=1;
while idx<size(C,2)
    num_ring=num_ring+1;
    idx=idx+C(2,idx)+1;
end
x=NaN(size(C,2)+num_ring,1);
y=x;
idx=1;
pos=1;
while idx<size(C,2)
    n=C(2,idx);
    x(pos:pos+n-1)=C(1,idx+1:idx+n);
    y(pos:pos+n-1)=C(2,idx+1:idx+n);
    pos=pos+n+1;
    idx=idx+n+1;
end
x=x(1:pos-2);
y=y(1:pos-2);
end
