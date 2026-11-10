function [zone_poly]=zone_bufferm_rev1(source_poly,d_km,max_vertices)
%zone_bufferm_rev1  Buffer a lat/lon polygon by d_km with bufferm, piece by piece.
%
%   zone_poly=zone_bufferm_rev1(source_poly,d_km,max_vertices) buffers each
%   region of SOURCE_POLY (planar polyshape, x = lon, y = lat) outward by
%   D_KM with bufferm, and unions the pieces into one polyshape. Regions
%   with more than MAX_VERTICES vertices are split into tiles first,
%   because bufferm slows sharply on long boundaries; the buffer of a union
%   equals the union of the buffers, so tiling does not change the result.
%
%   This is the independent check on distance_to_mask_km_rev1 +
%   field_to_zone_polyshape_rev1: same zone, different algorithm.
%   bufferm works in degrees of arc on a sphere, so the width is
%   km2deg(d_km) with the mean Earth radius.

arguments
    source_poly (1,1) polyshape
    d_km (1,1) double {mustBePositive}
    max_vertices (1,1) double {mustBePositive} = 2000
end

earth_radius_km=6371.0088;
width_deg=km2deg(d_km,earth_radius_km);

warn_state=warning('off','MATLAB:polyshape:repairedBySimplify');
cleanup_warn=onCleanup(@() warning(warn_state));

pieces=split_large(regions(source_poly),max_vertices);
buffered=repmat(polyshape(),numel(pieces),1);
for k=1:numel(pieces)
    [lon_b,lat_b]=boundary(pieces(k));
    [lat_out,lon_out]=bufferm(lat_b,lon_b,width_deg,'outPlusInterior');
    buffered(k)=polyshape(lon_out,lat_out);
end
zone_poly=union(buffered);
end

function out=split_large(in,max_vertices)
%%%%%Quarter any region whose vertex count exceeds max_vertices, recursively.
out=polyshape.empty(0,1);
for k=1:numel(in)
    p=in(k);
    if p.NumRegions==0
        continue
    end
    if size(p.Vertices,1)<=max_vertices
        out(end+1,1)=p; %#ok<AGROW> piece count is not known in advance
        continue
    end
    [x_lim,y_lim]=boundingbox(p);
    x_mid=mean(x_lim);
    y_mid=mean(y_lim);
    quads=[polyshape([x_lim(1) x_mid x_mid x_lim(1)],[y_lim(1) y_lim(1) y_mid y_mid]), ...
        polyshape([x_mid x_lim(2) x_lim(2) x_mid],[y_lim(1) y_lim(1) y_mid y_mid]), ...
        polyshape([x_lim(1) x_mid x_mid x_lim(1)],[y_mid y_mid y_lim(2) y_lim(2)]), ...
        polyshape([x_mid x_lim(2) x_lim(2) x_mid],[y_mid y_mid y_lim(2) y_lim(2)])];
    for j=1:4
        piece=intersect(p,quads(j));
        if piece.NumRegions>0
            out=[out; split_large(regions(piece),max_vertices)]; %#ok<AGROW>
        end
    end
end
end
