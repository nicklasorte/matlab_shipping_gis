function [url,file_name]=ais_day_url_rev1(day)
%ais_day_url_rev1  URL of one day of MarineCadastre AIS point data.
%
%   [url,file_name]=ais_day_url_rev1(day) returns the download URL and the
%   file name for the daily AIS file (USCG NAIS terrestrial receivers,
%   1-minute sample, U.S. EEZ, Great Lakes, and inland waterways).
%
%   2024 and later: zstd-compressed CSV with snake_case columns
%     https://noaaocm.blob.core.windows.net/ais/csv2/csv<yyyy>/ais-<yyyy-MM-dd>.csv.zst
%   2023 and earlier: zipped CSV with CamelCase columns
%     https://coast.noaa.gov/htdata/CMSP/AISDataHandler/<yyyy>/AIS_<yyyy_MM_dd>.zip
%
%   Both patterns were checked with an HTTP HEAD request on 2026-11-10.

arguments
    day (1,1) datetime
end

yr=year(day);
if yr>=2024
    file_name=char(string(day,'yyyy-MM-dd'));
    file_name=['ais-' file_name '.csv.zst'];
    url=sprintf('https://noaaocm.blob.core.windows.net/ais/csv2/csv%d/%s',yr,file_name);
else
    file_name=char(string(day,'yyyy_MM_dd'));
    file_name=['AIS_' file_name '.zip'];
    url=sprintf('https://coast.noaa.gov/htdata/CMSP/AISDataHandler/%d/%s',yr,file_name);
end
end
