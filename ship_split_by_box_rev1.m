function [cell_pairs,info]=ship_split_by_box_rev1(cell_pairs,in_box,keep)
%ship_split_by_box_rev1  Split ships by whether they were ever seen outside a region.
%
%   [cell_pairs,info]=ship_split_by_box_rev1(cell_pairs,in_box,keep) takes the
%   per-day [linear_cell mmsi] pairs (CELL_PAIRS, one N-by-2 array per day), a
%   logical raster IN_BOX of the region (box_mask_rev1), and KEEP:
%     "inside_only"   keep only ships whose every sampled position, on every
%                     day, lies inside the region (ships that sail only there)
%     "seen_outside"  keep every ship seen outside the region at least once,
%                     with all of its pairs, inside the region too
%   and returns the pairs of the kept ships. INFO counts the ships in each class.
%
%   A ship is classified by what the sampled days show: a ship that left the
%   region only on an unsampled day counts as "inside_only".
%
%   Built-ins: unique, ismember, setdiff. Pairs stay in memory one day at a
%   time (two passes), so the call needs no copy of all days together.

arguments
    cell_pairs cell
    in_box logical
    keep (1,1) string {mustBeMember(keep,["inside_only","seen_outside"])}
end
all_ships=zeros(0,1);
outside_ships=zeros(0,1);
for day_idx=1:numel(cell_pairs)
    day_pairs=cell_pairs{day_idx};
    if isempty(day_pairs)
        continue
    end
    all_ships=union(all_ships,unique(day_pairs(:,2)));
    outside_ships=union(outside_ships,unique(day_pairs(~in_box(day_pairs(:,1)),2)));
end
inside_ships=setdiff(all_ships,outside_ships);
info.num_ships=numel(all_ships);
info.num_inside_only=numel(inside_ships);
info.num_seen_outside=numel(outside_ships);
if keep=="inside_only"
    kept_ships=inside_ships;
else
    kept_ships=outside_ships;
end
for day_idx=1:numel(cell_pairs)
    day_pairs=cell_pairs{day_idx};
    if ~isempty(day_pairs)
        cell_pairs{day_idx}=day_pairs(ismember(day_pairs(:,2),kept_ships),:);
    end
end
end
