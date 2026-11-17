function [T]=zone_population_rev1(repo_dir,zone_dirs)
%zone_population_rev1  2020 Census population inside each zone (plan step R1, review R4OPP-3).
%
%   T=zone_population_rev1(repo_dir) counts the population of every 2020
%   Census block group whose center of population lies inside each zone
%   shapefile, for the four regions and the 25, 50, and 100 km zones.
%   Input: data/ref/CenPop2020_Mean_BG.txt (Census Bureau, 2020 Centers of
%   Population by block group). ZONE_DIRS (optional, 4-by-1 cell) overrides
%   the zone folders in the order lower 48, Hawaii, Puerto Rico and USVI,
%   Alaska. A block group counts wholly in or out by its population center.
%   The U.S. Virgin Islands aren't in the Census file.
%   MATLAB twin of python/zone_population.py.
%
%   Built-ins: readtable, readgeotable, geotable2table, inpolygon (with NaN
%   ring separators, so holes and multiple parts count correctly).

arguments
    repo_dir (1,:) char = pwd
    zone_dirs cell = {}
end

bg=readtable(fullfile(repo_dir,'data','ref','CenPop2020_Mean_BG.txt'),'TextType','string', ...
    'Delimiter',',','VariableNamingRule','modify');
bg.STATEFP=compose("%02d",double(bg.STATEFP));
regions={'lower48','outputs/2024_2025','shipping_zone_2024_2025',[22 50 -130 -66],"not";
    'hawaii','outputs/2024_2025/hawaii','shipping_zone_hawaii_2024_2025',[17 24 -162 -153],"15";
    'prusvi','outputs/2024_2025/prusvi','shipping_zone_prusvi_2024_2025',[16.5 19.5 -68.5 -64],"72";
    'alaska','outputs/2018_2019/alaska','shipping_zone_alaska_2018_2019',[51 72 -180 -129],"02"};
dist_list=[25 50 100];
rows=cell(0,7);
for r=1:size(regions,1)
    g=regions{r,4};
    in_box=bg.LATITUDE>=g(1) & bg.LATITUDE<=g(2) & bg.LONGITUDE>=g(3) & bg.LONGITUDE<=g(4);
    if regions{r,5}=="not"
        keep=in_box & ~ismember(bg.STATEFP,["02","15","72"]);
    else
        keep=in_box & bg.STATEFP==regions{r,5};
    end
    sub=bg(keep,:);
    total=sum(sub.POPULATION);
    folder=fullfile(repo_dir,regions{r,2});
    if ~isempty(zone_dirs), folder=zone_dirs{r}; end
    for km=dist_list
        f=fullfile(folder,sprintf('%s_ships_%dkm.shp',regions{r,3},km));
        if ~isfile(f), continue, end
        G=geotable2table(readgeotable(f),["Lat","Lon"]);
        lat=[]; lon=[];
        for k=1:height(G)
            lat=[lat; G.Lat{k}(:); NaN]; %#ok<AGROW>
            lon=[lon; G.Lon{k}(:); NaN]; %#ok<AGROW>
        end
        inside=inpolygon(sub.LONGITUDE,sub.LATITUDE,lon,lat);
        pop=sum(sub.POPULATION(inside));
        rows(end+1,:)={regions{r,1},km,pop,total,100*pop/total,nnz(inside),f}; %#ok<AGROW>
    end
end
T=cell2table(rows,'VariableNames',{'region','distance_km','population','region_population','share_pct','block_groups_in_zone','zone_file'});
end
