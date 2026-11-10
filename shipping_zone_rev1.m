function [result]=shipping_zone_rev1(p)
%shipping_zone_rev1  Zones within X km of large-ship traffic (S-band radar carriers), CONUS.
%
%   result=shipping_zone_rev1(p) builds, for each distance in
%   p.distances_km, a polygon that covers the water where large ships
%   operate and the land within that distance of them. See
%   init_shipping_zone_rev1.m for every field of P and README.md for the
%   method.
%
%   Steps
%     1. Large-ship cells: sample AIS days, keep likely S-band carriers
%        (ais_large_ship_cells_rev1), and keep grid cells visited by at
%        least p.min_unique_ships distinct ships.
%     2. Add NOAA shipping fairways and TSS lanes (optional).
%     3. Distance field:
%          'ships' mode: distance to the nearest ship-source cell.
%          'shore' mode: water within p.shore_link_km of ships is set to
%          0, and land is measured from the shoreline that faces that
%          water (Census TIGER coastline). Always a superset of 'ships'.
%     4. Contour at each distance; clip a land-only copy to U.S. land
%        (Census cartographic boundary states, 1:500,000).
%     5. Write .mat, shapefile, KML, and a map.
%
%   result (struct)
%     .R                 GeographicCellsReference of the grid
%     .source_mask       logical, ship and fairway cells
%     .ship_days         ship-days per cell over the sampled days
%     .unique_ships      distinct MMSI per cell over the sampled days
%     .land_mask         U.S. land cells
%     .dist_field_km     distance field that was contoured
%     .zone(k)           per distance: .distance_km, .poly, .latlon,
%                        .poly_land, .latlon_land, .land_area_km2,
%                        .files
%     .day_log           table: day, rows kept, MMSI kept

arguments
    p (1,1) struct
end

disp_progress('shipping_zone_rev1: start');
for folder={p.data_dir,p.out_dir}
    if ~isfolder(folder{1})
        mkdir(folder{1});
    end
end
R=georefcells(p.latlim,p.lonlim,1/p.cells_per_degree,1/p.cells_per_degree);
num_cell=prod(R.RasterSize);

%%%%%%%%%%1. Large-ship cells from AIS (one cache file per day)
num_day=numel(p.ais_days);
cell_pairs=cell(num_day,1);
day_rows=zeros(num_day,1);
day_mmsi=zeros(num_day,1);
ais_days=p.ais_days;
if p.parallel_flag
    %%%%%Days are independent; each worker downloads, filters, and caches its own day.
    parfor day_idx=1:num_day
        S=ais_cache_day_rev1(ais_days(day_idx),R,p);
        cell_pairs{day_idx}=S.pairs;
        day_rows(day_idx)=S.num_row_kept;
        day_mmsi(day_idx)=S.num_mmsi_kept;
    end
else
    for day_idx=1:num_day
        S=ais_cache_day_rev1(ais_days(day_idx),R,p);
        cell_pairs{day_idx}=S.pairs;
        day_rows(day_idx)=S.num_row_kept;
        day_mmsi(day_idx)=S.num_mmsi_kept;
        disp_progress(sprintf('AIS %s: %d large-ship reports, %d ships (%d of %d days)', ...
            string(ais_days(day_idx),'yyyy-MM-dd'),S.num_row_kept,S.num_mmsi_kept,day_idx,num_day));
    end
end
result.day_log=table(p.ais_days(:),day_rows,day_mmsi,'VariableNames',{'day','rows_kept','mmsi_kept'});

%%%%%Merge days one at a time so memory holds one running set, not all days
ship_days=zeros(R.RasterSize);
cell_mmsi=zeros(0,2);
for day_idx=1:num_day
    day_pairs=cell_pairs{day_idx};
    cell_pairs{day_idx}=[];
    if isempty(day_pairs)
        continue
    end
    ship_days=ship_days+reshape(accumarray(day_pairs(:,1),1,[num_cell 1]),R.RasterSize);
    cell_mmsi=unique([cell_mmsi; day_pairs],'rows');
end
unique_ships=reshape(accumarray(cell_mmsi(:,1),1,[num_cell 1]),R.RasterSize);
clear cell_mmsi
source_mask=unique_ships>=p.min_unique_ships;
disp_progress(sprintf('AIS source cells: %d',nnz(source_mask)));

%%%%%%%%%%2. Fairways and TSS lanes
if p.include_fairways
    fairway_mask=load_shipping_fairways_rev1(R,p.data_dir);
    disp_progress(sprintf('Fairway cells: %d (%d not already AIS cells)',nnz(fairway_mask),nnz(fairway_mask & ~source_mask)));
    source_mask=source_mask | fairway_mask;
end

%%%%%%%%%%3. Distance field (Census land and coastline as the land/water reference)
[land_mask,land_poly,coast_mask]=census_reference_rev1(R,p.data_dir,p.census_year);
max_km=max(p.distances_km);
switch p.zone_mode
    case 'ships'
        dist_field_km=distance_to_mask_km_rev1(source_mask,R,max_km,p.block_rows);
    case 'shore'
        dist_ship_km=distance_to_mask_km_rev1(source_mask,R,max_km+p.shore_link_km,p.block_rows);
        %%%%%Ship water: non-land within shore_link_km of a ship cell
        water_zone=~land_mask & dist_ship_km<=p.shore_link_km;
        %%%%%Facing shoreline: Census coastline cells within shore_link_km of a ship cell
        shore_mask=coast_mask & dist_ship_km<=p.shore_link_km;
        dist_shore_km=distance_to_mask_km_rev1(shore_mask,R,max_km,p.block_rows);
        %%%%%min() with dist_ship keeps river ports the coastline layer omits
        dist_field_km=min(dist_ship_km,dist_shore_km);
        clear dist_ship_km dist_shore_km   %%%%%free two full grids before contouring
        dist_field_km(water_zone)=0;
        dist_field_km(dist_field_km>max_km)=2*max_km;
        disp_progress(sprintf('Shore mode: %d coastline cells face shipping',nnz(shore_mask)));
    otherwise
        error('shipgis:mode','p.zone_mode must be ''ships'' or ''shore''.');
end

%%%%%%%%%%4-5. Contour, clip, write
num_dist=numel(p.distances_km);
zone=repmat(struct('distance_km',[],'poly',[],'latlon',[],'poly_land',[],'latlon_land',[],'land_area_km2',[],'files',[]),num_dist,1);
warn_state=warning('off','MATLAB:polyshape:repairedBySimplify');
cleanup_warn=onCleanup(@() warning(warn_state));
%%%%%Fewer vertices: simplify the land outline once and each zone outline
land_poly=simplify_polyshape_rev1(land_poly,p.simplify_deg);
for dist_idx=1:num_dist
    d_km=p.distances_km(dist_idx);
    zone_poly=field_to_zone_polyshape_rev1(dist_field_km,R,d_km);
    zone_poly=simplify_polyshape_rev1(zone_poly,p.simplify_deg);
    [lon_z,lat_z]=boundary(zone_poly);
    zone_latlon=[lat_z lon_z];
    zone_land=intersect(zone_poly,land_poly);
    [lon_l,lat_l]=boundary(zone_land);

    zone(dist_idx).distance_km=d_km;
    zone(dist_idx).poly=zone_poly;
    zone(dist_idx).latlon=zone_latlon;
    zone(dist_idx).poly_land=zone_land;
    zone(dist_idx).latlon_land=[lat_l lon_l];
    zone(dist_idx).land_area_km2=areamat(land_mask & dist_field_km<=d_km,R,wgs84Ellipsoid('km'));

    base_name=sprintf('%s_%s_%gkm',p.out_name,p.zone_mode,d_km);
    files_all=write_zone_outputs_rev1(zone_poly,p.out_dir,base_name, ...
        sprintf('%s mode, %g km (water + land)',p.zone_mode,d_km),p.kmz);
    files_land=write_zone_outputs_rev1(zone_land,p.out_dir,[base_name '_land'], ...
        sprintf('%s mode, %g km (U.S. land only)',p.zone_mode,d_km),p.kmz);
    zone(dist_idx).files=[files_all; files_land];
    disp_progress(sprintf('%g km: %d regions, U.S. land in zone %.0f km^2',d_km,zone_poly.NumRegions,zone(dist_idx).land_area_km2));
end

result.R=R;
result.source_mask=source_mask;
result.ship_days=ship_days;
result.unique_ships=unique_ships;
result.land_mask=land_mask;
result.dist_field_km=dist_field_km;
result.zone=zone;
result.params=p;

%%%%%Save the zones; the full-size grids only when asked, in compact types.
%%%%%-v7 compresses; -v7.3 (HDF5) is only needed above 2 GB per variable.
saved=rmfield(result,{'source_mask','ship_days','unique_ships','land_mask','dist_field_km'});
if p.save_grids
    saved.source_mask=sparse(source_mask);
    saved.land_mask=land_mask;
    saved.ship_days=uint16(min(ship_days,double(intmax('uint16'))));
    saved.unique_ships=uint16(min(unique_ships,double(intmax('uint16'))));
    saved.dist_field_km=single(dist_field_km);
end
mat_path=fullfile(p.out_dir,sprintf('%s_%s_rev1.mat',p.out_name,p.zone_mode));
save(mat_path,'-struct','saved','-v7');

if p.make_figure
    plot_shipping_zone_rev1(result,fullfile(p.out_dir,sprintf('%s_%s_map.png',p.out_name,p.zone_mode)));
    %%%%%One standalone U.S. map per distance
    state_shp=fullfile(p.data_dir,sprintf('cb_%d_us_state_500k',p.census_year),sprintf('cb_%d_us_state_500k.shp',p.census_year));
    for dist_idx=1:num_dist
        d_km=p.distances_km(dist_idx);
        map_info=plot_zone_map_rev1(result,d_km, ...
            fullfile(p.out_dir,sprintf('%s_%s_%gkm_us_map.png',p.out_name,p.zone_mode,d_km)),state_shp,p.png_dpi);
        disp_progress(sprintf('Map %g km: %s',d_km,map_info.title));
        %%%%%Routes with this buffer (water and land)
        plot_routes_map_rev1(result,d_km, ...
            fullfile(p.out_dir,sprintf('%s_%s_%gkm_routes_buffer_map.png',p.out_name,p.zone_mode,d_km)),state_shp,p.png_dpi);
    end
    %%%%%Routes alone
    plot_routes_map_rev1(result,[],fullfile(p.out_dir,sprintf('%s_routes_map.png',p.out_name)),state_shp,p.png_dpi);
end
disp_progress('shipping_zone_rev1: done');
end

function disp_progress(msg)
fprintf('%s  %s\n',string(datetime('now'),'HH:mm:ss'),msg);
end
