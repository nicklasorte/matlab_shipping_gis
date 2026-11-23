function [P, modes] = emc_params_rev1(param_csv, modes_csv)
%EMC_PARAMS_REV1 Read the EMC radar parameters and ship radar modes.
%   [P, modes] = EMC_PARAMS_REV1() reads data/emc/radar_params_rev1.csv into a struct
%   P.<system>.<parameter> (value column) and data/emc/radar_modes_rev1.csv into a table.
%   Errors if a value is missing or outside its low-high range.
arguments
    param_csv (1,1) string = fullfile(fileparts(mfilename("fullpath")), "data", "emc", "radar_params_rev1.csv")
    modes_csv (1,1) string = fullfile(fileparts(mfilename("fullpath")), "data", "emc", "radar_modes_rev1.csv")
end
if ~isfile(param_csv) || ~isfile(modes_csv)
    error("emc:noParams", "Parameter files not found: %s, %s", param_csv, modes_csv);
end
T = readtable(param_csv, "TextType", "string", "Delimiter", ",");
if any(ismissing(T.value)) || any(ismissing(T.low)) || any(ismissing(T.high))
    error("emc:missingValue", "A value, low, or high entry is missing in %s.", param_csv);
end
bad = T.value < T.low | T.value > T.high;
if any(bad)
    error("emc:outOfRange", "Value outside its range: %s", strjoin(T.system(bad) + "." + T.parameter(bad), ", "));
end
P = struct();
for k = 1:height(T)
    P.(T.system(k)).(T.parameter(k)) = T.value(k);
end
modes = readtable(modes_csv, "TextType", "string", "Delimiter", ",");
num = ["pulse_us", "prf_hz", "peak_kw", "gain_dbi", "if_mhz", "nf_db", "tx_bw_mhz", "otr_k"];
if any(ismissing(modes(:, num)), "all")
    error("emc:missingValue", "A numeric entry is missing in %s.", modes_csv);
end
end
