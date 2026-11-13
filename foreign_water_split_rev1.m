function T=foreign_water_split_rev1(zone_shp,land_shp,opts)
%foreign_water_split_rev1  Split a zone into U.S. land, U.S.-side water, and foreign-side water.
%
%   T=foreign_water_split_rev1(ZONE_SHP,LAND_SHP) samples the zone polygon in
%   ZONE_SHP on a regular latitude-longitude grid and classifies each point:
%     land           inside the zone's land polygon (LAND_SHP, the *_land.shp file)
%     us_water       water nearer U.S. land than foreign land (equidistance line)
%     foreign_water  water nearer foreign land than U.S. land
%   and, as an overlay on the two water classes, beyond_200nmi: water more than
%   200 nautical miles (370.4 km) from U.S. land.
%   Returns a one-row table of areas in km^2 (each point carries the area of its
%   grid cell, step^2 * cos(lat)).
%
%   The equidistance line stands in for the maritime boundary. It is the rule the
%   zone code already uses to drop charted lanes nearer foreign land
%   (shipping_zone_rev1). Negotiated boundaries (for example in the Strait of
%   Juan de Fuca, the Great Lakes, and the Gulf of Maine) depart from it, so the
%   split is an estimate for a decision, not a boundary product.
%
%   Built-ins: readgeotable, geotable2table, polyshape/isinterior, knnsearch
%   (Statistics and Machine Learning) on unit-sphere ECEF points; chord length
%   ranks neighbours the same as arc length and converts exactly.
%   Considered: clipping to an EEZ polygon (needs a layer not in the repo and
%   leaves the Great Lakes open); bufferm on foreign land (slow at this size).

arguments
    zone_shp (1,:) char
    land_shp (1,:) char
    opts.step_deg (1,1) double {mustBePositive}=0.02
    opts.us_states_shp (1,:) char=fullfile(pwd,'data','cb_2023_us_state_500k','cb_2023_us_state_500k.shp')
    opts.foreign_shp (1,:) char=fullfile(pwd,'data','ne_10m_admin_0_countries_lakes','ne_10m_admin_0_countries_lakes.shp')
    opts.search_km (1,1) double=800
end

R=6371.0088;   %%%%%IUGG mean Earth radius, km
Z=polygon_lonlat(zone_shp);
L=polygon_lonlat(land_shp);

%%%%%Grid over the zone's bounding box (cell centres).
[xl,yl]=boundingbox(Z);
lon=(floor(xl(1)/opts.step_deg)*opts.step_deg+opts.step_deg/2):opts.step_deg:xl(2);
lat=(floor(yl(1)/opts.step_deg)*opts.step_deg+opts.step_deg/2):opts.step_deg:yl(2);
[LON,LAT]=meshgrid(lon,lat);
in_zone=isinterior(Z,LON(:),LAT(:));
plon=LON(in_zone); plat=LAT(in_zone);
cell_km2=(opts.step_deg*pi/180*R)^2*cosd(plat);
on_land=isinterior(L,plon,plat);

%%%%%Nearest U.S. land and nearest foreign land, by chord distance in ECEF.
[ulon,ulat]=vertices(opts.us_states_shp,"STUSPS",[],[yl(1) yl(2)],opts.search_km);
%%%%%Natural Earth gives U.S. territories their own ADM0 codes; none is foreign.
[flon,flat]=vertices(opts.foreign_shp,"ADM0_A3",["USA" "PRI" "VIR" "GUM" "ASM" "MNP" "UMI"],[yl(1) yl(2)],opts.search_km);
w=~on_land;
P=xyz(plon(w),plat(w));
[~,du]=knnsearch(xyz(ulon,ulat),P);
du=2*R*asin(min(du/2,1));                       %%%%%chord on the unit sphere -> arc km
if isempty(flon)
    df=inf(size(du));
else
    [~,df]=knnsearch(xyz(flon,flat),P);
    df=2*R*asin(min(df/2,1));
end
a=cell_km2(w);
T=table(string(zone_shp),sum(cell_km2),sum(cell_km2(on_land)),sum(a(du<=df)),sum(a(du>df)),sum(a(du>370.4)), ...
    'VariableNames',["zone_file","total_km2","land_km2","us_water_km2","foreign_water_km2","beyond_200nmi_km2"]);
T.foreign_share_of_water=T.foreign_water_km2/(T.us_water_km2+T.foreign_water_km2);
end

function P=polygon_lonlat(shp)
G=geotable2table(readgeotable(shp),["Lat","Lon"]);
P=polyshape([G.Lon{:}],[G.Lat{:}],'Simplify',false,'KeepCollinearPoints',true);
end

function [lon,lat]=vertices(shp,field,drop,latlim,pad_km)
%%%%%Polygon vertices from SHP (rows whose FIELD is in DROP removed), kept
%%%%%within PAD_KM (in latitude) of LATLIM. Longitude is not filtered, so the
%%%%%180-degree meridian needs no special case.
G=readgeotable(shp);
if ~isempty(drop)
    G=G(~ismember(string(G.(field)),drop),:);
end
G=geotable2table(G,["Lat","Lon"]);
lat=[G.Lat{:}]; lon=[G.Lon{:}];
pad=pad_km/111.195;
k=~isnan(lat) & lat>=latlim(1)-pad & lat<=latlim(2)+pad;
lat=lat(k)'; lon=lon(k)';
end

function X=xyz(lon,lat)
X=[cosd(lat(:)).*cosd(lon(:)), cosd(lat(:)).*sind(lon(:)), sind(lat(:))];
end
