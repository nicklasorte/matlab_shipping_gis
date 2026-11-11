function [prod]=viz_products_rev1(p)
%viz_products_rev1  Data behind the ten ship-data figures, from the AIS day caches.
%
%   prod=viz_products_rev1(p) reads the per-day cache files for p.ais_days
%   (main filter p.filt and tug-barge filter p.filt_towing), keeps tug-barge
%   cells within p.towing_coast_km of the Census coastline, and returns:
%
%     prod.R               grid reference
%     prod.both_cell/ships distinct ships per cell over both years (all cells seen)
%     prod.route_cells     cells with >= p.min_unique_ships ships in either year
%     prod.both_years      route cells that pass in both years
%     prod.only_one_year   route cells that pass in one year only
%     prod.tow_only        route cells that pass only because of tug-barges
%     prod.daily           table: day, year, ships, Pacific, Gulf, Atlantic,
%                          Great_Lakes, Baltimore (distinct ships per day)
%     prod.offshore        table: cell, lat, lon, coast, coast_km (route cells)
%     prod.river           table: river_km_from, river_km_to, ships (Mississippi)
%     prod.river_km        struct: new_orleans, baton_rouge, last (km above Head of Passes)
%     prod.sites           table: group, name, lat, lon, route_km
%     prod.summary         struct of the headline numbers
%
%   The Python twin is python/ship_viz_products.py; both read the same
%   cache files. Built-ins: unique/accumarray for counts, KDTreeSearcher on
%   spherical ECEF for distances, graph/distances/shortestpath for the
%   river distance. The coastline cells come from census_reference_rev1.

arguments
    p (1,1) struct
end

R=georefcells(p.latlim,p.lonlim,1/p.cells_per_degree,1/p.cells_per_degree);
nr=R.RasterSize(1);
earth_km=6371.0088;
xyz=@(lat,lon) earth_km*[cosd(lat).*cosd(lon) cosd(lat).*sind(lon) sind(lat)];
arc=@(ch) 2*earth_km*asin(min(ch/(2*earth_km),1));
cell_ll=@(c) deal(R.LatitudeLimits(1)+R.CellExtentInLatitude*(mod(c-1,nr)+0.5), ...
    R.LongitudeLimits(1)+R.CellExtentInLongitude*(floor((c-1)/nr)+0.5));

%%%%%Coastline cells and a searcher for distance to the coast
[~,~,coast_mask]=census_reference_rev1(R,p.data_dir,p.census_year);
[clat,clon]=cell_ll(find(coast_mask));
coast_tree=KDTreeSearcher(xyz(clat,clon));
coast_km_of=@(c) coast_km(c,cell_ll,coast_tree,xyz,arc);

%%%%%Per day: main pairs plus tug-barge pairs near the coast
days=p.ais_days(:);
num_day=numel(days);
yrs=year(days);
p_tow=p;
p_tow.filt=p.filt_towing;
tow_near=containers.Map('KeyType','double','ValueType','logical');
pairs_year=cell(2,1);
main_year=cell(2,1);
uy=unique(yrs)';
daily=zeros(num_day,6);
baltimore=[39.235 -76.555];
for k=1:num_day
    S=ais_cache_day_rev1(days(k),R,p);
    T=ais_cache_day_rev1(days(k),R,p_tow);
    t=T.pairs;
    if ~isempty(t)
        tc=unique(t(:,1));
        new_c=tc(~isKey(tow_near,num2cell(tc)));
        if ~isempty(new_c)
            near=coast_km_of(new_c)<=p.towing_coast_km;
            for j=1:numel(new_c)
                tow_near(new_c(j))=near(j);
            end
        end
        keep=cell2mat(values(tow_near,num2cell(t(:,1))));
        t=t(keep,:);
    end
    both=unique([S.pairs; t],'rows');
    [blat,blon]=cell_ll(both(:,1));
    reg=coast_region(blat,blon);
    names=["Pacific","Gulf","Atlantic","Great Lakes"];
    daily(k,1)=numel(unique(both(:,2)));
    for j=1:4
        daily(k,1+j)=numel(unique(both(reg==names(j),2)));
    end
    d_b=arc(vecnorm(xyz(blat,blon)-xyz(baltimore(1),baltimore(2)),2,2));
    daily(k,6)=numel(unique(both(d_b<=8,2)));
    yi=find(uy==yrs(k));
    pairs_year{yi}=[pairs_year{yi}; both];
    main_year{yi}=[main_year{yi}; S.pairs];
end
for yi=1:numel(uy)
    pairs_year{yi}=unique(pairs_year{yi},'rows');
    main_year{yi}=unique(main_year{yi},'rows');
end
prod.daily=array2table(daily,'VariableNames',{'ships','Pacific','Gulf','Atlantic','Great_Lakes','Baltimore'});
prod.daily=addvars(prod.daily,days,yrs,'Before',1,'NewVariableNames',{'day','year'});

%%%%%Distinct ships per cell, per year; route cells = >= threshold in either year
pass=@(P) cell_pass(P,p.min_unique_ships);
r_all=cell(2,1);
r_main=cell(2,1);
for yi=1:numel(uy)
    r_all{yi}=pass(pairs_year{yi});
    r_main{yi}=pass(main_year{yi});
end
all_pairs=unique(vertcat(pairs_year{:}),'rows');
[prod.both_cell,~,ic]=unique(all_pairs(:,1));
prod.both_ships=accumarray(ic,1);
prod.route_cells=union(r_all{1},r_all{2});
prod.both_years=intersect(r_all{1},r_all{2});
prod.only_one_year=setxor(r_all{1},r_all{2});
prod.tow_only=setdiff(prod.route_cells,union(r_main{1},r_main{2}));
prod.R=R;

%%%%%Offshore distance of route cells
[rlat,rlon]=cell_ll(prod.route_cells);
rreg=coast_region(rlat,rlon);
prod.offshore=table(prod.route_cells,rlat,rlon,rreg,coast_km_of(prod.route_cells), ...
    'VariableNames',{'cell','lat','lon','coast','coast_km'});

%%%%%Mississippi: river distance from Head of Passes through route cells
in_box=rlat>29.1 & rlat<31.0 & rlon>-91.6 & rlon<-89.2;
rc=prod.route_cells(in_box);
[row_c,col_c]=ind2sub(R.RasterSize,rc);
src=[];dst=[];w=[];
for dr=-1:1
    for dc=-1:1
        if dr<0 || (dr==0 && dc<=0)
            continue   %%%%%each undirected edge once
        end
        nb=sub2ind(R.RasterSize,min(max(row_c+dr,1),R.RasterSize(1)),min(max(col_c+dc,1),R.RasterSize(2)));
        [tf,loc]=ismember(nb,rc);
        ii=find(tf);
        src=[src; ii]; %#ok<AGROW> eight offsets
        dst=[dst; loc(ii)]; %#ok<AGROW>
        [a1,o1]=cell_ll(rc(ii));
        [a2,o2]=cell_ll(rc(loc(ii)));
        w=[w; arc(vecnorm(xyz(a1,o1)-xyz(a2,o2),2,2))]; %#ok<AGROW>
    end
end
G=graph(src,dst,w,numel(rc));
[clat_r,clon_r]=cell_ll(rc);
[~,s0]=min(hypot(clat_r-29.15,(clon_r+89.25)*cosd(29.15)));   %%%%%Head of Passes
dist=distances(G,s0);
reach=find(isfinite(dist));
corridor=reach(clon_r(reach)<-90.9);
[~,kfar]=max(clat_r(corridor));
path_nodes=shortestpath(G,s0,corridor(kfar));
path_km=dist(path_nodes)';
ptree=KDTreeSearcher(xyz(clat_r(path_nodes),clon_r(path_nodes)));
[ip,dch]=knnsearch(ptree,xyz(clat_r(reach),clon_r(reach)));
on_river=arc(dch)<=2;
river_cells=rc(reach(on_river));
river_km=path_km(ip(on_river));
bin_km=5;
P=all_pairs(ismember(all_pairs(:,1),river_cells),:);
[~,loc]=ismember(P(:,1),river_cells);
bins=floor(river_km(loc)/bin_km);
ub=unique([bins P(:,2)],'rows');
[bvals,~,ib]=unique(ub(:,1));
prod.river=table(bvals*bin_km,(bvals+1)*bin_km,accumarray(ib,1), ...
    'VariableNames',{'river_km_from','river_km_to','ships'});
km_at=@(pt) path_km(knnsearch(ptree,xyz(pt(1),pt(2))));
prod.river_km=struct('new_orleans',km_at([29.95 -90.06]),'baton_rouge',km_at([30.44 -91.19]), ...
    'last',path_km(end));

%%%%%Sites: distance to the nearest route cell
route_tree=KDTreeSearcher(xyz(rlat,rlon));
sites=readtable(fullfile(p.out_dir,sprintf('%s_sites.csv',p.out_name)),'TextType','string');
pp=readtable(fullfile(p.out_dir,sprintf('%s_principal_port_check.csv',p.out_name)),'TextType','string');
group=sites.category;
is_pp=group=="usace_principal_port";
[tf,loc]=ismember(sites.name,pp.port);
group(is_pp & tf & pp.type(max(loc,1))=="I")="inland_port";
group(is_pp & tf & pp.type(max(loc,1))~="I" & pp.foreign_tons(max(loc,1))>=1e6)="deep_draft_port";
group(is_pp & tf & pp.type(max(loc,1))~="I" & pp.foreign_tons(max(loc,1))<1e6)="other_coastal_port";
keep=~is_pp | tf;
[~,dch]=knnsearch(route_tree,xyz(sites.lat(keep),sites.lon(keep)));
prod.sites=table(group(keep),sites.name(keep),sites.lat(keep),sites.lon(keep),arc(dch), ...
    'VariableNames',{'group','name','lat','lon','route_km'});

%%%%%Headline numbers
s.route_cells=numel(prod.route_cells);
s.route_cells_main_only=numel(union(r_main{1},r_main{2}));
s.tow_only_cells=numel(prod.tow_only);
s.both_years=numel(prod.both_years);
s.only_one_year=numel(prod.only_one_year);
r=ismember(prod.both_cell,prod.route_cells);
b=ismember(prod.both_cell,prod.both_years);
s.share_traffic_both_years=sum(prod.both_ships(r & b))/sum(prod.both_ships(r));
sh=sort(prod.both_ships(r),'descend');
s.share_cells_half_traffic=find(cumsum(sh)/sum(sh)>=0.5,1)/numel(sh);
for name=["Pacific","Gulf","Atlantic","Great Lakes"]
    f=matlab.lang.makeValidName(name);
    km=prod.offshore.coast_km(prod.offshore.coast==name);
    s.(['offshore_median_km_' f])=median(km);
    s.(['offshore_p90_km_' f])=prctile(km,90);
    [tl,to]=cell_ll(prod.tow_only);
    s.(['tow_only_' f])=nnz(coast_region(tl,to)==name);
end
prod.summary=s;
end

function km=coast_km(c,cell_ll,tree,xyz,arc)
[lat,lon]=cell_ll(c);
[~,ch]=knnsearch(tree,xyz(lat,lon));
km=arc(ch);
end

function cells=cell_pass(P,min_ships)
%%%%%Cells with at least MIN_SHIPS distinct ships in pair list P
[c,~,ic]=unique(P(:,1));
n=accumarray(ic,1);
cells=c(n>=min_ships);
end

function reg=coast_region(lat,lon)
%%%%%Pacific, Gulf, Atlantic, Great Lakes by simple boxes (same as the Python twin)
reg=repmat("Atlantic",size(lat));
reg(lon<-114)="Pacific";
reg(lon>=-98 & lon<-81 & lat<31)="Gulf";
lakes=(lat>41 & lat<49.5 & lon>-92.5 & lon<-75.8) | (lat>43.8 & lat<45.5 & lon>=-76.5 & lon<-74.3);
reg(lakes)="Great Lakes";
end
