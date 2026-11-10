function [cache_file]=ais_cache_name_rev1(day,R,p)
%ais_cache_name_rev1  Cache file path for one AIS day, grid, and filter.
%
%   cache_file=ais_cache_name_rev1(day,R,p) encodes the day, the grid
%   (limits and cell size), and the large-ship filter in the file name, so
%   a cache built with other settings is never reused by mistake.

arguments
    day (1,1) datetime
    R (1,1) map.rasterref.GeographicCellsReference
    p (1,1) struct
end

vt=p.filt.vessel_types;
filt_key=sprintf('L%g_imo%d_sog%g_vt%d-%d-n%d-s%d',p.filt.min_length_m,p.filt.require_imo, ...
    p.filt.min_sog_kn,min(vt),max(vt),numel(vt),sum(vt));
grid_key=sprintf('%g_%g_%g_%g_d%g',R.LatitudeLimits,R.LongitudeLimits,R.CellExtentInLatitude);
if isfield(p.filt,'no_imo_types') && ~isempty(p.filt.no_imo_types)
    filt_key=sprintf('%s_ni%s',filt_key,strjoin(string(p.filt.no_imo_types),'-'));
end
cache_file=fullfile(p.data_dir,sprintf('ais_cells_%s_%s_%s_rev1.mat', ...
    char(string(day,'yyyyMMdd')),filt_key,grid_key));
end
