# DFO vessel density, 2024 (not committed: 87 MB)

Source: Fisheries and Oceans Canada, *Vessel Density Mapping of 2024 AIS Data
in the Northwest Atlantic*, Open Government Licence – Canada.
Dataset page: https://donnees.iriu.ca/dataset/27b450d8-3a9a-460a-8f71-587737b2cdf4

File used: `TIF_for_Download_Albers.zip` (GeoTIFF, ESRI:102001, 1 km cells,
vessel tracks per day per km²), downloaded November 19, 2026 from
https://api-proxy.edh-cde.dfo-mpo.gc.ca/catalogue/records/27b450d8-3a9a-460a-8f71-587737b2cdf4/attachments/TIF_for_Download_Albers.zip

SHA-256 of the zip: `d64606cc7d1573c409dd8a7573c96c3f9b34a212dc4143eadf65f9cddb8e27e2`

Layers used: `CARGO_VPD_2024.tif`, `TANKER_VPD_2024.tif`. Method:
Veinot and others (2023), Can. Tech. Rep. Fish. Aquat. Sci. 3520 (CCG
terrestrial plus satellite AIS; vessel class from vessel databases; no length
filter). Used by `python/st_lawrence_dfo.py`.
