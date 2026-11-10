function [file_list]=write_zone_outputs_rev1(zone_poly,out_dir,base_name,zone_label,write_kmz)
%write_zone_outputs_rev1  Write one zone polygon as shapefile and KML.
%
%   file_list=write_zone_outputs_rev1(zone_poly,out_dir,base_name,zone_label)
%   writes ZONE_POLY (planar polyshape, x = lon, y = lat) to
%   <out_dir>/<base_name>.shp (EPSG:4326, with .prj) and .kml, and returns
%   the written paths. With WRITE_KMZ true (default), it also writes a
%   zipped copy of the KML as .kmz, about 5 times smaller.
%
%   Built-ins: geoshape carries the polygon; shapewrite and kmlwrite write it.

arguments
    zone_poly (1,1) polyshape
    out_dir (1,:) char
    base_name (1,:) char
    zone_label (1,:) char
    write_kmz (1,1) logical = true
end

if ~isfolder(out_dir)
    mkdir(out_dir);
end
file_list=strings(0,1);
if zone_poly.NumRegions==0
    return
end

[lon_b,lat_b]=boundary(zone_poly);
S=geoshape(lat_b,lon_b,'Geometry','polygon');
S.Name=zone_label;

shp_path=fullfile(out_dir,[base_name '.shp']);
shapewrite(S,shp_path);
%%%%%shapewrite writes no .prj; write the WGS84 geographic CRS so GIS tools read it as EPSG:4326.
prj_path=fullfile(out_dir,[base_name '.prj']);
writelines(wktstring(geocrs(4326),'Version','wkt1'),prj_path); %%%%%ESRI .prj files use WKT1

%%%%%KML always; with WRITE_KMZ also a zipped copy (KMZ is a zip holding doc.kml;
%%%%%kmlwrite has no KMZ option)
kml_path=fullfile(out_dir,[base_name '.kml']);
kmlwrite(kml_path,S,'Name',zone_label,'FaceColor',[0.85 0.33 0.10],'FaceAlpha',0.35,'EdgeColor','k');
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
