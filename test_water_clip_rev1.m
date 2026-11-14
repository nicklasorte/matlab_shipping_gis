function tests=test_water_clip_rev1
%test_water_clip_rev1  Tests for the foreign-side water clip (review R3COD-5).
%   runtests('test_water_clip_rev1')
tests=functiontests(localfunctions);
end

function test_distance_to_points_matches_distance(tc)
R=georefcells([30 32],[-80 -78],[200 200]);
lat=[31.2; 30.4]; lon=[-79.5; -78.3];
d=distance_to_points_km_rev1(lat,lon,R,1000);
[r,c]=geographicToDiscrete(R,31.0,-79.0);
lat_c=R.LatitudeLimits(1)+R.CellExtentInLatitude*(r-0.5);
lon_c=R.LongitudeLimits(1)+R.CellExtentInLongitude*(c-0.5);
ref=min(distance(lat_c,lon_c,lat,lon,referenceSphere('Earth','km')));
verifyEqual(tc,d(r,c),ref,'RelTol',1e-3);
end

function test_distance_cap_and_warning(tc)
R=georefcells([30 31],[-80 -79],[100 100]);
d=distance_to_points_km_rev1(35,-79.5,R,100);    %%%%%point about 450 km away
verifyEqual(tc,unique(d(:)),200);
verifyWarning(tc,@() distance_to_points_km_rev1(NaN,NaN,R,100),'shipgis:nopoints');
end

function test_equidistance_split_and_high_seas(tc)
%%%%%U.S. land on the west edge, foreign land 4 degrees east: the split falls
%%%%%near the middle; with a 100 km cap the middle (beyond 100 km of both)
%%%%%stays U.S.-side.
R=georefcells([0 1],[0 4],[100 400]);
us=false(R.RasterSize); us(:,1:5)=true;
f_lat=(0:0.01:1)'; f_lon=4.05*ones(size(f_lat));
P=foreign_side_polygon_rev1(us,f_lat,f_lon,R,2000);
verifyTrue(tc,isinterior(P,3.5,0.5));
verifyFalse(tc,isinterior(P,0.5,0.5));
[xl,~]=boundingbox(P);
verifyEqual(tc,xl(1),2.05,'AbsTol',0.05);       %%%%%about halfway between U.S. land (0.05) and foreign land (4.05)
P2=foreign_side_polygon_rev1(us,f_lat,f_lon,R,100);
verifyFalse(tc,isinterior(P2,2.05,0.5));         %%%%%high seas: kept
verifyTrue(tc,isinterior(P2,3.8,0.5));
verifyFalse(tc,any(isinterior(P2,0.02*ones(5,1),linspace(0.1,0.9,5)')));   %%%%%U.S. land never cut
end
