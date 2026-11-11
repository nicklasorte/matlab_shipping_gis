function [geo]=geo_products_rev1(p,prod,type_filts)
%geo_products_rev1  Data behind the nine geographic figures (Appendix A, maps A-9 to A-17).
%
%   geo=geo_products_rev1(p,prod,type_filts) uses PROD from viz_products_rev1
%   (route cells and the unique [cell mmsi] pairs) and the AIS day caches for
%   the ship-type filters in TYPE_FILTS (struct: name -> filt struct) and
%   returns:
%
%     geo.hex        table q, r, x_km, y_km, ships: distinct large ships per
%                    25 km hexagon (Albers, pointy-top), route cells only
%     geo.hex_types  table type, q, r, x_km, y_km, ships, one row per hexagon per type
%     geo.ports      table port, lat, lon, rank, ships: distinct large ships
%                    within 10 km of each deep-draft port
%     geo.profile    table coast, axis, from_deg, to_deg, ships: distinct large
%                    ships within 50 km of shore per half degree along each coast
%     geo.land       struct lat, lon, dist_km: distance from land to the nearest
%                    route cell on a 0.05 degree grid
%     geo.summary    struct of the headline numbers
%
%   The Python twin is python/ship_geo_products.py. Built-ins: projcrs/projfwd
%   for Albers, unique/accumarray for counts, KDTreeSearcher with knnsearch and
%   rangesearch on spherical ECEF for distances.

arguments
    p (1,1) struct
    prod (1,1) struct
    type_filts (1,1) struct
end

R=prod.R;
nr=R.RasterSize(1);
earth_km=6371.0088;
xyz=@(lat,lon) earth_km*[cosd(lat).*cosd(lon) cosd(lat).*sind(lon) sind(lat)];
arc=@(ch) 2*earth_km*asin(min(ch/(2*earth_km),1));
cell_lat=@(c) R.LatitudeLimits(1)+R.CellExtentInLatitude*(mod(c-1,nr)+0.5);
cell_lon=@(c) R.LongitudeLimits(1)+R.CellExtentInLongitude*(floor((c-1)/nr)+0.5);
albers=projcrs(5070);
hex_r=12.5;

%%%%%1. Hexagons, all large ships on route cells
P=prod.all_pairs;
Pr=P(ismember(P(:,1),prod.route_cells),:);
geo.hex=hex_counts(Pr,cell_lat,cell_lon,albers,hex_r);
n=sort(geo.hex.ships,'descend');
s.hex_count=height(geo.hex);
s.hex_max_ships=n(1);
s.hex_share_top5pct=sum(n(1:max(1,floor(numel(n)/20))))/sum(n);
s.hex_ge_1000=nnz(n>=1000);

%%%%%7. Hexagons by ship type (all cells for that type)
types=string(fieldnames(type_filts))';
parts=cell(numel(types),1);
for k=1:numel(types)
    pk=p;
    pk.filt=type_filts.(types(k));
    tp=zeros(0,2);
    for d=p.ais_days(:)'
        S=ais_cache_day_rev1(d,R,pk);
        tp=[tp; S.pairs]; %#ok<AGROW> 104 days, unique below
    end
    tp=unique(tp,'rows');
    T=hex_counts(tp,cell_lat,cell_lon,albers,hex_r);
    T=addvars(T,repmat(types(k),height(T),1),'Before',1,'NewVariableNames','type');
    parts{k}=T;
    s.(sprintf('type_ships_%s',types(k)))=numel(unique(tp(:,2)));
    reg=coast_region(cell_lat(tp(:,1)),cell_lon(tp(:,1)));
    s.(sprintf('type_share_ships_gulf_%s',types(k)))=numel(unique(tp(reg=="Gulf",2)))/numel(unique(tp(:,2)));
end
geo.hex_types=vertcat(parts{:});
if isempty(geo.hex_types)
    geo.hex_types=table();
end

%%%%%6. Deep-draft ports: distinct ships within 10 km
pp=readtable(fullfile(p.out_dir,sprintf('%s_principal_port_check.csv',p.out_name)),'TextType','string');
pp=pp(pp.type~="I" & pp.foreign_tons>=1e6,:);
[uc,~,inv]=unique(P(:,1));
port_tree=KDTreeSearcher(xyz(pp.lat,pp.lon));
chord=2*earth_km*sin(10/(2*earth_km));
hits=rangesearch(port_tree,xyz(cell_lat(uc),cell_lon(uc)),chord);
nhit=cellfun(@numel,hits);
cell_of_hit=repelem((1:numel(uc))',nhit);
port_of_hit=[hits{:}]';
%%%%%Join pairs to the cell -> port hits (many to many), then count distinct ships per port
near_port=nhit(inv)>0;
J=innerjoin(table(inv(near_port),P(near_port,2),'VariableNames',{'c','mmsi'}), ...
    table(cell_of_hit,port_of_hit,'VariableNames',{'c','port'}),'Keys','c');
pm=unique([J.port J.mmsi],'rows');
ships=accumarray(pm(:,1),1,[height(pp) 1]);
geo.ports=table(pp.port,pp.lat,pp.lon,pp.rank,ships,'VariableNames',{'port','lat','lon','rank','ships'});
[~,o]=sort(ships,'descend');
s.ports_top=[cellstr(pp.port(o(1:10))) num2cell(ships(o(1:10)))];
s.ports_ge_1000=nnz(ships>=1000);

%%%%%5. Near-shore profile along each coast
[~,~,coast_mask]=census_reference_rev1(R,p.data_dir,p.census_year);
cmask_cells=find(coast_mask);
coast_tree=KDTreeSearcher(xyz(cell_lat(cmask_cells),cell_lon(cmask_cells)));
[~,ch]=knnsearch(coast_tree,xyz(cell_lat(uc),cell_lon(uc)));
ck=arc(ch);
ulat=cell_lat(uc);
ulon=cell_lon(uc);
reg=coast_region(ulat,ulon);
spec={"Pacific","lat",32.0,49.0; "Gulf","lon",-97.5,-81.0; "Atlantic","lat",24.5,45.0};
prof=cell(3,1);
for k=1:3
    v=ulat;
    if spec{k,2}=="lon"
        v=ulon;
    end
    okc=ck<=50 & reg==spec{k,1} & v>=spec{k,3} & v<spec{k,4};
    b=floor((v-spec{k,3})/0.5);
    keep=okc(inv);
    bp=unique([b(inv(keep)) P(keep,2)],'rows');
    [bb,~,ib]=unique(bp(:,1));
    prof{k}=table(repmat(spec{k,1},numel(bb),1),repmat(spec{k,2},numel(bb),1),spec{k,3}+0.5*bb, ...
        spec{k,3}+0.5*(bb+1),accumarray(ib,1),'VariableNames',{'coast','axis','from_deg','to_deg','ships'});
    [mx,im]=max(prof{k}.ships);
    s.(sprintf('profile_peak_%s',spec{k,1}))=[prof{k}.from_deg(im) prof{k}.to_deg(im) mx];
end
geo.profile=vertcat(prof{:});

%%%%%8. Land distance to the nearest route cell (0.05 degree grid)
[land_mask,~,~]=census_reference_rev1(R,p.data_dir,p.census_year);
glat=(24.0:0.05:49.45)'+0.025;
glon=(-125.0:0.05:-66.55)'+0.025;
[LON,LAT]=meshgrid(glon,glat);
[ri,ci]=geographicToDiscrete(R,LAT(:),LON(:));
ok=~isnan(ri);
on_land=false(size(LAT));
on_land(ok)=land_mask(sub2ind(R.RasterSize,ri(ok),ci(ok)));
route_tree=KDTreeSearcher(xyz(cell_lat(prod.route_cells),cell_lon(prod.route_cells)));
dist=nan(size(LAT));
[~,ch]=knnsearch(route_tree,xyz(LAT(on_land),LON(on_land)));
dist(on_land)=arc(ch);
geo.land=struct('lat',glat,'lon',glon,'dist_km',dist);
s.land_max_km=max(dist(:),[],'omitnan');

%%%%%S-band racons near the routes (for the sites map headline)
sites=readtable(fullfile(p.out_dir,sprintf('%s_sites.csv',p.out_name)),'TextType','string');
rac=sites(sites.category=="racon" & sites.sband_source==1,:);
[~,ch]=knnsearch(route_tree,xyz(rac.lat,rac.lon));
s.sband_racons=height(rac);
s.sband_racons_within_5km=nnz(arc(ch)<=5);
geo.summary=s;
end

function T=hex_counts(P,cell_lat,cell_lon,albers,r)
%%%%%Distinct ships per pointy-top hexagon of circumradius r (km) in Albers
[uc,~,inv]=unique(P(:,1));
[x,y]=projfwd(albers,cell_lat(uc),cell_lon(uc));
[q,rr]=hex_index(x/1e3,y/1e3,r);
hp=unique([q(inv) rr(inv) P(:,2)],'rows');
[h,~,ih]=unique(hp(:,1:2),'rows');
ships=accumarray(ih,1);
xc=r*sqrt(3)*(h(:,1)+h(:,2)/2);
yc=r*1.5*h(:,2);
T=table(h(:,1),h(:,2),xc,yc,ships,'VariableNames',{'q','r','x_km','y_km','ships'});
end

function [q,r]=hex_index(x,y,rad)
%%%%%Axial hex index with cube rounding (same as the Python twin)
xc=(sqrt(3)/3*x-y/3)/rad;
zc=(2/3*y)/rad;
yc=-xc-zc;
rx=round(xc);
ry=round(yc);
rz=round(zc);
dx=abs(rx-xc);
dy=abs(ry-yc);
dz=abs(rz-zc);
fix_x=dx>dy & dx>dz;
fix_z=~fix_x & dy<=dz;
rx(fix_x)=-ry(fix_x)-rz(fix_x);
rz(fix_z)=-rx(fix_z)-ry(fix_z);
q=rx;
r=rz;
end

function reg=coast_region(lat,lon)
%%%%%Pacific, Gulf, Atlantic, Great Lakes by simple boxes (same as the Python twin)
reg=repmat("Atlantic",size(lat));
reg(lon<-114)="Pacific";
reg(lon>=-98 & lon<-81 & lat<31)="Gulf";
lakes=(lat>41 & lat<49.5 & lon>-92.5 & lon<-75.8) | (lat>43.8 & lat<45.5 & lon>=-76.5 & lon<-74.3);
reg(lakes)="Great Lakes";
end
