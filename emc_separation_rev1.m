function [d_sep_km, flag] = emc_separation_rev1(d_km, loss_db, l_req_db)
%EMC_SEPARATION_REV1 Separation distance at which path loss first stays at or above the required loss.
%   [d_sep_km, flag] = EMC_SEPARATION_REV1(d_km, loss_db, l_req_db): d_km is an ascending grid (column),
%   loss_db is numel(d_km)-by-P (one column per time percentage), l_req_db a vector of required losses.
%   d_sep_km(i, p) is the largest distance where loss < l_req (interference possible), interpolated to the
%   crossing. flag: 0 found; -1 loss already >= l_req at the first grid point (separation at or below
%   d_km(1)); +1 loss below l_req at the last grid point (separation beyond d_km(end)).
%   Built-ins considered: fzero needs a sign change on a monotone function; ITM loss can dip with distance in
%   the line-of-sight region, so the last crossing on a grid is used instead.
arguments
    d_km (:,1) double {mustBePositive}
    loss_db double
    l_req_db (:,1) double
end
if size(loss_db, 1) ~= numel(d_km)
    error("emc:gridSize", "loss_db must have one row per distance.");
end
n = numel(l_req_db); np = size(loss_db, 2);
d_sep_km = NaN(n, np); flag = zeros(n, np);
for p = 1:np
    L = loss_db(:, p);
    for i = 1:n
        k = find(L < l_req_db(i), 1, "last");
        if isempty(k)
            d_sep_km(i, p) = d_km(1); flag(i, p) = -1;
        elseif k == numel(d_km)
            d_sep_km(i, p) = d_km(end); flag(i, p) = 1;
        else
            d_sep_km(i, p) = interp1(L([k, k+1]), d_km([k, k+1]), l_req_db(i), "linear");
        end
    end
end
end
