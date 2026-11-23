function emc_fig_end_labels_rev1(ax, x, y, labels, colors, gap)
%EMC_FIG_END_LABELS_REV1 Direct labels at the right end of lines, spread apart by at least gap (y units)
%   while keeping their order. Custom block: text() has no collision avoidance and legend() would replace
%   direct labels.
arguments
    ax (1,1) matlab.graphics.axis.Axes
    x (1,1) double
    y (:,1) double
    labels (:,1) string
    colors (:,3) double
    gap (1,1) double {mustBePositive}
end
[ys, order] = sort(y);
for k = 2:numel(ys)
    ys(k) = max(ys(k), ys(k-1) + gap);
end
y_lab(order) = ys;
for k = 1:numel(y)
    text(ax, x, y_lab(k), labels(k), Color=colors(k, :), FontSize=8.5, FontWeight="bold", ...
        FontName="Times New Roman", VerticalAlignment="middle", Clipping="off");
end
end
