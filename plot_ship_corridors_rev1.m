function [titles]=plot_ship_corridors_rev1(cor,prod,out_dir,census_shp,dpi)
%plot_ship_corridors_rev1  Draw the river and ship-channel figures (MATLAB versions).
%
%   titles=plot_ship_corridors_rev1(cor,prod,out_dir,census_shp,dpi) draws,
%   from COR (corridor_products_rev1) and PROD (viz_products_rev1), and
%   writes PNGs to OUT_DIR:
%
%     corr01_reach_by_corridor   ships at the entrance and at the head port
%     corr02_profiles            small multiples of ships along each corridor
%     corr03_normalized_profiles share of entering ships still on each corridor
%     corr04_continuation_counts the same as ship counts
%     corr_<name>                route map and profile for each corridor
%
%   NTIA style: DRAFT//PRE-DECISIONAL, takeaway titles with computed numbers,
%   NTIA palette, Times New Roman. The Python versions are in
%   python/ship_corridor_figures.py.
%
%   Built-ins: readgeotable/geotable2table and polyshape (land), scatter,
%   stairs, xline, tiledlayout, exportgraphics.

arguments
    cor (1,1) struct
    prod (1,1) struct
    out_dir (1,:) char
    census_shp (1,:) char
    dpi (1,1) double {mustBePositive} = 200
end

if ~isfolder(out_dir)
    mkdir(out_dir);
end
C=style();
C.out_dir=out_dir;
C.dpi=dpi;
C.src=['Source: NTIA analysis of MarineCadastre AIS, 104 sampled days in 2023 and 2024; large ships = cargo, ' ...
    'tanker, passenger, military, and other seagoing ships 100 m or longer, plus tug-barges near the coast. ' ...
    'Distance is measured along the large-ship route cells from the entrance.'];
S=cor.summary;
S.share=S.ships_head./S.ships_entrance;
titles=strings(0,1);

%%%%%C1. Reach by corridor
[~,o]=sort(S.share);
So=S(o,:);
n_half=nnz(S.share<0.5);
titles(end+1)=sprintf(['On %d of %d rivers and ship channels, fewer than half of the large ships at the ' ...
    'entrance reach the head port'],n_half,height(S));
fig=new_page(C,titles(end),['Distinct large ships within 3 km of the entrance and of the head port, ' ...
    '104 sampled days in 2023 and 2024'],[C.src ' Entrance counts include ships bound for other ports near the entrance.'],6.6);
ax=axes(fig,'Position',[0.40 0.14 0.50 0.62]);
style_axes(C,ax);
set(ax,'YGrid','off','XGrid','on');
y=(1:height(So))';
for k=1:height(So)
    plot(ax,[So.ships_head(k) So.ships_entrance(k)],[y(k) y(k)],'-','Color',[0.85 0.85 0.85],'LineWidth',3);
end
scatter(ax,So.ships_entrance,y,36,C.gray,'filled');
scatter(ax,So.ships_head,y,36,C.blue,'filled');
labs=strings(height(So),1);
for k=1:height(So)
    en=cor.marks(cor.marks.corridor==So.corridor(k) & cor.marks.role=="end",:);
    to=" to "+en.name;
    if contains(So.label(k),en.name)
        to="";
    end
    extra="";
    if en.off_path_km>5
        extra=sprintf(" (routes end %.0f km short)",en.off_path_km);
    end
    labs(k)=So.label(k)+to+extra+sprintf(", %.0f km",So.length_km(k));
    text(ax,So.ships_entrance(k)+40,y(k),sprintf('%.0f%% reach the head',100*So.share(k)),'FontName',C.font, ...
        'FontSize',7.5,'Color',C.dark,'VerticalAlignment','middle');
end
set(ax,'YTick',y,'YTickLabel',labs,'FontSize',7.5);
xlim(ax,[0 max(So.ships_entrance)*1.35]);
ylim(ax,[0.4 height(So)+0.8]);
xlabel(ax,'Distinct large ships');
[~,iw]=max(So.ships_entrance-So.ships_head);
text(ax,So.ships_entrance(iw),iw+0.45,'At the entrance','FontName',C.font,'FontSize',8,'Color',C.dark, ...
    'HorizontalAlignment','center');
text(ax,So.ships_head(iw),iw+0.45,'At the head port','FontName',C.font,'FontSize',8,'Color',C.blue, ...
    'FontWeight','bold','HorizontalAlignment','center');
finish(C,fig,'corr01_reach_by_corridor');

%%%%%C2. Small multiples
[~,o]=sort(S.length_km,'descend');
titles(end+1)="Large-ship traffic falls off step by step as each river or channel passes its ports";
fig=new_page(C,titles(end),['Distinct large ships (vertical axis) in each reach of each corridor (2 km reaches ' ...
    'under 120 km long, 5 km otherwise), 2023 and 2024 together; each panel has its own scale'],C.src,8.0);
tl=tiledlayout(fig,3,5,'TileSpacing','loose','Padding','compact');
tl.Position=[0.03 0.10 0.94 0.70];
for k=o'
    ax=nexttile(tl);
    style_axes(C,ax);
    P=cor.profile(cor.profile.corridor==S.corridor(k),:);
    [xs,ys]=stairs([P.km_from; P.km_to(end)],[P.ships; P.ships(end)]);
    area(ax,xs,ys,'FaceColor',C.ramp(2,:),'EdgeColor','none');
    plot(ax,xs,ys,'Color',C.blue,'LineWidth',1);
    xlim(ax,[0 S.length_km(k)*1.03]);
    ylim(ax,[0 max(P.ships)*1.15]);
    title(ax,S.label(k),'FontName',C.font,'FontSize',7.5,'Color',C.dark,'HorizontalAlignment','left', ...
        'Units','normalized','Position',[0 1.04]);
    set(ax,'FontSize',7);
end
xlabel(tl,'km from the entrance','FontName',C.font,'FontSize',8,'Color',C.dark);
finish(C,fig,'corr02_profiles');

%%%%%C2b. Continuation curves: share and count of ships still on each corridor
titles=[titles; plot_corridor_normalized_rev1(cor,out_dir,dpi)];

%%%%%C3. One page per corridor
land=load_land(census_shp);
edges=[1 10 50 200 500 Inf];
R=prod.R;
nr=R.RasterSize(1);
rc=prod.route_cells;
rl=R.LatitudeLimits(1)+R.CellExtentInLatitude*(mod(rc-1,nr)+0.5);
ro=R.LongitudeLimits(1)+R.CellExtentInLongitude*(floor((rc-1)/nr)+0.5);
for k=1:height(S)
    c=S.corridor(k);
    M=cor.marks(cor.marks.corridor==c,:);
    en=M(M.role=="end",:);
    E=cor.cells(cor.cells.corridor==c,:);
    P=cor.profile(cor.profile.corridor==c,:);
    stop=en.off_path_km>5;
    if stop
        t=sprintf('Large-ship routes on the %s stop %.0f km short of %s; %s ships reach the end of the routes', ...
            S.label(k),en.off_path_km,en.name,comma(S.ships_head(k)));
    else
        t=sprintf('%s large ships reach %s, %.0f km from the entrance: %.0f%% of the %s seen at the entrance', ...
            comma(S.ships_head(k)),en.name,en.km,100*S.share(k),comma(S.ships_entrance(k)));
    end
    titles(end+1)=t; %#ok<AGROW> one per corridor
    fig=new_page(C,t,sprintf(['%s: distinct large ships per route cell (map) and per %g km reach (chart), ' ...
        '2023 and 2024 together (%d at the head in 2023, %d in 2024)'],S.label(k),S.bin_km(k), ...
        S.ships_head_2023(k),S.ships_head_2024(k)),C.src,5.4);
    %%%%%Map
    pts=[E.lat E.lon; M.lat(M.role~="target") M.lon(M.role~="target")];
    a0=min(pts(:,1));
    a1=max(pts(:,1));
    o0=min(pts(:,2));
    o1=max(pts(:,2));
    pad=0.12*max(a1-a0,(o1-o0)*cosd(a0));
    a0=a0-pad;
    a1=a1+pad;
    o0=o0-pad/cosd(a0);
    o1=o1+pad/cosd(a0);
    ax=axes(fig,'Position',[0.03 0.17 0.36 0.56]);
    hold(ax,'on');
    box=polyshape([o0 o1 o1 o0],[a0 a0 a1 a1]);
    for j=1:numel(land.poly)
        b=land.bbox(j,:);
        if b(1)<o1 && b(2)>o0 && b(3)<a1 && b(4)>a0
            plot(ax,intersect(land.poly(j),box),'FaceColor',C.panel,'FaceAlpha',1,'EdgeColor','w','LineWidth',0.4);
        end
    end
    xlim(ax,[o0 o1]);
    ylim(ax,[a0 a1]);
    daspect(ax,[1 cosd((a0+a1)/2) 1]);
    set(ax,'XTick',[],'YTick',[],'XColor',C.grid,'YColor',C.grid,'Box','on');
    v=rl>a0 & rl<a1 & ro>o0 & ro<o1;
    ax.Units='points';
    side=max(ax.Position(3)*0.01/(o1-o0),1);
    ax.Units='normalized';
    scatter(ax,ro(v),rl(v),side^2,[0.835 0.843 0.855],'s','filled');
    [~,oo]=sort(E.ships);
    bin=discretize(E.ships(oo),edges);
    scatter(ax,E.lon(oo),E.lat(oo),side^2,C.ramp(bin,:),'s','filled');
    for j=1:height(M)
        if M.role(j)=="target"
            continue
        end
        plot(ax,M.lon(j),M.lat(j),'o','MarkerSize',4,'MarkerFaceColor','w','MarkerEdgeColor',C.dark);
        right=M.lon(j)>(o0+o1)/2;
        lab="  "+M.name(j);
        ha='left';
        if right
            lab=M.name(j)+"  ";
            ha='right';
        end
        text(ax,M.lon(j),M.lat(j),lab,'FontName',C.font,'FontSize',7.5,'Color',C.dark,'HorizontalAlignment',ha, ...
            'BackgroundColor','none');
    end
    %%%%%Profile
    ax=axes(fig,'Position',[0.47 0.17 0.50 0.50]);
    style_axes(C,ax);
    [xs,ys]=stairs([P.km_from; P.km_to(end)],[P.ships; P.ships(end)]);
    area(ax,xs,ys,'FaceColor',C.ramp(2,:),'EdgeColor','none');
    plot(ax,xs,ys,'Color',C.blue,'LineWidth',1.5);
    for j=1:height(M)
        if M.role(j)=="start" || M.role(j)=="target" || (M.role(j)=="end" && stop)
            continue
        end
        xline(ax,M.km(j),'--',M.name(j),'Color',C.dark,'FontName',C.font,'FontSize',7.5,'LabelOrientation','aligned', ...
            'LabelVerticalAlignment','top','LabelHorizontalAlignment','left');
    end
    xlim(ax,[0 S.length_km(k)*1.04]);
    ylim(ax,[0 max(P.ships)*1.35]);
    xlabel(ax,'Distance from the entrance along the route (km)');
    ylabel(ax,'Distinct large ships');
    finish(C,fig,"corr_"+c);
end
end

function L=load_land(census_shp)
S=readgeotable(census_shp);
T=geotable2table(S,["Lat","Lon"]);
warn_state=warning('off','MATLAB:polyshape:repairedBySimplify');
cleanup=onCleanup(@() warning(warn_state));
L.poly=repmat(polyshape(),height(T),1);
L.bbox=zeros(height(T),4);
for k=1:height(T)
    L.poly(k)=polyshape(T.Lon{k}(:),T.Lat{k}(:));
    L.bbox(k,:)=[min(T.Lon{k}) max(T.Lon{k}) min(T.Lat{k}) max(T.Lat{k})];
end
end

function C=style()
C.dark=[22 51 83]/255;
C.blue=[86 116 196]/255;
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

function finish(C,fig,name)
exportgraphics(fig,fullfile(C.out_dir,char(name)+".png"),'Resolution',C.dpi,'BackgroundColor','white');
close(fig);
end

function s=comma(n)
s=char(string(round(n)));
s=fliplr(regexprep(fliplr(s),'(\d{3})(?=\d)','$1,'));
end
