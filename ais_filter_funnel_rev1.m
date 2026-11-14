function [funnel,by_type]=ais_filter_funnel_rev1(csv_path,R,filt,read_rows)
%ais_filter_funnel_rev1  Reports and ships left after each step of the large-ship filter.
%
%   [funnel,by_type]=ais_filter_funnel_rev1(csv_path,R,filt) reads one full
%   daily MarineCadastre AIS CSV (not prefiltered) and applies the filter of
%   ais_large_ship_cells_rev1 one step at a time:
%     1. all reports
%     2. AIS ship type in filt.vessel_types
%     3. and length overall >= filt.min_length_m
%     4. and an IMO number (or a type in filt.no_imo_types)
%     5. and inside the analysis grid R
%   FUNNEL is a table: step, reports, ships (distinct MMSI), and the share of
%   each kept relative to step 1. BY_TYPE breaks the ships and reports left
%   after step 5 down by AIS ship-type group.
%
%   The steps match ais_large_ship_cells_rev1 (same column mapping, same
%   tests), so the step-5 reports equal that function's num_row_kept for
%   reports inside the grid.
%
%   Built-ins: tabularTextDatastore for chunked reads, ismember and unique
%   for the counts, geographicToDiscrete for the grid test.

arguments
    csv_path (1,:) char
    R (1,1) map.rasterref.GeographicCellsReference
    filt (1,1) struct
    read_rows (1,1) double {mustBePositive,mustBeInteger} = 1e6
end

ds=tabularTextDatastore(csv_path,'TextType','string');
key=lower(erase(ds.VariableNames,'_'));
name_map=struct('mmsi',{{'mmsi'}},'lat',{{'lat','latitude'}},'lon',{{'lon','longitude'}}, ...
    'imo',{{'imo'}},'vessel_type',{{'vesseltype'}},'length',{{'length'}});
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

num_step=5;
step_reports=zeros(num_step,1);
step_mmsi=cell(num_step,1);
final_type=zeros(0,2);   %%%%%[mmsi vessel_type] after step 5
final_rows=zeros(0,1);   %%%%%vessel_type per kept report (for report counts by group)
length_type=zeros(0,2);  %%%%%[mmsi vessel_type] after step 3 (type and length), for ships by group before the IMO test (review R2NUM-6)
while hasdata(ds)
    T=read(ds);
    T=renamevars(T,src_names,out_names);
    has_imo=strlength(T.imo)>0 & ~ismissing(T.imo);
    if isfield(filt,'no_imo_types')
        has_imo=has_imo | ismember(T.vessel_type,filt.no_imo_types);
    end
    [row_idx,~]=geographicToDiscrete(R,T.lat,T.lon);
    keep=true(height(T),num_step);
    keep(:,2)=ismember(T.vessel_type,filt.vessel_types);
    keep(:,3)=keep(:,2) & T.length>=filt.min_length_m;
    keep(:,4)=keep(:,3) & (has_imo | ~filt.require_imo);
    keep(:,5)=keep(:,4) & ~isnan(row_idx);
    for s=1:num_step
        step_reports(s)=step_reports(s)+nnz(keep(:,s));
        step_mmsi{s}=unique([step_mmsi{s}; T.mmsi(keep(:,s))]);
    end
    final_type=unique([final_type; [T.mmsi(keep(:,5)) T.vessel_type(keep(:,5))]],'rows');
    length_type=unique([length_type; [T.mmsi(keep(:,3)) T.vessel_type(keep(:,3))]],'rows');
    final_rows=[final_rows; T.vessel_type(keep(:,5))]; %#ok<AGROW> chunk count unknown
end
step_ships=cellfun(@numel,step_mmsi);
step_names=["All reports";"AIS ship type kept";"and length >= " + compose("%g",filt.min_length_m) + " m"; ...
    "and IMO number (or military/law enforcement)";"and inside the lower-48 grid"];
funnel=table(step_names,step_reports,step_ships,step_reports/step_reports(1),step_ships/step_ships(1), ...
    'VariableNames',{'step','reports','ships','share_reports','share_ships'});

%%%%%Group the final ships by AIS type. A ship that changed its type code
%%%%%during the day is counted in its most common group.
groups=["Cargo (70-79)";"Tanker (80-89)";"Passenger (60-69)";"Towing (31, 32, 52)"; ...
    "Military (35)";"Law enforcement (55)";"Dredging (33)";"Other and unknown (0, 90-99)"];
group_of=@(vt) 1*(vt>=70 & vt<=79)+2*(vt>=80 & vt<=89)+3*(vt>=60 & vt<=69)+4*ismember(vt,[31 32 52]) ...
    +5*(vt==35)+6*(vt==55)+7*(vt==33)+8*(vt==0 | (vt>=90 & vt<=99));
ship_group=group_of(final_type(:,2));
[mmsi_u,~,ship_idx]=unique(final_type(:,1));
ship_main=accumarray(ship_idx,ship_group,[numel(mmsi_u) 1],@mode);
ships_by=accumarray(ship_main,1,[numel(groups) 1]);
reports_by=accumarray(group_of(final_rows),1,[numel(groups) 1]);
[mmsi_l,~,len_idx]=unique(length_type(:,1));
len_main=accumarray(len_idx,group_of(length_type(:,2)),[numel(mmsi_l) 1],@mode);
ships_len=accumarray(len_main(len_main>0),1,[numel(groups) 1]);
by_type=table(groups,ships_by,reports_by,ships_len,'VariableNames',{'group','ships','reports','ships_after_length_step'});
end
