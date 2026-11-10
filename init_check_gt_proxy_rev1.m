%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%init_check_gt_proxy_rev1
%%%%%
%%%%%Checks the large-ship filter (cargo, tanker, passenger; length >= 100 m;
%%%%%IMO number) against registry gross tonnage. SOLAS V/19 puts a 3 GHz
%%%%%(S-band) radar on ships of 3,000 GT and up; AIS has no GT, so the
%%%%%filter uses length. This script measures how often that is right.
%%%%%
%%%%%Inputs: AIS days from MarineCadastre (one per season), Wikidata gross
%%%%%tonnage by IMO number. Outputs: CSV tables and a scatter plot.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

c.days=[datetime(2024,1,10) datetime(2024,4,10) datetime(2024,7,10) datetime(2024,10,9)];
c.data_dir=fullfile(pwd,'data');
c.out_dir=fullfile(pwd,'output');
c.zstd_exe='/opt/homebrew/bin/zstd';
c.filt.vessel_types=[60:69 70:89];
c.filt.min_length_m=100;
if ~isfolder(c.out_dir)
    mkdir(c.out_dir);
end

%%%%%%%%%%Ships seen on the sample days (one row per MMSI; later days fill gaps).
%%%%%%%%%%The repo ships data/ais_vessels_2024_4days.csv; delete it to rebuild from AIS.
vessel_csv=fullfile(c.data_dir,'ais_vessels_2024_4days.csv');
if isfile(vessel_csv)
    V=readtable(vessel_csv);
else
    vessel_parts=cell(numel(c.days),1);
    for day_idx=1:numel(c.days)
        [csv_path,tf_private]=download_ais_day_rev1(c.days(day_idx),c.data_dir,c.zstd_exe,false);
        vessel_parts{day_idx}=ais_vessel_list_rev1(csv_path);
        if tf_private
            delete(csv_path);
        end
        fprintf('%s: %d ships\n',string(c.days(day_idx),'yyyy-MM-dd'),height(vessel_parts{day_idx}));
    end
    V=vertcat(vessel_parts{:});
    V=sortrows(V,{'mmsi','imo'});              %%%%%rows with an IMO number sort first per MMSI
    [~,first]=unique(V.mmsi,'stable');
    V=V(first,:);
    writetable(V,vessel_csv);
end

%%%%%%%%%%Registry gross tonnage, then the check
ref=load_wikidata_gt_rev1(fullfile(c.data_dir,'wikidata_imo_gt_len.csv'));
chk=check_gt_proxy_rev1(V,ref,c.filt,fullfile(c.out_dir,'gt_proxy_check_2024.png'));

writetable(chk.sweep,fullfile(c.out_dir,'gt_proxy_sweep_2024.csv'));
writetable(chk.by_type,fullfile(c.out_dir,'gt_proxy_by_type_2024.csv'));
writetable(chk.coverage,fullfile(c.out_dir,'gt_proxy_coverage_2024.csv'));
disp(chk.at_cutoff)
