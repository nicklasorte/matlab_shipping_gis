function [foreign_side_poly]=foreign_side_polygon_rev1(us_land_mask,f_lat,f_lon,R,cap_km,block_rows)
%foreign_side_polygon_rev1  Region of raster R nearer foreign land than U.S. land (equidistance).
%
%   P=foreign_side_polygon_rev1(us_land_mask,f_lat,f_lon,R,cap_km) returns a
%   planar polyshape (x = lon, y = lat) of the cells whose distance to foreign
%   land (the points F_LAT, F_LON, which may lie outside R) is less than or
%   equal to their distance to U.S. land (US_LAND_MASK on R). Distances run
%   out to CAP_KM; a cell farther than CAP_KM from both counts as U.S.-side,
%   so with CAP_KM = 370.4 (200 nautical miles) high seas are never in P.
%   U.S. land cells are never in P (their U.S. distance is 0).
%
%   Built-ins and helpers: distance_to_mask_km_rev1, distance_to_points_km_rev1
%   (KD-tree on the sphere), field_to_zone_polyshape_rev1 (contourc at 0).

arguments
    us_land_mask (:,:) logical
    f_lat (:,1) double
    f_lon (:,1) double
    R (1,1) map.rasterref.GeographicCellsReference
    cap_km (1,1) double {mustBePositive}
    block_rows (1,1) double {mustBePositive,mustBeInteger} = 200
end

if isempty(f_lat)
    foreign_side_poly=polyshape();
    return
end
d_us=distance_to_mask_km_rev1(us_land_mask,R,cap_km,block_rows);
d_foreign=distance_to_points_km_rev1(f_lat,f_lon,R,cap_km,block_rows);
side_km=d_foreign-d_us;                        %%%%%<= 0: foreign side
side_km(d_us>cap_km & d_foreign>cap_km)=1;     %%%%%beyond cap_km of both: U.S.-side (high seas kept)
side_km(us_land_mask)=1;                       %%%%%U.S. land is never foreign-side
foreign_side_poly=field_to_zone_polyshape_rev1(side_km,R,0);
end
