function [foreign_poly,vert_lat,vert_lon]=load_foreign_land_rev1(R,data_dir,pad_km)
%load_foreign_land_rev1  Land of other countries inside raster R, as a polyshape.
%
%   foreign_poly=load_foreign_land_rev1(R,data_dir) downloads (once, into
%   DATA_DIR) Natural Earth 1:10m Admin 0 countries without boundary lakes
%   (public domain,
%   https://www.naturalearthdata.com), keeps every country except the
%   United States and its territories whose outline touches the grid, and returns their union
%   as a planar polyshape (x = lon, y = lat). shipping_zone_rev1 subtracts
%   it from the zones so that foreign land (Vancouver, Tijuana, Havana) isn't
%   counted as ship water (review CA-3). The file without boundary lakes
%   keeps the Canadian half of the Great Lakes and border rivers as water, so
%   route cells there stay in the zones (round-two review R2MET-2).
%
%   [~,vert_lat,vert_lon]=load_foreign_land_rev1(R,data_dir,pad_km) also
%   returns the outline vertices of every foreign country within PAD_KM (in
%   latitude) of the grid, not clipped to it, for distances to foreign land
%   that runs past the grid edge (the equidistance water clip).
%
%   Built-ins: websave, unzip, readgeotable, geotable2table, polyshape, union.

arguments
    R (1,1) map.rasterref.GeographicCellsReference
    data_dir (1,:) char
    pad_km (1,1) double = 0
end

stem='ne_10m_admin_0_countries_lakes';
shp_path=fullfile(data_dir,stem,[stem '.shp']);
if ~isfile(shp_path)
    zip_path=fullfile(data_dir,[stem '.zip']);
    websave(zip_path,['https://naciscdn.org/naturalearth/10m/cultural/' stem '.zip'],weboptions('Timeout',300));
    unzip(zip_path,fullfile(data_dir,stem));
    delete(zip_path);
end
S=readgeotable(shp_path);
S=S(string(S.SOVEREIGNT)~="United States of America",:);   %%%%%drops the United States and its territories (Puerto Rico, the USVI, and others are their own units in Natural Earth, all with this sovereign)
T=geotable2table(S,["Lat","Lon"]);
if nargout>1
    pad=pad_km/111.0;
    vert_lat=cell2mat(cellfun(@(x) x(:),T.Lat,'UniformOutput',false));
    vert_lon=cell2mat(cellfun(@(x) x(:),T.Lon,'UniformOutput',false));
    keep=vert_lat>=R.LatitudeLimits(1)-pad & vert_lat<=R.LatitudeLimits(2)+pad;
    vert_lat=vert_lat(keep); vert_lon=vert_lon(keep);
end
lat_lo=cellfun(@min,T.Lat); lat_hi=cellfun(@max,T.Lat);
lon_lo=cellfun(@min,T.Lon); lon_hi=cellfun(@max,T.Lon);
in_grid=lat_hi>=R.LatitudeLimits(1) & lat_lo<=R.LatitudeLimits(2) & ...
    lon_hi>=R.LongitudeLimits(1) & lon_lo<=R.LongitudeLimits(2);
T=T(in_grid,:);
warn_state=warning('off','MATLAB:polyshape:repairedBySimplify');
cleanup_warn=onCleanup(@() warning(warn_state));
box=polyshape(R.LongitudeLimits([1 2 2 1]),R.LatitudeLimits([1 1 2 2]));
parts=repmat(polyshape(),height(T),1);
for k=1:height(T)
    parts(k)=intersect(polyshape(T.Lon{k}(:),T.Lat{k}(:)),box);
end
if isempty(parts)
    foreign_poly=polyshape();
else
    foreign_poly=union(parts);
end
end
