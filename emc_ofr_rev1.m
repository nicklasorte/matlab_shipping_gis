function ofr_db = emc_ofr_rev1(df_mhz, p_fun, h_fun, opts)
%EMC_OFR_REV1 Off-frequency rejection, Rec. ITU-R SM.337-6 Annex 1 equations (3) to (5).
%   ofr_db = EMC_OFR_REV1(df_mhz, p_fun, h_fun): p_fun(f) is the interferer PSD and h_fun(f) the victim
%   selectivity, both relative and centered on 0. OFR(df) = 10*log10( int P(f)H(f)df / int P(f)H(f+df)df ).
%   FDR = OTR + OFR, with OTR from emc_otr_rev1 (eq. 6). The integrals are evaluated for all offsets at once as
%   a cross-correlation on a uniform grid (conv of P with the reversed H).
%   Built-ins considered: integral() per offset is exact but slow for hundreds of offsets and narrow filters.
arguments
    df_mhz double {mustBeNonnegative}
    p_fun (1,1) function_handle
    h_fun (1,1) function_handle
    opts.span_mhz (1,1) double {mustBePositive} = 400
    opts.step_mhz (1,1) double {mustBePositive} = 0.005
end
if max(df_mhz) > opts.span_mhz/2
    error("emc:span", "Largest offset must be at most half the integration span.");
end
f = (-opts.span_mhz:opts.step_mhz:opts.span_mhz).';
P = p_fun(f);
H = h_fun(f);
m = 2^nextpow2(2*numel(f) - 1);             % FFT convolution: conv() is direct and too slow at this length
c = real(ifft(fft(P, m) .* fft(flipud(H), m)));
c = c(1:2*numel(f) - 1);                    % c(k) = sum_f P(f) H(f - lag), lags -2*span..2*span
lag = (-(numel(f)-1):(numel(f)-1)).' * opts.step_mhz;
c0 = interp1(lag, c, 0);
cd = interp1(lag, c, -df_mhz(:));           % sum_f P(f) H(f + df)
ofr_db = reshape(10*log10(c0 ./ cd), size(df_mhz));
end
