function per=period_rev1()
%period_rev1  Analysis period for every MATLAB product and figure.
%
%   per=period_rev1() returns the years, the sampled days (the first 52
%   Wednesdays of each year), and the text used in file names and titles.
%   Change the years here (and in python/ship_period.py) to move the whole
%   analysis. 2024-2025 replaced 2023-2024 on November 12, 2026; 2023 and
%   January-June 2026 are held out as stability checks.
%
%   per (struct)
%     .years         [2024 2025]
%     .days          104 datetimes
%     .tag           '2024_2025' (folders and file names)
%     .range         '2024-2025' (titles)
%     .and           '2024 and 2025' (sentences)
%     .closure_year  2024 (Key Bridge closure, Fort McHenry Federal Channel)

per.years=[2024 2025];
days_per_year=52;
d=NaT(days_per_year*numel(per.years),1);
for k=1:numel(per.years)
    jan1=datetime(per.years(k),1,1);
    first_wed=jan1+caldays(mod(4-weekday(jan1),7));   %%%%%weekday: Sunday=1, Wednesday=4
    d((k-1)*days_per_year+(1:days_per_year))=first_wed+caldays(7*(0:days_per_year-1));
end
per.days=d';
per.tag=sprintf('%d_%d',per.years);
per.range=sprintf('%d-%d',per.years);
per.and=sprintf('%d and %d',per.years);
per.closure_year=2024;
end
