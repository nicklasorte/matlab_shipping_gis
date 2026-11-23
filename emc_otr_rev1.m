function otr_db = emc_otr_rev1(bt_mhz, br_mhz, k)
%EMC_OTR_REV1 On-tune rejection, Rec. ITU-R SM.337-6 Annex 1 equation (6).
%   otr_db = EMC_OTR_REV1(bt_mhz, br_mhz, k): k*log10(B_T/B_R) when the receiver 3 dB bandwidth B_R is
%   narrower than the transmitter 3 dB bandwidth B_T, otherwise 0. k = 20 for pulses, 10 for non-coherent
%   (here: frequency-modulated, spread) signals. Inputs expand implicitly.
arguments
    bt_mhz double {mustBePositive}
    br_mhz double {mustBePositive}
    k double {mustBeMember(k, [10 20])}
end
otr_db = max(0, k .* log10(bt_mhz ./ br_mhz));
end
