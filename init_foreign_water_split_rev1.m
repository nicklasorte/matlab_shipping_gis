%%%%%init_foreign_water_split_rev1  How much of each zone is foreign water (review R2MET-1).
%%%%%
%%%%%Splits each zone (ships mode, 25, 50, and 100 km) into U.S. land, water
%%%%%nearer U.S. land, and water nearer foreign land, and flags water beyond
%%%%%200 nautical miles of U.S. land. Run from the repo folder after the four
%%%%%zone runs. Writes <out_name>.csv in outputs/.
%%%%%Zone folders: the committed copies by default; set zone_set='run' before
%%%%%running to read the folders a fresh zone run writes (output, output_hawaii,
%%%%%output_prusvi, output_alaska) instead (review R3COD-14).
%%%%%Python version: python/foreign_water_split.py (same method, cross-check).
clearvars -except zone_set out_name; clc;
if ~exist('zone_set','var'), zone_set='committed'; end
if ~exist('out_name','var'), out_name='foreign_water_split_rev1'; end
switch zone_set
    case 'committed'
        dirs={fullfile(pwd,'outputs','2024_2025');fullfile(pwd,'outputs','2024_2025','hawaii'); ...
            fullfile(pwd,'outputs','2024_2025','prusvi');fullfile(pwd,'outputs','2018_2019','alaska')};
    case 'run'
        dirs={fullfile(pwd,'output');fullfile(pwd,'output_hawaii');fullfile(pwd,'output_prusvi');fullfile(pwd,'output_alaska')};
    otherwise
        error('shipgis:zoneset','zone_set must be ''committed'' or ''run''.');
end
regions=table(["Lower 48";"Hawaii";"Puerto Rico and USVI";"Alaska"], ...
    string(dirs), ...
    ["shipping_zone_2024_2025";"shipping_zone_hawaii_2024_2025";"shipping_zone_prusvi_2024_2025";"shipping_zone_alaska_2018_2019"], ...
    'VariableNames',["region","dir","stem"]);
distances_km=[25 50 100];
parts=cell(height(regions)*numel(distances_km),1);
k=0;
for r=1:height(regions)
    for d=distances_km
        k=k+1;
        z=fullfile(regions.dir(r),sprintf('%s_ships_%dkm.shp',regions.stem(r),d));
        l=fullfile(regions.dir(r),sprintf('%s_ships_%dkm_land.shp',regions.stem(r),d));
        tic;
        T=foreign_water_split_rev1(char(z),char(l));
        T.region=regions.region(r); T.distance_km=d;
        fprintf('%s %d km: total %.0f, land %.0f, U.S. water %.0f, foreign water %.0f (%.1f%% of water), beyond 200 nmi %.0f km^2 (%.0f s)\n', ...
            regions.region(r),d,T.total_km2,T.land_km2,T.us_water_km2,T.foreign_water_km2,100*T.foreign_share_of_water,T.beyond_200nmi_km2,toc);
        parts{k}=T;
    end
end
S=vertcat(parts{:});
S=movevars(S,["region","distance_km"],'Before',1);
S.zone_file=extractAfter(S.zone_file,[pwd filesep]);
writetable(S,fullfile(pwd,'outputs',[out_name '.csv']));
disp(S(:,["region","distance_km","land_km2","us_water_km2","foreign_water_km2","foreign_share_of_water","beyond_200nmi_km2"]))
