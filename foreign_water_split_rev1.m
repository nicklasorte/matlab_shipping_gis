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
%   A grid cell counts when the zone (or land) polygon touches it, so areas run
%   slightly above the polygon areas; the Python twin samples cell centres.
%
%   Built-ins: readgeotable, geotable2table, georefcells, vec2mtx (through
%   rasterize_polygon_crop_rev1), knnsearch
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

earth_radius_km=6371.0088;   %%%%%IUGG mean Earth radius
[zlat,zlon]=polygon_latlon(zone_shp);
[llat,llon]=polygon_latlon(land_shp);

%%%%%Raster over the zone's bounding box; a cell is in the zone (or on land)
%%%%%when the polygon touches it (rasterize_polygon_crop_rev1, vec2mtx fill).
%%%%%isinterior on millions of points against the full polygon took more than
%%%%%10 minutes for the lower-48 25 km zone; the fill takes seconds.
step=opts.step_deg;
lat0=floor(min(zlat)/step)*step; lon0=floor(min(zlon)/step)*step;
num_row=ceil((max(zlat)-lat0)/step); num_col=ceil((max(zlon)-lon0)/step);
Rg=georefcells(lat0+[0 num_row*step],lon0+[0 num_col*step],[num_row num_col]);
in_zone=full_mask(zlat,zlon,Rg);
on_land=full_mask(llat,llon,Rg) & in_zone;
[row,col]=find(in_zone);
plat=lat0+(row-0.5)*step; plon=lon0+(col-0.5)*step;
cell_km2=(step*pi/180*earth_radius_km)^2*cosd(plat);
on_land=on_land(in_zone);
yl=[min(zlat) max(zlat)];

%%%%%Nearest U.S. land and nearest foreign land, by chord distance in ECEF.
[ulon,ulat]=vertices(opts.us_states_shp,"STUSPS",[],[yl(1) yl(2)],opts.search_km);
%%%%%Natural Earth gives U.S. territories their own ADM0 codes; none is foreign.
[flon,flat]=vertices(opts.foreign_shp,"ADM0_A3",["USA" "PRI" "VIR" "GUM" "ASM" "MNP" "UMI"],[yl(1) yl(2)],opts.search_km);
w=~on_land;
P=xyz(plon(w),plat(w));
[~,du]=knnsearch(xyz(ulon,ulat),P);
du=2*earth_radius_km*asin(min(du/2,1));                       %%%%%chord on the unit sphere -> arc km
if isempty(flon)
    df=inf(size(du));
else
    [~,df]=knnsearch(xyz(flon,flat),P);
    df=2*earth_radius_km*asin(min(df/2,1));
end
a=cell_km2(w);
T=table(string(zone_shp),sum(cell_km2),sum(cell_km2(on_land)),sum(a(du<=df)),sum(a(du>df)),sum(a(du>370.4)), ...
    'VariableNames',["zone_file","total_km2","land_km2","us_water_km2","foreign_water_km2","beyond_200nmi_km2"]);
T.foreign_share_of_water=T.foreign_water_km2/(T.us_water_km2+T.foreign_water_km2);
end

function [lat,lon]=polygon_latlon(shp)
%%%%%All rows of SHP as one NaN-separated polygon (parts and holes kept).
G=geotable2table(readgeotable(shp),["Lat","Lon"]);
lat=[]; lon=[];
for k=1:height(G)
    lat=[lat; G.Lat{k}(:); NaN]; %#ok<AGROW>
    lon=[lon; G.Lon{k}(:); NaN]; %#ok<AGROW>
end
end

function M=full_mask(lat,lon,Rg)
M=false(Rg.RasterSize);
[sub,rr,cc]=rasterize_polygon_crop_rev1(lat,lon,Rg);
if ~isempty(sub)
    M(rr,cc)=sub;
end
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
