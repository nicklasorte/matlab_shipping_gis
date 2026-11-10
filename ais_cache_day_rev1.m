function [S]=ais_cache_day_rev1(day,R,p)
%ais_cache_day_rev1  Large-ship cell pairs for one AIS day, cached on disk.
%
%   S=ais_cache_day_rev1(day,R,p) returns struct S with fields pairs,
%   num_row_kept, and num_mmsi_kept for DAY on raster R (see
%   ais_large_ship_cells_rev1). The first call downloads the day,
%   processes it, and writes a cache .mat in p.data_dir; later calls load
%   the cache. The cache name encodes the grid and the filter, so a change
%   to either builds a new cache.
%
%   The cache is written to a temporary file and moved into place
%   atomically, so a parallel worker or a second MATLAB session never
%   reads a partial file. If another process wrote the same day first, its
%   file is kept (first writer wins).

arguments
    day (1,1) datetime
    R (1,1) map.rasterref.GeographicCellsReference
    p (1,1) struct
end

cache_file=ais_cache_name_rev1(day,R,p);
if isfile(cache_file)
    S=load(cache_file,'pairs','num_row_kept','num_mmsi_kept');
    return
end

[csv_path,tf_private]=download_ais_day_rev1(day,p.data_dir,p.zstd_exe,~p.delete_csv);
[S.pairs,S.num_row_kept,S.num_mmsi_kept]=ais_large_ship_cells_rev1(csv_path,R,p.filt);

%%%%%Atomic write: unique temp name in the same folder, then ATOMIC_MOVE.
[~,stem]=fileparts(cache_file);
[~,token]=fileparts(tempname);  %%%%%tempname gives a unique token
tmp_file=fullfile(p.data_dir,sprintf('%s_%s.part.mat',stem,token));
save(tmp_file,'-struct','S');
if isfile(cache_file)
    delete(tmp_file);   %%%%%another process finished first; keep its file
else
    src=java.io.File(tmp_file).toPath();
    dst=java.io.File(cache_file).toPath();
    opts=javaArray('java.nio.file.CopyOption',2);
    opts(1)=java.nio.file.StandardCopyOption.REPLACE_EXISTING;
    opts(2)=java.nio.file.StandardCopyOption.ATOMIC_MOVE;
    java.nio.file.Files.move(src,dst,opts);
end

if tf_private
    delete(csv_path);   %%%%%only this call's private copy; a shared CSV is never deleted here
end
end
