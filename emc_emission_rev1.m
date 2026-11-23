function p = emc_emission_rev1(f_mhz, tau_us, rise_us, chirp_mhz)
%EMC_EMISSION_REV1 Relative power spectral density of a pulsed radar emission (peak 1).
%   p = EMC_EMISSION_REV1(f_mhz, tau_us, rise_us, chirp_mhz), f_mhz offset from the carrier.
%   Unmodulated pulse (chirp_mhz = 0): envelope of a trapezoidal pulse spectrum, flat to 1/(pi*tau),
%   then -20 dB/decade, and -40 dB/decade beyond 1/(pi*rise) (NTIA Manual 5.5 radar emission envelope form).
%   Checked against NOAA ROC (40 dBc at 7.26 MHz, 80 dBc at 62 MHz) and ITU-R M.1849-3 / M.1460-2 -20 dB points.
%   FM pulse (chirp_mhz > 0): flat over +/-chirp/2, then (chirp/2 / |f|)^2 (-20 dB/decade); no rise time is
%   published for the solid-state radar, so the skirt is the slower (stricter) one.
%   Built-ins considered: phased.RectangularWaveform/LinearFMWaveform + fft give exact line spectra with nulls;
%   the envelope avoids nulls, as spectrum-management masks do.
arguments
    f_mhz double
    tau_us (1,1) double {mustBePositive}
    rise_us (1,1) double {mustBeNonnegative}
    chirp_mhz (1,1) double {mustBeNonnegative} = 0
end
af = abs(f_mhz);
if chirp_mhz > 0
    p = ones(size(af));
    out = af > chirp_mhz/2;
    p(out) = (chirp_mhz/2 ./ af(out)).^2;
else
    p = min(1, (1 ./ (pi*af*tau_us)).^2);
    if rise_us > 0
        p = p .* min(1, (1 ./ (pi*af*rise_us)).^2);
    end
    p(af == 0) = 1;
end
end
