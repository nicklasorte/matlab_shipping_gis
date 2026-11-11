function [titles]=plot_ship_viz_rev1(prod,out_dir,census_shp,sweep_csv,funnel_csv,dpi)
%plot_ship_viz_rev1  Draw the ten ship-data figures (MATLAB versions).
%
%   titles=plot_ship_viz_rev1(prod,out_dir,census_shp,sweep_csv,funnel_csv,dpi)
%   draws ten standalone NTIA-style figures from PROD (viz_products_rev1)
%   and writes PNGs to OUT_DIR:
%
%     fig01_traffic_density          distinct ships per route cell (map)
%     fig02_baltimore_key_bridge     ships in Baltimore harbor by week, 2023 vs 2024
%     fig03_seasons_by_coast         ships per sampled day, four coasts
%     fig04_length_cutoff_sweep      length test vs gross tonnage, 50-200 m
%     fig05_filter_funnel            ships left after each filter step
%     fig06_stability_between_years  route cells in both years vs one year (map)
%     fig07_tug_barge_cells          cells only tug-barges add (map)
%     fig08_mississippi_profile      ships by river distance above Head of Passes
%     fig09_sites_near_routes        distance from ports, racons, VTS to a route
%     fig10_offshore_distance        route-cell distance to the coastline
%
%   Each figure follows the NTIA rules: DRAFT//PRE-DECISIONAL at the top, a
%   takeaway title whose number comes from PROD, direct labels, gray context
%   plus one light-blue highlight, dark-blue source line, Times New Roman.
%   TITLES returns the ten titles. The Python versions are in
%   python/ship_viz_figures.py.
%
%   Built-ins: projcrs/projfwd (Albers, EPSG:5070), scatter, stairs,
%   barh, tiledlayout, exportgraphics.

arguments
    prod (1,1) struct
    out_dir (1,:) char
    census_shp (1,:) char
    sweep_csv (1,:) char
    funnel_csv (1,:) char
    dpi (1,1) double {mustBePositive} = 200
end

if ~isfolder(out_dir)
    mkdir(out_dir);
end
C=style();
C.albers=projcrs(5070);
C.states=load_states(census_shp,C.albers);
C.dpi=dpi;
C.out_dir=out_dir;
C.src=['Source: NTIA analysis of MarineCadastre AIS, 104 sampled days in 2023 and 2024; large ships = cargo, ' ...
    'tanker, passenger, military, and other seagoing ships 100 m or longer, plus tug-barges near the coast.'];
s=prod.summary;
titles=strings(10,1);

%%%%%1. Traffic density
in_route=ismember(prod.both_cell,prod.route_cells);
cells=prod.both_cell(in_route);
ships=prod.both_ships(in_route);
titles(1)=sprintf('The busiest %.0f%% of route cells carry half of all large-ship traffic',100*s.share_cells_half_traffic);
[fig,ax]=new_map(C,titles(1),'Distinct large ships per 1 km route cell, 2023 and 2024 together',C.src);
[x,y]=cells_xy(prod.R,cells,C.albers);
edges=[4 10 50 200 1000 Inf];
bin=discretize(ships,edges);
[~,o]=sort(ships);
scatter(ax,x(o),y(o),0.6,C.ramp(bin(o),:),'s','filled','MarkerEdgeColor','none');
labels=["4-9","10-49","50-199","200-999","1,000+"];
for k=1:5
    rectangle(ax,'Position',[-2850+(k-1)*420 120 410 70],'FaceColor',C.ramp(k,:),'EdgeColor','none');
    text(ax,-2850+(k-1)*420+205,60,labels(k),'HorizontalAlignment','center','VerticalAlignment','top', ...
        'FontName',C.font,'FontSize',8,'Color',C.dark);
end
text(ax,-2850,240,'Distinct ships per cell','FontName',C.font,'FontSize',8.5,'FontWeight','bold','Color',C.dark);
finish(C,fig,'fig01_traffic_density');

%%%%%2. Baltimore and the Key Bridge closure
d=prod.daily;
doy=day(d.day,'dayofyear');
c0=day(datetime(2024,3,26),'dayofyear');
c1=day(datetime(2024,6,10),'dayofyear');
in24=d.year==2024 & doy>=c0 & doy<=c1;
in23=d.year==2023 & doy>=c0-3 & doy<=c1+3;
drop=1-mean(d.Baltimore(in24))/mean(d.Baltimore(in23));
titles(2)=sprintf('Large ships in Baltimore harbor fell %.0f%% during the 2024 Key Bridge closure',100*drop);
[fig,ax]=new_chart(C,titles(2),'Distinct large ships within 8 km of the Patapsco River harbor on each sampled Wednesday', ...
    [C.src ' Closure: Fort McHenry Federal Channel, March 26 to June 10, 2024 (USACE).']);
wk=(doy-1)/7+1;
patch(ax,[c0 c1 c1 c0]/7+1,[0 0 34 34],C.panel,'EdgeColor','none');
text(ax,(c0+c1)/14+1,31,'Key Bridge closure','HorizontalAlignment','center','FontName',C.font,'FontSize',9,'Color',C.dark);
m=d.year==2023;
plot(ax,wk(m),d.Baltimore(m),'Color',C.gray,'LineWidth',1.2);
text(ax,wk(find(m,1,'last'))+0.7,d.Baltimore(find(m,1,'last')),'2023','FontName',C.font,'FontSize',9,'FontWeight','bold','Color',C.dark);
m=d.year==2024;
plot(ax,wk(m),d.Baltimore(m),'Color',C.blue,'LineWidth',2);
text(ax,wk(find(m,1,'last'))+0.7,d.Baltimore(find(m,1,'last')),'2024','FontName',C.font,'FontSize',9,'FontWeight','bold','Color',C.dark);
xlim(ax,[1 55]);
ylim(ax,[0 34]);
xlabel(ax,'Week of the year');
ylabel(ax,'Large ships');
finish(C,fig,'fig02_baltimore_key_bridge');

%%%%%3. Seasons by coast
mon=month(d.day);
gl=d.Great_Lakes;
titles(3)=sprintf('Great Lakes traffic falls by half in winter (%.0f vs. %.0f ships); the ocean coasts barely change', ...
    mean(gl(ismember(mon,1:3))),mean(gl(ismember(mon,6:9))));
fig=new_page(C,titles(3),'Distinct large ships on each sampled Wednesday, 2023 and 2024', ...
    [C.src ' Coasts are split by simple latitude and longitude boxes.'],6.2);
tl=tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
tl.Position=[0.07 0.13 0.9 0.6];
names=["Great_Lakes","Atlantic","Gulf","Pacific"];
for k=1:4
    ax=nexttile(tl);
    style_axes(C,ax);
    v=d.(names(k));
    hl=k==1;
    plot(ax,d.day,v,'Color',ifelse(hl,C.blue,C.gray),'LineWidth',ifelse(hl,1.8,1.2));
    ylim(ax,[0 max(v)*1.15]);
    title(ax,strrep(names(k),'_',' '),'FontName',C.font,'FontSize',10,'Color',C.dark,'HorizontalAlignment','left');
    ax.TitleHorizontalAlignment='left';
end
finish(C,fig,'fig03_seasons_by_coast');

%%%%%4. Length cutoff sweep
sw=readtable(sweep_csv);
i100=find(sw.cutoff_m==100,1);
titles(4)=sprintf('At 100 m, the length test is right %.1f%% of the time and keeps %.1f%% of big ships', ...
    100*sw.precision(i100),100*sw.recall(i100));
[fig,ax]=new_chart(C,titles(4),['Length cutoff tested against registry gross tonnage (3,000 GT, the SOLAS size for a 3 GHz ' ...
    'radar), 4,129 cargo, tanker, and passenger ships'], ...
    'Source: NTIA analysis of MarineCadastre AIS (four days in 2024) matched by IMO number to Wikidata gross tonnage.');
plot(ax,sw.cutoff_m,100*sw.precision,'Color',C.gray,'LineWidth',1.6);
plot(ax,sw.cutoff_m,100*sw.recall,'Color',C.blue,'LineWidth',2);
xline(ax,100,'--','Color',C.dark,'LineWidth',1);
text(ax,101.5,60,'100 m cutoff','FontName',C.font,'FontSize',9,'Color',C.dark);
text(ax,150,101,'Kept ships that are 3,000 GT or more','HorizontalAlignment','center','VerticalAlignment','bottom', ...
    'FontName',C.font,'FontSize',9,'Color',C.dark);
text(ax,103,88,'3,000 GT ships the test keeps','VerticalAlignment','top','FontName',C.font,'FontSize',9, ...
    'FontWeight','bold','Color',C.blue);
xlim(ax,[50 200]);
ylim(ax,[floor(100*min([sw.precision; sw.recall])/5)*5-5 104]);
xlabel(ax,'Length cutoff (m)');
ylabel(ax,'Percent');
finish(C,fig,'fig04_length_cutoff_sweep');

%%%%%5. Filter funnel (July 10, 2024)
fn=readtable(funnel_csv,'TextType','string');
f24=fn(fn.day==datetime(2024,7,10),:);
steps=["All ships reporting","Ship type kept","Length 100 m or more","IMO number","Inside the analysis grid"];
titles(5)=sprintf('About 1 ship in %d reporting on AIS passes the large-ship filter',round(f24.ships(1)/f24.ships(end)));
[fig,ax]=new_chart(C,titles(5),['Distinct ships left after each filter step on July 10, 2024 (each step keeps only ' ...
    'ships that passed the steps above it)'],'Source: NTIA analysis of the full MarineCadastre AIS file for July 10, 2024.');
ax.Position=[0.25 0.14 0.68 0.6];
yy=numel(steps):-1:1;
barh(ax,yy(1:end-1),f24.ships(1:end-1),0.62,'FaceColor',C.gray,'EdgeColor','none');
barh(ax,yy(end),f24.ships(end),0.62,'FaceColor',C.blue,'EdgeColor','none');
for k=1:numel(steps)
    text(ax,f24.ships(k)+250,yy(k),comma(f24.ships(k)),'FontName',C.font,'FontSize',9.5,'Color',C.dark, ...
        'FontWeight',ifelse(k==numel(steps),'bold','normal'));
end
set(ax,'YTick',flip(yy),'YTickLabel',flip(steps),'XTick',[],'XColor','none','YGrid','off');
xlim(ax,[0 f24.ships(1)*1.12]);
finish(C,fig,'fig05_filter_funnel');

%%%%%6. Stability between years
titles(6)=sprintf('%.0f%% of large-ship traffic is in cells that pass the threshold in both years',100*s.share_traffic_both_years);
[fig,ax]=new_map(C,titles(6),sprintf(['Route cells with 4 or more ships in both 2023 and 2024 (%s cells, blue) or in only ' ...
    'one year (%s cells, gray)'],comma(s.both_years),comma(s.only_one_year)),C.src);
[x,y]=cells_xy(prod.R,prod.only_one_year,C.albers);
scatter(ax,x,y,0.4,C.gray,'s','filled','MarkerEdgeColor','none');
[x,y]=cells_xy(prod.R,prod.both_years,C.albers);
scatter(ax,x,y,0.4,C.blue,'s','filled','MarkerEdgeColor','none');
finish(C,fig,'fig06_stability_between_years');

%%%%%7. Tug-barge cells
titles(7)=sprintf('Tug-barges add %.0f%% more route cells, mostly near Atlantic, Gulf, and Great Lakes ports', ...
    100*s.tow_only_cells/s.route_cells_main_only);
[fig,ax]=new_map(C,titles(7),sprintf(['Route cells that only tug-barges put over the threshold (%s cells, blue) on the ' ...
    'other large-ship routes (gray)'],comma(s.tow_only_cells)),C.src);
[x,y]=cells_xy(prod.R,prod.route_cells,C.albers);
scatter(ax,x,y,0.3,[0.79 0.80 0.81],'s','filled','MarkerEdgeColor','none');
[x,y]=cells_xy(prod.R,prod.tow_only,C.albers);
scatter(ax,x,y,3,C.blue,'s','filled','MarkerEdgeColor','none');
lab=struct('Atlantic',[1950 1250],'Gulf',[650 120],'GreatLakes',[250 2450],'Pacific',[-2700 1500]);
for f=fieldnames(lab)'
    xy=lab.(f{1});
    text(ax,xy(1),xy(2),sprintf('%s\n%s cells',strrep(f{1},'GreatLakes','Great Lakes'),comma(s.(['tow_only_' f{1}]))), ...
        'HorizontalAlignment','center','FontName',C.font,'FontSize',8.5,'Color',C.dark);
end
finish(C,fig,'fig07_tug_barge_cells');

%%%%%8. Mississippi profile
rv=prod.river;
km=(rv.river_km_from+rv.river_km_to)/2;
titles(8)=sprintf('Traffic thins above New Orleans, but large ships still reach Baton Rouge, %.0f river km upstream', ...
    prod.river_km.baton_rouge);
[fig,ax]=new_chart(C,titles(8),'Distinct large ships in each 5 km reach of the Mississippi River, 104 sampled days in 2023 and 2024', ...
    [C.src ' River distance is measured through the route cells from Head of Passes.']);
stairs(ax,[rv.river_km_from; rv.river_km_to(end)],[rv.ships; rv.ships(end)],'Color',C.blue,'LineWidth',1.8);
top=max(rv.ships);
for pl={prod.river_km.new_orleans,'New Orleans','left',3; prod.river_km.baton_rouge,'Baton Rouge','right',-3}'
    xline(ax,pl{1},'--','Color',C.dark,'LineWidth',1);
    text(ax,pl{1}+pl{4},top*1.04,pl{2},'HorizontalAlignment',pl{3},'FontName',C.font,'FontSize',9,'Color',C.dark);
end
xlim(ax,[0 max(km)+15]);
ylim(ax,[0 top*1.12]);
xlabel(ax,'River distance above Head of Passes (km)');
ylabel(ax,'Distinct large ships');
finish(C,fig,'fig08_mississippi_profile');

%%%%%9. Sites near routes (strip plot, log distance)
st=prod.sites;
groups=["named_port","Named major ports";"deep_draft_port","Deep-draft ports";"other_coastal_port","Other coastal ports"; ...
    "racon","S-band racons";"vts_area","VTS areas";"inland_port","Inland river ports"];
dd=st.route_km(st.group=="deep_draft_port");
titles(9)=sprintf(['Every named major port and %.0f%% of deep-draft ports sit within 5 km of a large-ship route; ' ...
    'inland river ports do not'],100*mean(dd<=5));
[fig,ax]=new_chart(C,titles(9),'Distance from each site to the nearest large-ship route cell (log scale); each dot is one site', ...
    [C.src ' Ports: USACE Principal Ports (deep-draft = coastal or Great Lakes, 1 million tons or more of foreign trade). ' ...
    'Racons: NOAA ENC Direct. VTS: U.S. Coast Guard.']);
rs=RandStream('mrg32k3a','Seed',1);
ng=size(groups,1);
for k=1:ng
    v=max(st.route_km(st.group==groups(k,1)),0.1);
    yk=ng-k+1+(rand(rs,numel(v),1)-0.5)*0.36;
    hl=k<=2;
    scatter(ax,v,yk,14,ifelse(hl,C.blue,C.gray),'filled','MarkerFaceAlpha',0.85,'MarkerEdgeColor','none');
    text(ax,0.11,ng-k+1.26,sprintf('%s (%d)',groups(k,2),numel(v)),'VerticalAlignment','bottom','FontName',C.font, ...
        'FontSize',9,'Color',C.dark,'FontWeight',ifelse(hl,'bold','normal'));
end
xline(ax,5,'--','Color',C.dark,'LineWidth',1);
text(ax,5.4,ng+0.55,'5 km','FontName',C.font,'FontSize',9,'Color',C.dark);
set(ax,'XScale','log','YTick',[],'YColor','none','YGrid','off','XGrid','on');
xlim(ax,[0.1 1000]);
ylim(ax,[0.5 ng+0.9]);
ax.Position=[0.09 0.21 0.84 0.5];
xticks(ax,[0.1 1 10 100 1000]);
xticklabels(ax,{'0.1','1','10','100','1,000'});
xlabel(ax,'Distance to the nearest large-ship route cell (km)');
finish(C,fig,'fig09_sites_near_routes');

%%%%%10. Offshore distance
of=prod.offshore;
titles(10)=sprintf(['Half of Pacific and Gulf route cells lie more than %.0f km offshore; 90%% of Great Lakes route ' ...
    'cells are within %.0f km of shore'],floor(min(s.offshore_median_km_Pacific,s.offshore_median_km_Gulf)/10)*10, ...
    s.offshore_p90_km_GreatLakes);
[fig,ax]=new_chart(C,titles(10),'Share of large-ship route cells within a given distance of the Census coastline, by coast', ...
    [C.src ' Coastline: Census TIGER/Line 2023. The analysis grid ends at 130 W and 22 N.']);
ax.Position(3)=0.74;
for g=["Great Lakes","Atlantic","Gulf","Pacific"]
    v=sort(of.coast_km(of.coast==g));
    pc=(1:numel(v))'/numel(v)*100;
    hl=g=="Pacific";
    plot(ax,v,pc,'Color',ifelse(hl,C.blue,C.gray),'LineWidth',ifelse(hl,2,1.3));
    x_end=min(v(end),600);
    y_end=pc(find(v<=x_end,1,'last'));
    text(ax,x_end+8,y_end,g,'FontName',C.font,'FontSize',9,'Color',C.dark,'FontWeight',ifelse(hl,'bold','normal'), ...
        'Clipping','off');
end
xlim(ax,[0 600]);
ylim(ax,[0 103]);
xlabel(ax,'Distance from the coastline (km)');
ylabel(ax,'Percent of route cells');
finish(C,fig,'fig10_offshore_distance');
end

%%%%%-------------------------------------------------------------------------
function C=style()
C.dark=[22 51 83]/255;      %%%%%#163353
C.blue=[86 116 196]/255;    %%%%%#5674C4
C.gray=[138 141 145]/255;   %%%%%#8A8D91
C.panel=[232 233 234]/255;  %%%%%#E8E9EA
C.grid=[230 230 230]/255;
C.ramp=[228 233 246; 180 194 230; 127 150 211; 63 95 168; 22 51 83]/255;
C.font='Times New Roman';
end

function fig=new_page(C,title_str,subtitle,source,h_in)
fig=figure('Visible','off','Units','inches','Position',[0 0 7.5 h_in],'Color','w','Theme','light');
annotation(fig,'textbox',[0.02 1-0.32/h_in 0.96 0.25/h_in],'String','DRAFT//PRE-DECISIONAL','EdgeColor','none', ...
    'Color',C.dark,'FontWeight','bold','FontName',C.font,'FontSize',8,'HorizontalAlignment','left');
annotation(fig,'textbox',[0.02 1-1.0/h_in 0.96 0.62/h_in],'String',title_str,'EdgeColor','none','Color',C.dark, ...
    'FontWeight','bold','FontName',C.font,'FontSize',13,'HorizontalAlignment','left','VerticalAlignment','top');
annotation(fig,'textbox',[0.02 1-1.42/h_in 0.96 0.4/h_in],'String',subtitle,'EdgeColor','none','Color',C.dark, ...
    'FontName',C.font,'FontSize',9.5,'HorizontalAlignment','left','VerticalAlignment','top');
annotation(fig,'textbox',[0.02 0.01 0.96 0.55/h_in],'String',source,'EdgeColor','none','Color',C.dark, ...
    'FontName',C.font,'FontSize',8,'HorizontalAlignment','left','VerticalAlignment','bottom');
end

function [fig,ax]=new_chart(C,title_str,subtitle,source)
h_in=5.4;
fig=new_page(C,title_str,subtitle,source,h_in);
ax=axes(fig,'Position',[0.09 0.15 0.84 1-0.15-1.6/h_in]);
style_axes(C,ax);
end

function style_axes(C,ax)
hold(ax,'on');
set(ax,'FontName',C.font,'FontSize',9,'XColor',C.dark,'YColor',C.dark,'Box','off','TickDir','out', ...
    'YGrid','on','GridColor',C.grid,'GridAlpha',1,'Layer','bottom');
end

function [fig,ax]=new_map(C,title_str,subtitle,source)
h_in=6.0;
fig=new_page(C,title_str,subtitle,source,h_in);
ax=axes(fig,'Position',[0.02 0.10 0.96 1-0.10-1.55/h_in]);
hold(ax,'on');
plot(ax,C.states,'FaceColor',C.panel,'FaceAlpha',1,'EdgeColor','w','LineWidth',0.3);
axis(ax,'equal');
axis(ax,'off');
xlim(ax,[-2950 2550]);
ylim(ax,[-150 3300]);
end

function finish(C,fig,name)
exportgraphics(fig,fullfile(C.out_dir,[name '.png']),'Resolution',C.dpi,'BackgroundColor','white');
close(fig);
end

function P=load_states(census_shp,albers)
%%%%%Lower-48 state outlines as one Albers polyshape array (km)
S=readgeotable(census_shp);
S=S(~ismember(string(S.STUSPS),["AK","HI","PR","VI","GU","MP","AS"]),:);
T=geotable2table(S,["Lat","Lon"]);
warn_state=warning('off','MATLAB:polyshape:repairedBySimplify');
cleanup=onCleanup(@() warning(warn_state));
P=repmat(polyshape(),height(T),1);
for k=1:height(T)
    [x,y]=projfwd(albers,T.Lat{k}(:),T.Lon{k}(:));
    P(k)=polyshape(x/1e3,y/1e3);
end
end

function [x,y]=cells_xy(R,cells,albers)
%%%%%Cell centers (1-based linear index, rows from the south) in Albers km
[row,col]=ind2sub(R.RasterSize,cells(:));
lat=R.LatitudeLimits(1)+R.CellExtentInLatitude*(row-0.5);
lon=R.LongitudeLimits(1)+R.CellExtentInLongitude*(col-0.5);
[x,y]=projfwd(albers,lat,lon);
x=x/1e3;
y=y/1e3;
end

function out=ifelse(tf,a,b)
if tf
    out=a;
else
    out=b;
end
end

function s=comma(n)
s=char(string(round(n)));
s=fliplr(regexprep(fliplr(s),'(\d{3})(?=\d)','$1,'));
end
