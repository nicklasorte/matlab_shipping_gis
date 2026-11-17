function [relaxed]=port_relax_cells_rev1(source_mask,max_year_ships,near_port,near_coast,min_ships)
%port_relax_cells_rev1  Cells added by the port-approach rule.
%
%   relaxed=port_relax_cells_rev1(source_mask,max_year_ships,near_port,
%   near_coast,min_ships) returns the cells that aren't already route cells,
%   lie near a deep-draft port (NEAR_PORT) and within the coastline band
%   (NEAR_COAST; pass true(size) to skip the band), and reach MIN_SHIPS
%   distinct ships in one year (MAX_YEAR_SHIPS). Factored out of
%   shipping_zone_rev1 for unit tests (review R4MET-5).

arguments
    source_mask logical
    max_year_ships double
    near_port logical
    near_coast logical
    min_ships (1,1) double {mustBePositive}
end
if ~isequal(size(source_mask),size(max_year_ships),size(near_port),size(near_coast))
    error('shipgis:size','All inputs must be the same size.');
end
relaxed=near_port & near_coast & ~source_mask & max_year_ships>=min_ships;
end
