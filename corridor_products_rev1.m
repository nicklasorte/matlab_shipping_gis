function [cor]=corridor_products_rev1(prod,corridor_csv)
%corridor_products_rev1  Distinct large ships along each river and ship channel.
%
%   cor=corridor_products_rev1(prod,corridor_csv) generalizes the Mississippi
%   profile (Head of Passes to Baton Rouge) to every corridor in CORRIDOR_CSV
%   (config/corridors_rev1.csv: corridor, label, role, name, lat, lon; role
%   is start, mark, end, or the optional target). PROD comes from
%   viz_products_rev1. For each corridor:
%
%     1. Route cells inside a box around the start, end, and marks (padded
%        0.3 degrees) become the nodes of a graph with 8-neighbor edges. Each
%        edge costs km*(1+100/ships), ships = the smaller distinct-ship count
%        of its two cells, so the path keeps to the busy channel.
%     2. shortestpath runs from the cell nearest the start to the reachable
%        cell nearest the target (the end port unless a target is given).
%     3. Reachable route cells within 2 km of the path take the along-path
%        distance of the nearest path cell. Distinct ships are counted per
%        2 km reach (corridors under 120 km) or 5 km reach.
%     4. Entrance: distinct ships within 3 km (along the path) of the start.
%        Head: distinct ships within 3 km of the end port, or of the path
%        end when the routes stop short of the port.
%     5. Continuation: distinct ships seen at or beyond each point (any
%        sampled day), on 201 points with distance scaled so 1 = the head
%        port, counted from 3 km in (which drops ships passing the entrance).
%        It can only fall going upstream, so anchorage spikes drop out.
%
%   Returns struct cor with tables profile, marks, cells, path, summary,
%   continuation (same
%   columns as the Python twin, python/ship_corridor_products.py).
%
%   Built-ins: readtable, graph/shortestpath/distances, KDTreeSearcher with
%   knnsearch on spherical ECEF, ismember, unique, accumarray.

arguments
    prod (1,1) struct
    corridor_csv (1,:) char
end

box_pad=0.3;
cost_k=100;
path_km_max=2;
end_km=3;
short_km=120;

R=prod.R;
nr=R.RasterSize(1);
nc=R.RasterSize(2);
earth_km=6371.0088;
xyz=@(lat,lon) earth_km*[cosd(lat).*cosd(lon) cosd(lat).*sind(lon) sind(lat)];
arc=@(ch) 2*earth_km*asin(min(ch/(2*earth_km),1));
cell_lat=@(c) R.LatitudeLimits(1)+R.CellExtentInLatitude*(mod(c-1,nr)+0.5);
cell_lon=@(c) R.LongitudeLimits(1)+R.CellExtentInLongitude*(floor((c-1)/nr)+0.5);

C=readtable(corridor_csv,'TextType','string');
names=unique(C.corridor,'stable');
route=prod.route_cells(:);
[~,loc]=ismember(route,prod.both_cell);
route_ships=prod.both_ships(loc);
rlat=cell_lat(route);
rlon=cell_lon(route);
both=prod.all_pairs;

prof=cell(numel(names),1);
mk=cell(numel(names),1);
ce=cell(numel(names),1);
pa=cell(numel(names),1);
su=cell(numel(names),1);
co=cell(numel(names),1);
for i=1:numel(names)
    Ci=C(C.corridor==names(i),:);
    st=Ci(Ci.role=="start",:);
    en=Ci(Ci.role=="end",:);
    tg=Ci(Ci.role=="target",:);
    if isempty(tg)
        tg=en;
    end
    %%%%%1. Graph of route cells in the box
    in_box=rlat>min(Ci.lat)-box_pad & rlat<max(Ci.lat)+box_pad & rlon>min(Ci.lon)-box_pad & rlon<max(Ci.lon)+box_pad;
    cells=route(in_box);
    sh=route_ships(in_box);
    P3=xyz(cell_lat(cells),cell_lon(cells));
    [r0,c0]=ind2sub([nr nc],cells);
    src=[];
    dst=[];
    for off=[1 -1; 1 0; 1 1; 0 1]'
        rr=r0+off(1);
        cc=c0+off(2);
        ok=rr>=1 & rr<=nr & cc>=1 & cc<=nc;
        nb=zeros(size(cells));
        nb(ok)=sub2ind([nr nc],rr(ok),cc(ok));
        [tf,j]=ismember(nb,cells);
        src=[src; find(tf)]; %#ok<AGROW> four offsets
        dst=[dst; j(tf)]; %#ok<AGROW>
    end
    w=arc(vecnorm(P3(src,:)-P3(dst,:),2,2));
    G=graph(src,dst,w.*(1+cost_k./min(sh(src),sh(dst))),numel(cells));
    %%%%%2. Least-cost path from the start to the reachable cell nearest the target
    tree=KDTreeSearcher(P3);
    s0=knnsearch(tree,xyz(st.lat,st.lon));
    reach=isfinite(distances(G,s0))';
    rtree=KDTreeSearcher(P3(reach,:));
    ridx=find(reach);
    e0=ridx(knnsearch(rtree,xyz(tg.lat,tg.lon)));
    path=shortestpath(G,s0,e0)';
    pkm=[0; cumsum(arc(vecnorm(diff(P3(path,:)),2,2)))];
    %%%%%3. Corridor cells and distinct ships per reach
    ptree=KDTreeSearcher(P3(path,:));
    [ip,dch]=knnsearch(ptree,P3(ridx,:));
    on=arc(dch)<=path_km_max;
    ccell=cells(ridx(on));
    ckm=pkm(ip(on));
    len=pkm(end);
    bin_km=5;
    if len<short_km
        bin_km=2;
    end
    km_of=@(Pp) ckm(loc_in(Pp(:,1),ccell));
    Pb=both(ismember(both(:,1),ccell),:);
    kb=km_of(Pb);
    ub=unique([floor(kb/bin_km) Pb(:,2)],'rows');
    [bb,~,ib]=unique(ub(:,1));
    prof{i}=table(repmat(names(i),numel(bb),1),bb*bin_km,(bb+1)*bin_km,accumarray(ib,1), ...
        'VariableNames',{'corridor','km_from','km_to','ships'});
    [uc,~,iu]=unique(Pb(:,1));
    nship=accumarray(iu,1);
    [tf,j]=ismember(ccell,uc);
    cs=zeros(size(ccell));
    cs(tf)=nship(j(tf));
    ce{i}=table(repmat(names(i),numel(ccell),1),ccell,cell_lat(ccell),cell_lon(ccell),ckm,cs, ...
        'VariableNames',{'corridor','cell','lat','lon','km','ships'});
    [tf,j]=ismember(cells(path),uc);
    ps=zeros(size(path));
    ps(tf)=nship(j(tf));
    pa{i}=table(repmat(names(i),numel(path),1),pkm,cell_lat(cells(path)),cell_lon(cells(path)),ps, ...
        'VariableNames',{'corridor','km','lat','lon','ships'});
    %%%%%4. Entrance and head counts
    e_km=pkm(knnsearch(ptree,xyz(en.lat,en.lon)));
    count=@(Pp,keep) numel(unique(Pp(keep(km_of(Pp)),2)));
    in_c=@(Pp) Pp(ismember(Pp(:,1),ccell),:);
    ent=count(Pb,@(k) k<=end_km);
    head=count(Pb,@(k) abs(k-e_km)<=end_km);
    hy=zeros(1,2);
    for y=1:2
        Py=in_c(prod.pairs_year{y});
        hy(y)=count(Py,@(k) abs(k-e_km)<=end_km);
    end
    %%%%%5. Continuation curve: distinct ships seen at or beyond each point, counted from 3 km in
    [um,~,im]=unique(Pb(:,2));
    far=accumarray(im,kb,[numel(um) 1],@max);
    n_in=nnz(far>=end_km);
    f=linspace(0,1,201)';
    thr=min(max(f*e_km,end_km),e_km-end_km);
    nb=sum(far'>=thr,2);
    co{i}=table(repmat(names(i),numel(f),1),f,nb,nb/n_in, ...
        'VariableNames',{'corridor','frac_to_head','ships_beyond','share_beyond'});
    su{i}=table(names(i),st.label,len,bin_km,ent,head,hy(1),hy(2),head/ent,n_in,nb(end)/n_in, ...
        'VariableNames',{'corridor','label','length_km','bin_km','ships_entrance','ships_head', ...
        'ships_head_2023','ships_head_2024','share_head','ships_entering','share_reaching_head'});
    [jm,dm]=knnsearch(ptree,xyz(Ci.lat,Ci.lon));
    mk{i}=table(Ci.corridor,Ci.role,Ci.name,Ci.lat,Ci.lon,pkm(jm),arc(dm), ...
        'VariableNames',{'corridor','role','name','lat','lon','km','off_path_km'});
end
cor.profile=vertcat(prof{:});
cor.marks=vertcat(mk{:});
cor.cells=vertcat(ce{:});
cor.path=vertcat(pa{:});
cor.summary=vertcat(su{:});
cor.continuation=vertcat(co{:});
end

function j=loc_in(a,b)
%%%%%Location in b of each element of a (all present)
[~,j]=ismember(a,b);
end
