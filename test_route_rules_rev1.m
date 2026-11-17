function tests=test_route_rules_rev1
%test_route_rules_rev1  Known-answer tests for the route rules (review R4MET-5).
%
%   results=runtests('test_route_rules_rev1') checks, on hand-built grids:
%   the per-year union and the both-years rule, the ship-days rule, the
%   port-approach rule, the tug-barge coastline band, and the zone boundary
%   at the largest distance (review R4MET-1).
tests=functiontests(localfunctions);
end

function test_year_counts_union(tc)
%%%%%Cell 1: 4 ships in 2024 only. Cell 2: 2 ships in each year (same ships).
%%%%%Cell 3: 3 ships in 2024 and 4 in 2025. Cell 4: one ship seen on 3 days.
d24a=[1 101;1 102;2 201;3 301;4 401];
d24b=[1 103;1 104;2 202;3 302;3 303;4 401];
d25a=[2 201;2 202;3 301;3 302;4 401];
d25b=[3 303;3 304];
C=route_year_counts_rev1({d24a;d24b;d25a;d25b},[2024;2024;2025;2025],[2 2]);
verifyEqual(tc,C.max_year_ships(:)',[4 2 4 1]);
verifyEqual(tc,C.min_year_ships(:)',[0 2 3 1]);
verifyEqual(tc,C.unique_ships(:)',[4 2 4 1]);
verifyEqual(tc,C.ship_days(:)',[4 4 7 3]);
%%%%%Three ships in either year: cells 1 and 3. In both years: cell 3 only.
p.min_unique_ships=3;
either=route_source_mask_rev1(C.ship_days,C.max_year_ships,p);
both=route_source_mask_rev1(C.ship_days,C.min_year_ships,p);
verifyEqual(tc,either(:)',logical([1 0 1 0]));
verifyEqual(tc,both(:)',logical([0 0 1 0]));
end

function test_year_counts_missing_year(tc)
%%%%%A year with no pairs at all makes min_year_ships zero everywhere.
C=route_year_counts_rev1({[1 1;1 2];zeros(0,2)},[2024;2025],[1 2]);
verifyEqual(tc,C.max_year_ships,[2 0]);
verifyEqual(tc,C.min_year_ships,[0 0]);
end

function test_ship_days_rule(tc)
p.route_rule='ship_days'; p.min_ship_days=6;
m=route_source_mask_rev1([5 6 12],[1 1 1],p);
verifyEqual(tc,m,logical([0 1 1]));
p.route_rule='other';
verifyError(tc,@() route_source_mask_rev1(1,1,p),'shipgis:rule');
end

function test_port_relax(tc)
source=logical([1 0 0 0 0]);
maxy=[9 2 2 1 2];
near_port=logical([1 1 1 1 0]);
near_coast=logical([1 1 0 1 1]);
r=port_relax_cells_rev1(source,maxy,near_port,near_coast,2);
%%%%%Cell 1 is already a route cell; cell 3 is off the coastline band;
%%%%%cell 4 has one ship; cell 5 is far from a port. Only cell 2 is added.
verifyEqual(tc,r,logical([0 1 0 0 0]));
end

function test_tug_barge_band(tc)
%%%%%Tug-barge pairs count only in cells within the coastline band,
%%%%%as in shipping_zone_rev1: tow=S.pairs(near_coast(S.pairs(:,1)),:).
R=georefcells([30 30.1],[-90 -89.9],[10 10]);
coast=false(R.RasterSize); coast(:,1)=true;          %%%%%coastline along the west edge
near=distance_to_mask_km_rev1(coast,R,5)<=5;          %%%%%cells within 5 km of it
pairs=[sub2ind(R.RasterSize,5,1) 1; sub2ind(R.RasterSize,5,10) 2];
kept=pairs(near(pairs(:,1)),:);
verifyEqual(tc,kept(:,2),1);
end

function test_zone_boundary_at_largest_distance(tc)
%%%%%One source cell; the 100 km contour must lie at 100 km within 0.05 km
%%%%%when the field is computed past 100 km (shipping_zone_rev1 uses +5 km).
R=georefcells([37 43],[-104 -96],[600 800]);
m=false(R.RasterSize); m(300,400)=true;
lat0=37+0.01*(300-0.5); lon0=-104+0.01*(400-0.5);
F=distance_to_mask_km_rev1(m,R,105);
P=field_to_zone_polyshape_rev1(F,R,100);
v=P.Vertices(~isnan(P.Vertices(:,1)),:);
d=distance(lat0,lon0,v(:,2),v(:,1),[6371.0088 0]);
verifyLessThan(tc,max(abs(d-100)),0.05);
end
