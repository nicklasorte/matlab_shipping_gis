function [titles]=plot_ship_geo_rev1(prod,geo,out_dir,census_shp,sites_csv,dpi)
%plot_ship_geo_rev1  Draw the nine geographic figures (MATLAB versions).
%
%   titles=plot_ship_geo_rev1(prod,geo,out_dir,census_shp,sites_csv,dpi)
%   draws, from PROD (viz_products_rev1) and GEO (geo_products_rev1), and
%   writes PNGs to OUT_DIR:
%
%     geo01_hex_grid        distinct large ships per 25 km hexagon
%     geo02_spike_map       the same as vertical spikes
%     geo03_port_closeups   six port areas at 1 km
%     geo04_offshore_bands  route cells by distance from shore
%     geo05_coast_profile   near-shore ships along each coast
%     geo06_port_bubbles    ships within 10 km of each deep-draft port
%     geo07_ship_types      where tankers, cargo, passenger, government ships go
%     geo08_land_distance   distance from land to the nearest route
%     geo09_sband_sites     racons and VTS areas over the hexagons
%
%   NTIA style: DRAFT//PRE-DECISIONAL, takeaway titles with computed numbers,
%   NTIA palette, Times New Roman, dark-blue source line. The Python versions
%   are in python/ship_geo_figures.py.
%
%   Built-ins: projcrs/projfwd (EPSG:5070), patch (hexagons and spikes),
%   scatter, bar, tiledlayout, exportgraphics.

arguments
    prod (1,1) struct
    geo (1,1) struct
    out_dir (1,:) char
    census_shp (1,:) char
    sites_csv (1,:) char
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
s=geo.summary;
H=geo.hex;
titles=strings(9,1);
hex_edges=[1 10 100 500 1000 Inf];
hex_labels=["1-9","10-99","100-499","500-999","1,000+"];

%%%%%G1. Hex grid
titles(1)=sprintf('The busiest 5%% of hexagons carry %.0f%% of large-ship traffic',100*s.hex_share_top5pct);
[fig,ax]=new_map(C,titles(1),'Distinct large ships per 25 km hexagon on the large-ship routes, 2023 and 2024 together', ...
    [C.src ' Hexagons are drawn on an equal-area (Albers) projection.']);
[~,o]=sort(H.ships);
draw_hex(ax,H.x_km(o),H.y_km(o),C.ramp(discretize(H.ships(o),hex_edges),:),'w');
ramp_key(C,ax,hex_labels,'Distinct ships per hexagon',420);
finish(C,fig,'geo01_hex_grid');

%%%%%G2. Spike map
titles(2)='Galveston Bay, the lower Mississippi, Los Angeles-Long Beach, and New York tower over the rest of the coast';
[fig,ax]=new_map(C,titles(2),sprintf(['Spike height = distinct large ships per 25 km hexagon with 10 or more ships, ' ...
    '2023 and 2024 together (tallest spike: %s ships)'],comma(s.hex_max_ships)),C.src);
ylim(ax,[-150 3550]);
k=H.ships>=10;
[~,o]=sort(H.y_km(k),'descend');
x=H.x_km(k);
y=H.y_km(k);
n=H.ships(k);
x=x(o);
y=y(o);
n=n(o);
sc=420/max(H.ships);
V=reshape([x-7 y x y+n*sc x+7 y]',2,[])';
F=reshape(1:3*numel(x),3,[])';
patch(ax,'Faces',F,'Vertices',V,'FaceColor',C.blue,'FaceAlpha',0.75,'EdgeColor',C.dark,'LineWidth',0.2);
lab={'Galveston Bay',-94.8,29.35,-20,-230,'right';'Lower Mississippi',-89.4,29.1,20,-230,'left'; ...
    'Los Angeles-Long Beach',-118.25,33.7,40,-40,'left';'New York',-74.0,40.5,60,-20,'left'};
for i=1:size(lab,1)
    [lx,ly]=projfwd(C.albers,lab{i,3},lab{i,2});
    text(ax,lx/1e3+lab{i,4},ly/1e3+lab{i,5},lab{i,1},'HorizontalAlignment',lab{i,6},'VerticalAlignment','top', ...
        'FontName',C.font,'FontSize',8.5,'FontWeight','bold','Color',C.dark);
end
finish(C,fig,'geo02_spike_map');

%%%%%G3. Port close-ups
areas={'New York-New Jersey',[40.30 40.95],[-74.35 -73.60];'Chesapeake and Delaware Bays',[36.80 39.90],[-77.00 -74.70]; ...
    'Houston-Galveston',[29.20 29.85],[-95.30 -94.50];'Lower Mississippi',[28.90 30.60],[-91.30 -89.00]; ...
    'Los Angeles-Long Beach',[33.40 33.90],[-118.55 -117.90];'Puget Sound',[47.00 48.60],[-123.30 -122.10]};
in_route=ismember(prod.both_cell,prod.route_cells);
cells=prod.both_cell(in_route);
ships=prod.both_ships(in_route);
[row,col]=ind2sub(prod.R.RasterSize,cells);
clat=prod.R.LatitudeLimits(1)+prod.R.CellExtentInLatitude*(row-0.5);
clon=prod.R.LongitudeLimits(1)+prod.R.CellExtentInLongitude*(col-0.5);
busy=ships>=200;
inside=false(size(busy));
for i=1:size(areas,1)
    inside=inside | (clat>=areas{i,2}(1) & clat<=areas{i,2}(2) & clon>=areas{i,3}(1) & clon<=areas{i,3}(2));
end
titles(3)=sprintf(['Inside the busiest port areas, large ships keep to narrow channels; these six areas hold %.0f%% ' ...
    'of the busiest route cells'],100*nnz(busy & inside)/nnz(busy));
fig=new_page(C,titles(3),'Distinct large ships per 1 km route cell, 2023 and 2024 together (busiest cells: 200 or more ships)', ...
    C.src,6.2);
tl=tiledlayout(fig,2,3,'TileSpacing','compact','Padding','compact');
tl.Position=[0.03 0.11 0.94 0.63];
S=readgeotable(census_shp);
T=geotable2table(S,["Lat","Lon"]);
warn_state=warning('off','MATLAB:polyshape:repairedBySimplify');
cleanup=onCleanup(@() warning(warn_state));
edges=[4 10 50 200 1000 Inf];
for i=1:size(areas,1)
    ax=nexttile(tl);
    hold(ax,'on');
    la=areas{i,2};
    lo=areas{i,3};
    box=polyshape(lo([1 2 2 1])+[-0.5 0.5 0.5 -0.5],la([1 1 2 2])+[-0.5 -0.5 0.5 0.5]);
    for k=1:height(T)
        b=[min(T.Lon{k}) max(T.Lon{k}) min(T.Lat{k}) max(T.Lat{k})];
        if b(1)<lo(2)+0.5 && b(2)>lo(1)-0.5 && b(3)<la(2)+0.5 && b(4)>la(1)-0.5
            plot(ax,intersect(polyshape(T.Lon{k}(:),T.Lat{k}(:)),box),'FaceColor',C.panel,'FaceAlpha',1,'EdgeColor','w');
        end
    end
    m=clat>=la(1) & clat<=la(2) & clon>=lo(1) & clon<=lo(2);
    [~,o]=sort(ships(m));
    xs=clon(m);
    ys=clat(m);
    vs=ships(m);
    xlim(ax,lo);
    ylim(ax,la);
    daspect(ax,[1 cosd(mean(la)) 1]);
    set(ax,'XTick',[],'YTick',[],'Box','on','XColor',C.grid,'YColor',C.grid);
    ax.Units='points';
    side_pt=ax.Position(3)*0.01/diff(lo);
    ax.Units='normalized';
    scatter(ax,xs(o),ys(o),max(side_pt,0.5)^2,C.ramp(discretize(vs(o),edges),:),'s','filled','MarkerEdgeColor','none');
    title(ax,areas{i,1},'FontName',C.font,'FontSize',9,'Color',C.dark,'FontWeight','bold');
    ax.TitleHorizontalAlignment='left';
end
finish(C,fig,'geo03_port_closeups');

%%%%%G4. Offshore distance bands
of=prod.offshore;
titles(4)=sprintf('Half of all large-ship route cells are within 100 km of shore; %.0f%% are within 50 km', ...
    100*mean(of.coast_km<=50));
[fig,ax]=new_map(C,titles(4),'Large-ship route cells colored by distance from the Census coastline', ...
    [C.src ' Coastline: Census TIGER/Line 2023.']);
[x,y]=projfwd(C.albers,of.lat,of.lon);
band=discretize(of.coast_km,[0 25 50 100 Inf]);
cols=flipud(C.ramp(2:5,:));
[~,o]=sort(of.coast_km,'descend');
scatter(ax,x(o)/1e3,y(o)/1e3,0.5,cols(band(o),:),'s','filled','MarkerEdgeColor','none');
key(C,ax,["0-25 km","25-50","50-100","Over 100"],cols,'Distance from shore',520);
finish(C,fig,'geo04_offshore_bands');

%%%%%G5. Near-shore profile
titles(5)='Near-shore traffic peaks off Houston-Galveston, New York, and Los Angeles-Long Beach';
fig=new_page(C,titles(5),'Distinct large ships within 50 km of shore in each half-degree along the coast, 2023 and 2024', ...
    [C.src ' Pacific and Atlantic by latitude (south to north); Gulf by longitude (west to east).'],6.2);
tl=tiledlayout(fig,3,1,'TileSpacing','compact','Padding','compact');
tl.Position=[0.08 0.12 0.88 0.62];
peaks=struct('Pacific','Los Angeles-Long Beach','Gulf','Houston-Galveston','Atlantic','New York');
for c=["Pacific","Gulf","Atlantic"]
    ax=nexttile(tl);
    style_axes(C,ax);
    pr=geo.profile(geo.profile.coast==c,:);
    [mx,im]=max(pr.ships);
    cl=repmat(C.gray,height(pr),1);
    cl(im,:)=C.blue;
    b=bar(ax,pr.from_deg+0.25,pr.ships,0.9,'FaceColor','flat','EdgeColor','none');
    b.CData=cl;
    ylim(ax,[0 4400]);
    yticks(ax,[0 2000 4000]);
    yticklabels(ax,{'0','2,000','4,000'});
    text(ax,pr.from_deg(im)+0.6,mx,sprintf('%s (%s)',peaks.(c),comma(mx)),'FontName',C.font,'FontSize',8.5, ...
        'FontWeight','bold','Color',C.dark);
    title(ax,c,'FontName',C.font,'FontSize',9.5,'Color',C.dark);
    ax.TitleHorizontalAlignment='left';
    xlabel(ax,ifelse(c=="Gulf",'Longitude (degrees)','Latitude (degrees north)'));
end
finish(C,fig,'geo05_coast_profile');

%%%%%G6. Port bubbles
gp=geo.ports;
titles(6)=sprintf('%d deep-draft ports each saw 1,000 or more different large ships within 10 km',s.ports_ge_1000);
[fig,ax]=new_map(C,titles(6),'Circle area = distinct large ships within 10 km of each deep-draft port, 2023 and 2024 together', ...
    [C.src ' Ports: USACE Principal Ports, coastal or Great Lakes, 1 million tons or more of foreign trade.']);
[x,y]=projfwd(C.albers,gp.lat,gp.lon);
[~,o]=sort(gp.ships,'descend');
scatter(ax,x(o)/1e3,y(o)/1e3,gp.ships(o)/12,C.blue,'filled','MarkerFaceAlpha',0.55,'MarkerEdgeColor',C.dark,'LineWidth',0.4);
lab={'Galveston',40,-150;'New Orleans',70,110;'Port of Long Beach',90,-60;'New York',90,0;'Houston',-70,120};
for i=1:size(lab,1)
    r=find(startsWith(gp.port,lab{i,1}),1);
    nm=erase(lab{i,1},'Port of ');
    text(ax,x(r)/1e3+lab{i,2},y(r)/1e3+lab{i,3},sprintf('%s\n%s',nm,comma(gp.ships(r))),'FontName',C.font, ...
        'FontSize',8,'Color',C.dark,'HorizontalAlignment',ifelse(lab{i,2}>0,'left','right'),'BackgroundColor','none');
end
text(ax,-2850,330,'Large ships within 10 km','FontName',C.font,'FontSize',8.5,'FontWeight','bold','Color',C.dark);
for i=1:3
    v=[500 1500 3000];
    scatter(ax,-2750+(i-1)*260,200,v(i)/12,C.blue,'filled','MarkerFaceAlpha',0.55,'MarkerEdgeColor',C.dark);
    text(ax,-2750+(i-1)*260,80,comma(v(i)),'HorizontalAlignment','center','FontName',C.font,'FontSize',8,'Color',C.dark);
end
finish(C,fig,'geo06_port_bubbles');

%%%%%G7. Ship types (skipped when the ship-type caches are not built yet)
ht=geo.hex_types;
if isempty(ht) || height(ht)==0
    titles(7)="(skipped: no ship-type data)";
else
titles(7)=sprintf(['%.0f%% of tankers sail in Gulf waters, against %.0f%% of cargo ships; passenger and government ' ...
    'ships cluster at a few ports'],100*s.type_share_ships_gulf_tanker,100*s.type_share_ships_gulf_cargo);
fig=new_page(C,titles(7),'Distinct ships of each type per 25 km hexagon, 2023 and 2024 together (each map has its own shading)', ...
    [C.src ' Types from the AIS ship-type code: tanker 80-89, cargo 70-79, passenger 60-69, military 35, ' ...
    'law enforcement 55.'],6.6);
tl=tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
tl.Position=[0.02 0.11 0.96 0.66];
names={'tanker','Tankers';'cargo','Cargo and container ships';'passenger','Passenger ships';'government','Military and law enforcement'};
for i=1:4
    ax=nexttile(tl);
    hold(ax,'on');
    plot(ax,C.states,'FaceColor',C.panel,'FaceAlpha',1,'EdgeColor','w','LineWidth',0.3);
    t=ht(ht.type==names{i,1},:);
    q=unique(quantile(t.ships,[0 0.5 0.8 0.95 0.99]));
    e=[q(:)' Inf];
    cols=C.ramp(end-numel(e)+2:end,:);
    [~,o]=sort(t.ships);
    draw_hex(ax,t.x_km(o),t.y_km(o),cols(discretize(t.ships(o),e),:),'none');
    axis(ax,'equal');
    axis(ax,'off');
    xlim(ax,[-2950 2550]);
    ylim(ax,[-150 3300]);
    title(ax,sprintf('%s (%s ships)',names{i,2},comma(s.(['type_ships_' names{i,1}]))),'FontName',C.font, ...
        'FontSize',9,'Color',C.dark);
end
finish(C,fig,'geo07_ship_types');
end

%%%%%G8. Land distance
L=geo.land;
titles(8)='Away from the coasts, only the Great Lakes and a few deep rivers bring large-ship routes inland';
[fig,ax]=new_map(C,titles(8),'Distance from each point of U.S. land to the nearest large-ship route cell', ...
    [C.src ' Land: Census cartographic boundary states, 2023 (0.05 degree grid).']);
cla(ax);
hold(ax,'on');
[LON,LAT]=meshgrid(L.lon,L.lat);
ok=~isnan(L.dist_km);
[x,y]=projfwd(C.albers,LAT(ok),LON(ok));
cols=flipud(C.ramp);
band=discretize(L.dist_km(ok),[0 25 50 100 200 Inf]);
scatter(ax,x/1e3,y/1e3,1.3,cols(band,:),'s','filled','MarkerEdgeColor','none');
xlim(ax,[-2950 2550]);
ylim(ax,[-150 3300]);
key(C,ax,["0-25 km","25-50","50-100","100-200","Over 200"],cols,'Distance to the nearest large-ship route',500);
finish(C,fig,'geo08_land_distance');

%%%%%G9. Fixed S-band sites
st=readtable(sites_csv,'TextType','string');
titles(9)=sprintf('%d of %d charted S-band racons and 9 of 10 VTS areas sit within 5 km of a large-ship route', ...
    s.sband_racons_within_5km,s.sband_racons);
[fig,ax]=new_map(C,titles(9),'Racons and Coast Guard Vessel Traffic Service areas over the large-ship hexagon grid', ...
    [C.src ' Racons: NOAA ENC Direct (S-band = charted wavelength 0.10 m). VTS: U.S. Coast Guard.']);
draw_hex(ax,H.x_km,H.y_km,repmat(C.ramp(2,:),height(H),1),'none');
r=st(st.category=="racon",:);
[x,y]=projfwd(C.albers,r.lat,r.lon);
sb=r.sband_source==1;
scatter(ax,x(~sb)/1e3,y(~sb)/1e3,10,C.gray,'filled','MarkerEdgeColor','w');
scatter(ax,x(sb)/1e3,y(sb)/1e3,22,C.dark,'filled','MarkerEdgeColor','w');
v=st(st.category=="vts_area",:);
[x,y]=projfwd(C.albers,v.lat,v.lon);
scatter(ax,x/1e3,y/1e3,40,C.purple,'^','filled','MarkerEdgeColor','w');
scatter(ax,-2800,330,22,C.dark,'filled','MarkerEdgeColor','w');
text(ax,-2760,330,'Charted S-band racon','FontName',C.font,'FontSize',8.5,'Color',C.dark);
scatter(ax,-2800,230,10,C.gray,'filled','MarkerEdgeColor','w');
text(ax,-2760,230,'Other racon (X-band or not charted)','FontName',C.font,'FontSize',8.5,'Color',C.dark);
scatter(ax,-2800,130,40,C.purple,'^','filled','MarkerEdgeColor','w');
text(ax,-2760,130,'VTS area','FontName',C.font,'FontSize',8.5,'Color',C.dark);
finish(C,fig,'geo09_sband_sites');
end

%%%%%-------------------------------------------------------------------------
function draw_hex(ax,x,y,cols,edge)
%%%%%Pointy-top hexagons (circumradius 12.5 km) as one patch
ang=(0:5)*60+30;
r=12.5;
nx=numel(x);
V=zeros(6*nx,2);
V(:,1)=reshape((x(:)+r*cosd(ang))',[],1);
V(:,2)=reshape((y(:)+r*sind(ang))',[],1);
F=reshape(1:6*nx,6,[])';
patch(ax,'Faces',F,'Vertices',V,'FaceVertexCData',cols,'FaceColor','flat','EdgeColor',edge,'LineWidth',0.1);
end

function ramp_key(C,ax,labels,title_str,w)
key(C,ax,labels,C.ramp,title_str,w);
end

function key(C,ax,labels,cols,title_str,w)
for k=1:numel(labels)
    rectangle(ax,'Position',[-2850+(k-1)*w 120 w-10 70],'FaceColor',cols(k,:),'EdgeColor','none');
    text(ax,-2850+(k-1)*w+(w-10)/2,60,labels(k),'HorizontalAlignment','center','VerticalAlignment','top', ...
        'FontName',C.font,'FontSize',8,'Color',C.dark);
end
text(ax,-2850,240,title_str,'FontName',C.font,'FontSize',8.5,'FontWeight','bold','Color',C.dark);
end

function C=style()
C.dark=[22 51 83]/255;
C.blue=[86 116 196]/255;
C.purple=[110 79 146]/255;
C.gray=[138 141 145]/255;
C.panel=[232 233 234]/255;
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

function style_axes(C,ax)
hold(ax,'on');
set(ax,'FontName',C.font,'FontSize',8.5,'XColor',C.dark,'YColor',C.dark,'Box','off','TickDir','out', ...
    'YGrid','on','GridColor',C.grid,'GridAlpha',1);
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
