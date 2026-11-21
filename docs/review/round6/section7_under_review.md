## 7. Guam and the Northern Mariana Islands

Large-ship zones around Guam and the Northern Mariana Islands (CNMI) cover 872 km² of U.S. land at 25, 50, and 100 km. That is 86% of the 1,019 km² of U.S. land in the grid. The routes around Guam come from AIS. The routes between Guam, Rota, Tinian, and Saipan are straight-line links that the analysis assumes, because the sampled AIS days hold almost no large-ship traffic there. Guam and the CNMI are one region, because the zones overlap at 100 km.

### 7.1 Routes

The route rule is the Hawaii rule: a cell is a route cell if large ships were in it on at least 6 ship-days over the 104 sampled days (Section 4.1). The AIS data give 1,468 route cells. Apra Harbor, the Port of Guam, is on them: 257 cells within 15 km of the harbor have at least one ship-day, and the busiest has 318. Elsewhere the AIS data are thin:

- Rota has 116 cells within 15 km, and none has more than 5 ship-days.
- Saipan has 5 cells within 15 km, and none has more than 2 ship-days.
- Tinian has none.

No ship-days threshold connects Saipan or Tinian, so the analysis adds 231 link cells (229 that aren't already route cells) along straight lines from Apra Harbor to Rota, Tinian, and Saipan. With the links, all 4 ports reach a continuous route. Without them, only Apra Harbor does. The links are an assumption about where ships run, not a measurement.

### 7.2 Zones

Because no foreign land lies near the grid, the water clip at the equidistance line removes nothing, and only the 200 nautical mile cap applies. Figure 11 maps the routes and the 25 km zone. With the links, the zones cover 872 km² of land at all three distances, because the islands are small and close together. Without the links, the zones cover 531 km² (52% of the land) at 25 km and 647 km² (63%) at 50 and 100 km. The links add 341 km² at 25 km and 225 km² at 50 and 100 km.

Figure 11 caption: Large-ship routes and the 25 km zone around Guam and the Northern Mariana Islands, 2024–2025. Blue cells are AIS route cells. Purple cells are assumed straight-line links from Apra Harbor to Rota, Tinian, and Saipan. Dark land lies within 25 km of a route cell: 872 of 1,019 km² (86%). The 50 and 100 km zones cover the same land. The 147 km² outside the zone lies on islands north of 16° N, which the map doesn't show.

### 7.3 Limits

- **Reception.** MarineCadastre notes that its AIS data may be incomplete around Guam and the CNMI. The missing Saipan and Tinian lanes may reflect missing reports, not missing ships. The analysis hasn't tested this.
- **Navy ships.** Naval Base Guam shares Apra Harbor with the commercial port, and Navy ships often run with AIS off (Section 1.10), so the AIS routes undercount Navy radar use.
- **Port positions.** The positions of Apra Harbor, Tinian, and Rota come from charts and haven't been checked against the NGA World Port Index.
- **Checks.** The Python cross-check, the land split between Guam and the CNMI, and the held-out-day check aren't done.

The MATLAB code (`init_shipping_zone_guam_rev1.m`, with `cnmi_links=true`) and `python/guam_cnmi_links.py` give the results. The run log is `outputs/rerun_logs_20261121/guam_cnmi_links.log`, and the Guam-only log is `outputs/rerun_logs_20261120_regions/guam.log`.
