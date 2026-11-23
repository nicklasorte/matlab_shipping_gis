function h = emc_selectivity_rev1(f_mhz, kind, opts)
%EMC_SELECTIVITY_REV1 Relative power response of a radar receiver (1 at the tuned frequency).
%   h = EMC_SELECTIVITY_REV1(f_mhz, "nexrad", tau_us=1.57, bpf=[f1 f2 f3 f4]) : NEXRAD matched filter for
%   its rectangular pulse (sinc^2 envelope, flat to 1/(pi*tau) then -20 dB/decade) times the front-end filter
%   (NOAA ROC: 0.5 dB at f1, 3 dB at f2, 30 dB at f3, 60 dB at f4 MHz; linear in dB between points, 60 dB beyond).
%   h = EMC_SELECTIVITY_REV1(f_mhz, "ship", if_mhz=2.5, floor_db=60, poles=2) : IF response
%   1/(1+(2f/B)^(2n)) from the published 3 dB bandwidth B, floored at the spurious response rejection.
arguments
    f_mhz double
    kind (1,1) string {mustBeMember(kind, ["nexrad", "ship"])}
    opts.tau_us (1,1) double = 1.57
    opts.bpf (1,4) double = [0.35 10 25 100]
    opts.if_mhz (1,1) double = 2.5
    opts.floor_db (1,1) double = 60
    opts.poles (1,1) double = 2
end
af = abs(f_mhz);
if kind == "nexrad"
    mf = min(1, (1 ./ (pi*af*opts.tau_us)).^2);
    mf(af == 0) = 1;
    bpf_db = interp1([0 opts.bpf], [0 0.5 3 30 60], min(af, opts.bpf(4)), "linear");
    h = mf .* 10.^(-bpf_db/10);
else
    h = 1 ./ (1 + (2*af/opts.if_mhz).^(2*opts.poles));
    h = max(h, 10^(-opts.floor_db/10));
end
end
