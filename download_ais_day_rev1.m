function [csv_path,tf_private]=download_ais_day_rev1(day,data_dir,zstd_exe,keep_csv,prefilter_min_length)
%download_ais_day_rev1  Download and decompress one day of AIS data.
%
%   [csv_path,tf_private]=download_ais_day_rev1(day,data_dir,zstd_exe,keep_csv,prefilter_min_length)
%   returns the path of the daily MarineCadastre AIS CSV for DAY.
%
%   - If the shared CSV (for example AIS 2024-01-01 -> ais-2024-01-01.csv)
%     already exists in DATA_DIR, it is returned as is (tf_private=false).
%   - Otherwise the file is downloaded and decompressed under a unique
%     temporary name, so parallel workers or several MATLAB sessions never
%     write the same file. With KEEP_CSV=true the result is moved into
%     the shared name atomically (first writer wins) and tf_private=false.
%     With KEEP_CSV=false the private file is returned (tf_private=true)
%     and the caller deletes it when done.
%
%   With PREFILTER_MIN_LENGTH > 0 (2024+ files only), the file is
%   decompressed through ais_prefilter.py, which keeps only rows with a
%   length of at least that many meters, so the full CSV (about 1 GB) never
%   touches the disk. Set it no higher than the ship filter's length.
%
%   2024+ files are .csv.zst. MATLAB has no zstd reader (unzip, gunzip,
%   and untar don't handle zstd), so the zstd command-line tool is called.
%   Install it with "brew install zstd". 2023 and earlier files are .zip
%   and use the built-in unzip.

arguments
    day (1,1) datetime
    data_dir (1,:) char
    zstd_exe (1,:) char = '/opt/homebrew/bin/zstd'
    keep_csv (1,1) logical = false
    prefilter_min_length (1,1) double {mustBeNonnegative} = 0
end

if ~isfolder(data_dir)
    mkdir(data_dir);
end

[url,file_name]=ais_day_url_rev1(day);
if endsWith(file_name,'.csv.zst')
    shared_csv=fullfile(data_dir,erase(file_name,'.zst'));
else
    shared_csv=fullfile(data_dir,replace(file_name,'.zip','.csv'));
end
if isfile(shared_csv)
    csv_path=shared_csv;
    tf_private=false;
    return
end

%%%%%Unique names for this call
[~,token]=fileparts(tempname);
work_dir=fullfile(data_dir,['dl_' token]);
mkdir(work_dir);
cleanup_dir=onCleanup(@() remove_folder(work_dir));
archive_path=fullfile(work_dir,file_name);
private_csv=fullfile(data_dir,sprintf('%s_%s.part.csv',erase(file_name,{'.csv.zst','.zip'}),token));

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

%%%%%Decompress into the private CSV
if endsWith(file_name,'.csv.zst')
    if ~isfile(zstd_exe)
        error('shipgis:zstd','zstd not found at %s. Install it (brew install zstd) or pass its path.',zstd_exe);
    end
    if prefilter_min_length>0
        %%%%%Stream: zstd to stdout, filter by length in Python, write the small CSV
        script=fullfile(fileparts(mfilename('fullpath')),'ais_prefilter.py');
        %%%%%pipefail: a zstd failure must fail the command, not just a Python one
        [status,msg]=system(sprintf('set -o pipefail; "%s" -dc -q "%s" | /usr/bin/python3 "%s" %g > "%s"', ...
            zstd_exe,archive_path,script,prefilter_min_length,private_csv));
    else
        [status,msg]=system(sprintf('"%s" -d -f -q "%s" -o "%s"',zstd_exe,archive_path,private_csv));
    end
    if status~=0
        error('shipgis:zstd','zstd failed on %s: %s',archive_path,msg);
    end
else
    out_files=unzip(archive_path,work_dir);
    csv_found=out_files(endsWith(out_files,'.csv'));
    if isempty(csv_found)
        error('shipgis:unzip','No CSV inside %s',archive_path);
    end
    atomic_move(csv_found{1},private_csv);
end

if ~keep_csv
    csv_path=private_csv;
    tf_private=true;
    return
end

%%%%%Publish the shared CSV; if another process already did, use theirs.
if isfile(shared_csv)
    delete(private_csv);
else
    atomic_move(private_csv,shared_csv);
end
csv_path=shared_csv;
tf_private=false;
end

function atomic_move(src_path,dst_path)
%%%%%java.nio ATOMIC_MOVE; movefile deletes then copies, so a reader can see a missing file.
opts=javaArray('java.nio.file.CopyOption',2);
opts(1)=java.nio.file.StandardCopyOption.REPLACE_EXISTING;
opts(2)=java.nio.file.StandardCopyOption.ATOMIC_MOVE;
java.nio.file.Files.move(java.io.File(src_path).toPath(),java.io.File(dst_path).toPath(),opts);
end

function remove_folder(folder)
if isfolder(folder)
    rmdir(folder,'s');
end
end
