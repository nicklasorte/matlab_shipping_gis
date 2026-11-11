function [file_list]=write_zone_outputs_rev1(zone_poly,out_dir,base_name,zone_label,write_kmz)
%write_zone_outputs_rev1  Write one zone polygon as shapefile and KML.
%
%   file_list=write_zone_outputs_rev1(zone_poly,out_dir,base_name,zone_label)
%   writes ZONE_POLY (planar polyshape, x = lon, y = lat) to
%   <out_dir>/<base_name>.shp (EPSG:4326, with .prj) and .kml, and returns
%   the written paths. With WRITE_KMZ true (default), it also writes a
%   zipped copy of the KML as .kmz, about 5 times smaller.
%
%   ZONE_POLY can also be a cell array of N-by-2 [lat lon] ring arrays (NaN
%   between rings, outer rings clockwise), one polygon feature per cell, as
%   routes_polygons_rev1 returns.
%
%   Built-ins: geoshape carries the polygon; shapewrite and kmlwrite write it.

arguments
    zone_poly
    out_dir (1,:) char
    base_name (1,:) char
    zone_label (1,:) char
    write_kmz (1,1) logical = true
end

if ~isfolder(out_dir)
    mkdir(out_dir);
end
file_list=strings(0,1);
if isa(zone_poly,'polyshape')
    if zone_poly.NumRegions==0
        return
    end
    [lon_b,lat_b]=boundary(zone_poly);
    S=geoshape(lat_b,lon_b,'Geometry','polygon');
else
    if isempty(zone_poly)
        return
    end
    S=geoshape(cellfun(@(c) c(:,1)',zone_poly,'UniformOutput',false), ...
        cellfun(@(c) c(:,2)',zone_poly,'UniformOutput',false),'Geometry','polygon');
end
S.Name=repmat({zone_label},1,length(S));   %%%%%one name per feature

shp_path=fullfile(out_dir,[base_name '.shp']);
shapewrite(S,shp_path);
%%%%%shapewrite writes no .prj; write the WGS84 geographic CRS so GIS tools read it as EPSG:4326.
prj_path=fullfile(out_dir,[base_name '.prj']);
writelines(wktstring(geocrs(4326),'Version','wkt1'),prj_path); %%%%%ESRI .prj files use WKT1

%%%%%KML always; with WRITE_KMZ also a zipped copy (KMZ is a zip holding doc.kml;
%%%%%kmlwrite has no KMZ option)
kml_path=fullfile(out_dir,[base_name '.kml']);
%%%%%'Name' must be one name per feature: with a single char name and several
%%%%%multi-part features, R2025b kmlwrite wrote only 38 of 42,629 placemarks
%%%%%for the routes file (checked 2026-11-10).
kmlwrite(kml_path,S,'Name',S.Name,'FaceColor',[0.85 0.33 0.10],'FaceAlpha',0.35,'EdgeColor','k');
kmz_files=strings(0,1);
if write_kmz
    tmp_dir=tempname;
    mkdir(tmp_dir);
    cleanup_tmp=onCleanup(@() rmdir(tmp_dir,'s'));
    copyfile(kml_path,fullfile(tmp_dir,'doc.kml'));
    zip_path=fullfile(out_dir,[base_name '.zip']);
    zip(zip_path,'doc.kml',tmp_dir);
    kmz_path=fullfile(out_dir,[base_name '.kmz']);
    movefile(zip_path,kmz_path,'f');
    kmz_files=string(kmz_path);
end

file_list=[string(shp_path); string(prj_path); string(kml_path); kmz_files];
end
