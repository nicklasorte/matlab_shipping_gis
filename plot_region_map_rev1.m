function plot_region_map_rev1(result,d_km,latlim,lonlim,ports,title_str,png_path,census_shp,dpi)
%plot_region_map_rev1  Zoomed map of large-ship routes, the d_km zone, and named ports.
%
%   plot_region_map_rev1(result,d_km,latlim,lonlim,ports,title_str,png_path,census_shp,dpi)
%   draws, inside LATLIM and LONLIM, the land (gray), the zone for D_KM
%   (light blue, water and land), the large-ship cells (dark blue), and the
%   ports in table PORTS (name, lat, lon) as labeled dots. Albers equal
%   area (EPSG:5070), Times New Roman, DRAFT//PRE-DECISIONAL at the top.
%
%   Example: the lower Mississippi from the Gulf to Baton Rouge.

arguments
    result (1,1) struct
    d_km (1,1) double {mustBePositive}
    latlim (1,2) double
    lonlim (1,2) double
    ports table
    title_str (1,:) char
    png_path (1,:) char
    census_shp (1,:) char
    dpi (1,1) double {mustBePositive} = 200
end

dark_blue=[22 51 83]/255;
light_blue=[86 116 196]/255;
land_gray=[232 233 234]/255;
line_gray=[138 141 145]/255;
font_name='Times New Roman';
albers=projcrs(5070);
warn_state=warning('off','MATLAB:polyshape:repairedBySimplify');
cleanup_warn=onCleanup(@() warning(warn_state));

%%%%%Clip box (with a margin so fills reach the frame)
box_ll=polyshape(lonlim([1 2 2 1])+[-1 1 1 -1],latlim([1 1 2 2])+[-1 -1 1 1]);

%%%%%States in the box
S=readgeotable(census_shp);
T=geotable2table(S,["Lat","Lon"]);
state_polys=repmat(polyshape(),height(T),1);
for k=1:height(T)
    state_polys(k)=intersect(polyshape(T.Lon{k}(:),T.Lat{k}(:)),box_ll);
end
land_ll=union(state_polys);

zone_idx=find([result.zone.distance_km]==d_km,1);
if isempty(zone_idx)
    error('shipgis:distance','No zone for %g km in result.zone.',d_km);
end
zone_ll=intersect(result.zone(zone_idx).poly,box_ll);

%%%%%Ship cells in the box
R=result.R;
[row_idx,col_idx]=find(full(result.source_mask));
lat_c=R.LatitudeLimits(1)+R.CellExtentInLatitude*(row_idx-0.5);
lon_c=R.LongitudeLimits(1)+R.CellExtentInLongitude*(col_idx-0.5);
in_box=lat_c>=latlim(1)-0.5 & lat_c<=latlim(2)+0.5 & lon_c>=lonlim(1)-0.5 & lon_c<=lonlim(2)+0.5;
[cx,cy]=projfwd(albers,lat_c(in_box),lon_c(in_box));

fig=figure('Visible','off','Units','inches','Position',[0 0 7.5 5.6],'Color','w','Theme','light');
ax=axes(fig,'Position',[0.02 0.09 0.96 0.75]);
hold(ax,'on');
plot(ax,to_xy(land_ll,albers),'FaceColor',land_gray,'FaceAlpha',1,'EdgeColor',line_gray,'LineWidth',0.3);
plot(ax,to_xy(zone_ll,albers),'FaceColor',light_blue,'FaceAlpha',0.45,'EdgeColor','none');
scatter(ax,cx/1e3,cy/1e3,2,dark_blue,'filled','MarkerEdgeColor','none');
[px,py]=projfwd(albers,ports.lat,ports.lon);
scatter(ax,px/1e3,py/1e3,28,'w','filled','MarkerEdgeColor',dark_blue,'LineWidth',1.2);
text(ax,px/1e3+8,py/1e3,string(ports.name),'Color',dark_blue,'FontWeight','bold','FontName',font_name,'FontSize',9);
axis(ax,'equal');
axis(ax,'off');
[bx,by]=projfwd(albers,latlim([1 1 2 2]),lonlim([1 2 2 1]));
xlim(ax,[min(bx) max(bx)]/1e3);
ylim(ax,[min(by) max(by)]/1e3);

%%%%%Direct label for the zone, and a 50 km scale bar
x_lim=xlim(ax);
y_lim=ylim(ax);
%%%%%Key in the top-left corner, clear of the offshore routes
text(ax,x_lim(1)+10,y_lim(2)-15,'Dark blue: large-ship routes (2024 AIS)','Color',dark_blue,'FontWeight','bold', ...
    'FontName',font_name,'FontSize',9,'HorizontalAlignment','left','BackgroundColor','w','Margin',1);
text(ax,x_lim(1)+10,y_lim(2)-37,sprintf('Light blue: %g km zone',d_km),'Color',light_blue,'FontWeight','bold', ...
    'FontName',font_name,'FontSize',9,'HorizontalAlignment','left','BackgroundColor','w','Margin',1);
plot(ax,x_lim(1)+[15 65],y_lim(1)+[20 20],'Color',dark_blue,'LineWidth',1.5);
text(ax,x_lim(1)+40,y_lim(1)+32,'50 km','Color',dark_blue,'FontName',font_name,'FontSize',8,'HorizontalAlignment','center');

annotation(fig,'textbox',[0.02 0.94 0.96 0.05],'String','DRAFT//PRE-DECISIONAL','EdgeColor','none', ...
    'Color',dark_blue,'FontWeight','bold','FontName',font_name,'FontSize',8,'HorizontalAlignment','center');
annotation(fig,'textbox',[0.02 0.84 0.96 0.09],'String',title_str,'EdgeColor','none', ...
    'Color',dark_blue,'FontWeight','bold','FontName',font_name,'FontSize',12,'HorizontalAlignment','left');
annotation(fig,'textbox',[0.02 0.0 0.96 0.07],'String', ...
    ['Source: NTIA analysis of MarineCadastre AIS (52 days in 2024; merchant, military, and other seagoing ships ' ...
    '100 m or longer), NOAA shipping fairways and S-band racons, and Census 2023 boundaries.'],'EdgeColor','none', ...
    'Color',dark_blue,'FontName',font_name,'FontSize',8,'HorizontalAlignment','left');
exportgraphics(fig,png_path,'Resolution',dpi,'BackgroundColor','white');
close(fig);
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
