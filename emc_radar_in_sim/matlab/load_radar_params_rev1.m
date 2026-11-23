function params_tbl = load_radar_params_rev1(csv_path)
%LOAD_RADAR_PARAMS_REV1 Read data/radar_params.csv as a table of strings.
%   params_tbl = load_radar_params_rev1() reads ../data/radar_params.csv
%   relative to this file. Every column is read as string because many
%   cells hold ranges ("973-1040") or mode pairs ("1.2 SP / 1.8 LP").
%   make_radar_rev1 parses the numbers it needs.
arguments
    csv_path (1,1) string = fullfile(fileparts(mfilename("fullpath")), "..", "data", "radar_params.csv")
end
if ~isfile(csv_path)
    error("radar_in:noParams", "Radar parameter file not found: %s", csv_path);
end
opts = detectImportOptions(csv_path, "TextType", "string", "Delimiter", ",");
opts = setvartype(opts, opts.VariableNames, "string");
params_tbl = readtable(csv_path, opts);
end
