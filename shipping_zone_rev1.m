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
%        least p.min_unique_ships distinct ships in any one year
%        (p.port_min_unique_ships within p.port_relax_km of deep-draft
%        ports).
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
%     .max_year_ships    largest one-year distinct-MMSI count per cell
%     .ais_mask          AIS route cells (before fairways and racons)
%     .routes_files      routes shapefile, KML, and KMZ paths
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

%%%%%Census land and coastline (also the reference for the towing rule)
[land_mask,land_poly,coast_mask]=census_reference_rev1(R,p.data_dir,p.census_year);

%%%%%Tug-barges: towing ships with an IMO number (p.filt_towing) count only
%%%%%in cells within p.towing_coast_km of the Census coastline (ocean, bays,
%%%%%Great Lakes). Inland river towboats also carry IMO numbers and report
%%%%%the whole barge tow as their length; this keeps them off the rivers.
result.towing_cells=0;
if isfield(p,'filt_towing') && ~isempty(p.filt_towing)
    near_coast=distance_to_mask_km_rev1(coast_mask,R,p.towing_coast_km,p.block_rows)<=p.towing_coast_km;
    p_tow=p;
    p_tow.filt=p.filt_towing;
    tow_cells=false(R.RasterSize);
    for day_idx=1:num_day
        S=ais_cache_day_rev1(ais_days(day_idx),R,p_tow);
        tow=S.pairs(near_coast(S.pairs(:,1)),:);
        tow_cells(tow(:,1))=true;
        cell_pairs{day_idx}=unique([cell_pairs{day_idx}; tow],'rows');
        day_rows(day_idx)=day_rows(day_idx)+S.num_row_kept;
    end
    result.day_log.rows_kept=day_rows;
    result.towing_cells=nnz(tow_cells);
    disp_progress(sprintf('Tug-barges: %d cells within %g km of the coastline',nnz(tow_cells),p.towing_coast_km));
    clear near_coast tow_cells
end

%%%%%Merge days one at a time so memory holds one running set, not all days.
%%%%%Distinct ships are counted per calendar year, and a cell counts when
%%%%%any one year reaches the threshold (union of years). Pooling two years
%%%%%would double the one-off visitors and loosen the threshold.
ship_days=zeros(R.RasterSize);
unique_ships=zeros(R.RasterSize);          %%%%%distinct ships over all days
max_year_ships=zeros(R.RasterSize);        %%%%%largest per-year distinct-ship count
day_year=year(ais_days(:));
all_mmsi=zeros(0,2);
for yr=unique(day_year)'
    cell_mmsi=zeros(0,2);
    for day_idx=find(day_year==yr)'
        day_pairs=cell_pairs{day_idx};
        cell_pairs{day_idx}=[];
        if isempty(day_pairs)
            continue
        end
        ship_days=ship_days+reshape(accumarray(day_pairs(:,1),1,[num_cell 1]),R.RasterSize);
        cell_mmsi=unique([cell_mmsi; day_pairs],'rows');
    end
    if isempty(cell_mmsi)
        continue
    end
    max_year_ships=max(max_year_ships,reshape(accumarray(cell_mmsi(:,1),1,[num_cell 1]),R.RasterSize));
    all_mmsi=unique([all_mmsi; cell_mmsi],'rows');
end
if ~isempty(all_mmsi)
    unique_ships=reshape(accumarray(all_mmsi(:,1),1,[num_cell 1]),R.RasterSize);
end
clear cell_mmsi all_mmsi
%%%%%Route rule: 'unique_ships' (default) or 'ship_days' (route_source_mask_rev1).
source_mask=route_source_mask_rev1(ship_days,max_year_ships,p);
route_rule='unique_ships';
if isfield(p,'route_rule')
    route_rule=p.route_rule;
end
disp_progress(sprintf('AIS source cells (%s rule): %d (%d years)',route_rule,nnz(source_mask),numel(unique(day_year))));

%%%%%Lower threshold near deep-draft ports: approaches to small deep-draft
%%%%%ports (Searsport, Coos Bay) see fewer distinct ships than the main
%%%%%lanes, so cells within p.port_relax_km of a deep-draft USACE Principal
%%%%%Port count at p.port_min_unique_ships in any one year.
if isfield(p,'port_relax_km') && p.port_relax_km>0
    pp=load_principal_ports_rev1(fullfile(p.data_dir,'usace_principal_ports.csv'));
    pp=pp(pp.type~="I" & pp.foreign_tons>=1e6,:);
    [port_row,port_col]=geographicToDiscrete(R,pp.lat,pp.lon);
    in_grid=~isnan(port_row);
    port_mask=false(R.RasterSize);
    port_mask(sub2ind(R.RasterSize,port_row(in_grid),port_col(in_grid)))=true;
    near_port=distance_to_mask_km_rev1(port_mask,R,p.port_relax_km,p.block_rows)<=p.port_relax_km;
    relaxed=near_port & ~source_mask & max_year_ships>=p.port_min_unique_ships;
    %%%%%Approaches only: with p.port_relax_coast_km set, a relaxed cell must lie
    %%%%%within that distance of the Census coastline, so the rule can't extend a
    %%%%%route upriver past a port (it made the Mississippi route above Baton
    %%%%%Rouge from two river vessels; review CA-8).
    if isfield(p,'port_relax_coast_km') && ~isempty(p.port_relax_coast_km)
        near_coast=distance_to_mask_km_rev1(coast_mask,R,p.port_relax_coast_km,p.block_rows)<=p.port_relax_coast_km;
        disp_progress(sprintf('Port approaches: %d candidate cells dropped as more than %g km from the coastline', ...
            nnz(relaxed & ~near_coast),p.port_relax_coast_km));
        relaxed=relaxed & near_coast;
        clear near_coast
    end
    source_mask=source_mask | relaxed;
    disp_progress(sprintf('Port approaches: %d cells added within %g km of %d deep-draft ports (>= %d ships)', ...
        nnz(relaxed),p.port_relax_km,nnz(in_grid),p.port_min_unique_ships));
    clear near_port relaxed
end
ais_mask=source_mask;   %%%%%AIS cells only, before fairways and racons

%%%%%%%%%%2. Fairways and TSS lanes
if p.include_fairways
    fairway_mask=load_shipping_fairways_rev1(R,p.data_dir);
    %%%%%U.S. charts also show other countries' routing measures (traffic
    %%%%%separation schemes off Cuba in the Old Bahama Channel). Keep only
    %%%%%charted-lane cells nearer to U.S. land than to foreign land, an
    %%%%%equidistance stand-in for the maritime boundary (no EEZ layer is used).
    if ~isfield(p,'clip_foreign') || p.clip_foreign
        foreign_mask=foreign_land_mask(R,p.data_dir,land_mask);
        if any(foreign_mask,'all') && any(fairway_mask,'all')
            cap_km=400;
            d_us=distance_to_mask_km_rev1(land_mask,R,cap_km,p.block_rows);
            d_foreign=distance_to_mask_km_rev1(foreign_mask,R,cap_km,p.block_rows);
            foreign_side=fairway_mask & d_foreign<d_us;
            disp_progress(sprintf('Fairway cells nearer foreign land than U.S. land dropped: %d',nnz(foreign_side)));
            fairway_mask=fairway_mask & ~foreign_side;
            clear d_us d_foreign foreign_side
        end
    end
    disp_progress(sprintf('Fairway cells: %d (%d not already AIS cells)',nnz(fairway_mask),nnz(fairway_mask & ~source_mask)));
    source_mask=source_mask | fairway_mask;
end

%%%%%%%%%%2a. Extra ship water from another source (Alaska: satellite-AIS
%%%%%%%%%%lanes beyond shore-receiver range, python/alaska_satellite_lanes.py).
%%%%%%%%%%The CSV holds one linear cell index per row on this grid.
if isfield(p,'extra_source_csv') && strlength(p.extra_source_csv)>0
    extra_mask=read_extra_cells_rev1(p.extra_source_csv,R);
    disp_progress(sprintf('Extra source cells: %d (%d not already route cells)',nnz(extra_mask),nnz(extra_mask & ~source_mask)));
    source_mask=source_mask | extra_mask;
    result.extra_cells=nnz(extra_mask);
end

%%%%%%%%%%2b. Racons (radar beacons) as fixed 2900-3100 MHz sites
if isfield(p,'include_racons') && p.include_racons
    racons=load_racons_rev1(p.data_dir);
    in_box=racons.lat>=R.LatitudeLimits(1) & racons.lat<=R.LatitudeLimits(2) & ...
        racons.lon>=R.LongitudeLimits(1) & racons.lon<=R.LongitudeLimits(2);
    result.racons_all=racons(in_box,:);   %%%%%every charted racon in the grid, for the sites CSV
    if p.racon_bands=="S"
        racons=racons(racons.s_band,:);
    end
    [r_row,r_col]=geographicToDiscrete(R,racons.lat,racons.lon);
    in_grid=~isnan(r_row);
    racon_mask=false(R.RasterSize);
    racon_mask(sub2ind(R.RasterSize,r_row(in_grid),r_col(in_grid)))=true;
    disp_progress(sprintf('Racons: %d in the grid (%d cells not already ship cells)',nnz(in_grid),nnz(racon_mask & ~source_mask)));
    source_mask=source_mask | racon_mask;
    result.racons=racons(in_grid,:);
    writetable(result.racons,fullfile(p.out_dir,sprintf('%s_racons.csv',p.out_name)));
end

%%%%%%%%%%3. Distance field (Census land and coastline as the land/water reference)
%%%%%(land_mask, land_poly, coast_mask from census_reference_rev1 above)
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
zone=repmat(struct('distance_km',[],'poly',[],'latlon',[],'poly_land',[],'latlon_land',[],'land_area_km2',[],'land_cells_area_km2',[],'files',[]),num_dist,1);
warn_state=warning('off','MATLAB:polyshape:repairedBySimplify');
cleanup_warn=onCleanup(@() warning(warn_state));
%%%%%Fewer vertices: simplify the land outline once and each zone outline
land_poly=simplify_polyshape_rev1(land_poly,p.simplify_deg);
%%%%%Other countries' land is taken out of every zone (review CA-3); the zones
%%%%%then hold U.S. land and water only.
foreign_poly=polyshape();
if ~isfield(p,'clip_foreign') || p.clip_foreign
    foreign_poly=load_foreign_land_rev1(R,p.data_dir);
    %%%%%Natural Earth's 1:10m border coast overlaps Census U.S. land at border
    %%%%%rivers (the Detroit River, Niagara); keep every Census U.S. land area.
    foreign_poly=subtract(foreign_poly,land_poly);
end
%%%%%Water nearer foreign land than U.S. land is also taken out (review
%%%%%R2MET-1, option 2, chosen November 13, 2026): an equidistance stand-in
%%%%%for the maritime boundary, the same rule as the charted-lane filter above
%%%%%but with distances out to p.clip_water_cap_km so far-offshore water is
%%%%%judged too. Only the written zones change; route cells in foreign water
%%%%%stay zone sources, so U.S. land in the zones doesn't change.
%%%%%Built-ins considered: an EEZ polygon (option 3, needs a new input layer).
if isfield(p,'clip_water_foreign_side') && p.clip_water_foreign_side && foreign_poly.NumRegions>0
    cap_km=p.clip_water_cap_km;
    %%%%%Foreign land past the grid edge counts too (the Dominican Republic
    %%%%%beyond 68.5 W, Russia west of 180), so distances to foreign land run
    %%%%%to the country outline vertices, not to a mask clipped to the grid.
    [~,f_lat,f_lon]=load_foreign_land_rev1(R,p.data_dir,cap_km);
    d_us=distance_to_mask_km_rev1(land_mask,R,cap_km,p.block_rows);
    d_foreign=distance_to_points_km_rev1(f_lat,f_lon,R,cap_km,p.block_rows);
    %%%%%Region where d_foreign-d_us <= 0 is foreign land or foreign-side water;
    %%%%%cells beyond cap_km of both get equal distances and stay U.S.-side.
    side_km=d_foreign-d_us;
    side_km(d_us>cap_km & d_foreign>cap_km)=1;   %%%%%beyond cap_km of both: U.S.-side
    foreign_side_poly=field_to_zone_polyshape_rev1(side_km,R,0);
    foreign_side_poly=simplify_polyshape_rev1(foreign_side_poly,p.simplify_deg);
    foreign_side_poly=subtract(foreign_side_poly,land_poly);   %%%%%never cut U.S. land
    foreign_poly=union(foreign_poly,foreign_side_poly);
    disp_progress(sprintf('Foreign-side water clip: equidistance line from %d foreign outline vertices (distances to %g km)',numel(f_lat),cap_km));
    clear d_us d_foreign side_km foreign_side_poly f_lat f_lon
end
for dist_idx=1:num_dist
    d_km=p.distances_km(dist_idx);
    zone_poly=field_to_zone_polyshape_rev1(dist_field_km,R,d_km);
    zone_poly=simplify_polyshape_rev1(zone_poly,p.simplify_deg);
    if foreign_poly.NumRegions>0
        zone_poly=subtract(zone_poly,foreign_poly);
    end
    [lon_z,lat_z]=boundary(zone_poly);
    zone_latlon=[lat_z lon_z];
    zone_land=intersect(zone_poly,land_poly);
    [lon_l,lat_l]=boundary(zone_land);

    zone(dist_idx).distance_km=d_km;
    zone(dist_idx).poly=zone_poly;
    zone(dist_idx).latlon=zone_latlon;
    zone(dist_idx).poly_land=zone_land;
    zone(dist_idx).latlon_land=[lat_l lon_l];
    %%%%%Land area from the clipped land polygon (equal-area projection), not
    %%%%%from counting grid cells that touch land (review CA-33). The cell count
    %%%%%is kept for comparison.
    zone(dist_idx).land_area_km2=polyshape_area_km2_rev1(zone_land);
    zone(dist_idx).land_cells_area_km2=areamat(land_mask & dist_field_km<=d_km,R,wgs84Ellipsoid('km'));

    base_name=sprintf('%s_%s_%gkm',p.out_name,p.zone_mode,d_km);
    files_all=write_zone_outputs_rev1(zone_poly,p.out_dir,base_name, ...
        sprintf('%s mode, %g km (U.S. water + land)',p.zone_mode,d_km),p.kmz);
    files_land=write_zone_outputs_rev1(zone_land,p.out_dir,[base_name '_land'], ...
        sprintf('%s mode, %g km (U.S. land only)',p.zone_mode,d_km),p.kmz);
    zone(dist_idx).files=[files_all; files_land];
    disp_progress(sprintf('%g km: %d regions, U.S. land in zone %.0f km^2 (grid cells touching land: %.0f km^2)',d_km,zone_poly.NumRegions, ...
        zone(dist_idx).land_area_km2,zone(dist_idx).land_cells_area_km2));
end

result.R=R;
result.source_mask=source_mask;
result.ship_days=ship_days;
result.unique_ships=unique_ships;
result.max_year_ships=max_year_ships;
result.ais_mask=ais_mask;
result.period_label=period_label(ais_days);
result.ais_note=sprintf('%d days in %s',num_day,result.period_label);
result.land_mask=land_mask;
result.dist_field_km=dist_field_km;
result.zone=zone;
result.params=p;

%%%%%Ports that the routes must reach (Baton Rouge: head of deep-draft
%%%%%navigation on the Mississippi)
if isfield(p,'check_ports') && ~isempty(p.check_ports)
    result.port_check=check_ports_rev1(result,p.check_ports);
    writetable(result.port_check,fullfile(p.out_dir,sprintf('%s_port_check.csv',p.out_name)));
    disp_progress(sprintf('Port check: %d of %d ports reached by a continuous route', ...
        nnz(result.port_check.reached & result.port_check.on_route_network),height(result.port_check)));
end

%%%%%All USACE Principal Ports in the grid: warn only for coastal and Great
%%%%%Lakes ports with at least 1 million tons of foreign trade (deep-draft
%%%%%ports). Inland river ports are barge ports and are not expected to be
%%%%%reached. Port points are district reference points, so the gap allowed
%%%%%is p.principal_ports_gap_km.
if isfield(p,'principal_ports') && p.principal_ports
    pp=load_principal_ports_rev1(fullfile(p.data_dir,'usace_principal_ports.csv'));
    pp=pp(pp.lat>=R.LatitudeLimits(1) & pp.lat<=R.LatitudeLimits(2) & ...
        pp.lon>=R.LongitudeLimits(1) & pp.lon<=R.LongitudeLimits(2),:);
    deep_draft=pp.type~="I" & pp.foreign_tons>=1e6;
    result.principal_port_check=check_ports_rev1(result,pp,p.principal_ports_gap_km,2000,deep_draft);
    writetable(result.principal_port_check,fullfile(p.out_dir,sprintf('%s_principal_port_check.csv',p.out_name)));
    ok=result.principal_port_check.reached & result.principal_port_check.on_route_network;
    disp_progress(sprintf('Principal ports: %d of %d deep-draft ports reached; %d of %d inland ports reached', ...
        nnz(ok & deep_draft),nnz(deep_draft),nnz(ok & pp.type=="I"),nnz(pp.type=="I")));
end

%%%%%Coast Guard Vessel Traffic Service areas (report only: Louisville and
%%%%%Berwick Bay serve towboats, not S-band ships)
if isfield(p,'check_vts') && ~isempty(p.check_vts)
    result.vts_check=check_ports_rev1(result,p.check_vts,5,2000,false(height(p.check_vts),1));
    writetable(result.vts_check,fullfile(p.out_dir,sprintf('%s_vts_check.csv',p.out_name)));
end

%%%%%Routes file: the route cells (AIS ship cells, fairways, racons) as
%%%%%polygons in shapefile, KML, and KMZ, plus the AIS-only cells
routes_tile_deg=1;
[routes_rings,num_tile]=routes_polygons_rev1(source_mask,R,routes_tile_deg,p.routes_simplify_deg);
result.routes_files=write_zone_outputs_rev1(routes_rings,p.out_dir,sprintf('%s_routes',p.out_name), ...
    sprintf('Large-ship routes, %s (AIS, fairways, S-band racons)',result.period_label),p.kmz);
ais_rings=routes_polygons_rev1(ais_mask,R,routes_tile_deg,p.routes_simplify_deg);
result.routes_files=[result.routes_files; write_zone_outputs_rev1(ais_rings,p.out_dir,sprintf('%s_routes_ais_only',p.out_name), ...
    sprintf('Large-ship AIS cells, %s',result.period_label),p.kmz)];
disp_progress(sprintf('Routes: %d one-degree tiles hold route cells',num_tile));

%%%%%Frequency-dependent zones: each band gets the zone for its distance
%%%%%(shapefile, KML, KMZ named by band) and one row in <out_name>_band_zones.csv
if isfield(p,'band_zones') && ~isempty(p.band_zones)
    bz=p.band_zones;
    zone_files=strings(height(bz),1);
    for b=1:height(bz)
        zone_idx=find([zone.distance_km]==bz.distance_km(b),1);
        if isempty(zone_idx)
            error('shipgis:band','Band %g-%g MHz needs a %g km zone; add it to p.distances_km.', ...
                bz.f_low_mhz(b),bz.f_high_mhz(b),bz.distance_km(b));
        end
        band_name=sprintf('%s_band_%g-%gMHz_%gkm',p.out_name,bz.f_low_mhz(b),bz.f_high_mhz(b),bz.distance_km(b));
        files=write_zone_outputs_rev1(zone(zone_idx).poly,p.out_dir,band_name, ...
            sprintf('%g-%g MHz: %g km zone (water + land)',bz.f_low_mhz(b),bz.f_high_mhz(b),bz.distance_km(b)),p.kmz);
        [~,shp_name,shp_ext]=fileparts(files(1));
        zone_files(b)=shp_name+shp_ext;
    end
    bz.zone_file=zone_files;
    writetable(bz,fullfile(p.out_dir,sprintf('%s_band_zones.csv',p.out_name)));
    result.band_zones=bz;
end

%%%%%One CSV of every checked site (racons, VTS areas, ports)
write_sites_csv_rev1(result,fullfile(p.out_dir,sprintf('%s_sites.csv',p.out_name)));

%%%%%Save the zones; the full-size grids only when asked, in compact types.
%%%%%-v7 compresses; -v7.3 (HDF5) is only needed above 2 GB per variable.
saved=rmfield(result,{'source_mask','ais_mask','ship_days','unique_ships','max_year_ships','land_mask','dist_field_km'});
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
    %%%%%Frequency-dependent zones, one panel per band
    if isfield(p,'band_zones') && ~isempty(p.band_zones)
        band_info=plot_band_zones_rev1(result,p.band_zones, ...
            fullfile(p.out_dir,sprintf('%s_band_zones_map.png',p.out_name)),state_shp,p.png_dpi);
        disp_progress(sprintf('Band map: %s',band_info.title));
    end
    %%%%%Zoomed regional maps (for example, the Mississippi to Baton Rouge)
    if isfield(p,'region_maps')
        for reg=p.region_maps(:)'
            note='';
            if isfield(reg,'count_port') && strlength(reg.count_port)>0
                port_row=reg.ports(reg.ports.name==reg.count_port,:);
                counts=count_ships_near_rev1(p,R,port_row.lat(1),port_row.lon(1),reg.count_radius_km);
                writetable(counts,fullfile(p.out_dir,sprintf('%s_%s_ship_counts.csv',p.out_name,reg.name)));
                yr_rows=counts(~isnan(counts.year),:);
                parts=compose('%d: %d',[yr_rows.year yr_rows.num_ships]);
                note=sprintf('Distinct large ships within %g km of %s: %s',reg.count_radius_km, ...
                    extractBefore(reg.count_port,','),strjoin(parts,', '));
                disp_progress(note);
            end
            if isempty(reg.d_km)
                png_name=sprintf('%s_%s_routes_map.png',p.out_name,reg.name);
            else
                png_name=sprintf('%s_%s_%gkm_map.png',p.out_name,reg.name,reg.d_km);
            end
            plot_region_map_rev1(result,reg.d_km,reg.latlim,reg.lonlim,reg.ports,reg.title, ...
                fullfile(p.out_dir,png_name),state_shp,p.png_dpi,note);
        end
    end
end
disp_progress('shipping_zone_rev1: done');
end

function label=period_label(days)
%%%%%'2024' or '2023-2024' from the sampled days
yrs=unique(year(days));
if isscalar(yrs)
    label=sprintf('%d',yrs);
else
    label=sprintf('%d-%d',min(yrs),max(yrs));
end
end

function disp_progress(msg)
fprintf('%s  %s\n',string(datetime('now'),'HH:mm:ss'),msg);
end

function foreign_mask=foreign_land_mask(R,data_dir,land_mask)
%%%%%Grid cells inside other countries' land (Natural Earth), never on Census U.S. land.
foreign_poly=load_foreign_land_rev1(R,data_dir);
foreign_mask=false(R.RasterSize);
if foreign_poly.NumRegions==0
    return
end
regs=regions(foreign_poly);
for k=1:numel(regs)
    [lon_b,lat_b]=boundary(regs(k));
    [Z_sub,row_range,col_range]=rasterize_polygon_crop_rev1(lat_b,lon_b,R);
    if ~isempty(Z_sub)
        foreign_mask(row_range,col_range)=foreign_mask(row_range,col_range) | Z_sub;
    end
end
foreign_mask=foreign_mask & ~land_mask;
end
