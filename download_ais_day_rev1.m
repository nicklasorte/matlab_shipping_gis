function [csv_path]=download_ais_day_rev1(day,data_dir,zstd_exe)
%download_ais_day_rev1  Download and decompress one day of AIS data.
%
%   csv_path=download_ais_day_rev1(day,data_dir,zstd_exe) downloads the
%   daily MarineCadastre AIS file for DAY into DATA_DIR, decompresses it,
%   and returns the path of the CSV. A CSV that already exists is reused.
%
%   2024+ files are .csv.zst. MATLAB has no zstd reader (unzip, gunzip,
%   and untar don't handle zstd), so the zstd command-line tool is called.
%   Install it with "brew install zstd". 2023 and earlier files are .zip
%   and use the built-in unzip.

arguments
    day (1,1) datetime
    data_dir (1,:) char
    zstd_exe (1,:) char = '/opt/homebrew/bin/zstd'
end

if ~isfolder(data_dir)
    mkdir(data_dir);
end

[url,file_name]=ais_day_url_rev1(day);
archive_path=fullfile(data_dir,file_name);

%%%%%Expected CSV name after decompression
if endsWith(file_name,'.csv.zst')
    csv_path=fullfile(data_dir,erase(file_name,'.zst'));
else
    csv_path=fullfile(data_dir,replace(file_name,'.zip','.csv'));
end
if isfile(csv_path)
    return
end

%%%%%Download, bounded retries
num_try=3;
for try_idx=1:num_try
    try
        websave(archive_path,url,weboptions('Timeout',600));
        break
    catch err
        if try_idx==num_try
            error('shipgis:download','Download failed after %d tries: %s (%s)',num_try,url,err.message);
        end
    end
end

%%%%%Decompress
if endsWith(file_name,'.csv.zst')
    if ~isfile(zstd_exe)
        error('shipgis:zstd','zstd not found at %s. Install it (brew install zstd) or pass its path.',zstd_exe);
    end
    [status,msg]=system(sprintf('"%s" -d -f -q "%s" -o "%s"',zstd_exe,archive_path,csv_path));
    if status~=0
        error('shipgis:zstd','zstd failed on %s: %s',archive_path,msg);
    end
else
    out_files=unzip(archive_path,data_dir);
    csv_found=out_files(endsWith(out_files,'.csv'));
    if isempty(csv_found)
        error('shipgis:unzip','No CSV inside %s',archive_path);
    end
    if ~strcmp(csv_found{1},csv_path)
        movefile(csv_found{1},csv_path);
    end
end
delete(archive_path);
end
