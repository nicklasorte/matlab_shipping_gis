function [el1_deg, el2_deg, d_los_km, ae_km] = emc_takeoff_angle_rev1(d_km, h1_m, h2_m, n0)
%EMC_TAKEOFF_ANGLE_REV1 Takeoff angles at both ends of a smooth-earth path (ITM effective earth).
%   [el1_deg, el2_deg, d_los_km, ae_km] = EMC_TAKEOFF_ANGLE_REV1(d_km, h1_m, h2_m, n0) returns the elevation,
%   above the local horizontal, at which energy leaves each antenna toward the other end:
%     line of sight (d <= d_los): the direct ray, el1 = (h2 - h1)/d - d/(2*ae)  (rad);
%     beyond the radio horizon: each end's horizon ray, el = -sqrt(2*h/ae). Troposcatter and diffraction
%     energy leaves along the horizon rays; the scatter volume is high because the earth curves away, not
%     because the antennas look up.
%   d_los = sqrt(2*ae*h1) + sqrt(2*ae*h2). The effective earth radius follows ITM v1.4 (Hufford, 1995):
%   curvature gamma_e = 157e-9*(1 - 0.04665*exp(Ns/179.3)) 1/m, with Ns = n0 at sea level.
%   Built-ins considered: Mapping Toolbox elevation() and los2 need terrain and a true earth radius, not ITM's
%   effective radius on a smooth sea path.
arguments
    d_km double {mustBePositive}
    h1_m (1,1) double {mustBePositive}
    h2_m (1,1) double {mustBePositive}
    n0 (1,1) double {mustBePositive} = 301
end
ae_km = 1e-3 / (157e-9*(1 - 0.04665*exp(n0/179.3)));
r1 = sqrt(2*h1_m*1e-3/ae_km);                  % horizon depression, rad
r2 = sqrt(2*h2_m*1e-3/ae_km);
d_los_km = ae_km*(r1 + r2);
el1 = (h2_m - h1_m)*1e-3 ./ d_km - d_km/(2*ae_km);
el2 = (h1_m - h2_m)*1e-3 ./ d_km - d_km/(2*ae_km);
bh = d_km > d_los_km;
el1(bh) = -r1;
el2(bh) = -r2;
el1_deg = rad2deg(el1);
el2_deg = rad2deg(el2);
end
