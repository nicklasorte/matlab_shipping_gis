function out = plot_emc_offset_rev1(opts)
%PLOT_EMC_OFFSET_REV1 EMC paper Figure 1: separation for 50% of time against frequency offset.
%   out = PLOT_EMC_OFFSET_REV1() reads outputs/emc/offset_envelope_rev1.csv (largest distance over the mode
%   pairs) and writes docs/emc/fig_offset_separation_matlab_rev1.png (300 dpi) and .pdf, with alt text in
%   .alt.txt. MATLAB twin of python/emc_offset_figure.py.
%   opts.level "q10", "q1" or "q0_1" reads stat_envelope_offset_rev1.csv instead (interference no more than 10,
%   1 or 0.1% of the time, both antennas scanning, ITM time variability; init_emc_statistics_rev1) and writes
%   docs/emc/fig_offset_separation_<level>_rev1.
arguments
    opts.level (1,1) string {mustBeMember(opts.level, ["main_beam", "q10", "q1", "q0_1"])} = "main_beam"
    opts.out_base (1,1) string = ""
    opts.visible (1,1) string {mustBeMember(opts.visible, ["on", "off"])} = "off"
end
here = fileparts(mfilename("fullpath"));
if opts.level == "main_beam"
    E = readtable(fullfile(here, "outputs", "emc", "offset_envelope_rev1.csv"), "TextType", "string");
    ycol = "d_km_p50"; y_top = 1200; ylab = "Separation for 50% of time (km)";
    if opts.out_base == "", opts.out_base = fullfile(here, "docs", "emc", "fig_offset_separation_matlab_rev1"); end
    cpl = "main beam to main beam";
else
    E = readtable(fullfile(here, "outputs", "emc", "stat_envelope_offset_rev1.csv"), "TextType", "string");
    ycol = "d_km_" + opts.level; y_top = 900; ylab = "Separation (km)";
    if opts.out_base == "", opts.out_base = fullfile(here, "docs", "emc", "fig_offset_separation_" + opts.level + "_rev1"); end
    cpl = "both antennas scanning, interference no more than " + replace(extractAfter(opts.level, "q"), "_", ".") + "% of the time";
end
panels = {"ship to NEXRAD", "Ship radar into NEXRAD", ["NEXRAD pulsed", "NEXRAD constant"], ["pulsed level", "-10 dB"]
          "NEXRAD to ship", "NEXRAD into ship radar", ["ship -6 dB", "ship 30 dB"], ["-6 dB", "+30 dB"]};
fig = figure(Visible=opts.visible, Units="inches", Position=[1 1 8.5 4.4], Color="w");
theme(fig, "light");   % R2025b follows the desktop theme; figures for the paper are always light
pos = [0.075 0.13 0.27 0.77; 0.57 0.13 0.27 0.77];   % room at the right of each panel for end labels
for p = 1:2
    ax = axes(fig, Position=pos(p, :));
    hold(ax, "on");
    lab = strings(0, 1); y_end = zeros(0, 1); col = zeros(0, 3);
    for sys = ["magnetron", "solid_state"]
        [c, name] = emc_fig_color_rev1(sys);
        for q = 1:2
            g = sortrows(E(E.direction == panels{p, 1} & E.system == sys & E.protection == panels{p, 3}(q), :), "df_mhz");
            if isempty(g)
                error("emc:noRows", "No envelope rows for %s, %s, %s.", panels{p, 1}, sys, panels{p, 3}(q));
            end
            ls = ["-", "--"]; lw = [2 1.4];
            plot(ax, g.df_mhz, g.(ycol), ls(q), Color=c, LineWidth=lw(q));
            lab(end+1) = name + ", " + panels{p, 4}(q); y_end(end+1) = g.(ycol)(end); col(end+1, :) = c; %#ok<AGROW> four lines
        end
    end
    emc_fig_end_labels_rev1(ax, 153, y_end, lab, col, 45);
    xline(ax, 60, ":", Color=[0.541 0.553 0.569], LineWidth=1);
    text(ax, 61, y_top - 50, ["60 MHz: widest offset", "inside 3020-3080 MHz"], FontSize=8, ...
        Color=[0.122 0.165 0.267], VerticalAlignment="top", FontName="Times New Roman");
    emc_fig_axes_rev1(ax, panels{p, 2}, "Frequency offset (MHz)", [0 150], [0 y_top]);
    if p == 1, ylabel(ax, ylab); end
end
out = opts.out_base;
exportgraphics(fig, out + ".png", Resolution=300);
exportgraphics(fig, out + ".pdf", ContentType="vector");
writelines("Two line charts of separation distance against frequency offset from 0 to " + ...
    "150 MHz, " + cpl + ", ship radar into NEXRAD (left) and NEXRAD into ship radar (right), for " + ...
    "magnetron and solid-state ship radars at both protection levels of each victim. A dotted line marks " + ...
    "60 MHz, the widest offset inside 3020-3080 MHz. Values: column " + ycol + " of the envelope CSV in outputs/emc.", out + ".alt.txt");
close(fig);
end
