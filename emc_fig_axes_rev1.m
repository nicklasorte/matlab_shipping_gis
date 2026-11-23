function emc_fig_axes_rev1(ax, ttl, xlab, xl, yl)
%EMC_FIG_AXES_REV1 NTIA style for an EMC figure axis: Times New Roman, title at left in dark blue, no top or
%   right axis line, light horizontal grid only.
arguments
    ax (1,1) matlab.graphics.axis.Axes
    ttl (1,1) string
    xlab (1,1) string
    xl (1,2) double
    yl (1,2) double
end
dark = [31 42 68] / 255;
set(ax, FontName="Times New Roman", FontSize=10, Box="off", XLim=xl, YLim=yl, TickDir="out", ...
    YGrid="on", XGrid="off", GridColor=[0.898 0.898 0.898], GridAlpha=1, Layer="top");
title(ax, ttl, Color=dark, FontWeight="bold", FontSize=11, HorizontalAlignment="left", Units="normalized", ...
    Position=[0 1.02 0]);
xlabel(ax, xlab);
end
