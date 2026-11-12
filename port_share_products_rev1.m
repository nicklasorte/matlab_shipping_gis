function [ps]=port_share_products_rev1(p,prod,type_filts)
%port_share_products_rev1  Share of large-ship port visits at each deep-draft port.
%
%   ps=port_share_products_rev1(p,prod,type_filts) uses PROD from
%   viz_products_rev1 (pairs per year, main filter plus coastal tug-barges)
%   and the ship-type day caches in TYPE_FILTS. Port areas are the cells
%   within 10 km of a deep-draft port (coastal or Great Lakes USACE Principal
%   Port with at least 1 million tons of foreign trade), each cell assigned to
%   its nearest port. Traffic at a port = distinct large ships seen in its
%   area; a ship that calls at two ports counts at both, so shares are shares
%   of port visits. Returns:
%
%     ps.ports    table port, short, complex, coast, lat, lon, rank, ships,
%                 ships_y0, ships_y1, share, cargo, tanker, passenger,
%                 government (sorted by ships, descending)
%     ps.complex  table complex, coast, ships (distinct in the union of its
%                 port areas), visits (sum of its ports), share
%
%   Names come from config/port_short_names_rev1.csv and complexes from
%   config/port_complexes_rev1.csv. The Python twin is
%   python/ship_port_share_products.py. Built-ins: readtable,
%   KDTreeSearcher/knnsearch on spherical ECEF, unique, accumarray.

arguments
    p (1,1) struct
    prod (1,1) struct
    type_filts (1,1) struct
end

port_km=10;
R=prod.R;
nr=R.RasterSize(1);
earth_km=6371.0088;
xyz=@(lat,lon) earth_km*[cosd(lat).*cosd(lon) cosd(lat).*sind(lon) sind(lat)];
cell_lat=@(c) R.LatitudeLimits(1)+R.CellExtentInLatitude*(mod(c-1,nr)+0.5);
cell_lon=@(c) R.LongitudeLimits(1)+R.CellExtentInLongitude*(floor((c-1)/nr)+0.5);

pp=readtable(fullfile(p.out_dir,sprintf('%s_principal_port_check.csv',p.out_name)),'TextType','string');
pp=pp(pp.type~="I" & pp.foreign_tons>=1e6,:);
sn=readtable(fullfile(p.config_dir,'port_short_names_rev1.csv'),'TextType','string');
cx=readtable(fullfile(p.config_dir,'port_complexes_rev1.csv'),'TextType','string');
[~,j]=ismember(pp.port,sn.port);
short=sn.short(j);
comp=short;
[tf,j]=ismember(pp.port,cx.port);
comp(tf)=cx.complex(j(tf));
coast=coast_region(pp.lat,pp.lon);
coast(pp.type=="L")="Great Lakes";
num_port=height(pp);
tree=KDTreeSearcher(xyz(pp.lat,pp.lon));
chord=2*earth_km*sin(port_km/(2*earth_km));

counts=@(P) port_counts(P,tree,chord,num_port,cell_lat,cell_lon,xyz);
[n_all,pm]=counts(unique([prod.pairs_year{1}; prod.pairs_year{2}],'rows'));
per=period_rev1();
n23=counts(prod.pairs_year{prod.years==per.years(1)});   %%%%%first year
n24=counts(prod.pairs_year{prod.years==per.years(2)});   %%%%%second year
types=["cargo","tanker","passenger","government"];
n_type=zeros(num_port,numel(types));
for k=1:numel(types)
    pk=p;
    pk.filt=type_filts.(types(k));
    tp=zeros(0,2);
    for d=p.ais_days(:)'
        S=ais_cache_day_rev1(d,R,pk);
        tp=[tp; S.pairs]; %#ok<AGROW> 104 days, unique below
    end
    n_type(:,k)=counts(unique(tp,'rows'));
end
total=sum(n_all);
T=table(pp.port,short,comp,coast,pp.lat,pp.lon,pp.rank,n_all,n23,n24,n_all/total, ...
    'VariableNames',{'port','short','complex','coast','lat','lon','rank','ships','ships_y0','ships_y1','share'});
for k=1:numel(types)
    T.(types(k))=n_type(:,k);
end
port_index=(1:num_port)';
T.port_index=port_index;
T=sortrows(T,'ships','descend');

%%%%%Complexes: distinct ships in the union of the member port areas
[uc,~,ic]=unique(comp,'stable');
ships=zeros(numel(uc),1);
visits=accumarray(ic,n_all);
c_coast=strings(numel(uc),1);
for k=1:numel(uc)
    idx=find(ic==k);
    ships(k)=numel(unique(pm(ismember(pm(:,1),idx),2)));
    c_coast(k)=coast(idx(1));
end
C=table(uc,c_coast,ships,visits,visits/total,'VariableNames',{'complex','coast','ships','visits','share'});
ps.ports=removevars(T,'port_index');
ps.complex=sortrows(C,'visits','descend');
end

function [n,pm]=port_counts(P,tree,chord,num_port,cell_lat,cell_lon,xyz)
%%%%%Distinct ships per port area; each cell goes to its nearest port within the chord distance
[uc,~,iu]=unique(P(:,1));
[ip,d]=knnsearch(tree,xyz(cell_lat(uc),cell_lon(uc)));
ip(d>chord)=0;
pi_=ip(iu);
keep=pi_>0;
pm=unique([pi_(keep) P(keep,2)],'rows');
n=accumarray(pm(:,1),1,[num_port 1]);
end

function reg=coast_region(lat,lon)
%%%%%Pacific, Gulf, Atlantic, Great Lakes by simple boxes (same as the Python twin)
reg=repmat("Atlantic",size(lat));
reg(lon<-114)="Pacific";
reg(lon>=-98 & lon<-81 & lat<31)="Gulf";
lakes=(lat>41 & lat<49.5 & lon>-92.5 & lon<-75.8) | (lat>43.8 & lat<45.5 & lon>=-76.5 & lon<-74.3);
reg(lakes)="Great Lakes";
end
