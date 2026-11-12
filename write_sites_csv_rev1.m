function [S]=write_sites_csv_rev1(result,csv_path)
%write_sites_csv_rev1  One CSV of every checked site: racons, VTS areas, and ports.
%
%   S=write_sites_csv_rev1(result,csv_path) gathers the racons
%   (result.racons_all, every charted racon in the grid), the Vessel Traffic
%   Service areas (result.vts_check), the named ports (result.port_check),
%   and the USACE Principal Ports (result.principal_port_check) into one
%   table and writes it to CSV_PATH. Columns: category, name, lat, lon,
%   sband_source (racons charted in S-band, which are zone sources),
%   gap_to_ship_cell_km, reached_by_ship_routes, in_<X>km_zone for each
%   zone distance, and notes. Missing inputs are skipped.

arguments
    result (1,1) struct
    csv_path (1,:) char
end

parts=cell(0,1);
if isfield(result,'racons_all')
    T=result.racons_all;
    parts{end+1,1}=site_table("racon",T.name,T.lat,T.lon,T.s_band,NaN(height(T),1),false(height(T),1), ...
        "chart wavelength "+T.radwal,result);
end
if isfield(result,'vts_check')
    T=result.vts_check;
    parts{end+1,1}=site_table("vts_area",T.port,T.lat,T.lon,false(height(T),1),T.gap_to_ship_cell_km, ...
        T.reached & T.on_route_network,repmat("Coast Guard Vessel Traffic Service area, approximate center",height(T),1),result);
end
if isfield(result,'port_check')
    T=result.port_check;
    parts{end+1,1}=site_table("named_port",T.port,T.lat,T.lon,false(height(T),1),T.gap_to_ship_cell_km, ...
        T.reached & T.on_route_network,repmat("required deep-draft port (p.check_ports)",height(T),1),result);
end
if isfield(result,'principal_port_check')
    T=result.principal_port_check;
    parts{end+1,1}=site_table("usace_principal_port",T.port,T.lat,T.lon,false(height(T),1),T.gap_to_ship_cell_km, ...
        T.reached & T.on_route_network,"type "+T.type+"; rank "+string(T.rank)+"; foreign tons "+string(round(T.foreign_tons)),result);
end
S=vertcat(parts{:});
writetable(S,csv_path);
end

function T=site_table(category,name,lat,lon,sband,gap,reached,notes,result)
%%%%%One block of rows, with a zone-membership column per distance
n=numel(lat);
T=table(repmat(string(category),n,1),string(name),lat(:),lon(:),logical(sband(:)),gap(:),logical(reached(:)), ...
    'VariableNames',{'category','name','lat','lon','sband_source','gap_to_ship_cell_km','reached_by_ship_routes'});
for z=1:numel(result.zone)
    if n==0   %%%%%no sites of this kind in the grid (Hawaii has no S-band racons); isinterior rejects empty points
        T.(sprintf('in_%gkm_zone',result.zone(z).distance_km))=false(0,1);
    else
        T.(sprintf('in_%gkm_zone',result.zone(z).distance_km))=isinterior(result.zone(z).poly,lon(:),lat(:));
    end
end
T.notes=string(notes(:));
end
