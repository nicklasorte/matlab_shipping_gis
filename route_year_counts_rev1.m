function [C]=route_year_counts_rev1(cell_pairs,day_year,raster_size)
%route_year_counts_rev1  Per-cell ship counts from daily cell-and-ship pairs.
%
%   C=route_year_counts_rev1(cell_pairs,day_year,raster_size) takes one
%   N-by-2 array of [linear_cell mmsi] pairs per sampled day (CELL_PAIRS),
%   the calendar year of each day (DAY_YEAR), and the raster size, and
%   returns a struct of raster-size arrays:
%     .ship_days       distinct ships per day, summed over all days
%     .unique_ships    distinct ships over all days
%     .max_year_ships  largest one-year distinct-ship count
%     .min_year_ships  smallest one-year count (0 where a cell is missing in
%                      any year, including a year with no data)
%   Distinct ships are counted per calendar year, so a cell meets a threshold
%   "in either year" through max_year_ships and "in both years" through
%   min_year_ships (decision run R5).
%
%   Built-ins: unique(...,'rows'), accumarray. Factored out of
%   shipping_zone_rev1 for unit tests (review R4MET-5).

arguments
    cell_pairs cell
    day_year (:,1) double
    raster_size (1,2) double {mustBeInteger,mustBePositive}
end
if numel(cell_pairs)~=numel(day_year)
    error('shipgis:size','cell_pairs and day_year must have one entry per day.');
end
num_cell=prod(raster_size);
C.ship_days=zeros(raster_size);
C.max_year_ships=zeros(raster_size);
C.min_year_ships=inf(raster_size);
all_mmsi=zeros(0,2);
for yr=unique(day_year)'
    cell_mmsi=zeros(0,2);
    for day_idx=find(day_year==yr)'
        day_pairs=cell_pairs{day_idx};
        if isempty(day_pairs)
            continue
        end
        C.ship_days=C.ship_days+reshape(accumarray(day_pairs(:,1),1,[num_cell 1]),raster_size);
        cell_mmsi=unique([cell_mmsi; day_pairs],'rows');
    end
    year_count=zeros(raster_size);
    if ~isempty(cell_mmsi)
        year_count=reshape(accumarray(cell_mmsi(:,1),1,[num_cell 1]),raster_size);
        all_mmsi=unique([all_mmsi; cell_mmsi],'rows');
    end
    C.max_year_ships=max(C.max_year_ships,year_count);
    C.min_year_ships=min(C.min_year_ships,year_count);
end
C.min_year_ships(isinf(C.min_year_ships))=0;
C.unique_ships=zeros(raster_size);
if ~isempty(all_mmsi)
    C.unique_ships=reshape(accumarray(all_mmsi(:,1),1,[num_cell 1]),raster_size);
end
end
