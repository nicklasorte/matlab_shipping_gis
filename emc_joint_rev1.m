function J = emc_joint_rev1(P, f_mhz, opts)
%EMC_JOINT_REV1 Share of time with interference, scanning antennas and ITM time variability combined.
%   J = EMC_JOINT_REV1(P, f_mhz) returns, for each ship radar type, the table
%     J.(type).pexc(i, k) = P( L(d_i) - MAG < x_k )
%   the share of time that a pair with x = x_k sees interference at distance d_i. Here x = L_req - G_nexrad_peak(f),
%   with L_req the required loss with both peak gains after FDR (emc_required_loss_rev1 less OFR), and MAG the
%   mutual antenna gain of the tables of emc_antennas_rev1 (NEXRAD at its peak gain, the ship antenna relative
%   to its peak). Then L(d) < L_req - G_nexrad_peak - G_ship_peak + (MAG + G_ship_peak) = x + MAG is exactly
%   received I/N above the criterion.
%   Statistics: MAG and the path loss are independent. MAG: NEXRAD scanning its VCPs (216 modes, worst-mode
%   envelope at each gain) and the ship antenna rotating, Rec. ITU-R M.2069-0 Annex 1 random mode
%   (mag_pair_cdf_rev1, return_curve), at the takeoff angles of emc_takeoff_angle_rev1 for each distance.
%   Path loss: ITM v1.4 area mode time variability (P.analysis settings) at opts.q_itm percentages,
%   interpolated linearly in time share between them and held at the end values outside.
%     pexc(d, x) = sum_g pmf_MAG(g; d) * T(d, x + g),   T(d, y) = share of time L(d) < y
%   evaluated as a correlation along the loss axis with FFTs (conv() is direct; this is a 2-D batch).
%   opts.d_km    distance grid (default 1-44.5 km in 0.5 km, then 45-2,000 km in 1 km)
%   opts.x_db    grid of x (default 60-340 dB in 0.1 dB)
%   opts.q_itm   ITM time percentages (default 0.001-99.999, 33 values)
arguments
    P (1,1) struct
    f_mhz (1,1) double {mustBePositive}
    opts.d_km (:,1) double = [(1:0.5:44.5)'; (45:1:2000)']
    opts.x_db (1,:) double = 60:0.1:340
    opts.q_itm (1,:) double = [0.001 0.002 0.005 0.01 0.02 0.05 0.1 0.2 0.5 1 2 5 10 15 20 30 40 50 ...
        60 70 80 85 90 95 98 99 99.5 99.8 99.9 99.95 99.99 99.995 99.999]
end
dx = 0.1;
if any(abs(diff(opts.x_db) - dx) > 1e-9)
    error("emc:xGrid", "x_db must be uniform in %g dB steps.", dx);
end
if ~exist("mag_pair_cdf_rev1", "file")
    error("emc:noMag", "mutual_antenna_gain is not on the path.");
end
d = opts.d_km;
nd = numel(d);
a = P.analysis;
L = itm_area_rev1(P.nexrad.height_m, P.ship.height_m, d, a.delta_h_m, f_mhz, opts.q_itm, climate=a.climate, ...
    N_0=a.n0, polarization=a.polarization, epsilon=a.epsilon, sigma=a.sigma, mdvar=a.mdvar, ...
    confidence=a.confidence_pct, validity="off");
qf = opts.q_itm / 100;

% Takeoff angles per distance (equal heights: equal at both ends)
[el_n, el_s] = emc_takeoff_angle_rev1(d, P.nexrad.height_m, P.ship.height_m, a.n0);
[el_u, ~, iel] = unique(round([el_n(:), el_s(:)], 6), "rows");

% Antenna tables
A = emc_antennas_rev1(P, f_mhz);
el_grid = (-0.5:0.05:0.5).';
[scans, names] = nexrad_mode_scans_rev1("all");
Tn = gain_dist_table_rev1(A.nexrad, scans, struct("name", "WSR-88D", "mode_names", names, "el_grid_deg", el_grid));
J = struct("f_mhz", f_mhz, "d_km", d, "x_db", opts.x_db, "itm_loss_db", L, "q_itm", opts.q_itm, ...
    "el_nexrad_deg", el_n, "el_ship_deg", el_s);
for t = ["magnetron", "solid_state"]
    Ts = gain_dist_table_rev1(A.(t), A.ship_scan.(t), struct("name", t, "el_grid_deg", el_grid));
    R = mag_pair_cdf_rev1(Tn, Ts, el_u(:, 1), el_u(:, 2), struct("return_curve", true, "pct", 99));
    % pmf on a dx grid: mass at each upper bin edge from the exceedance curve (conservative by < dx)
    gmin = inf; gmax = -inf;
    for u = 1:numel(R.curve)
        gmin = min(gmin, R.curve{u}.gain_dBi(1)); gmax = max(gmax, R.curve{u}.gain_dBi(end));
    end
    g = (floor(gmin/dx)*dx : dx : ceil(gmax/dx)*dx);
    pmf_u = zeros(numel(R.curve), numel(g));
    for u = 1:numel(R.curve)
        c = R.curve{u};
        e = interp1(c.gain_dBi, c.exceed_pct/100, g, "previous", "extrap");
        e(g < c.gain_dBi(1)) = 1;
        e(g >= c.gain_dBi(end)) = 0;
        pmf_u(u, :) = -diff([1, e]);
    end
    if any(abs(sum(pmf_u, 2) - 1) > 1e-6)
        error("emc:pmf", "MAG distribution does not sum to 1.");
    end
    % T(d, y) on y = x + g
    ng = numel(g);
    y = opts.x_db(1) + g(1) + dx*(0:numel(opts.x_db) + ng - 2);
    T = zeros(nd, numel(y));
    for i = 1:nd
        Li = L(i, :) + (1:numel(qf))*1e-9;              % strictly increasing for interp1
        T(i, :) = interp1(Li, qf, y, "linear");
        T(i, y < Li(1)) = qf(1);
        T(i, y > Li(end)) = qf(end);
    end
    % pexc(:, k) = sum_j pmf(j) * T(:, k + j - 1): correlation along y (valid part)
    m = 2^nextpow2(size(T, 2) + ng - 1);
    K = fft(fliplr(pmf_u(iel, :)), m, 2);
    C = real(ifft(fft(T, m, 2) .* K, [], 2));
    pex = C(:, ng:ng + numel(opts.x_db) - 1);
    J.(t).pexc = min(max(pex, 0), 1);
    J.(t).gain_peak_dbi = gmax;
    J.(t).mag_curve = R.curve;
    J.(t).el_u = el_u;
end
end
