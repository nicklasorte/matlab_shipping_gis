function source_mask=route_source_mask_rev1(ship_days,max_year_ships,p)
%route_source_mask_rev1  AIS route cells under the chosen route rule.
%
%   source_mask=route_source_mask_rev1(ship_days,max_year_ships,p) applies
%   p.route_rule to the per-cell counts:
%
%     'unique_ships' (default; lower 48, Puerto Rico and the USVI)
%         max_year_ships>=p.min_unique_ships, the distinct ships in the
%         busiest single year.
%     'ship_days' (Hawaii, Alaska)
%         ship_days>=p.min_ship_days, distinct ships per sampled day summed
%         over all days, so a few dedicated ships that cross the same lane
%         every week still make a route. p.min_ship_days=6 best matches the
%         lower-48 unique_ships network (Jaccard 0.81 for 2023-2024 and 0.80
%         for 2024-2025; python/ship_route_rules.py).

arguments
    ship_days double
    max_year_ships double {mustBeEqualSize(ship_days,max_year_ships)}
    p (1,1) struct
end

route_rule='unique_ships';
if isfield(p,'route_rule')
    route_rule=p.route_rule;
end
switch route_rule
    case 'unique_ships'
        source_mask=max_year_ships>=p.min_unique_ships;
    case 'ship_days'
        source_mask=ship_days>=p.min_ship_days;
    otherwise
        error('shipgis:rule','p.route_rule must be ''unique_ships'' or ''ship_days''.');
end
end

function mustBeEqualSize(a,b)
if ~isequal(size(a),size(b))
    error('shipgis:size','ship_days and max_year_ships must be the same size.');
end
end
