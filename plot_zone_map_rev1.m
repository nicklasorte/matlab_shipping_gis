function [info]=plot_zone_map_rev1(result,d_km,png_path,census_shp)
%plot_zone_map_rev1  Standalone map of the lower 48 with the land within d_km of large-ship water.
%
%   info=plot_zone_map_rev1(result,d_km,png_path,census_shp) draws the U.S.
%   land inside the zone for distance D_KM (light blue), the large-ship
%   water (pale blue), and state lines (gray) on an Albers equal-area
%   projection (EPSG:5070), and writes a 300 dpi PNG to PNG_PATH.
%   CENSUS_SHP is the Census cartographic-boundary state shapefile.
%
%   Follows the NTIA figure rules: DRAFT//PRE-DECISIONAL at the top, a
%   takeaway title, direct labels instead of a legend, a scale bar, and a
%   source line in dark blue. Times New Roman throughout.
%
%   info returns the land area in the zone, the lower-48 land area, and
%   the share (computed from the exact cell areas, rounded only in the title).
%
%   Built-ins: projcrs/projfwd for the projection, polyshape plot for the
%   fills, areamat for areas, exportgraphics for the file. A geoaxes with a
%   basemap would draw Web Mercator, which inflates northern areas.

arguments
    result (1,1) struct
    d_km (1,1) double {mustBePositive}
    png_path (1,:) char
    census_shp (1,:) char
end

dark_blue=[22 51 83]/255;      %%%%%#163353 text
light_blue=[86 116 196]/255;   %%%%%#5674C4 the one highlight
pale_blue=[180 194 230]/255;   %%%%%#B4C2E6 second ramp step, context water
land_gray=[232 233 234]/255;   %%%%%#E8E9EA land fill
line_gray=[138 141 145]/255;   %%%%%#8A8D91 state lines
font_name='Times New Roman';

zone_idx=find([result.zone.distance_km]==d_km,1);
if isempty(zone_idx)
    error('shipgis:distance','No zone for %g km in result.zone.',d_km);
end
zone=result.zone(zone_idx);

%%%%%Exact areas from the grid; round only for display
ellipsoid_km=wgs84Ellipsoid('km');
info.land_area_km2=zone.land_area_km2;
info.lower48_land_km2=areamat(result.land_mask,result.R,ellipsoid_km);
info.share=info.land_area_km2/info.lower48_land_km2;

%%%%%Geometry: states, land zone, and ship water (zone minus land)
warn_state=warning('off','MATLAB:polyshape:repairedBySimplify');
cleanup_warn=onCleanup(@() warning(warn_state));
S=readgeotable(census_shp);
S=S(~ismember(string(S.STUSPS),["AK","HI","PR","VI","GU","MP","AS"]),:);
T=geotable2table(S,["Lat","Lon"]);
state_lat=cellfun(@(v) [v(:);NaN],T.Lat,'UniformOutput',false);
state_lon=cellfun(@(v) [v(:);NaN],T.Lon,'UniformOutput',false);
state_lat=vertcat(state_lat{:});
state_lon=vertcat(state_lon{:});

albers=projcrs(5070);   %%%%%NAD83 / Conus Albers, equal area
[sx,sy]=projfwd(albers,state_lat,state_lon);
land_xy=to_xy(union(polyshape(state_lon,state_lat)),albers);
zone_land_xy=to_xy(zone.poly_land,albers);
ship_water_xy=to_xy(subtract(zone.poly,zone.poly_land),albers);

%%%%%Show ship water only near the coast (within water_show_km of land), so
%%%%%ocean lanes far offshore don't dominate the picture. polybuffer runs on
%%%%%a coarse copy of the land outline (reducem, about 2 km tolerance) in
%%%%%Albers km, where planar distance is accurate to about 1 percent.
water_show_km=100;
[lat_r,lon_r]=reducem(state_lat,state_lon,0.02);
coarse_land=to_xy(union(polyshape(lon_r,lat_r)),albers);
near_land=polybuffer(coarse_land,water_show_km);
ship_water_xy=intersect(ship_water_xy,near_land);

%%%%%Figure: 7.5 x 5.2 in, white background
fig=figure('Visible','off','Units','inches','Position',[0 0 7.5 5.2],'Color','w');
ax=axes(fig,'Position',[0.02 0.10 0.96 0.72]);
hold(ax,'on');
plot(ax,land_xy,'FaceColor',land_gray,'FaceAlpha',1,'EdgeColor','none');
plot(ax,ship_water_xy,'FaceColor',pale_blue,'FaceAlpha',1,'EdgeColor','none');
plot(ax,zone_land_xy,'FaceColor',light_blue,'FaceAlpha',1,'EdgeColor','none');
plot(ax,sx/1e3,sy/1e3,'Color',line_gray,'LineWidth',0.3);
axis(ax,'equal');
axis(ax,'off');

%%%%%Crop to the lower 48 plus the near-shore water shown
[x_lim,y_lim]=boundingbox(union(land_xy,ship_water_xy));
xlim(ax,x_lim+[-20 20]);
ylim(ax,y_lim+[-20 20]);

%%%%%Direct labels: land label on gray land with a leader to the Texas coast;
%%%%%water label in the Atlantic
[lx,ly]=projfwd(albers,[33.6 29.6 33.5],[-101.5 -95.2 -72.6]);
lx=lx/1e3;
ly=ly/1e3;
plot(ax,[lx(1) lx(2)],[ly(1)-40 ly(2)+15],'Color',light_blue,'LineWidth',1);
text(ax,lx(1),ly(1),sprintf('Land within %g km\nof large-ship water',d_km), ...
    'Color',light_blue,'FontWeight','bold','FontName',font_name,'FontSize',9, ...
    'HorizontalAlignment','center','VerticalAlignment','bottom');
text(ax,lx(3),ly(3),sprintf('Large-ship water\n(2024 AIS)'), ...
    'Color',dark_blue,'FontName',font_name,'FontSize',9,'HorizontalAlignment','center');

%%%%%Scale bar: 500 km
x0=x_lim(1)+80;
y0=y_lim(1)+60;
plot(ax,[x0 x0+500],[y0 y0],'Color',dark_blue,'LineWidth',1.5);
text(ax,x0+250,y0+45,'500 km','Color',dark_blue,'FontName',font_name,'FontSize',8,'HorizontalAlignment','center');

%%%%%Marking, title, source line
annotation(fig,'textbox',[0.02 0.94 0.96 0.05],'String','DRAFT//PRE-DECISIONAL','EdgeColor','none', ...
    'Color',dark_blue,'FontWeight','bold','FontName',font_name,'FontSize',8,'HorizontalAlignment','center');
title_str=sprintf('Land within %g km of large-ship water covers about %s km^2, %d%% of the lower 48', ...
    d_km,format_thousands(round(info.land_area_km2,-4)),round(100*info.share));
annotation(fig,'textbox',[0.02 0.85 0.96 0.09],'String',title_str,'EdgeColor','none','Interpreter','tex', ...
    'Color',dark_blue,'FontWeight','bold','FontName',font_name,'FontSize',12,'HorizontalAlignment','left');
source_str=['Source: NTIA analysis of MarineCadastre AIS (52 days in 2024; cargo, tanker, and passenger ships ' ...
    '100 m or longer), NOAA shipping fairways, and Census 2023 coastline and state boundaries.'];
annotation(fig,'textbox',[0.02 0.0 0.96 0.09],'String',source_str,'EdgeColor','none', ...
    'Color',dark_blue,'FontName',font_name,'FontSize',8,'HorizontalAlignment','left');

exportgraphics(fig,png_path,'Resolution',300,'BackgroundColor','white');
close(fig);
info.title=title_str;
end

function p_xy=to_xy(p_lonlat,albers)
%%%%%Project a lon/lat polyshape to Albers km; polyshape keeps the holes.
if p_lonlat.NumRegions==0
    p_xy=polyshape();
    return
end
[lon_b,lat_b]=boundary(p_lonlat);
[x,y]=projfwd(albers,lat_b,lon_b);
p_xy=polyshape(x/1e3,y/1e3);
end

function s=format_thousands(v)
%%%%%Integer with comma separators (num2str and string add none).
s=char(compose("%d",v));
n=numel(s);
for k=n-3:-3:1
    s=[s(1:k) ',' s(k+1:end)];
end
end
