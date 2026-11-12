function [fairway_mask,GT]=load_shipping_fairways_rev1(R,data_dir,theme_layers)
%load_shipping_fairways_rev1  NOAA shipping fairways and TSS lanes as a grid mask.
%
%   [fairway_mask,GT]=load_shipping_fairways_rev1(R,data_dir,theme_layers)
%   downloads the NOAA ENC Direct "Shipping Lanes and Regulations" polygons
%   (MarineTransportation FeatureServer layer 0, EPSG:4326) inside the
%   extent of raster R, keeps the THEMELAYER values in THEME_LAYERS, and
%   rasterizes them onto R.
%
%   The GeoJSON is cached in DATA_DIR as fairways_rev1.geojson.
%
%   OUTPUTS
%     fairway_mask  logical, size R.RasterSize, true inside a kept polygon
%     GT            geotable of the kept polygons (for plots and KML)

arguments
    R (1,1) map.rasterref.GeographicCellsReference
    data_dir (1,:) char
    theme_layers (1,:) string = ["Shipping Fairways Lanes and Zones", ...
        "Traffic Separation Schemes/Traffic Lanes","Traffic Separation Schemes (TSS)", ...
        "Precautionary Areas","Recommended Routes"]
end

if ~isfolder(data_dir)
    mkdir(data_dir);
end
geojson_path=fullfile(data_dir,'fairways_rev1.geojson');   %%%%%lower-48 grid keeps its original name
if ~isequal(R.LatitudeLimits,[22 50]) || ~isequal(R.LongitudeLimits,[-130 -66])
    geojson_path=fullfile(data_dir,sprintf('fairways_rev1_%g_%g_%g_%g.geojson',R.LatitudeLimits,R.LongitudeLimits));
end
url='https://encdirect.noaa.gov/arcgis/rest/services/NavigationChartData/MarineTransportation/FeatureServer/0/query';

if ~isfile(geojson_path)
    %%%%%The layer holds a few hundred features (MaxRecordCount 10000), so one request is enough.
    envelope=sprintf('%.6f,%.6f,%.6f,%.6f',R.LongitudeLimits(1),R.LatitudeLimits(1),R.LongitudeLimits(2),R.LatitudeLimits(2));
    num_try=3;
    for try_idx=1:num_try
        try
            websave(geojson_path,url,'where','1=1','geometry',envelope, ...
                'geometryType','esriGeometryEnvelope','inSR','4326','spatialRel','esriSpatialRelIntersects', ...
                'outFields','THEMELAYER,OBJNAM','outSR','4326','f','geojson',weboptions('Timeout',300));
            break
        catch err
            if try_idx==num_try
                error('shipgis:fairways','Fairway download failed: %s',err.message);
            end
        end
    end
end

GT=readgeotable(geojson_path);
GT=GT(ismember(string(GT.THEMELAYER),theme_layers),:);

%%%%%Rasterize: vec2mtx 'filled' returns 0 inside, 1 on the edge, 2 outside.
fairway_mask=false(R.RasterSize);
if height(GT)==0
    return
end
T=geotable2table(GT,["Lat","Lon"]);
for k=1:height(T)
    lat=T.Lat{k}(:);
    lon=T.Lon{k}(:);
    [Z_sub,row_range,col_range]=rasterize_polygon_crop_rev1(lat,lon,R);
    if isempty(Z_sub)
        continue
    end
    fairway_mask(row_range,col_range)=fairway_mask(row_range,col_range) | Z_sub;
end
end
