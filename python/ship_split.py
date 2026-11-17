"""Python twin of box_mask_rev1.m and ship_split_by_box_rev1.m (review R5MET-1, R5MET-7).

box_mask: raster of cells whose centers lie inside any [lat_min, lat_max, lon_min, lon_max] box.
ship_split: keep ships never seen outside a region ("inside_only") or seen outside it at
least once ("seen_outside"). A ship is classified by what the sampled days show.
The two implementations must agree exactly (integer and logical outputs).
"""
import numpy as np


def box_mask(lat_lim, lon_lim, cells_per_degree, boxes):
    """Logical array (rows south to north, columns west to east) for N-by-4 boxes."""
    boxes = np.atleast_2d(np.asarray(boxes, float))
    if boxes.shape[1] != 4 or np.any(boxes[:, 0] > boxes[:, 1]) or np.any(boxes[:, 2] > boxes[:, 3]):
        raise ValueError("each box must be [lat_min lat_max lon_min lon_max] with min <= max")
    step = 1.0 / cells_per_degree
    n_lat = int(round((lat_lim[1] - lat_lim[0]) / step))
    n_lon = int(round((lon_lim[1] - lon_lim[0]) / step))
    lat_c = lat_lim[0] + step * (np.arange(1, n_lat + 1) - 0.5)
    lon_c = lon_lim[0] + step * (np.arange(1, n_lon + 1) - 0.5)
    out = np.zeros((n_lat, n_lon), bool)
    for b in boxes:
        out |= ((lat_c >= b[0]) & (lat_c <= b[1]))[:, None] & ((lon_c >= b[2]) & (lon_c <= b[3]))[None, :]
    return out


def ship_split(day_pairs, in_box_flat, keep):
    """day_pairs: list of (n, 2) int arrays [linear_cell (0-based), mmsi]; in_box_flat: bool by cell."""
    if keep not in ("inside_only", "seen_outside"):
        raise ValueError("keep must be 'inside_only' or 'seen_outside'")
    all_ships, outside = set(), set()
    for d in day_pairs:
        if len(d) == 0:
            continue
        all_ships.update(np.unique(d[:, 1]).tolist())
        outside.update(np.unique(d[~in_box_flat[d[:, 0]], 1]).tolist())
    inside = all_ships - outside
    kept = inside if keep == "inside_only" else outside
    info = dict(num_ships=len(all_ships), num_inside_only=len(inside), num_seen_outside=len(outside))
    out = [d[np.isin(d[:, 1], list(kept))] if len(d) else d for d in day_pairs]
    return out, info
