function [titles]=plot_port_share_rev1(ps,out_dir,census_shp,dpi)
%plot_port_share_rev1  Ten figures on how large-ship port visits split among the ports.
%
%   titles=plot_port_share_rev1(ps,out_dir,census_shp,dpi) draws, from PS
%   (port_share_products_rev1), and writes PNGs to OUT_DIR:
%
%     share01_treemap        treemap: coast, then port (squarified)
%     share02_circle_pack    packed circles, one per port
%     share03_pareto         top 25 ports with the running total
%     share04_concentration  cumulative share against number of ports
%     share05_waffle         100 squares by port complex
%     share06_marimekko      top 12 complexes: width = share, height = type mix
%     share07_sunburst       rings: coast, complex, port
%     share08_dorling        Dorling map of the ports
%     share09_coast_bars     100% bars: each coast split among its ports
%     share10_years          first-year against second-year share, top 15 ports (dumbbell)
%
%   NTIA style: DRAFT//PRE-DECISIONAL, takeaway titles with computed numbers,
%   NTIA palette (plus a dark ochre for the Great Lakes), Times New Roman.
%   The Python versions are in python/ship_port_share_figures.py. Built-ins:
%   rectangle, patch, scatter, barh, stairs, polyshape, projfwd, exportgraphics.
%   The squarified treemap, circle packing, and Dorling layout have no
%   built-in, so they are written here (the same algorithms as the Python twin).

arguments
    ps (1,1) struct
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
per=period_rev1();   %%%%%analysis years (period_rev1.m)
C.src=[['Source: NTIA analysis of MarineCadastre AIS, 104 sampled days in ' per.and '; large ships = cargo, '] ...
    'tanker, passenger, military, and other seagoing ships 100 m or longer, plus tug-barges near the coast. Port ' ...
    'visits = distinct large ships seen within 10 km of a deep-draft port (each 1 km cell assigned to its nearest ' ...
    'port); a ship that calls at two ports counts at both.'];
T=ps.ports;
X=ps.complex;
coasts=["Gulf","Atlantic","Pacific","Great Lakes"];
ccol=containers.Map(cellstr(coasts),{C.dark,C.blue,C.purple,C.ochre});
total=sum(T.ships);
cshare=arrayfun(@(c) sum(T.ships(T.coast==c))/total,coasts);
titles=strings(10,1);

%%%%%1. Treemap
titles(1)=sprintf('Gulf ports take %.0f%% of large-ship port visits; Galveston alone takes %.0f%%',100*cshare(1), ...
    100*T.share(1));
[fig,ax]=new_page(C,titles(1),['Share of large-ship port visits at the 73 deep-draft ports, grouped by coast, ' ...
    ['' per.and ' together (area = share)']],C.src,5.8,[0.04 0.13 0.92 0.60]);
W=1.6;
H=1.0;
set(ax,'YDir','reverse','XLim',[0 W],'YLim',[0 H]);
daspect(ax,[1 1 1]);
boxes=squarify(cshare,0,0,W,H);
for k=1:numel(coasts)
    rows=T(T.coast==coasts(k),:);
    rects=squarify(rows.ships,boxes(k,1),boxes(k,2),boxes(k,3),boxes(k,4));
    for j=1:height(rows)
        r=rects(j,:);
        rectangle(ax,'Position',r,'FaceColor',ccol(char(coasts(k))),'EdgeColor','w','LineWidth',1);
        if r(3)>0.06 && r(4)>0.05
            fit_label(C,ax,r,rows.short(j),rows.share(j));
        end
    end
    rectangle(ax,'Position',boxes(k,:),'EdgeColor','w','LineWidth',3);
end
xlim(ax,[0 W]);
ylim(ax,[0 H]);
set(ax,'YDir','reverse','Visible','off');
daspect(ax,[1 1 1]);
key_text(C,ax,coasts,cshare,ccol,[0 -0.02],0.4);
finish(C,fig,'share01_treemap');

%%%%%2. Circle packing
rad=sqrt(T.ships/pi);
xy=pack_circles(rad);
titles(2)=sprintf('The 10 busiest deep-draft ports take %.0f%% of large-ship port visits; the other 63 share the rest', ...
    100*sum(T.share(1:10)));
[fig,ax]=new_page(C,titles(2),['One circle per deep-draft port, area = distinct large ships within 10 km, ' ...
    per.and ' together, colored by coast'],C.src,5.8,[0.04 0.13 0.92 0.60]);
hold(ax,'on');
th=linspace(0,2*pi,60);
for k=1:height(T)
    patch(ax,xy(k,1)+0.97*rad(k)*cos(th),xy(k,2)+0.97*rad(k)*sin(th),ccol(char(T.coast(k))),'EdgeColor','w');
    if rad(k)>19
        text(ax,xy(k,1),xy(k,2),sprintf('%s\n%s',wrap_name(T.short(k)),comma(T.ships(k))),'HorizontalAlignment', ...
            'center','FontName',C.font,'FontSize',7,'FontWeight','bold','Color','w');
    end
end
axis(ax,'equal');
set(ax,'Visible','off');
m=max(abs(xy(:))+[rad;rad])*1.02;
xlim(ax,[-1.6*m 1.05*m]);
ylim(ax,[-m m]);
key_box(C,ax,coasts,cshare,ccol,[-1.55*m 0.9*m],0.13*m);
finish(C,fig,'share02_circle_pack');

%%%%%3. Pareto
cum=cumsum(T.share);
n50=find(cum>=0.5,1);
titles(3)=sprintf('%d ports take half of all large-ship port visits; the busiest 25 take %.0f%%',n50,100*cum(25));
[fig,ax]=new_page(C,titles(3),['Share of large-ship port visits, the 25 busiest deep-draft ports, with the ' ...
    ['running total, ' per.and ' together']],C.src,6.4,[0.20 0.16 0.62 0.59]);
style_axes(C,ax);
set(ax,'YGrid','off','XGrid','on');
y=(25:-1:1)';
for k=1:25
    barh(ax,y(k),100*T.share(k),0.72,'FaceColor',ccol(char(T.coast(k))),'EdgeColor','none');
    text(ax,100*T.share(k)+0.08,y(k),sprintf('%.1f%%',100*T.share(k)),'FontName',C.font,'FontSize',7.5,'Color',C.dark);
    text(ax,100*T.share(1)*1.2,y(k),sprintf('%.0f%%',100*cum(k)),'FontName',C.font,'FontSize',7.5,'Color',C.dark, ...
        'FontWeight',ifelse(k==n50,'bold','normal'));
end
text(ax,100*T.share(1)*1.2,25.9,'Running total','FontName',C.font,'FontSize',7.5,'Color',C.dark);
yline(ax,y(n50)-0.5,'--','Half of all visits above this line','Color',C.dark,'FontName',C.font,'FontSize',7.5, ...
    'LabelHorizontalAlignment','right');
set(ax,'YTick',flipud(y),'YTickLabel',flipud(T.short(1:25)),'FontSize',7.5);
xlim(ax,[0 100*T.share(1)*1.18]);
ylim(ax,[0.3 25.7]);
xlabel(ax,'Share of large-ship port visits (%)');
finish(C,fig,'share03_pareto');

%%%%%4. Concentration curve
cum0=[0; cum];
n80=find(cum>=0.8,1);
titles(4)=sprintf(['Large-ship port visits are concentrated: %d of 73 deep-draft ports take half, and %d take ' ...
    'four-fifths'],n50,n80);
[fig,ax]=new_page(C,titles(4),['Cumulative share of large-ship port visits, ports ranked from busiest to least ' ...
    ['busy, ' per.and ' together']],C.src,5.6,[0.09 0.19 0.86 0.54]);
style_axes(C,ax);
plot(ax,[0 73],[0 100],'--','Color',C.gray);
text(ax,50,100*50/73-4,'Even split across all 73 ports','FontName',C.font,'FontSize',8,'Color',C.dark);
stairs(ax,0:73,100*cum0,'Color',C.blue,'LineWidth',2);
labs=["half","four-fifths"];
nk=[n50 n80];
for k=1:2
    plot(ax,[nk(k) nk(k) 0],[0 100*cum0(nk(k)+1) 100*cum0(nk(k)+1)],':','Color',C.dark);
    text(ax,nk(k)+1,100*cum0(nk(k)+1)-3,sprintf('%d ports take %s (%.0f%%)',nk(k),labs(k),100*cum0(nk(k)+1)), ...
        'FontName',C.font,'FontSize',8.5,'FontWeight','bold','Color',C.blue,'VerticalAlignment','top');
end
xlim(ax,[0 73]);
ylim(ax,[0 102]);
xlabel(ax,'Number of ports, busiest first');
ylabel(ax,'Cumulative share of large-ship port visits (%)');
finish(C,fig,'share04_concentration');

%%%%%5. Waffle
top=X(1:8,:);
n=round(100*top.share);
names=[top.complex; "All other ports"];
n=[n; 100-sum(n)];
wcol=[22 51 83; 63 95 168; 86 116 196; 127 150 211; 110 79 146; 156 130 188; 154 107 0; 201 165 74; 213 215 218]/255;
titles(5)=sprintf('Eight port complexes take %d%% of large-ship port visits, led by the lower Mississippi (%.0f%%) and Houston-Galveston (%.0f%%)', ...
    100-n(end),100*top.share(1),100*top.share(2));
[fig,ax]=new_page(C,titles(5),['Each square = 1% of large-ship port visits at the 73 deep-draft ports, ' per.and ...
    ' together (complexes group neighboring ports)'],[C.src ' Shares rounded to whole squares.'],5.6, ...
    [0.04 0.13 0.92 0.60]);
hold(ax,'on');
k=0;
for g=1:numel(n)
    for j=1:n(g)
        [c_,r_]=deal(mod(k,10),floor(k/10));
        rectangle(ax,'Position',[c_ 9-r_ 0.9 0.9],'FaceColor',wcol(g,:),'EdgeColor','none');
        k=k+1;
    end
    rectangle(ax,'Position',[11 9.1-(g-1)*1.1 0.7 0.7],'FaceColor',wcol(g,:),'EdgeColor','none');
    text(ax,12,9.45-(g-1)*1.1,sprintf('%s: %d%%',names(g),n(g)),'FontName',C.font,'FontSize',8.5,'Color',C.dark);
end
axis(ax,'equal');
set(ax,'Visible','off','XLim',[0 21],'YLim',[-0.2 10]);
finish(C,fig,'share05_waffle');

%%%%%6. Marimekko
top=X(1:12,:);
types=["tanker","cargo","passenger","government"];
tcol=[C.dark; C.blue; C.purple; C.ochre; 0.79 0.80 0.81];
mix=zeros(height(top),5);
for k=1:height(top)
    rows=T(T.complex==top.complex(k),:);
    for j=1:4
        mix(k,j)=sum(rows.(types(j)));
    end
    mix(k,5)=sum(rows.ships)-sum(mix(k,1:4));
end
mix=mix./top.visits;
[tmax,it]=max(mix(:,1));
titles(6)=sprintf(['Tankers make up %.0f%% of large-ship visits at %s and %.0f%% at Houston-Galveston; cargo ' ...
    'and container ships lead everywhere else'],100*tmax,top.complex(it),100*mix(top.complex=="Houston-Galveston",1));
[fig,ax]=new_page(C,titles(6),['The 12 busiest port complexes: width = share of their large-ship port visits, ' ...
    ['height = ship-type mix, ' per.and ' together']],[C.src ' Types from the AIS ship-type code (tanker 80-89, ' ...
    'cargo 70-79, passenger 60-69, military 35, law enforcement 55).'],6.0,[0.08 0.13 0.70 0.58]);
hold(ax,'on');
x=0;
wsum=sum(top.visits);
for k=1:height(top)
    w=top.visits(k)/wsum;
    y=0;
    for j=1:5
        rectangle(ax,'Position',[x y w mix(k,j)],'FaceColor',tcol(j,:),'EdgeColor','w');
        y=y+mix(k,j);
    end
    text(ax,x+w/2,0.015,top.complex(k),'Rotation',90,'FontName',C.font,'FontSize',7.5,'FontWeight','bold', ...
        'Color','w');
    if w>0.035
        text(ax,x+w/2,1.01,sprintf('%.0f%%',100*top.share(k)),'HorizontalAlignment','center', ...
            'VerticalAlignment','bottom','FontName',C.font,'FontSize',7,'Color',C.dark);
    end
    x=x+w;
end
tl=["Tankers","Cargo and container","Passenger","Military and law enforcement","Other large ships and tug-barges"];
for j=1:5
    rectangle(ax,'Position',[1.03 0.92-(j-1)*0.08 0.025 0.05],'FaceColor',tcol(j,:),'EdgeColor','none','Clipping','off');
    text(ax,1.065,0.945-(j-1)*0.08,tl(j),'FontName',C.font,'FontSize',7.5,'Color',C.dark,'Clipping','off');
end
text(ax,0,1.07,'Share of all port visits:','FontName',C.font,'FontSize',7.5,'Color',C.dark);
set(ax,'XLim',[0 1],'YLim',[0 1],'XTick',[],'YTick',0:0.25:1,'YTickLabel',{'0%','25%','50%','75%','100%'}, ...
    'FontName',C.font,'FontSize',8,'XColor','none','YColor',C.dark,'Box','off');
ylabel(ax,"Share of the complex's large-ship visits");
finish(C,fig,'share06_marimekko');

%%%%%7. Sunburst
lm=sum(T.ships(T.complex=="Lower Mississippi"))/sum(T.ships(T.coast=="Gulf"));
titles(7)=sprintf(['Nearly half of all large-ship port visits are at Gulf ports, and %s of those are on the ' ...
    'lower Mississippi'],ifelse(abs(lm-1/3)<0.04,'a third',sprintf('%.0f%%',100*lm)));
[fig,ax]=new_page(C,titles(7),['Rings from the center: coast, port complex, port; angle = share of large-ship ' ...
    ['port visits, ' per.and ' together']],C.src,6.0,[0.04 0.12 0.92 0.64]);
hold(ax,'on');
a0=90;
for k=1:numel(coasts)
    rows=T(T.coast==coasts(k),:);
    cs=sum(rows.ships)/total;
    col=ccol(char(coasts(k)));
    ring(ax,0.55,1.0,a0-360*cs,a0,col,1.5);
    if cs>0.05
        mid=a0-180*cs;
        text(ax,0.775*cosd(mid),0.775*sind(mid),sprintf('%s\n%.0f%%',coasts(k),100*cs),'HorizontalAlignment', ...
            'center','FontName',C.font,'FontSize',8,'FontWeight','bold','Color','w');
    end
    [~,~,ic]=unique(rows.complex,'stable');
    cv=accumarray(ic,rows.ships);
    [~,o]=sort(cv,'descend');
    b0=a0;
    for j=o'
        sub=rows(ic==j,:);
        v=sum(sub.ships)/total;
        ring(ax,1.02,1.45,b0-360*v,b0,0.25+0.75*col,1);
        p0=b0;
        for q=1:height(sub)
            pv=sub.ships(q)/total;
            ring(ax,1.47,1.75,p0-360*pv,p0,0.5+0.5*col,0.6);
            if pv>0.022
                m3=p0-180*pv;
                left=mod(m3,360)>90 && mod(m3,360)<270;
                text(ax,1.8*cosd(m3),1.8*sind(m3),sub.short(q),'Rotation',m3-180*left,'HorizontalAlignment', ...
                    ifelse(left,'right','left'),'FontName',C.font,'FontSize',7.5,'Color',C.dark);
            end
            p0=p0-360*pv;
        end
        b0=b0-360*v;
    end
    a0=a0-360*cs;
end
axis(ax,'equal');
set(ax,'Visible','off','XLim',[-2.9 2.9],'YLim',[-2.75 2.45]);
finish(C,fig,'share07_sunburst');

%%%%%8. Dorling map
albers=projcrs(5070);
[px,py]=projfwd(albers,T.lat,T.lon);
px=px/1e3;
py=py/1e3;
rk=sqrt(T.ships)*4.0;
[dx,dy]=dorling(px,py,rk);
titles(8)="On a map, the Gulf ports from Corpus Christi to the Mississippi form the largest cluster of large-ship port visits";
[fig,ax]=new_page(C,titles(8),['Dorling map: one circle per deep-draft port, area = distinct large ships within ' ...
    ['10 km, nudged apart so none overlap, ' per.and ' together']],C.src,5.8,[0.02 0.10 0.96 0.64]);
hold(ax,'on');
S=readgeotable(census_shp);
S=S(~ismember(string(S.STUSPS),["AK","HI","PR","VI","GU","MP","AS"]),:);
G=geotable2table(S,["Lat","Lon"]);
warn_state=warning('off','MATLAB:polyshape:repairedBySimplify');
cleanup=onCleanup(@() warning(warn_state));
for k=1:height(G)
    [sx,sy]=projfwd(albers,G.Lat{k}(:),G.Lon{k}(:));
    plot(ax,polyshape(sx/1e3,sy/1e3),'FaceColor',C.panel,'FaceAlpha',1,'EdgeColor','w','LineWidth',0.3);
end
[~,o]=sort(rk,'descend');
for k=o'
    patch(ax,dx(k)+rk(k)*cos(th),dy(k)+rk(k)*sin(th),ccol(char(T.coast(k))),'EdgeColor','w','FaceAlpha',0.92);
end
%%%%%Labels with short leader lines, pointing away from the cluster (same directions as the Python twin)
lab_dir=containers.Map({'Galveston','Houston','New Orleans','Plaquemines','South Louisiana','Port Arthur', ...
    'New York-New Jersey','Long Beach','Baltimore','Sabine Pass'},{[-1 -1],[-1 1],[1 1],[1 -1],[0 1],[0 1], ...
    [1 0],[-1 0],[1 0],[0 -1]});
ha={'right','center','left'};
va={'top','middle','bottom'};
for k=1:10
    u=[1 0];
    if isKey(lab_dir,char(T.short(k)))
        u=lab_dir(char(T.short(k)));
    end
    f=1;
    if all(u~=0)
        f=0.7071;
    end
    e=[dx(k) dy(k)]+u*f*rk(k);
    t=e+u*f*55;
    plot(ax,[e(1) t(1)],[e(2) t(2)],'Color',C.dark,'LineWidth',0.6);
    text(ax,t(1)+u(1)*8,t(2)+u(2)*8,T.short(k),'HorizontalAlignment',ha{u(1)+2},'VerticalAlignment', ...
        va{u(2)+2},'FontName',C.font,'FontSize',7.5,'FontWeight','bold','Color',C.dark,'BackgroundColor','w', ...
        'Margin',0.5);
end
for k=1:2
    sv=[2000 500];
    rr=sqrt(sv(k))*4.0;
    cxk=-2700+(k-1)*330;
    plot(ax,cxk+rr*cos(th),250+rr+rr*sin(th),'Color',C.dark);
    text(ax,cxk,250+2*rr+25,ifelse(k==1,'2,000 ships','500'),'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom','FontName',C.font,'FontSize',7.5,'Color',C.dark);
end
axis(ax,'equal');
set(ax,'Visible','off','XLim',[-2950 2550],'YLim',[-150 3300]);
key_box(C,ax,coasts,cshare,ccol,[1900 1050],110);
finish(C,fig,'share08_dorling');

%%%%%9. 100% bars by coast
titles(9)="Galveston, New York, and Long Beach lead their coasts, but no port takes more than a sixth of any ocean coast's large-ship visits";
top_share=arrayfun(@(c) max(T.ships(T.coast==c))/sum(T.ships(T.coast==c)),coasts(1:3));
if any(top_share>1/6+0.005)
    error('plot_port_share_rev1:title','The coast-bars headline no longer matches the data; rewrite it.');
end
[fig,ax]=new_page(C,titles(9),['How each coast''s large-ship port visits split among its ports (top five named), ' ...
    ['' per.and ' together']],C.src,5.2,[0.03 0.13 0.94 0.58]);
hold(ax,'on');
for k=1:numel(coasts)
    rows=T(T.coast==coasts(k),:);
    tot=sum(rows.ships);
    yy=numel(coasts)-k;
    x=0;
    col=ccol(char(coasts(k)));
    for j=1:5
        w=rows.ships(j)/tot;
        shade=col+(1-col)*0.15*(j-1);
        rectangle(ax,'Position',[x yy-0.35 w 0.7],'FaceColor',shade,'EdgeColor','w','LineWidth',1.5);
        if w>0.075
            text(ax,x+w/2,yy,sprintf('%s\n%.0f%%',wrap_name(rows.short(j)),100*w),'HorizontalAlignment','center', ...
                'FontName',C.font,'FontSize',7,'FontWeight','bold','Color',ifelse(j<4,'w',C.dark));
        end
        x=x+w;
    end
    rectangle(ax,'Position',[x yy-0.35 1-x 0.7],'FaceColor',[0.835 0.843 0.855],'EdgeColor','w','LineWidth',1.5);
    text(ax,x+(1-x)/2,yy,sprintf('%d others\n%.0f%%',height(rows)-5,100*(1-x)),'HorizontalAlignment','center', ...
        'FontName',C.font,'FontSize',7,'Color',C.dark);
    text(ax,0,yy+0.4,sprintf('%s: %s port visits',coasts(k),comma(tot)),'VerticalAlignment','bottom', ...
        'FontName',C.font,'FontSize',8.5,'FontWeight','bold','Color',col);
end
set(ax,'XLim',[0 1],'YLim',[-0.6 numel(coasts)-0.2],'YTick',[],'XTick',0:0.25:1, ...
    'XTickLabel',{'0%','25%','50%','75%','100%'},'FontName',C.font,'FontSize',8,'XColor',C.dark,'YColor','none', ...
    'Box','off');
finish(C,fig,'share09_coast_bars');

%%%%%10. First year against second year
top=T(1:15,:);
s23=top.ships_y0/sum(T.ships_y0);
s24=top.ships_y1/sum(T.ships_y1);
ch=s24-s23;
[~,ib]=max(abs(ch));
titles(10)=sprintf('Port shares barely moved between years; the largest shift among the top 15 is %.1f points at %s', ...
    100*abs(ch(ib)),top.short(ib));
[fig,ax]=new_page(C,titles(10),['Share of large-ship port visits in ' num2str(per.years(1)) ' (open circle) and ' num2str(per.years(2)) ' (filled circle), ' ...
    'the 15 busiest deep-draft ports'],C.src,5.8,[0.20 0.18 0.72 0.54]);
style_axes(C,ax);
set(ax,'YGrid','off','XGrid','on');
y=(15:-1:1)';
for k=1:15
    col=ccol(char(top.coast(k)));
    plot(ax,100*[s23(k) s24(k)],[y(k) y(k)],'Color',col,'LineWidth',2);
    scatter(ax,100*s23(k),y(k),36,'MarkerFaceColor','w','MarkerEdgeColor',col,'LineWidth',1.5);
    scatter(ax,100*s24(k),y(k),36,col,'filled');
    v=round(100*ch(k),1);
    lab=sprintf('%+.1f pts',v);
    if v==0
        lab='0.0 pts';
    end
    text(ax,100*max(s23(k),s24(k))+0.12,y(k),lab,'FontName',C.font,'FontSize',7.5,'FontWeight','bold','Color',col);
end
set(ax,'YTick',flipud(y),'YTickLabel',flipud(top.short),'FontSize',8);
xlim(ax,[0 100*max([s23; s24])*1.15]);
ylim(ax,[0.3 15.7]);
xlabel(ax,'Share of large-ship port visits (%)');
finish(C,fig,'share10_years');
end

function rects=squarify(values,x,y,w,h)
%%%%%Squarified treemap (Bruls, Huizing, and van Wijk 2000); values sorted descending; rows [x y w h]
vals=values(:)'*w*h/sum(values);
rects=zeros(numel(vals),4);
n=0;
row=[];
while ~isempty(vals)
    side=min(w,h);
    v=vals(1);
    if isempty(row) || worst([row v],side)<=worst(row,side)
        row=[row v]; %#ok<AGROW> a few items per row
        vals(1)=[];
    else
        [r,x,y,w,h]=lay(row,x,y,w,h);
        rects(n+1:n+numel(row),:)=r;
        n=n+numel(row);
        row=[];
    end
end
if ~isempty(row)
    rects(n+1:n+numel(row),:)=lay(row,x,y,w,h);
end
end

function v=worst(row,side)
s=sum(row);
v=max(max(side^2*row/s^2,s^2./(side^2*row)));
end

function [r,x,y,w,h]=lay(row,x,y,w,h)
s=sum(row);
r=zeros(numel(row),4);
if w>=h
    cw=s/h;
    yy=y;
    for k=1:numel(row)
        r(k,:)=[x yy cw row(k)/cw];
        yy=yy+row(k)/cw;
    end
    x=x+cw;
    w=w-cw;
else
    rh=s/w;
    xx=x;
    for k=1:numel(row)
        r(k,:)=[xx y row(k)/rh rh];
        xx=xx+row(k)/rh;
    end
    y=y+rh;
    h=h-rh;
end
end

function pos=pack_circles(rad)
%%%%%Greedy packing, largest first: each circle at the tangent spot nearest the center (as the Python twin)
n=numel(rad);
pos=zeros(n,2);
for i=2:n
    r=rad(i);
    cand=zeros(0,2);
    for j=1:i-1
        a=(0:23)'/24*2*pi;
        cand=[cand; pos(j,:)+(rad(j)+r)*[cos(a) sin(a)]]; %#ok<AGROW> candidate points
        for k=j+1:i-1
            d1=rad(j)+r;
            d2=rad(k)+r;
            dv=pos(k,:)-pos(j,:);
            d=norm(dv);
            if d==0 || d>d1+d2 || d<abs(d1-d2)
                continue
            end
            a_=(d1^2-d2^2+d^2)/(2*d);
            hh=sqrt(max(d1^2-a_^2,0));
            m=pos(j,:)+a_*dv/d;
            cand=[cand; m+hh*[dv(2) -dv(1)]/d; m-hh*[dv(2) -dv(1)]/d]; %#ok<AGROW>
        end
    end
    [~,o]=sort(sum(cand.^2,2));
    for c=o'
        if all(vecnorm(pos(1:i-1,:)-cand(c,:),2,2)>=rad(1:i-1)+r-1e-9)
            pos(i,:)=cand(c,:);
            break
        end
    end
end
end

function [x,y]=dorling(x0,y0,r)
%%%%%Push overlapping circles apart, pull gently home (as the Python twin)
x=x0;
y=y0;
n=numel(x);
for it=1:400
    moved=false;
    for i=1:n
        dx=x-x(i);
        dy=y-y(i);
        d=hypot(dx,dy);
        need=r+r(i)+6;
        for k=find(d<need & (1:n)'~=i)'
            dd=max(d(k),1e-6);
            push=(need(k)-dd)/2;
            x(k)=x(k)+dx(k)/dd*push;
            y(k)=y(k)+dy(k)/dd*push;
            x(i)=x(i)-dx(k)/dd*push;
            y(i)=y(i)-dy(k)/dd*push;
            moved=true;
        end
    end
    x=x+0.02*(x0-x);
    y=y+0.02*(y0-y);
    if ~moved
        break
    end
end
end

function ring(ax,r0,r1,a0,a1,col,lw)
%%%%%Annular sector from angle a0 to a1 (degrees)
t=linspace(a0,a1,max(8,ceil(abs(a1-a0))));
patch(ax,[r1*cosd(t) r0*cosd(fliplr(t))],[r1*sind(t) r0*sind(fliplr(t))],col,'EdgeColor','w','LineWidth',lw);
end

function fit_label(C,ax,r,name,share)
%%%%%Label a treemap rectangle only if the label fits inside it (measured with Extent)
name=char(extractBefore(string(name)+" (", " ("));
tries={{sprintf('%s\n%.1f%%',name,100*share),8},{sprintf('%s\n%.1f%%',name,100*share),7}, ...
    {sprintf('%s\n%.1f%%',regexprep(name,'[ -]','$0\n','once'),100*share),7}};
for k=1:numel(tries)
    t=text(ax,r(1)+0.007,r(2)+0.007,tries{k}{1},'VerticalAlignment','top','FontName',C.font, ...
        'FontSize',tries{k}{2},'FontWeight','bold','Color','w');
    e=t.Extent;
    if e(3)<r(3)-0.012 && e(4)<r(4)-0.012
        return
    end
    delete(t);
end
end

function key_box(C,ax,coasts,cshare,ccol,xy,dy)
for k=1:numel(coasts)
    plot(ax,xy(1),xy(2)-(k-1)*dy,'s','MarkerSize',8,'MarkerFaceColor',ccol(char(coasts(k))),'MarkerEdgeColor','none');
    text(ax,xy(1)+0.4*dy,xy(2)-(k-1)*dy,sprintf('%s (%.0f%%)',coasts(k),100*cshare(k)),'FontName',C.font, ...
        'FontSize',8,'FontWeight','bold','Color',ccol(char(coasts(k))));
end
end

function key_text(C,ax,coasts,cshare,ccol,xy,step)
nm=["dark blue","light blue","purple","ochre"];
for k=1:numel(coasts)
    text(ax,xy(1)+(k-1)*step,xy(2),sprintf('%s (%s) %.0f%%',coasts(k),nm(k),100*cshare(k)),'FontName',C.font, ...
        'FontSize',8,'FontWeight','bold','Color',ccol(char(coasts(k))),'VerticalAlignment','bottom');
end
end

function s=wrap_name(name)
s=char(extractBefore(name+" (", " ("));
s=strrep(s,'New York-New Jersey',['New York-' newline 'New Jersey']);
if numel(s)>12 && ~contains(s,newline)
    k=find(s==' ' | s=='-',1);
    if ~isempty(k)
        s=[s(1:k) newline s(k+1:end)];
    end
end
end

function C=style()
C.dark=[22 51 83]/255;
C.blue=[86 116 196]/255;
C.purple=[110 79 146]/255;
C.ochre=[154 107 0]/255;
C.gray=[138 141 145]/255;
C.panel=[232 233 234]/255;
C.grid=[230 230 230]/255;
C.font='Times New Roman';
end

function [fig,ax]=new_page(C,title_str,subtitle,source,h_in,pos)
fig=figure('Visible','off','Units','inches','Position',[0 0 8 h_in],'Color','w','Theme','light');
annotation(fig,'textbox',[0.02 1-0.32/h_in 0.96 0.25/h_in],'String','DRAFT//PRE-DECISIONAL','EdgeColor','none', ...
    'Color',C.dark,'FontWeight','bold','FontName',C.font,'FontSize',8);
annotation(fig,'textbox',[0.02 1-1.0/h_in 0.96 0.62/h_in],'String',title_str,'EdgeColor','none','Color',C.dark, ...
    'FontWeight','bold','FontName',C.font,'FontSize',12.5,'VerticalAlignment','top');
annotation(fig,'textbox',[0.02 1-1.42/h_in 0.96 0.4/h_in],'String',subtitle,'EdgeColor','none','Color',C.dark, ...
    'FontName',C.font,'FontSize',9,'VerticalAlignment','top');
annotation(fig,'textbox',[0.02 0.01 0.96 0.55/h_in],'String',source,'EdgeColor','none','Color',C.dark, ...
    'FontName',C.font,'FontSize',7.5,'VerticalAlignment','bottom');
ax=axes(fig,'Position',pos);
hold(ax,'on');
end

function style_axes(C,ax)
hold(ax,'on');
set(ax,'FontName',C.font,'FontSize',8,'XColor',C.dark,'YColor',C.dark,'Box','off','TickDir','out', ...
    'YGrid','on','GridColor',C.grid,'GridAlpha',1);
end

function finish(C,fig,name)
exportgraphics(fig,fullfile(C.out_dir,[name '.png']),'Resolution',C.dpi,'BackgroundColor','white');
close(fig);
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
