function out = plot_emc_nexrad_sweep_rev1(opts)
%PLOT_EMC_NEXRAD_SWEEP_REV1 EMC paper Figure 2: separation for 50% of time against NEXRAD tuned frequency.
%   out = PLOT_EMC_NEXRAD_SWEEP_REV1() reads outputs/emc/nexrad_sweep_envelope_rev1.csv (largest distance over
%   the mode pairs, each ship mode at its closest tuning) and writes docs/emc/fig_nexrad_sweep_rev1.png
%   (300 dpi) and .pdf, with alt text in .alt.txt. The shaded band is the magnetron tuning range
%   (3020-3080 MHz); the dotted line is the top of NEXRAD's published range (3000 MHz).
%   opts.coupling: "main_beam" (default; nexrad_sweep_envelope_rev1.csv) or a level of coupling_envelope_rev1.csv
%   ("peak", "p99.9", "p99", "p90"; init_emc_coupling_rev1), or a time share of stat_envelope_sweep_rev1.csv
%   ("q10", "q1", "q0_1": interference no more than 10, 1 or 0.1% of the time with both antennas scanning and ITM
%   time variability; init_emc_statistics_rev1), written to fig_nexrad_sweep_<level>_rev1.
arguments
    opts.coupling (1,1) string {mustBeMember(opts.coupling, ["main_beam", "peak", "p99.9", "p99", "p90", "q10", "q1", "q0_1"])} = "main_beam"
    opts.out_base (1,1) string = ""
    opts.visible (1,1) string {mustBeMember(opts.visible, ["on", "off"])} = "off"
end
here = fileparts(mfilename("fullpath"));
ycol = "d_km_p50"; y_top = 1400; ylab = "Separation for 50% of time (km)";
if startsWith(opts.coupling, "q")
    E = readtable(fullfile(here, "outputs", "emc", "stat_envelope_sweep_rev1.csv"), "TextType", "string");
    ycol = "d_km_" + opts.coupling; y_top = 900; ylab = "Separation (km)";
    if opts.out_base == "", opts.out_base = fullfile(here, "docs", "emc", "fig_nexrad_sweep_" + opts.coupling + "_rev1"); end
elseif opts.coupling == "main_beam"
    E = readtable(fullfile(here, "outputs", "emc", "nexrad_sweep_envelope_rev1.csv"), "TextType", "string");
    if opts.out_base == "", opts.out_base = fullfile(here, "docs", "emc", "fig_nexrad_sweep_rev1"); end
else
    E = readtable(fullfile(here, "outputs", "emc", "coupling_envelope_rev1.csv"), "TextType", "string");
    E = E(E.coupling == opts.coupling, :);
    if opts.out_base == ""
        opts.out_base = fullfile(here, "docs", "emc", "fig_nexrad_sweep_" + replace(opts.coupling, ".", "_") + "_rev1");
    end
end
panels = {"ship to NEXRAD", "Ship radar into NEXRAD", ["NEXRAD pulsed", "NEXRAD constant"], ["pulsed level", "-10 dB"]
          "NEXRAD to ship", "NEXRAD into ship radar", ["ship -6 dB", "ship 30 dB"], ["-6 dB", "+30 dB"]};
gray = [0.541 0.553 0.569]; dark = [31 42 68] / 255;
fig = figure(Visible=opts.visible, Units="inches", Position=[1 1 8.5 4.4], Color="w");
theme(fig, "light");   % R2025b follows the desktop theme; figures for the paper are always light
pos = [0.075 0.13 0.27 0.77; 0.57 0.13 0.27 0.77];   % room at the right of each panel for end labels
for p = 1:2
    ax = axes(fig, Position=pos(p, :));
    hold(ax, "on");
    patch(ax, [3020 3080 3080 3020], [0 0 y_top y_top], [0.93 0.93 0.94], EdgeColor="none");
    xline(ax, 3000, ":", Color=gray, LineWidth=1);
    text(ax, 3050, y_top - 15, ["Magnetron", "range"], FontSize=8, Color=dark, VerticalAlignment="top", ...
        HorizontalAlignment="center", FontName="Times New Roman");
    text(ax, 2995, y_top - 15, ["NEXRAD published", "range ends 3000 MHz"], FontSize=8, Color=dark, ...
        HorizontalAlignment="right", VerticalAlignment="top", FontName="Times New Roman");
    lab = strings(0, 1); y_end = zeros(0, 1); col = zeros(0, 3);
    for sys = ["magnetron", "solid_state"]
        [c, name] = emc_fig_color_rev1(sys);
        for q = 1:2
            g = sortrows(E(E.direction == panels{p, 1} & E.system == sys & E.protection == panels{p, 3}(q), :), "f_nexrad_mhz");
            if isempty(g)
                error("emc:noRows", "No envelope rows for %s, %s, %s.", panels{p, 1}, sys, panels{p, 3}(q));
            end
            ls = ["-", "--"]; lw = [2 1.4];
            plot(ax, g.f_nexrad_mhz, g.(ycol), ls(q), Color=c, LineWidth=lw(q));
            lab(end+1) = name + ", " + panels{p, 4}(q); y_end(end+1) = g.(ycol)(end); col(end+1, :) = c; %#ok<AGROW> four lines
        end
    end
    emc_fig_end_labels_rev1(ax, 3105, y_end, lab, col, 60);
    emc_fig_axes_rev1(ax, panels{p, 2}, "NEXRAD frequency (MHz)", [2800 3100], [0 y_top]);
    ax.XTick = 2800:100:3100;
    if p == 1, ylabel(ax, ylab); end
end
out = opts.out_base;
exportgraphics(fig, out + ".png", Resolution=300);
exportgraphics(fig, out + ".pdf", ContentType="vector");
writelines(emc_sweep_alt(E, opts.coupling, ycol), out + ".alt.txt");
close(fig);
end

function s = emc_sweep_alt(E, coupling, ycol)
% Alt text with the end-point values read from the envelope.
v = @(d, sys, pr, f) round(E.(ycol)(E.direction == d & E.system == sys & E.protection == pr & E.f_nexrad_mhz == f));
if coupling == "main_beam"
    cpl = 'main beam to main beam';
elseif startsWith(coupling, "q")
    cpl = sprintf('both antennas scanning, interference no more than %s%%%% of the time', replace(extractAfter(coupling, "q"), "_", "."));
elseif coupling == "peak"
    cpl = 'both beams aimed along the path, NEXRAD at its lowest tilt seen along the horizon ray';
else
    cpl = sprintf('antenna coupling exceeded %g%%%% of the time with both radars scanning', 100 - str2double(extractAfter(coupling, "p")));
end
s = sprintf(['Two line charts of separation distance against NEXRAD tuned frequency from ' ...
    '2800 to 3100 MHz, ' cpl ', with each ship radar at its closest tuning. Left, ship radar into ' ...
    'NEXRAD at NEXRAD''s pulsed protection level: magnetron radars need %d km at 2800 MHz and %d km at 3050 MHz; ' ...
    'the solid-state radar needs %d km and %d km. Right, NEXRAD into ship radar at -6 dB: %d km and %d km ' ...
    '(magnetron), %d km and %d km (solid state). Dashed lines show the other protection level. A shaded band ' ...
    'marks the magnetron tuning range, 3020-3080 MHz, and a dotted line marks 3000 MHz, the top of NEXRAD''s ' ...
    'published range.'], ...
    v("ship to NEXRAD", "magnetron", "NEXRAD pulsed", 2800), v("ship to NEXRAD", "magnetron", "NEXRAD pulsed", 3050), ...
    v("ship to NEXRAD", "solid_state", "NEXRAD pulsed", 2800), v("ship to NEXRAD", "solid_state", "NEXRAD pulsed", 3050), ...
    v("NEXRAD to ship", "magnetron", "ship -6 dB", 2800), v("NEXRAD to ship", "magnetron", "ship -6 dB", 3050), ...
    v("NEXRAD to ship", "solid_state", "ship -6 dB", 2800), v("NEXRAD to ship", "solid_state", "ship -6 dB", 3050));
end
