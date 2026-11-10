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
%          water. Always a superset of 'ships' mode.
%     4. Contour at each distance; clip a land-only copy to U.S. land.
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
R=georefcells(p.latlim,p.lonlim,1/p.cells_per_degree,1/p.cells_per_degree);
num_cell=prod(R.RasterSize);

%%%%%%%%%%1. Large-ship cells from AIS
num_day=numel(p.ais_days);
cell_pairs=cell(num_day,1);
day_rows=zeros(num_day,1);
day_mmsi=zeros(num_day,1);
filt_key=sprintf('cpd%d_L%g_imo%d_sog%g_vt%d-%d-n%d-s%d',p.cells_per_degree,p.filt.min_length_m, ...
    p.filt.require_imo,p.filt.min_sog_kn,min(p.filt.vessel_types),max(p.filt.vessel_types), ...
    numel(p.filt.vessel_types),sum(p.filt.vessel_types));
lat_key=sprintf('%g_%g_%g_%g',p.latlim,p.lonlim);
for day_idx=1:num_day
    day=p.ais_days(day_idx);
    cache_file=fullfile(p.data_dir,sprintf('ais_cells_%s_%s_%s_rev1.mat',string(day,'yyyyMMdd'),filt_key,lat_key));
    if isfile(cache_file)
        S=load(cache_file,'pairs','num_row_kept','num_mmsi_kept');
    else
        csv_path=download_ais_day_rev1(day,p.data_dir,p.zstd_exe);
        [S.pairs,S.num_row_kept,S.num_mmsi_kept]=ais_large_ship_cells_rev1(csv_path,R,p.filt);
        save(cache_file,'-struct','S');
        if p.delete_csv
            delete(csv_path);
        end
    end
    cell_pairs{day_idx}=S.pairs;
    day_rows(day_idx)=S.num_row_kept;
    day_mmsi(day_idx)=S.num_mmsi_kept;
    disp_progress(sprintf('AIS %s: %d large-ship reports, %d ships (%d of %d days)', ...
        string(day,'yyyy-MM-dd'),S.num_row_kept,S.num_mmsi_kept,day_idx,num_day));
end
result.day_log=table(p.ais_days(:),day_rows,day_mmsi,'VariableNames',{'day','rows_kept','mmsi_kept'});

all_pairs=vertcat(cell_pairs{:});
ship_days=zeros(R.RasterSize);
unique_ships=zeros(R.RasterSize);
if ~isempty(all_pairs)
    ship_days=reshape(accumarray(all_pairs(:,1),1,[num_cell 1]),R.RasterSize);
    cell_mmsi=unique(all_pairs,'rows');
    unique_ships=reshape(accumarray(cell_mmsi(:,1),1,[num_cell 1]),R.RasterSize);
end
source_mask=unique_ships>=p.min_unique_ships;
disp_progress(sprintf('AIS source cells: %d',nnz(source_mask)));

%%%%%%%%%%2. Fairways and TSS lanes
if p.include_fairways
    fairway_mask=load_shipping_fairways_rev1(R,p.data_dir);
    disp_progress(sprintf('Fairway cells: %d (%d not already AIS cells)',nnz(fairway_mask),nnz(fairway_mask & ~source_mask)));
    source_mask=source_mask | fairway_mask;
end

%%%%%%%%%%3. Distance field
[land_mask,land_poly]=us_land_mask_rev1(R);
max_km=max(p.distances_km);
switch p.zone_mode
    case 'ships'
        dist_field_km=distance_to_mask_km_rev1(source_mask,R,max_km);
    case 'shore'
        dist_ship_km=distance_to_mask_km_rev1(source_mask,R,max_km+p.shore_link_km);
        water_zone=~land_mask & dist_ship_km<=p.shore_link_km;
        %%%%%Shoreline: land cells with a 4-neighbor in water_zone (manual shift; imdilate needs Image Processing).
        wz_pad=false(size(water_zone)+2);
        wz_pad(2:end-1,2:end-1)=water_zone;
        touch=wz_pad(1:end-2,2:end-1) | wz_pad(3:end,2:end-1) | wz_pad(2:end-1,1:end-2) | wz_pad(2:end-1,3:end);
        shore_mask=land_mask & touch;
        dist_shore_km=distance_to_mask_km_rev1(shore_mask,R,max_km);
        dist_field_km=min(dist_ship_km,dist_shore_km);
        dist_field_km(water_zone)=0;
        dist_field_km(dist_field_km>max_km)=2*max_km;
        disp_progress(sprintf('Shore mode: %d shoreline cells facing shipping',nnz(shore_mask)));
    otherwise
        error('shipgis:mode','p.zone_mode must be ''ships'' or ''shore''.');
end

%%%%%%%%%%4-5. Contour, clip, write
num_dist=numel(p.distances_km);
zone=repmat(struct('distance_km',[],'poly',[],'latlon',[],'poly_land',[],'latlon_land',[],'land_area_km2',[],'files',[]),num_dist,1);
warn_state=warning('off','MATLAB:polyshape:repairedBySimplify');
cleanup_warn=onCleanup(@() warning(warn_state));
for dist_idx=1:num_dist
    d_km=p.distances_km(dist_idx);
    [zone_poly,zone_latlon]=field_to_zone_polyshape_rev1(dist_field_km,R,d_km);
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
        sprintf('%s mode, %g km (water + land)',p.zone_mode,d_km));
    files_land=write_zone_outputs_rev1(zone_land,p.out_dir,[base_name '_land'], ...
        sprintf('%s mode, %g km (U.S. land only)',p.zone_mode,d_km));
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

mat_path=fullfile(p.out_dir,sprintf('%s_%s_rev1.mat',p.out_name,p.zone_mode));
save(mat_path,'result','-v7.3');

if p.make_figure
    plot_shipping_zone_rev1(result,fullfile(p.out_dir,sprintf('%s_%s_map.png',p.out_name,p.zone_mode)));
end
disp_progress('shipping_zone_rev1: done');
end

function disp_progress(msg)
fprintf('%s  %s\n',string(datetime('now'),'HH:mm:ss'),msg);
end
