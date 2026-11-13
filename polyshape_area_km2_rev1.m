function area_km2=polyshape_area_km2_rev1(poly)
%polyshape_area_km2_rev1  Area of a lon/lat polyshape on the WGS84 ellipsoid, in km^2.
%
%   area_km2=polyshape_area_km2_rev1(poly) projects POLY (x = lon, y = lat)
%   to the equal-area WGS 84 / NSIDC EASE-Grid 2.0 Global projection
%   (EPSG:6933) and returns its area. Used for the land in each zone, so the
%   areas come from the clipped land polygons rather than from counting grid
%   cells that touch land (review CA-33).
%
%   Built-ins: projcrs, projfwd, polyshape, area.

arguments
    poly (1,1) polyshape
end

if poly.NumRegions==0
    area_km2=0;
    return
end
proj=projcrs(6933);
[lon_b,lat_b]=boundary(poly);   %%%%%NaN between rings; outer rings clockwise, holes counterclockwise
[x,y]=projfwd(proj,lat_b,lon_b);
warn_state=warning('off','MATLAB:polyshape:repairedBySimplify');
cleanup_warn=onCleanup(@() warning(warn_state));
area_km2=area(polyshape(x/1000,y/1000,'Simplify',false,'KeepCollinearPoints',true));
end
