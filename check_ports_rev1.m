function [T]=check_ports_rev1(result,ports,max_gap_km,min_network_cells,warn_rows,link_cells)
%check_ports_rev1  Confirm that large-ship traffic reaches named ports.
%
%   T=check_ports_rev1(result,ports,max_gap_km) returns, for each port in
%   the table PORTS (name, lat, lon), the distance from the port to the
%   nearest large-ship cell and whether the port is inside each zone.
%   Ports farther than MAX_GAP_KM (default 2 km) from a ship cell are
%   flagged with reached=false, and a warning names them, so a filter
%   change that cuts off a river port (for example, Baton Rouge at the head
%   of deep-draft navigation on the Mississippi) can't pass unnoticed.
%
%   WARN_ROWS (default all true) picks the ports a miss should warn about,
%   for example only the deep-draft ports in a longer list.
%
%   It also reports, per port, whether the ship cells near the port belong
%   to a large connected network of ship cells (cells within LINK_CELLS
%   cells of each other count as connected, default 3, about 3 km, which
%   bridges short gaps where approach traffic spreads out; at least
%   MIN_NETWORK_CELLS cells, or touching the grid edge, where routes leave
%   for open sea). The Gulf, Atlantic, Pacific, and Great Lakes networks
%   don't join inside the grid, so there is more than one. A river port on
%   a small isolated patch fails this test.

arguments
    result (1,1) struct
    ports table
    max_gap_km (1,1) double {mustBePositive} = 2
    min_network_cells (1,1) double {mustBePositive} = 2000
    warn_rows logical = true(height(ports),1)
    link_cells (1,1) double {mustBeInteger,mustBePositive} = 3
end

R=result.R;
source_mask=full(result.source_mask);
earth_radius_km=6371.0088;
lat_vec=R.LatitudeLimits(1)+R.CellExtentInLatitude*((1:R.RasterSize(1))'-0.5);
lon_vec=R.LongitudeLimits(1)+R.CellExtentInLongitude*((1:R.RasterSize(2))-0.5);

%%%%%Connected pieces of the ship-cell mask (graph conncomp; bwconncomp needs Image Processing)
[row_s,col_s]=find(source_mask);
num_src=numel(row_s);
id=zeros(R.RasterSize);
id(sub2ind(R.RasterSize,row_s,col_s))=1:num_src;
edges=zeros(0,2);
for dr=0:link_cells
    for dc=-link_cells:link_cells
        if dr==0 && dc<=0
            continue   %%%%%each neighbor pair once
        end
        r2=row_s+dr;
        c2=col_s+dc;
        ok=r2>=1 & r2<=R.RasterSize(1) & c2>=1 & c2<=R.RasterSize(2);
        j=zeros(size(r2));
        j(ok)=id(sub2ind(R.RasterSize,r2(ok),c2(ok)));
        edges=[edges; find(j>0) j(j>0)]; %#ok<AGROW> a few dozen offsets at most
    end
end
piece=conncomp(graph(edges(:,1),edges(:,2),[],num_src));
piece_size=accumarray(piece(:),1);
at_edge=row_s==1 | row_s==R.RasterSize(1) | col_s==1 | col_s==R.RasterSize(2);
touches_edge=accumarray(piece(:),at_edge,[numel(piece_size) 1],@any);
is_network=piece_size>=min_network_cells | touches_edge;

num_port=height(ports);
gap_km=NaN(num_port,1);
on_network=false(num_port,1);
for k=1:num_port
    d=2*earth_radius_km*asin(min(1,sqrt(sind((lat_vec(row_s)-ports.lat(k))/2).^2 + ...
        cosd(ports.lat(k))*cosd(lat_vec(row_s)).*sind((lon_vec(col_s)'-ports.lon(k))/2).^2)));
    [gap_km(k),ix]=min(d);
    on_network(k)=is_network(piece(ix));
end
extra=ports(:,setdiff(ports.Properties.VariableNames,{'name','lat','lon'},'stable'));
T=table(string(ports.name),ports.lat,ports.lon,gap_km,gap_km<=max_gap_km,on_network, ...
    'VariableNames',{'port','lat','lon','gap_to_ship_cell_km','reached','on_route_network'});
T=[T extra];   %%%%%carry any extra columns (type, rank, tonnage) through
for z=1:numel(result.zone)
    T.(sprintf('in_%gkm_zone',result.zone(z).distance_km))=isinterior(result.zone(z).poly,ports.lon,ports.lat);
end

missed=T.port(warn_rows(:) & (~T.reached | ~T.on_route_network));
if ~isempty(missed)
    warning('shipgis:portMissed','Large-ship routes do not reach: %s',strjoin(missed,', '));
end
end
