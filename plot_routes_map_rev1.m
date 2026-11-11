function [info]=plot_routes_map_rev1(result,d_km,png_path,census_shp,dpi)
%plot_routes_map_rev1  Map of large-ship routes, optionally with the d_km buffer.
%
%   info=plot_routes_map_rev1(result,d_km,png_path,census_shp,dpi) draws the
%   grid cells that large ships used in the sampled AIS days (dark blue)
%   on the lower 48 (Albers equal area, EPSG:5070). When D_KM is not empty,
%   it also fills the zone for that distance, water and land (light blue).
%   Pass D_KM=[] for the routes alone. The PNG goes to PNG_PATH at DPI.
%
%   RESULT must be the struct returned by shipping_zone_rev1 (it holds
%   source_mask), or a saved .mat made with p.save_grids=true.
%
%   Built-ins: projfwd for the projection, scatter for the 1 km route
%   cells (a regular raster image can't be drawn in a conic projection),
%   polyshape plot for the buffer, exportgraphics for the file.

arguments
    result (1,1) struct
    d_km double
    png_path (1,:) char
    census_shp (1,:) char
    dpi (1,1) double {mustBePositive} = 200
end

if ~isfield(result,'source_mask')
    error('shipgis:grids','RESULT has no source_mask. Use the struct shipping_zone_rev1 returns, or save with p.save_grids=true.');
end
source_mask=full(result.source_mask);

dark_blue=[22 51 83]/255;      %%%%%#163353 routes and text
light_blue=[86 116 196]/255;   %%%%%#5674C4 buffer
land_gray=[232 233 234]/255;   %%%%%#E8E9EA land
line_gray=[138 141 145]/255;   %%%%%#8A8D91 state lines
font_name='Times New Roman';
[period,ais_note]=labels(result);
albers=projcrs(5070);

warn_state=warning('off','MATLAB:polyshape:repairedBySimplify');
cleanup_warn=onCleanup(@() warning(warn_state));

%%%%%States and land
S=readgeotable(census_shp);
S=S(~ismember(string(S.STUSPS),["AK","HI","PR","VI","GU","MP","AS"]),:);
T=geotable2table(S,["Lat","Lon"]);
state_lat=cellfun(@(v) [v(:);NaN],T.Lat,'UniformOutput',false);
state_lon=cellfun(@(v) [v(:);NaN],T.Lon,'UniformOutput',false);
state_lat=vertcat(state_lat{:});
state_lon=vertcat(state_lon{:});
[sx,sy]=projfwd(albers,state_lat,state_lon);
land_xy=to_xy(union(polyshape(state_lon,state_lat)),albers);

%%%%%Route cells: centers of the ship cells, from 1-D coordinate vectors
R=result.R;
[row_idx,col_idx]=find(source_mask);
lat_c=R.LatitudeLimits(1)+R.CellExtentInLatitude*(row_idx-0.5);
lon_c=R.LongitudeLimits(1)+R.CellExtentInLongitude*(col_idx-0.5);
[cx,cy]=projfwd(albers,lat_c,lon_c);
info.num_route_cells=numel(row_idx);

%%%%%Crop: the lower 48 and every route cell, plus a 40 km margin, so no
%%%%%offshore lane (Pacific approaches, western Gulf) is cut at the frame
[x_lim,y_lim]=boundingbox(land_xy);
x_lim=[min(x_lim(1),min(cx)/1e3) max(x_lim(2),max(cx)/1e3)]+[-40 40];
y_lim=[min(y_lim(1),min(cy)/1e3) max(y_lim(2),max(cy)/1e3)]+[-40 40];
keep=true(size(cx));

fig=figure('Visible','off','Units','inches','Position',[0 0 7.5 5.2],'Color','w','Theme','light');
ax=axes(fig,'Position',[0.02 0.10 0.96 0.72]);
hold(ax,'on');
plot(ax,land_xy,'FaceColor',land_gray,'FaceAlpha',1,'EdgeColor','none');
if ~isempty(d_km)
    zone_idx=find([result.zone.distance_km]==d_km,1);
    if isempty(zone_idx)
        error('shipgis:distance','No zone for %g km in result.zone.',d_km);
    end
    zone_xy=to_xy(result.zone(zone_idx).poly,albers);
    plot(ax,zone_xy,'FaceColor',light_blue,'FaceAlpha',0.45,'EdgeColor','none');
end
plot(ax,sx/1e3,sy/1e3,'Color',line_gray,'LineWidth',0.3);
scatter(ax,cx(keep)/1e3,cy(keep)/1e3,0.5,dark_blue,'filled','MarkerEdgeColor','none');
axis(ax,'equal');
axis(ax,'off');
xlim(ax,x_lim);
ylim(ax,y_lim);

%%%%%Direct labels in the Atlantic
[lx,ly]=projfwd(albers,[31.5 35.0],[-70.5 -69.0]);
text(ax,lx(1)/1e3,ly(1)/1e3,sprintf('Large-ship routes\n(%s AIS)',period),'Color',dark_blue,'FontWeight','bold', ...
    'FontName',font_name,'FontSize',9,'HorizontalAlignment','center');
if ~isempty(d_km)
    text(ax,lx(2)/1e3,ly(2)/1e3,sprintf('%g km buffer',d_km),'Color',light_blue,'FontWeight','bold', ...
        'FontName',font_name,'FontSize',9,'HorizontalAlignment','center');
end

%%%%%Scale bar: 500 km
x0=x_lim(1)+80;
y0=y_lim(1)+60;
plot(ax,[x0 x0+500],[y0 y0],'Color',dark_blue,'LineWidth',1.5);
text(ax,x0+250,y0+80,'500 km','Color',dark_blue,'FontName',font_name,'FontSize',8,'HorizontalAlignment','center');

%%%%%Marking, title, source line
annotation(fig,'textbox',[0.02 0.94 0.96 0.05],'String','DRAFT//PRE-DECISIONAL','EdgeColor','none', ...
    'Color',dark_blue,'FontWeight','bold','FontName',font_name,'FontSize',8,'HorizontalAlignment','center');
if isempty(d_km)
    title_str=sprintf('Large ships stay on the coasts, the Great Lakes, and a few deep rivers (%s)',period);
else
    title_str=sprintf('Large-ship routes and the %g km buffer, lower 48 (%s)',d_km,period);
end
annotation(fig,'textbox',[0.02 0.85 0.96 0.09],'String',title_str,'EdgeColor','none', ...
    'Color',dark_blue,'FontWeight','bold','FontName',font_name,'FontSize',12,'HorizontalAlignment','left');
source_str=['Source: NTIA analysis of MarineCadastre AIS (' ais_note '; merchant, military, tug-barge, and other seagoing ships ' ...
    '100 m or longer; 1 km cells used by 4 or more ships), NOAA shipping fairways and S-band racons, and Census 2023 boundaries.'];
annotation(fig,'textbox',[0.02 0.0 0.96 0.09],'String',source_str,'EdgeColor','none', ...
    'Color',dark_blue,'FontName',font_name,'FontSize',8,'HorizontalAlignment','left');

exportgraphics(fig,png_path,'Resolution',dpi,'BackgroundColor','white');
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

function [period,ais_note]=labels(result)
%%%%%Period and AIS-sample labels; older saved results have neither field
period='2024';
ais_note='52 days in 2024';
if isfield(result,'period_label')
    period=result.period_label;
    ais_note=result.ais_note;
end
end
