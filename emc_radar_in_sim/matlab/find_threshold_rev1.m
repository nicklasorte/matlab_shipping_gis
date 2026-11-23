function thr_db = find_threshold_rev1(in_db, degradation, criterion)
%FIND_THRESHOLD_REV1 Lowest I/N at which a degradation metric reaches a criterion.
%   thr_db = find_threshold_rev1(in_db, degradation, criterion) linearly
%   interpolates between the last I/N below the criterion and the first at
%   or above it. Returns -Inf if the first point already fails and +Inf if
%   no point fails (threshold above the swept range).
arguments
    in_db (:,1) double
    degradation (:,1) double
    criterion (1,1) double
end
k = find(degradation >= criterion, 1, "first");
if isempty(k)
    thr_db = Inf;
elseif k == 1
    thr_db = -Inf;
else
    thr_db = interp1(degradation([k-1, k]) + [0; eps], in_db([k-1, k]), criterion, "linear");
end
end
