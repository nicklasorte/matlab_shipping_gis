function [pairs,num_row_kept,num_mmsi_kept]=ais_large_ship_cells_rev1(csv_path,R,filt)
%ais_large_ship_cells_rev1  Grid cells visited by large ships in one AIS day.
%
%   [pairs,num_row_kept,num_mmsi_kept]=ais_large_ship_cells_rev1(csv_path,R,filt)
%   reads one daily MarineCadastre AIS CSV, keeps the reports from ships
%   that are likely to carry a 2.9-3.1 GHz (S-band) navigation radar, and
%   returns the unique [cell_index mmsi] pairs on raster R.
%
%   Why these filters (proxy for the SOLAS V/19 radar carriage rule):
%   SOLAS Chapter V Regulation 19 requires ships of 3000 gross tonnage and
%   upward to carry a 3 GHz radar or a second 9 GHz radar. AIS does not
%   report gross tonnage or radar band, so the filter uses:
%     filt.vessel_types   AIS ship-type codes (default 60-69 passenger,
%                         70-79 cargo, 80-89 tanker)
%     filt.min_length_m   length overall, the GT proxy (default 100 m;
%                         TODO: validate against a GT table such as the
%                         USCG PSIX or IHS registry before final use)
%     filt.require_imo    IMO number present (IMO numbers go to seagoing
%                         SOLAS ships), default true
%     filt.min_sog_kn     minimum speed over ground, default 0 (keep ships
%                         at anchor; radars are often on at anchor)
%
%   INPUTS
%     csv_path  daily AIS CSV (2024+ snake_case or 2009-2023 CamelCase)
%     R         GeographicCellsReference of the analysis grid
%     filt      struct with the fields above
%
%   OUTPUTS
%     pairs          K-by-2 double, unique [linear cell index, MMSI]
%     num_row_kept   AIS reports that passed the filter
%     num_mmsi_kept  distinct MMSI that passed the filter

arguments
    csv_path (1,:) char
    R (1,1) map.rasterref.GeographicCellsReference
    filt (1,1) struct
end

%%%%%Map both column-name styles onto one set of names
opts=detectImportOptions(csv_path);
key=lower(erase(opts.VariableNames,'_'));
name_map=struct('mmsi',{{'mmsi'}},'lat',{{'lat','latitude'}},'lon',{{'lon','longitude'}}, ...
    'sog',{{'sog'}},'imo',{{'imo'}},'vessel_type',{{'vesseltype'}},'length',{{'length'}});
out_names=fieldnames(name_map);
src_names=cell(size(out_names));
for k=1:numel(out_names)
    hit=find(ismember(key,name_map.(out_names{k})),1);
    if isempty(hit)
        error('shipgis:columns','Column for "%s" not found in %s',out_names{k},csv_path);
    end
    src_names{k}=opts.VariableNames{hit};
end
opts.SelectedVariableNames=src_names;
num_cols=src_names(~strcmp(out_names,'imo'));
opts=setvartype(opts,num_cols,'double');
opts=setvartype(opts,src_names(strcmp(out_names,'imo')),'string');
T=readtable(csv_path,opts);
T=renamevars(T,src_names,out_names);

%%%%%Large-ship filter
keep=ismember(T.vessel_type,filt.vessel_types) & T.length>=filt.min_length_m;
if filt.require_imo
    keep=keep & strlength(T.imo)>0 & ~ismissing(T.imo);
end
if filt.min_sog_kn>0
    keep=keep & T.sog>=filt.min_sog_kn;
end
T=T(keep,:);
num_row_kept=height(T);
num_mmsi_kept=numel(unique(T.mmsi));

%%%%%Bin onto the grid; reports outside the grid return NaN and are dropped
[row_idx,col_idx]=geographicToDiscrete(R,T.lat,T.lon);
in_grid=~isnan(row_idx);
cell_idx=sub2ind(R.RasterSize,row_idx(in_grid),col_idx(in_grid));
pairs=unique([cell_idx T.mmsi(in_grid)],'rows');
end
