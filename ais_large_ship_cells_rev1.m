function [pairs,num_row_kept,num_mmsi_kept]=ais_large_ship_cells_rev1(csv_path,R,filt,read_rows)
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
%                         init_check_gt_proxy_rev1 found 99.6% precision
%                         and 98.1% recall against registry tonnage)
%     filt.require_imo    IMO number present (IMO numbers go to seagoing
%                         SOLAS ships), default true
%     filt.no_imo_types   optional: AIS types kept without an IMO number
%                         (military 35, law enforcement 55)
%     filt.min_sog_kn     minimum speed over ground, default 0 (keep ships
%                         at anchor; radars are often on at anchor)
%
%   INPUTS
%     csv_path  daily AIS CSV (2024+ snake_case or 2009-2023 CamelCase)
%     R         GeographicCellsReference of the analysis grid
%     filt      struct with the fields above
%     read_rows rows read per chunk (default 1e6). The file is read in
%               chunks with a tabularTextDatastore, so memory stays near
%               one chunk (about 150 MB at 1e6 rows) instead of the whole
%               day (7-10 million rows).
%
%   OUTPUTS
%     pairs          K-by-2 double, unique [linear cell index, MMSI]
%     num_row_kept   AIS reports that passed the filter
%     num_mmsi_kept  distinct MMSI that passed the filter

arguments
    csv_path (1,:) char
    R (1,1) map.rasterref.GeographicCellsReference
    filt (1,1) struct
    read_rows (1,1) double {mustBePositive,mustBeInteger} = 1e6
end

%%%%%Map both column-name styles onto one set of names
ds=tabularTextDatastore(csv_path,'TextType','string');
key=lower(erase(ds.VariableNames,'_'));
name_map=struct('mmsi',{{'mmsi'}},'lat',{{'lat','latitude'}},'lon',{{'lon','longitude'}}, ...
    'sog',{{'sog'}},'imo',{{'imo'}},'vessel_type',{{'vesseltype'}},'length',{{'length'}});
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

%%%%%Read, filter, and bin one chunk at a time
chunk_pairs=cell(0,1);
chunk_mmsi=cell(0,1);
num_row_kept=0;
while hasdata(ds)
    T=read(ds);
    T=renamevars(T,src_names,out_names);
    keep=ismember(T.vessel_type,filt.vessel_types) & T.length>=filt.min_length_m;
    if filt.require_imo
        has_imo=strlength(T.imo)>0 & ~ismissing(T.imo);
        if isfield(filt,'no_imo_types')
            has_imo=has_imo | ismember(T.vessel_type,filt.no_imo_types);   %%%%%e.g. Navy ships carry no IMO number
        end
        keep=keep & has_imo;
    end
    if filt.min_sog_kn>0
        keep=keep & T.sog>=filt.min_sog_kn;
    end
    T=T(keep,:);
    num_row_kept=num_row_kept+height(T);
    chunk_mmsi{end+1,1}=unique(T.mmsi); %#ok<AGROW> chunk count is not known in advance

    %%%%%Bin onto the grid; reports outside the grid return NaN and are dropped
    [row_idx,col_idx]=geographicToDiscrete(R,T.lat,T.lon);
    in_grid=~isnan(row_idx);
    cell_idx=sub2ind(R.RasterSize,row_idx(in_grid),col_idx(in_grid));
    chunk_pairs{end+1,1}=unique([cell_idx T.mmsi(in_grid)],'rows'); %#ok<AGROW>
end
num_mmsi_kept=numel(unique(vertcat(chunk_mmsi{:})));
pairs=unique(vertcat(chunk_pairs{:}),'rows');
if isempty(pairs)
    pairs=zeros(0,2);
end
end
