"""Analysis period for every product and figure: one Wednesday a week, 52 per year.

Change Y0 and Y1 here (and p.ais_days in the MATLAB init scripts) to move the
whole analysis to other years. Outputs go to outputs/<TAG>/.

2024-2025 replaced 2023-2024 on November 12, 2026: the two most recent full years.
2023 and January-June 2026 are held out as stability checks
(python/ship_year_stability.py).
"""
import datetime as dt

Y0, Y1 = 2024, 2025
YEARS = (Y0, Y1)
TAG = f"{Y0}_{Y1}"              # folder and file-name tag
RANGE = f"{Y0}–{Y1}"       # "2024–2025" for titles
AND = f"{Y0} and {Y1}"          # "2024 and 2025" for sentences
DAYS_PER_YEAR = 52
CLOSURE_YEAR = 2024             # Key Bridge closure (Fort McHenry Federal Channel)


def days():
    """The first 52 Wednesdays of each year."""
    out = []
    for yr in YEARS:
        d = dt.date(yr, 1, 1)
        d += dt.timedelta((2 - d.weekday()) % 7)   # first Wednesday
        for _ in range(DAYS_PER_YEAR):
            out.append(d)
            d += dt.timedelta(7)
    return out
