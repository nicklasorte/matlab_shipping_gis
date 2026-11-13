function [info]=plot_band_zones_rev1(result,bands,png_path,census_shp,dpi)
%plot_band_zones_rev1  Small multiples: the zone that applies in each frequency band.
%
%   info=plot_band_zones_rev1(result,bands,png_path,census_shp,dpi) draws one
%   lower-48 panel per row of table BANDS (variables f_low_mhz, f_high_mhz,
%   distance_km). Each panel shows the U.S. land within that band's distance
%   of large-ship water (light blue), the large-ship water near the coast
%   (pale blue), and state lines, on Albers equal area (EPSG:5070). Every
%   distance in BANDS must be in result.zone.
%
%   The figure follows the NTIA rules: DRAFT//PRE-DECISIONAL at the top, a
%   takeaway title, direct labels (panel titles carry the band and the
%   distance), and a dark-blue source line. Times New Roman.
%
%   info returns the panel labels and the title.
%
%   Built-ins: projcrs/projfwd, polyshape plot, polybuffer, tiledlayout,
%   exportgraphics. Geometry for each distinct distance is built once.

arguments
    result (1,1) struct
    bands table
    png_path (1,:) char
    census_shp (1,:) char
    dpi (1,1) double {mustBePositive} = 200
end

dark_blue=[22 51 83]/255;
light_blue=[86 116 196]/255;
pale_blue=[180 194 230]/255;
land_gray=[232 233 234]/255;
line_gray=[138 141 145]/255;
font_name='Times New Roman';
albers=projcrs(5070);
warn_state=warning('off','MATLAB:polyshape:repairedBySimplify');
cleanup_warn=onCleanup(@() warning(warn_state));

period='2024';
if isfield(result,'period_label')
    period=result.period_label;
end

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
[lat_r,lon_r]=reducem(state_lat,state_lon,0.02);
near_land=polybuffer(to_xy(union(polyshape(lon_r,lat_r)),albers),100);   %%%%%show water within 100 km of land

%%%%%Geometry per distinct distance
dist_list=unique(bands.distance_km);
geom=struct('d_km',num2cell(dist_list),'land',[],'water',[]);
for k=1:numel(dist_list)
    zone_idx=find([result.zone.distance_km]==dist_list(k),1);
    if isempty(zone_idx)
        error('shipgis:distance','No zone for %g km in result.zone. Add it to p.distances_km.',dist_list(k));
    end
    z=result.zone(zone_idx);
    geom(k).land=to_xy(z.poly_land,albers);
    geom(k).water=intersect(to_xy(subtract(z.poly,z.poly_land),albers),near_land);
end
[x_lim,y_lim]=boundingbox(land_xy);
x_lim=x_lim+[-40 40];
y_lim=y_lim+[-40 40];

%%%%%Panels
num_band=height(bands);
num_col=2;
num_row=ceil(num_band/num_col);
fig=figure('Visible','off','Units','inches','Position',[0 0 7.5 1.0+2.55*num_row],'Color','w','Theme','light');
tl=tiledlayout(fig,num_row,num_col,'TileSpacing','compact','Padding','compact');
tl.OuterPosition=[0 0.07 1 0.93-0.75/(1.0+2.55*num_row)];
info.labels=strings(num_band,1);
for b=1:num_band
    g=geom([geom.d_km]==bands.distance_km(b));
    ax=nexttile(tl);
    hold(ax,'on');
    plot(ax,land_xy,'FaceColor',land_gray,'FaceAlpha',1,'EdgeColor','none');
    plot(ax,g.water,'FaceColor',pale_blue,'FaceAlpha',1,'EdgeColor',dark_blue,'LineWidth',0.3);   %%%%%outline: the pale fill is under 3:1 on gray (review CB-77)
    plot(ax,g.land,'FaceColor',light_blue,'FaceAlpha',1,'EdgeColor','none');
    plot(ax,sx/1e3,sy/1e3,'Color',line_gray,'LineWidth',0.25);
    axis(ax,'equal');
    axis(ax,'off');
    xlim(ax,x_lim);
    ylim(ax,y_lim);
    info.labels(b)=sprintf('%g-%g MHz: %g km',bands.f_low_mhz(b),bands.f_high_mhz(b),bands.distance_km(b));
    title(ax,info.labels(b),'Color',dark_blue,'FontName',font_name,'FontSize',10,'FontWeight','bold');
end

%%%%%Marking, title, key, source line
fig_h=1.0+2.55*num_row;
annotation(fig,'textbox',[0.02 1-0.25/fig_h 0.96 0.2/fig_h],'String','DRAFT//PRE-DECISIONAL','EdgeColor','none', ...
    'Color',dark_blue,'FontWeight','bold','FontName',font_name,'FontSize',8,'HorizontalAlignment','center');
[~,widest]=max(bands.distance_km);
info.title=sprintf('Example zones by frequency: %g km applies only at %g-%g MHz', ...
    bands.distance_km(widest),bands.f_low_mhz(widest),bands.f_high_mhz(widest));
annotation(fig,'textbox',[0.02 1-0.62/fig_h 0.96 0.36/fig_h],'String',info.title,'EdgeColor','none', ...
    'Color',dark_blue,'FontWeight','bold','FontName',font_name,'FontSize',12,'HorizontalAlignment','left');
annotation(fig,'textbox',[0.02 1-0.85/fig_h 0.96 0.24/fig_h],'String', ...
    'Light blue: U.S. land in the zone.  Pale blue: large-ship water.  Distances are examples, not EMC results.', ...
    'EdgeColor','none','Color',dark_blue,'FontName',font_name,'FontSize',8.5,'HorizontalAlignment','left');
source_str=['Source: NTIA analysis of MarineCadastre AIS (large-ship routes, ' period ...
    '), NOAA shipping fairways and S-band racons, and Census 2023 coastline and state boundaries.'];
annotation(fig,'textbox',[0.02 0.0 0.96 0.5/fig_h],'String',source_str,'EdgeColor','none', ...
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
