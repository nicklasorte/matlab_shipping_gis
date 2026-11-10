function [ref]=load_wikidata_gt_rev1(cache_csv)
%load_wikidata_gt_rev1  Ships' gross tonnage and length by IMO number, from Wikidata.
%
%   ref=load_wikidata_gt_rev1(cache_csv) returns a table with one row per
%   IMO number: imo, gt (gross tonnage), len_wd_m (length on Wikidata,
%   NaN if absent). The first call queries the Wikidata SPARQL service once
%   (all items with an IMO number, property P458, and gross tonnage, P1093;
%   length is P2043) and caches the CSV; later calls read the cache.
%
%   Wikidata is a public, community-edited source; most of its ship
%   tonnages were imported from public registers. Rows with gross tonnage
%   of 0 or less are dropped, and IMO numbers listed more than once keep
%   the median value.

arguments
    cache_csv (1,:) char
end

if ~isfile(cache_csv)
    query='SELECT ?imo ?gt ?len WHERE { ?s wdt:P458 ?imo. ?s wdt:P1093 ?gt. OPTIONAL{?s wdt:P2043 ?len} }';
    opts=weboptions('Timeout',180,'ContentType','text', ...
        'HeaderFields',{'User-Agent','NTIA-shipgis-check/0.1';'Accept','text/csv'});
    num_try=3;
    for try_idx=1:num_try
        try
            txt=webwrite('https://query.wikidata.org/sparql',"query",query,opts);
            break
        catch err
            if try_idx==num_try
                error('shipgis:wikidata','Wikidata query failed after %d tries: %s',num_try,err.message);
            end
            pause(65);   %%%%%the service may limit clients to 1 request a minute
        end
    end
    writelines(string(txt),cache_csv);
end

T=readtable(cache_csv,'TextType','string');
T.imo=double(T.imo);
T=T(T.gt>0 & ~isnan(T.imo),:);
ref=groupsummary(T,'imo','median',{'gt','len'});
ref=renamevars(ref,{'median_gt','median_len'},{'gt','len_wd_m'});
ref=ref(:,{'imo','gt','len_wd_m'});
end
