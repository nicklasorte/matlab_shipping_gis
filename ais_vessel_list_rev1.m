function [V]=ais_vessel_list_rev1(csv_path,read_rows)
%ais_vessel_list_rev1  One row per ship from a daily AIS CSV: MMSI, IMO, type, size.
%
%   V=ais_vessel_list_rev1(csv_path,read_rows) reads the static fields of a
%   MarineCadastre AIS day in chunks and returns a table with one row per
%   MMSI: mmsi, imo (number, NaN if none), vessel_type, length_m, width_m.
%   Each field is the most common non-missing value the ship reported that
%   day, so one bad message doesn't decide it.
%
%   Built-ins: tabularTextDatastore for chunked reads, groupsummary with
%   mode for the per-ship values.

arguments
    csv_path (1,:) char
    read_rows (1,1) double {mustBePositive,mustBeInteger} = 1e6
end

ds=tabularTextDatastore(csv_path,'TextType','string');
key=lower(erase(ds.VariableNames,'_'));
name_map=struct('mmsi',{{'mmsi'}},'imo',{{'imo'}},'vessel_type',{{'vesseltype'}}, ...
    'length_m',{{'length'}},'width_m',{{'width'}});
out_names=fieldnames(name_map);
src_names=cell(size(out_names));
for k=1:numel(out_names)
    hit=find(ismember(key,name_map.(out_names{k})),1);
    if isempty(hit)
        error('shipgis:columns','Column for "%s" not found in %s',out_names{k},csv_path);
    end
    src_names{k}=ds.VariableNames{hit};
end
ds.SelectedVariableNames=src_names;
fmt=repmat({'%f'},1,numel(out_names));
fmt(strcmp(out_names,'imo'))={'%q'};
ds.SelectedFormats=fmt;
ds.ReadSize=read_rows;

%%%%%Per chunk: one row per (mmsi, imo, type, length, width) with a count
parts=cell(0,1);
while hasdata(ds)
    T=renamevars(read(ds),src_names,out_names);
    T.imo=str2double(erase(T.imo,"IMO"));   %%%%%"IMO9321483" -> 9321483; blank -> NaN
    parts{end+1,1}=groupsummary(T,out_names,'IncludeMissingGroups',true); %#ok<AGROW> chunk count unknown
end
G=vertcat(parts{:});
G=groupsummary(G,out_names,'sum','GroupCount','IncludeMissingGroups',true);

%%%%%Per ship, keep each field's most frequent non-missing value
mmsi_list=unique(G.mmsi(~isnan(G.mmsi)));
num_ship=numel(mmsi_list);
V=table(mmsi_list,NaN(num_ship,1),NaN(num_ship,1),NaN(num_ship,1),NaN(num_ship,1), ...
    'VariableNames',{'mmsi','imo','vessel_type','length_m','width_m'});
[~,ship_idx]=ismember(G.mmsi,mmsi_list);
for field={'imo','vessel_type','length_m','width_m'}
    f=field{1};
    ok=ship_idx>0 & ~isnan(G.(f)) & G.(f)>0;
    W=groupsummary(table(ship_idx(ok),G.(f)(ok),G.sum_GroupCount(ok),'VariableNames',{'ship','value','n'}), ...
        {'ship','value'},'sum','n');
    W=sortrows(W,{'ship','sum_n'},{'ascend','descend'});
    [~,first]=unique(W.ship,'stable');
    V.(f)(W.ship(first))=W.value(first);
end
end
