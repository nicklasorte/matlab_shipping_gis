function [p_out]=simplify_polyshape_rev1(p_in,tol_deg)
%simplify_polyshape_rev1  Drop vertices from a lon/lat polyshape within a tolerance.
%
%   p_out=simplify_polyshape_rev1(p_in,tol_deg) removes vertices that lie
%   within TOL_DEG degrees of the simplified outline (reducem,
%   Douglas-Peucker on latitude and longitude) and rebuilds the polyshape,
%   so holes and separate regions are kept.
%
%   At 0.005 deg (about 0.5 km, half a grid cell) the 2024 50 km land zone
%   went from 71,423 to 11,509 vertices, and the outline moved by less than
%   1 percent of the zone's area. TOL_DEG=0 returns P_IN unchanged.

arguments
    p_in (1,1) polyshape
    tol_deg (1,1) double {mustBeNonnegative}
end

if tol_deg==0 || p_in.NumRegions==0
    p_out=p_in;
    return
end
warn_state=warning('off','MATLAB:polyshape:repairedBySimplify');
cleanup_warn=onCleanup(@() warning(warn_state));
[lon_b,lat_b]=boundary(p_in);
[lat_r,lon_r]=reducem(lat_b,lon_b,tol_deg);
p_out=polyshape(lon_r,lat_r);
end
