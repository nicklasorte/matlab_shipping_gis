function [S]=truth_ship_zone_check_rev1(tracks_dir,repo_dir)
%truth_ship_zone_check_rev1  Where the S-band research ships sail, and whether the ship filter keeps them.
%
%   S=truth_ship_zone_check_rev1(tracks_dir,repo_dir) reads the per-day AIS
%   extracts (tracks_<yyyy-mm-dd>.csv) written by python/truth_ship_tracks.sh
%   for the research-ship truth set (data/sband_truth_ships.csv) and returns
%   one row per ship: the AIS identity it reports (most common IMO, type,
%   length), which large-ship filter step drops it (Section 1.4: vessel type,
%   length of 100 m or more, IMO number), days and reports seen, and the share
%   of reports inside the clipped 25, 50, and 100 km zones of any region.
%   MATLAB twin of python/truth_ship_zone_check.py (the Python version also
%   reports distance to lower-48 route cells).
%
%   Built-ins: readtable, readgeotable, geotable2table, georefcells,
%   geographicToDiscrete, groupsummary/mode; zone membership by rasterizing
%   each zone at 0.01 deg (rasterize_polygon_crop_rev1), because isinterior on
%   the full zone polygons is slow for hundreds of thousands of points.

arguments
    tracks_dir (1,:) char
    repo_dir (1,:) char = pwd
end

ships=table(["369140000";"367800100";"368996000";"369888000";"369991000";"367241000";"369958000";"368926382";"303913000"], ...
    ["Sally Ride";"Roger Revelle";"Ronald H. Brown";"Okeanos Explorer";"Henry B. Bigelow";"Atlantis";"Thomas Jefferson";"Oscar Dyson";"Gordon Gunter"], ...
    'VariableNames',["mmsi","ship"]);
kept_types=[0 33 35 55 60:89 90:99];
no_imo_types=[35 55];

files=dir(fullfile(tracks_dir,'tracks_*.csv'));
if isempty(files)
    error('shipgis:notracks','No tracks_*.csv files in %s',tracks_dir);
end
parts=cell(numel(files),1);
for k=1:numel(files)
    opts=detectImportOptions(fullfile(files(k).folder,files(k).name),'TextType','string');
    opts=setvartype(opts,intersect(opts.VariableNames,["mmsi","imo","vessel_name","call_sign"]),'string');
    T=readtable(fullfile(files(k).folder,files(k).name),opts);
    T.day=repmat(string(files(k).name(8:17)),height(T),1);
    parts{k}=T(:,["mmsi","latitude","longitude","imo","vessel_type","length","vessel_name","day"]);
end
T=vertcat(parts{:});
T=T(ismember(T.mmsi,ships.mmsi),:);

%%%%%Zone membership: any region's clipped zone at each distance.
zone_dirs={fullfile(repo_dir,'outputs','2024_2025'),'shipping_zone_2024_2025';
    fullfile(repo_dir,'outputs','2024_2025','hawaii'),'shipping_zone_hawaii_2024_2025';
    fullfile(repo_dir,'outputs','2024_2025','prusvi'),'shipping_zone_prusvi_2024_2025';
    fullfile(repo_dir,'outputs','2018_2019','alaska'),'shipping_zone_alaska_2018_2019'};
dist_list=[25 50 100];
in_zone=false(height(T),numel(dist_list));
for j=1:numel(dist_list)
    for r=1:size(zone_dirs,1)
        G=geotable2table(readgeotable(fullfile(zone_dirs{r,1},sprintf('%s_ships_%dkm.shp',zone_dirs{r,2},dist_list(j)))),["Lat","Lon"]);
        lat=[]; lon=[];
        for g=1:height(G)
            lat=[lat; G.Lat{g}(:); NaN]; %#ok<AGROW>
            lon=[lon; G.Lon{g}(:); NaN]; %#ok<AGROW>
        end
        step=0.01;
        lat0=floor(min(lat)/step)*step; lon0=floor(min(lon)/step)*step;
        Rg=georefcells(lat0+[0 ceil((max(lat)-lat0)/step)*step],lon0+[0 ceil((max(lon)-lon0)/step)*step], ...
            [ceil((max(lat)-lat0)/step) ceil((max(lon)-lon0)/step)]);
        M=false(Rg.RasterSize);
        [sub,rr,cc]=rasterize_polygon_crop_rev1(lat,lon,Rg);
        M(rr,cc)=sub;
        [row,col]=geographicToDiscrete(Rg,T.latitude,T.longitude);
        ok=~isnan(row);
        hit=false(height(T),1);
        hit(ok)=M(sub2ind(Rg.RasterSize,row(ok),col(ok)));
        in_zone(:,j)=in_zone(:,j) | hit;
    end
end

S=table('Size',[height(ships) 0]);
S.ship=ships.ship; S.mmsi=ships.mmsi;
S.ais_imo=strings(height(ships),1); S.ais_vessel_type=NaN(height(ships),1); S.ais_length_m=NaN(height(ships),1);
S.filter_result=strings(height(ships),1);
S.days_sampled=repmat(numel(files),height(ships),1); S.days_seen=zeros(height(ships),1); S.reports=zeros(height(ships),1);
S.share_in_25km_zone=NaN(height(ships),1); S.share_in_50km_zone=NaN(height(ships),1); S.share_in_100km_zone=NaN(height(ships),1);
for k=1:height(ships)
    m=T.mmsi==ships.mmsi(k);
    if ~any(m), S.filter_result(k)="not seen"; continue, end
    imo=T.imo(m); imo=imo(~ismissing(imo) & strlength(imo)>0);
    if ~isempty(imo), S.ais_imo(k)=mode(categorical(imo)); end
    S.ais_vessel_type(k)=mode(T.vessel_type(m));
    S.ais_length_m(k)=mode(T.length(m));
    why=strings(0,1);
    if ~ismember(S.ais_vessel_type(k),kept_types), why(end+1)="type"; end %#ok<AGROW>
    if ~(S.ais_length_m(k)>=100), why(end+1)="length"; end %#ok<AGROW>
    if (S.ais_imo(k)=="" || S.ais_imo(k)=="IMO0000000") && ~ismember(S.ais_vessel_type(k),no_imo_types), why(end+1)="IMO"; end %#ok<AGROW>
    if isempty(why), S.filter_result(k)="kept"; else, S.filter_result(k)="dropped: "+strjoin(why,", "); end
    S.days_seen(k)=numel(unique(T.day(m)));
    S.reports(k)=nnz(m);
    S.share_in_25km_zone(k)=mean(in_zone(m,1));
    S.share_in_50km_zone(k)=mean(in_zone(m,2));
    S.share_in_100km_zone(k)=mean(in_zone(m,3));
end
end
