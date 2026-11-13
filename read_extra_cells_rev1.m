function extra_mask=read_extra_cells_rev1(csv_path,R)
%read_extra_cells_rev1  Extra ship-water cells from a CSV of linear indices.
%
%   extra_mask=read_extra_cells_rev1(csv_path,R) reads one linear cell
%   index per row (column-major from the south-west cell, 1-based, the
%   MATLAB order for raster R) and returns them as a mask. Alaska uses it
%   for the satellite-AIS lanes beyond shore-receiver range
%   (python/alaska_satellite_lanes.py). An index outside the grid, or one
%   that isn't a whole number, is an error, because it means the CSV was
%   built for another grid.

arguments
    csv_path (1,1) string {mustBeFile}
    R (1,1) map.rasterref.GeographicCellsReference
end

extra_idx=readmatrix(csv_path);
num_cell=prod(R.RasterSize);
if any(~isfinite(extra_idx) | extra_idx<1 | extra_idx>num_cell | extra_idx~=round(extra_idx),'all')
    error('shipgis:extra','%s holds cell indices outside this grid.',csv_path);
end
extra_mask=false(R.RasterSize);
extra_mask(extra_idx)=true;
end
