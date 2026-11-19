# World Bank / IMF Global Shipping Traffic Density, Commercial (clip)

`wb_commercial_stlawrence_rev1.tif`: window lat 43 to 52, lon -80 to -55 of
`ShipDensity_Commercial1.tif` (0.005 deg, AIS position counts, January 2015 to
February 2021; IMF World Seaborne Trade Monitoring System). CC BY 4.0.
Dataset: https://datacatalog.worldbank.org/search/dataset/0037580
Zip: https://datacatalogfiles.worldbank.org/ddh-published/0037580/5/DR0045405/shipdensity_commercial_.zip
(downloaded November 19, 2026; SHA-256 `0cfdce41d9934982bbc8f16bd92ce7545cc088839327cbaa9b0ed1469dda31e8`).

Values are used only by rank: the threshold is calibrated against our AIS route
cells and the DFO route cells (`python/st_lawrence_route.py`). The counts in the
channel (tens of millions per 500 m cell) are larger than hourly positions over six
years would allow, so treat them as relative intensity, not counts.
