function [fairway_mask,GT]=load_shipping_fairways_rev1(R,data_dir,theme_layers)
%load_shipping_fairways_rev1  NOAA shipping fairways and TSS lanes as a grid mask.
%
%   [fairway_mask,GT]=load_shipping_fairways_rev1(R,data_dir,theme_layers)
%   downloads the NOAA ENC Direct "Shipping Lanes and Regulations" polygons
%   (MarineTransportation FeatureServer layer 0, EPSG:4326) inside the
%   extent of raster R, keeps the THEMELAYER values in THEME_LAYERS, and
%   rasterizes them onto R.
%
%   The features are cached in DATA_DIR as fairways_rev2_<grid limits>.mat,
%   downloaded in pages and checked against NOAA's feature count.
%
%   OUTPUTS
%     fairway_mask  logical, size R.RasterSize, true inside a kept polygon
%     GT            geotable of the kept polygons (for plots and KML)

arguments
    R (1,1) map.rasterref.GeographicCellsReference
    data_dir (1,:) char
    theme_layers (1,:) string = ["Shipping Fairways Lanes and Zones", ...
        "Traffic Separation Schemes/Traffic Lanes","Traffic Separation Schemes", ...   %%%%%the layer value has no "(TSS)" (review CA-2)
        "Precautionary Areas","Recommended Routes"]
end

if ~isfolder(data_dir)
    mkdir(data_dir);
end
%%%%%Cache per grid, with the feature count NOAA reported at download time. The
%%%%%earlier single-request download (fairways_rev1*.geojson) could come back
%%%%%truncated: the lower-48 file held 28 of 291 features (review CA-1).
cache_path=fullfile(data_dir,sprintf('fairways_rev2_%g_%g_%g_%g.mat',R.LatitudeLimits,R.LongitudeLimits));
url='https://encdirect.noaa.gov/arcgis/rest/services/NavigationChartData/MarineTransportation/FeatureServer/0/query';
envelope=sprintf('%.6f,%.6f,%.6f,%.6f',R.LongitudeLimits(1),R.LatitudeLimits(1),R.LongitudeLimits(2),R.LatitudeLimits(2));
query={'where','1=1','geometry',envelope,'geometryType','esriGeometryEnvelope','inSR','4326', ...
    'spatialRel','esriSpatialRelIntersects'};
opts=weboptions('Timeout',300);
if ~isfile(cache_path)
    num_expected=fetch_with_retry(@() webread(url,query{:},'returnCountOnly','true','f','json',opts)).count;
    page_size=500;
    pages={};
    for offset=0:page_size:max(num_expected-1,0)
        page_path=[tempname '.geojson'];
        cleanup_page=onCleanup(@() delete_if_file(page_path));
        fetch_with_retry(@() websave(page_path,url,query{:},'outFields','THEMELAYER,OBJNAM','outSR','4326', ...
            'orderByFields','OBJECTID','resultOffset',offset,'resultRecordCount',page_size,'f','geojson',opts));
        G=readgeotable(page_path);
        if ismember('THEMELAYER',G.Properties.VariableNames)
            pages{end+1}=G(:,{'Shape','THEMELAYER','OBJNAM'}); %#ok<AGROW> few pages; Shape first keeps it a geotable
        end
        clear cleanup_page
    end
    if isempty(pages)
        GT=table.empty;
    else
        GT=vertcat(pages{:});
    end
    if height(GT)~=num_expected
        error('shipgis:fairways','NOAA reported %d fairway features in the grid but %d were downloaded.',num_expected,height(GT));
    end
    save(cache_path,'GT','num_expected');
end
S=load(cache_path,'GT');
GT=S.GT;
if ~isempty(GT) && ismember('Shape',GT.Properties.VariableNames) && ~isgeotable(GT)
    GT=movevars(GT,'Shape','Before',1);   %%%%%a geotable has Shape as its first variable
end
if isempty(GT) || ~ismember('THEMELAYER',GT.Properties.VariableNames)   %%%%%no features in the grid
    fairway_mask=false(R.RasterSize);
    return
end
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

function out=fetch_with_retry(fcn)
%%%%%NOAA's service fails now and then; three tries, then a loud error.
num_try=3;
for try_idx=1:num_try
    try
        out=fcn();
        return
    catch err
        if try_idx==num_try
            error('shipgis:fairways','Fairway download failed: %s',err.message);
        end
        pause(5);
    end
end
end

function delete_if_file(f)
if isfile(f)
    delete(f);
end
end
