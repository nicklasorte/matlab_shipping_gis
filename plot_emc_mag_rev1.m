function out = plot_emc_mag_rev1(opts)
%PLOT_EMC_MAG_REV1 EMC paper Figure 3: how the mutual antenna gain builds from the two antennas' gains.
%   out = PLOT_EMC_MAG_REV1() computes the curves with emc_mag_components_rev1 at 3050 MHz (needs matlab_itm's
%   sibling mutual_antenna_gain on the path), writes outputs/emc/mag_components_3050_rev1.csv, and draws two
%   panels: left, the share of time each antenna's gain toward the other radar exceeds a value; right, the same
%   for the mutual antenna gain of each pair, with the 10%, 1% and 0.1% levels marked and the main beam to
%   main beam sum for reference. Writes docs/emc/fig_mag_distribution_rev1.png (300 dpi), .pdf, and .alt.txt.
arguments
    opts.out_base (1,1) string = fullfile(fileparts(mfilename("fullpath")), "docs", "emc", "fig_mag_distribution_rev1")
    opts.visible (1,1) string {mustBeMember(opts.visible, ["on", "off"])} = "off"
end
here = fileparts(mfilename("fullpath"));
[P, modes] = emc_params_rev1();
C = emc_mag_components_rev1(P, modes, P.analysis.f_mhz);
writetable(C, fullfile(here, "outputs", "emc", "mag_components_3050_rev1.csv"));
dark = [31 42 68] / 255; gray = [0.541 0.553 0.569];
[cm, ~] = emc_fig_color_rev1("magnetron"); [cs, ~] = emc_fig_color_rev1("solid_state");
fig = figure(Visible=opts.visible, Units="inches", Position=[1 1 8.5 4.4], Color="w");
theme(fig, "light");   % R2025b follows the desktop theme; figures for the paper are always light
pos = [0.075 0.13 0.30 0.77; 0.57 0.13 0.30 0.77];
spec = {{"nexrad", dark, "NEXRAD"; "magnetron", cm, "Magnetron fan beam"; "solid_state", cs, "Solid-state fan beam"}, ...
        {"mag_magnetron", cm, "NEXRAD and magnetron"; "mag_solid_state", cs, "NEXRAD and solid state"}};
ttl = ["Each antenna's gain toward the other radar", "Mutual antenna gain of the pair"];
for p = 1:2
    ax = axes(fig, Position=pos(p, :));
    hold(ax, "on");
    s = spec{p};
    lab = strings(0, 1); y_end = zeros(0, 1); col = zeros(0, 3);
    for k = 1:size(s, 1)
        c = C(C.curve == s{k, 1} & C.exceed_pct > 0, :);
        if isempty(c), error("emc:noCurve", "No rows for %s.", s{k, 1}); end
        stairs(ax, c.gain_dbi, c.exceed_pct, Color=s{k, 2}, LineWidth=2);
        lab(end+1) = s{k, 3}; y_end(end+1) = log10(c.exceed_pct(end)); col(end+1, :) = s{k, 2}; %#ok<AGROW> few curves
        x_end(k) = c.gain_dbi(end); %#ok<AGROW> few curves
    end
    set(ax, YScale="log");
    if p == 2
        for q = [10 1 0.1]
            yline(ax, q, ":", Color=gray, LineWidth=1);
            text(ax, -18, q*1.25, q + "% of the time", FontSize=8, Color=dark, FontName="Times New Roman");
        end
        mb = P.nexrad.gain_dbi + max(modes.gain_dbi(modes.system == "magnetron"));
        xline(ax, mb, "--", Color=gray, LineWidth=1);
        text(ax, mb - 1, 30, ["Main beam to", "main beam"], FontSize=8, Color=dark, HorizontalAlignment="right", ...
            FontName="Times New Roman");
    end
    for k = 1:numel(lab)
        text(ax, x_end(k) + 1, 10^y_end(k), lab(k), Color=col(k, :), FontSize=8.5, FontWeight="bold", ...
            FontName="Times New Roman", VerticalAlignment="middle", Clipping="off");
    end
    emc_fig_axes_rev1(ax, ttl(p), "Gain toward the other radar (dBi)", [-20 80], [1e-3 100]);
    ax.YTick = [1e-3 1e-2 0.1 1 10 100];
    ax.YTickLabel = ["0.001%", "0.01%", "0.1%", "1%", "10%", "100%"];
    if p == 1, ylabel(ax, "Share of time the gain is exceeded"); end
    clear x_end
end
out = opts.out_base;
exportgraphics(fig, out + ".png", Resolution=300);
exportgraphics(fig, out + ".pdf", ContentType="vector");
writelines("Two step charts on a logarithmic time-share axis at 3050 MHz, beyond the radio horizon. Left: the " + ...
    "share of time NEXRAD's gain toward the ship, and each ship fan beam's gain toward NEXRAD, exceeds a value; " + ...
    "each antenna spends most of the time on sidelobes and only a small share near its peak. Right: the mutual " + ...
    "antenna gain of each pair, the sum of the two gains, with dotted lines at 10%, 1% and 0.1% of the time and " + ...
    "a dashed line at the main beam to main beam sum. Values: outputs/emc/mag_components_3050_rev1.csv.", out + ".alt.txt");
close(fig);
end
