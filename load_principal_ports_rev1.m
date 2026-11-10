function [ports]=load_principal_ports_rev1(cache_csv)
%load_principal_ports_rev1  USACE Principal Ports (name, type, tonnage, location).
%
%   ports=load_principal_ports_rev1(cache_csv) returns the USACE Principal
%   Ports of the United States as a table: name, type ("C" coastal, "L"
%   Great Lakes, "I" inland), rank, total_tons, foreign_tons, lat, lon.
%   The first call downloads the layer from a public ArcGIS copy (NETL
%   Energy Transition Atlas, layer "Principal Port") and caches it as a
%   CSV; later calls read the cache.
%
%   Each port's location is the USACE reference point for the port
%   district, which can sit a few kilometers from the ship berths.

arguments
    cache_csv (1,:) char
end

if ~isfile(cache_csv)
    url=['https://arcgis.netl.doe.gov/server/rest/services/Hosted/' ...
        'Energy_Transition_Atlas_493d6/FeatureServer/16/query'];
    J=webread(url,'where','1=1','outFields','port_name,type,rank,total,foreign_,latitude1,longitude1', ...
        'returnGeometry','false','f','json',weboptions('Timeout',120));
    features=J.features;
    if ~iscell(features)
        features=num2cell(features);
    end
    A=cellfun(@(s) s.attributes,features);
    T=struct2table(A(:));
    T=renamevars(T,{'port_name','total','foreign_','latitude1','longitude1'}, ...
        {'name','total_tons','foreign_tons','lat','lon'});
    T=T(:,{'name','type','rank','total_tons','foreign_tons','lat','lon'});
    writetable(sortrows(T,'rank'),cache_csv);
end
ports=readtable(cache_csv,'TextType','string');
end
