function [c, name] = emc_fig_color_rev1(sys)
%EMC_FIG_COLOR_REV1 NTIA palette color and display name for a ship radar type in EMC figures.
%   Magnetron: NTIA light blue #5674C4; solid state: NTIA purple #7B3F98.
arguments
    sys (1,1) string {mustBeMember(sys, ["magnetron", "solid_state"])}
end
if sys == "magnetron"
    c = [86 116 196] / 255; name = "Magnetron";
else
    c = [123 63 152] / 255; name = "Solid state";
end
end
