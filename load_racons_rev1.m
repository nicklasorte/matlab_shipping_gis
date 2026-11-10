function [racons]=load_racons_rev1(data_dir)
%load_racons_rev1  Radar beacons (racons) from NOAA electronic navigational charts.
%
%   racons=load_racons_rev1(data_dir) returns every radar transponder
%   beacon (S-57 object RTPBCN) in the NOAA ENC Direct general, coastal,
%   and approach chart layers as a table: name, radwal (the chart's
%   wavelength attribute, for example "0.03-X,0.10-S"), lat, lon, s_band.
%   s_band is true when the chart lists the 0.10 m (S-band, 2900-3100 MHz)
%   wavelength. Beacons charted at more than one scale are kept once
%   (positions within 0.005 deg). The first call caches the layers as
%   GeoJSON in DATA_DIR/racons/.
%
%   Racons answer ship radars in the band they are interrogated on, so an
%   S-band racon receives and transmits in 2900-3100 MHz.

arguments
    data_dir (1,:) char
end

cache_dir=fullfile(data_dir,'racons');
if ~isfolder(cache_dir)
    mkdir(cache_dir);
end
layers={'enc_general',12;'enc_coastal',14;'enc_approach',17};
parts=cell(size(layers,1),1);
for k=1:size(layers,1)
    f=fullfile(cache_dir,[layers{k,1} '_rtpbcn.geojson']);
    if ~isfile(f)
        url=sprintf('https://encdirect.noaa.gov/arcgis/rest/services/encdirect/%s/MapServer/%d/query',layers{k,1},layers{k,2});
        websave(f,url,'where','1=1','outFields','OBJNAM,RADWAL','outSR','4326','f','geojson',weboptions('Timeout',120));
    end
    T=geotable2table(readgeotable(f),["lat","lon"]);
    parts{k}=table(string(T.OBJNAM),string(T.RADWAL),T.lat,T.lon,'VariableNames',{'name','radwal','lat','lon'});
end
racons=vertcat(parts{:});
racons.radwal(ismissing(racons.radwal))="";
racons.s_band=contains(lower(racons.radwal),"0.10");

%%%%%Keep one row per position (charts at different scales repeat beacons);
%%%%%prefer the row that lists the most wavelengths
racons=sortrows(racons,'radwal','descend');
key=round([racons.lat racons.lon]/0.005);
[~,first]=unique(key,'rows','stable');
racons=racons(first,:);
end
