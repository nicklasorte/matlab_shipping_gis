# 2.7 GHz Study: Large-Ship Routes and Frequency-Dependent Zones

Nov 10, 2026 · @Nick LaSorte

**DRAFT//PRE-DECISIONAL**

These are draft sections for the 2.7 GHz aggregate zones working paper. Section 1 maps where ships that carry 2900–3100 MHz maritime radionavigation radars operate in the lower 48 states and explains how the routes were built from public data; Sections 4, 5, and 6 extend the routes and zones to Hawaii, Alaska, and Puerto Rico and the U.S. Virgin Islands. Section 2 is reserved for the electromagnetic compatibility (EMC) analysis. Section 3 shows how frequency-dependent zones are drawn from the Section 1 routes, using example distances. The MATLAB code for every figure and number is in the [matlab\_shipping\_gis](https://github.com/nicklasorte/matlab_shipping_gis) repository.

## 1. Large-Ship Routes

Large ships that carry 2900–3100 MHz radars travel the coasts, the Great Lakes, and a few deep-draft rivers. They reach every major port, including Baton Rouge on the Mississippi. Figure 1 shows the routes built from 104 days of 2024 and 2025 vessel tracking data. No zone or buffer is drawn on it.

&#91;image: Large-ship routes in the lower 48 states, 2024-2025: routes follow the coasts, the Great Lakes, and a few deep rivers\]

**Figure 1. Large-ship routes in the lower 48 states, 2024–2025.** Each dark blue mark is a 1 km cell that large ships used on the 104 sampled days, plus NOAA fairways and S-band racons. No buffer is drawn.

### 1.1 Which ships use 2900–3100 MHz

The 2900–3100 MHz band is allocated to maritime radionavigation. Its main users are shipborne navigation radars, Coast Guard and Navy ships, shore-based Vessel Traffic Service radars, and radar beacons (racons).

International rules set which ships carry a radar in this band. SOLAS Chapter V, Regulation 19 requires ships of 300 gross tonnage (GT) and up to carry a 9 GHz radar. Ships of 3,000 GT and up must also carry a 3 GHz radar, or a second 9 GHz radar where the flag state allows it. In practice, large merchant ships carry the 3 GHz (S-band) radar. U.S. navigation safety rules in [33 CFR 164.35](https://www.ecfr.gov/current/title-33/chapter-I/subchapter-P/part-164/section-164.35) also require a marine radar on large U.S. ships, without naming a band.

Vessel tracking data don't report gross tonnage or radar band. This analysis therefore uses ship type, length, and IMO number as a proxy for a ship of 3,000 GT or more (Section 1.4).

### 1.2 Data sources

All data are public.

| Data | Source | Use |
| --- | --- | --- |
| Ship positions (AIS) | [MarineCadastre.gov](https://marinecadastre.gov/ais), Bureau of Ocean Energy Management and NOAA Office for Coastal Management, from Coast Guard terrestrial AIS receivers | Where large ships go |
| Shipping fairways and traffic separation schemes | [NOAA ENC Direct](https://encdirect.noaa.gov) | Charted lanes, added to the routes |
| Racons | NOAA ENC Direct (general, coastal, and approach chart layers) | Fixed S-band sites, added to the routes |
| States | Census Bureau [cartographic boundary file](https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.html), 1:500,000, 2023 | Land and water reference, maps |
| Coastline | Census Bureau [TIGER/Line coastline](https://www2.census.gov/geo/tiger/TIGER2023/COASTLINE/), 2023 | Tug-barge rule; distances inland (Section 3) |
| Ports | U.S. Army Corps of Engineers Principal Ports | Checks that routes reach the ports |
| Gross tonnage | Wikidata ship records (IMO number, gross tonnage, length) | Check of the length proxy |

AIS (Automatic Identification System) reports give each ship's position about once a minute. MarineCadastre publishes one file per day for U.S. waters, including the Great Lakes and inland waterways. A day holds about 10 million reports from about 22,000 ships. This analysis uses six fields from each report: ship identifier (MMSI), latitude, longitude, AIS ship type, length, and IMO number.

### 1.3 Sampling

The analysis uses one day a week for two years: the first 52 Wednesdays of each year, January 3 to December 25, 2024, and January 1 to December 24, 2025. That is 104 days. These are the two most recent full years; 2023 and January to June 2026 are held out to check how stable the routes are (Appendix A.6).

- One day a week covers seasonal traffic, such as the Great Lakes winter closure, at one-seventh of the data volume.
- Two years keep one unusual year from setting the routes. In 2024, the Francis Scott Key Bridge collapse closed Baltimore's main channel from March 26 until it was [fully restored on June 10](https://www.army.mil/article/277129).

### 1.4 Filtering

Each AIS report passes four tests. A report is kept only if it passes all of them.

1. **Ship type.** The AIS ship type is cargo (70–79), tanker (80–89), passenger (60–69), military (35), law enforcement (55), dredging (33), other or unknown (0, 90–99), or towing (31, 32, 52). Fishing, sailing, pleasure, and special craft are left out.
2. **Length.** The reported length is 100 m or more. This is the proxy for 3,000 GT.
3. **IMO number.** The report carries an IMO number, which is issued to seagoing ships. Military and law enforcement ships have no IMO number and are kept without one.
4. **Location.** The position is inside the analysis grid (22–50° N, 66–130° W), which covers the lower 48 states, the Great Lakes, the Florida Straits, and waters up to several hundred kilometers offshore.

Table 1 shows how much each test keeps on one full day from each year. About 1 ship in 12 that reported that day passed all four tests.

**Table 1. AIS reports and ships kept after each filter step**

| Step | Reports, 2024-07-10 | Ships, 2024-07-10 | Reports, 2025-07-09 | Ships, 2025-07-09 |
| --- | --- | --- | --- | --- |
| All reports | 9,626,350 | 22,414 | 9,186,207 | 23,548 |
| Ship type kept | 5,670,287 | 8,295 | 5,022,885 | 8,214 |
| and length 100 m or more | 1,884,907 | 2,754 | 1,580,824 | 2,583 |
| and IMO number (or military or law enforcement) | 1,347,288 | 2,184 | 1,101,052 | 2,017 |
| and inside the analysis grid | 1,237,989 | 1,980 | 1,059,711 | 1,886 |

Most ships drop out at the length step. Many towing ships report the length of the whole tow, so 761 of them reached 100 m on July 10, 2024 (files before 2024 gave the tug's own length). The IMO test removes most river towboats, and the tug-barge rule in Section 1.5 handles the rest.

**Table 2. Ships kept on each day, by AIS ship type**

| Ship type | 2024-07-10 | 2025-07-09 |
| --- | --- | --- |
| Cargo | 946 | 936 |
| Tanker | 635 | 563 |
| Passenger | 90 | 81 |
| Towing | 237 | 235 |
| Military | 15 | 13 |
| Law enforcement | 2 | 5 |
| Dredging | 8 | 6 |
| Other and unknown | 47 | 47 |
| Total | 1,980 | 1,886 |

**How well length stands in for gross tonnage.** Figure 2 tests the length test against registry gross tonnage. Cargo, tanker, and passenger ships with an IMO number, seen on four days in 2024 (January 10, April 10, July 10, and October 9), were matched by IMO number to Wikidata ship records; 4,129 ships matched. Of the 3,873 matched ships of 3,000 GT or more, the 100 m test keeps 3,801 (98.1%). Of the 3,818 ships it keeps, all but 17 are 3,000 GT or more (99.6%). Of the 72 large ships it drops, 45 are cargo ships, 22 are passenger ships, and 5 are tankers. Most are just under 100 m; a few gray dots far to the left are ships whose AIS length is clearly wrong.

&#91;image: Scatter plot of registry gross tonnage against AIS length for 4,129 ships, with the 100 m filter and the 3,000 GT line splitting them into four groups\]

**Figure 2. What the 100 m length test keeps and drops.** Each dot is a ship, placed by its AIS length and its registry gross tonnage. Light blue ships pass the length test; gray ships fail it. The dashed line is 3,000 GT, the SOLAS size for a 3 GHz radar.

### 1.5 From reports to routes

The kept reports become routes on a grid of 0.01° cells, about 1 km on a side, covering 22–50° N and 66–130° W. A cell is a route cell when enough different ships used it.

1. **Ship threshold.** A cell is a route cell when at least four different ships (by MMSI) reported from it in one calendar year. Each year is counted separately, and a cell that meets the threshold in either year counts. Four ships removes one-off visits and scattered reports.
2. **Port approaches.** Within 50 km of a deep-draft port, two ships in one year are enough. Deep-draft ports are the 73 coastal and Great Lakes Principal Ports with at least 1 million tons of foreign trade. Small ports such as Searsport, Maine, and Coos Bay, Oregon, see fewer distinct ships on their approaches.
3. **Tug-barges.** Towing ships 100 m or longer with an IMO number count only within 25 km of the Census coastline, which includes bays and the Great Lakes. This keeps ocean-going tug-barges and drops river towboats. Some river towboats also report IMO numbers. Without this rule, the routes reached 15 inland river ports.
4. **Charted lanes and racons.** Cells crossed by NOAA shipping fairways and traffic separation schemes are added, as are cells holding a charted S-band racon.

**Table 3. Route cells by source**

| Source | Cells |
| --- | --- |
| AIS cells with 4 or more large ships in a year (tug-barges near the coast included) | 658,865 |
| Port approaches (2 or more ships within 50 km of 73 deep-draft ports) | 15,782 |
| NOAA fairways and traffic separation schemes not already AIS cells | 1,099 |
| S-band racons not already route cells | 17 |
| Total route cells | 675,763 |

The routes are written as polygons in a shapefile, a KML file, and a KMZ file (`shipping_zone_2024_2025_routes`). A second set holds the AIS cells only, without fairways and racons.

### 1.6 Checks

Three checks test the filter and the routes against data from outside the analysis.

- **Length as a proxy for 3,000 GT.** Against registry gross tonnage, the 100 m test is right for 99.6% of the ships it keeps and keeps 98.1% of ships of 3,000 GT or more (Section 1.4 and Figure 2; 4,129 of 5,674 ships matched). Reported AIS length and registry length differed by a median of 0.1 m.
- **Two independent implementations.** The daily cell files were built by a Python streaming reader and checked against the MATLAB reader. On 2024-01-03, both produced the same 166,382 cell and ship pairs. On the two full days in Table 1, the MATLAB step counts matched the Python files exactly (1,347,288 reports and 2,184 ships on July 10, 2024; 1,101,052 reports and 2,017 ships on July 9, 2025).
- **Ports reached.** A port counts as reached when a continuous chain of route cells connects it to the open-water route network.
  - All 24 major ports in the check list are reached, including Baltimore, Albany, Stockton, Duluth, and Baton Rouge.
  - 69 of the 73 deep-draft Principal Ports are reached. The four that aren't are Portland, Oregon, and Illinois International Port, where the Corps reference point sits several kilometers from the ship berths, and Panama City, Florida, and Searsport, Maine, where approach traffic is thin.
  - None of the 36 inland river Principal Ports are reached, as expected for barge ports.

### 1.7 New Orleans to Baton Rouge

Large ships use the whole Mississippi River from New Orleans to Baton Rouge, the head of deep-draft navigation on the river. On the 104 sampled days, 263 different large ships reported within 3 km of Baton Rouge: 138 in 2024 and 139 in 2025. Figure 3 shows the route cells along this reach. The route is continuous from the Gulf to Baton Rouge. It continues about 35 km past the city, to 30.77° N, and it reaches none of the 36 inland river ports farther upstream.

&#91;image: Route cells along the Mississippi River from New Orleans to Baton Rouge, 2024-2025\]

**Figure 3. Large-ship route cells on the Mississippi River from New Orleans to Baton Rouge, 2024–2025.** Each square is a 1 km route cell. No buffer is drawn.

### 1.8 Major ports included

The routes reach every major U.S. port that large ships serve. Two lists were checked.

**Busiest ports first.** The analysis gives the most weight to the ports with the most large-ship traffic, because that is where S-band radars operate most often. Table 4 ranks the deep-draft ports by distinct large ships within 10 km over the 104 sampled days. Five port complexes lead: Galveston Bay (Galveston, Houston, and Texas City), the lower Mississippi (New Orleans, Plaquemines, and South Louisiana), Los Angeles–Long Beach, New York–New Jersey, and Sabine Pass–Port Arthur. Fifteen ports see 1,000 or more large ships.

The ranking differs from the Corps tonnage rank, which counts cargo tons, not ships. Galveston ranks first because every ship bound for Houston, Texas City, or Galveston passes its 10 km circle at the Bolivar Roads entrance. Neighboring ports share ships where their circles overlap, so the counts don't add. The mix differs by coast: tankers lead at Galveston, Sabine Pass, and Port Arthur, while cargo and container ships lead at Los Angeles, Long Beach, New York, Baltimore, and Virginia.

**Table 4. The 15 busiest deep-draft ports by distinct large ships within 10 km, 2024–2025**

| Rank | Port | Corps tonnage rank | Large ships | Tankers | Cargo | Passenger | Military and law enforcement |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Galveston, TX | 46 | 2,953 | 1,758 | 1,019 | 11 | 0 |
| 2 | New Orleans, LA | 5 | 2,426 | 705 | 1,556 | 6 | 0 |
| 3 | Plaquemines Port District, LA | 12 | 2,193 | 747 | 1,384 | 2 | 0 |
| 4 | Port of Long Beach, CA | 6 | 1,898 | 520 | 1,318 | 33 | 7 |
| 5 | Port of Los Angeles, CA | 9 | 1,839 | 481 | 1,303 | 34 | 1 |
| 6 | Houston Port Authority, TX | 1 | 1,704 | 796 | 827 | 1 | 0 |
| 7 | New York, NY & NJ | 4 | 1,700 | 530 | 1,058 | 42 | 1 |
| 8 | South Louisiana, LA | 2 | 1,415 | 482 | 932 | 2 | 0 |
| 9 | Sabine Pass Port Authority, TX | 73 | 1,327 | 928 | 262 | 1 | 0 |
| 10 | Port Arthur, TX | 15 | 1,209 | 764 | 303 | 1 | 0 |
| 11 | San Francisco Port, CA | 107 | 1,112 | 378 | 681 | 24 | 4 |
| 12 | Port of Oakland, CA | 36 | 1,068 | 366 | 648 | 24 | 5 |
| 13 | Baltimore, MD | 18 | 1,067 | 48 | 993 | 2 | 3 |
| 14 | Virginia, VA | 10 | 1,063 | 44 | 963 | 3 | 20 |
| 15 | Port of Savannah, GA | 13 | 1,024 | 130 | 876 | 0 | 0 |

Large ships count each ship once over 2024 and 2025. The four type columns use the AIS ship-type code (tanker 80–89, cargo 70–79, passenger 60–69, military 35 and law enforcement 55) with the same 100 m and IMO rules; ships of other types and tug-barges make up the rest of the total. Appendix A.14 maps all 73 ports, and Appendix A.15 maps where each type goes.

**Named major ports (24).** All 24 are on the route network: Baton Rouge, LA; New Orleans, LA; Houston, TX; Corpus Christi, TX; Mobile, AL; Tampa, FL; Miami, FL; Savannah, GA; Charleston, SC; Norfolk, VA; Baltimore, MD; Philadelphia, PA; Newark, NJ (New York/New Jersey); Albany, NY; Boston, MA; Los Angeles/Long Beach, CA; Oakland, CA; Sacramento, CA; Stockton, CA; Portland, OR; Seattle, WA; Tacoma, WA; Duluth, MN; Chicago, IL.

**Deep-draft ports (73).** Table 5 lists every U.S. Army Corps of Engineers Principal Port on the coasts or the Great Lakes with at least 1 million tons of foreign trade, ranked by total tonnage. 69 of the 73 are on the route network, and all 73 are inside the 25 km zone. The four that aren't on the network are Portland, Oregon, and Illinois International Port, where the Corps reference point sits 5 to 12 km from the route cells at the ship berths, and Panama City, Florida, and Searsport, Maine, where the route cells at the port don't connect to the open-water lanes because approach traffic is thin.

**Table 5. Deep-draft ports and the large-ship routes, 2024–2025**

| Rank | Port | Foreign trade (million tons) | Distance to route (km) | On the route network | In 25 km zone |
| --- | --- | --- | --- | --- | --- |
| 1 | Houston Port Authority, TX | 196.8 | 0.3 | Yes | Yes |
| 2 | South Louisiana, LA, Port of | 112.7 | 0.3 | Yes | Yes |
| 3 | Corpus Christi, TX | 125.7 | 0.4 | Yes | Yes |
| 4 | New York, NY & NJ | 83.6 | 0.3 | Yes | Yes |
| 5 | New Orleans, LA | 37.8 | 0.1 | Yes | Yes |
| 6 | Port of Long Beach, CA | 65.7 | 0.7 | Yes | Yes |
| 7 | Port of Greater Baton Rouge, LA | 28.3 | 0.5 | Yes | Yes |
| 8 | Beaumont, TX | 45.8 | 1.0 | Yes | Yes |
| 9 | Port of Los Angeles, CA | 55.0 | 0.3 | Yes | Yes |
| 10 | Virginia, VA, Port of | 53.1 | 0.3 | Yes | Yes |
| 11 | Mobile, AL | 34.4 | 0.4 | Yes | Yes |
| 12 | Plaquemines Port District, LA | 20.9 | 0.6 | Yes | Yes |
| 13 | Port of Savannah, GA | 42.3 | 0.0 | Yes | Yes |
| 14 | Lake Charles Harbor District, LA | 22.7 | 0.2 | Yes | Yes |
| 15 | Port Arthur, TX | 23.9 | 0.6 | Yes | Yes |
| 16 | Port Freeport, TX | 34.6 | 2.3 | Yes | Yes |
| 18 | Baltimore, MD | 31.0 | 0.5 | Yes | Yes |
| 20 | Texas City, TX | 21.2 | 0.4 | Yes | Yes |
| 23 | Philadelphia Regional Port, PA | 16.9 | 3.8 | Yes | Yes |
| 24 | Tampa Port Authority, FL | 12.6 | 0.3 | Yes | Yes |
| 26 | Duluth-Superior, MN and WI | 5.7 | 0.4 | Yes | Yes |
| 27 | Port of Charleston, SC | 23.1 | 0.5 | Yes | Yes |
| 29 | Jackson County Port, MS | 14.8 | 0.7 | Yes | Yes |
| 30 | Seattle, WA | 18.1 | 0.4 | Yes | Yes |
| 31 | Tacoma, WA | 17.4 | 0.6 | Yes | Yes |
| 32 | Richmond, CA | 14.8 | 0.8 | Yes | Yes |
| 33 | Port of Portland, OR | 14.3 | 5.1 | No | Yes |
| 34 | Port Everglades, FL | 9.3 | 0.3 | Yes | Yes |
| 35 | South Jersey Port District, NJ | 11.9 | 0.4 | Yes | Yes |
| 36 | Port of Oakland, CA | 18.1 | 0.5 | Yes | Yes |
| 37 | Port of Kalama, WA | 16.7 | 0.2 | Yes | Yes |
| 38 | Jacksonville, FL | 8.8 | 3.0 | Yes | Yes |
| 43 | Two Harbors, MN | 1.8 | 0.3 | Yes | Yes |
| 44 | Boston, MA | 9.9 | 0.8 | Yes | Yes |
| 46 | Galveston, TX | 6.7 | 0.5 | Yes | Yes |
| 47 | Port of Longview, WA | 9.9 | 4.8 | Yes | Yes |
| 48 | Port of Vancouver USA, WA | 7.6 | 1.2 | Yes | Yes |
| 49 | Cleveland-Cuyahoga Port, OH | 1.8 | 0.5 | Yes | Yes |
| 51 | Illinois International Port, IL | 1.9 | 12.2 | No | Yes |
| 52 | Toledo-Lucas County Port, OH | 4.7 | 0.3 | Yes | Yes |
| 55 | PortMiami, FL | 8.2 | 0.4 | Yes | Yes |
| 57 | Detroit-Wayne County Port, MI | 2.4 | 0.6 | Yes | Yes |
| 58 | New Haven, CT | 3.3 | 0.4 | Yes | Yes |
| 63 | Port of Providence, RI | 4.5 | 0.5 | Yes | Yes |
| 64 | Conneaut, OH | 2.1 | 0.4 | Yes | Yes |
| 65 | Anacortes, WA | 1.3 | 1.5 | Yes | Yes |
| 66 | Brownsville, TX | 4.0 | 0.4 | Yes | Yes |
| 67 | Wilmington, NC | 5.8 | 0.5 | Yes | Yes |
| 71 | Marquette, MI | 1.2 | 0.3 | Yes | Yes |
| 72 | Wilmington, DE | 4.8 | 0.2 | Yes | Yes |
| 73 | Sabine Pass Port Authority, TX | 3.4 | 0.3 | Yes | Yes |
| 77 | Calhoun Port Authority, TX | 2.1 | 2.7 | Yes | Yes |
| 78 | Stockton, CA | 4.6 | 0.3 | Yes | Yes |
| 79 | Albany Port District, NY | 1.1 | 2.0 | Yes | Yes |
| 80 | Canaveral Port District, FL | 3.4 | 0.3 | Yes | Yes |
| 82 | Portland, ME | 3.7 | 0.6 | Yes | Yes |
| 84 | Manatee County Port, FL | 3.2 | 0.2 | Yes | Yes |
| 93 | Grays Harbor Port District, WA | 2.9 | 0.1 | Yes | Yes |
| 98 | Milwaukee, WI | 1.5 | 2.2 | Yes | Yes |
| 99 | Portsmouth, NH | 2.5 | 0.3 | Yes | Yes |
| 101 | Port of Brunswick, GA | 2.4 | 0.3 | Yes | Yes |
| 106 | Port of Palm Beach District, FL | 1.4 | 0.5 | Yes | Yes |
| 107 | San Francisco Port, CA | 1.1 | 0.4 | Yes | Yes |
| 110 | Panama City Port Authority, FL | 1.6 | 0.2 | No | Yes |
| 115 | Redwood City, CA | 1.9 | 0.1 | Yes | Yes |
| 118 | Oxnard Harbor District, CA | 1.8 | 0.5 | Yes | Yes |
| 119 | Coos Bay OR, Port of | 1.8 | 0.4 | Yes | Yes |
| 123 | Morehead City, NC | 1.2 | 1.8 | Yes | Yes |
| 125 | Sandusky, OH | 1.1 | 0.6 | Yes | Yes |
| 128 | Gulfport, MS | 1.6 | 0.6 | Yes | Yes |
| 129 | Searsport, ME | 1.5 | 2.1 | No | Yes |
| 133 | San Diego Unified Port, CA | 1.2 | 0.5 | Yes | Yes |
| 143 | Sacramento-Yolo Port, CA | 1.2 | 0.5 | Yes | Yes |

Distance to route is from the Corps reference point to the nearest large-ship route cell. Inland river ports (36 Principal Ports on the Mississippi, Ohio, and other rivers) are not on the route network; they sit about 50 to 700 km from it.

### 1.9 How far up rivers and ship channels large ships go

Large ships thin out as they pass the ports along a river or ship channel: on 10 of 15 corridors, fewer than half of the large ships seen at the entrance reach the head port. Table 6 extends the New Orleans to Baton Rouge count in Section 1.7 to 14 more corridors, which answers a question any zone drawn along a river raises: how much of the traffic reaches the inland end.

For each corridor, distance runs from the entrance to the head port along the busiest chain of route cells. Each step between neighboring cells costs its length times (1 + 100 / ships), so the path keeps to the main channel instead of a shorter, lightly used lane. Route cells within 2 km of that path belong to the corridor. A ship counts at the entrance or at the head port if it used a corridor cell within 3 km of that point, measured along the path.

**Table 6. Large ships at the entrance and at the head port of 15 rivers and ship channels, 2024–2025**

| Corridor | Head port | Length (km) | Ships at entrance | Ships at head port | Share reaching head | At head, 2024 | At head, 2025 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Mobile Bay | Mobile | 55 | 475 | 495 | 104% | 248 | 301 |
| Savannah River | Garden City | 39 | 785 | 765 | 97% | 444 | 474 |
| Cape Fear River | Wilmington, NC | 43 | 206 | 179 | 87% | 99 | 97 |
| Chesapeake Bay | Baltimore | 291 | 1,461 | 829 | 57% | 423 | 530 |
| Calcasieu Ship Channel | Lake Charles | 58 | 409 | 211 | 52% | 109 | 116 |
| Columbia River | Vancouver, WA | 174 | 580 | 279 | 48% | 158 | 132 |
| St. Johns River | Jacksonville | 31 | 393 | 157 | 40% | 89 | 105 |
| San Joaquin River | Stockton | 145 | 743 | 164 | 22% | 85 | 87 |
| Sabine-Neches Waterway | Beaumont | 76 | 1,032 | 205 | 20% | 94 | 126 |
| Houston Ship Channel | Houston | 92 | 2,693 | 491 | 18% | 260 | 268 |
| Delaware River | Trenton | 214 | 761 | 123 | 16% | 69 | 57 |
| Mississippi River | Baton Rouge | 360 | 2,095 | 262 | 13% | 138 | 138 |
| Sacramento River | West Sacramento | 156 | 743 | 91 | 12% | 53 | 46 |
| Hudson River | Albany | 248 | 1,380 | 69 | 5% | 36 | 35 |
| James River | Hopewell (routes end 22 km below Richmond) | 122 | 975 | 28 | 3% | 17 | 16 |

- **Short channels keep most of their traffic.** Nearly every large ship that enters Mobile Bay or the Savannah River reaches the head port, because the main terminals sit at the head. At Mobile, more ships were counted at the head port than at the entrance: a weekly sample catches some ships at the berth that it never sees crossing the entrance.
- **Long rivers lose it step by step.** Traffic drops at each port it passes: on the Delaware, from about 750 ships below Wilmington to about 60 above Philadelphia; on the Hudson, from 1,380 at the Narrows to about 100 above the George Washington Bridge.
- **Every head port still sees large ships every year.** The smallest yearly count is 16 ships, at the head of the James. Large-ship routes on the James stop at Hopewell, 22 km below the Port of Richmond.
- **Head counts hold steady between years.** Baton Rouge saw 138 large ships in 2024 and 138 in 2025; Houston saw 260 and 268.
- **Entrance counts include ships bound for ports at the entrance.** Hampton Roads traffic to Norfolk, Narrows traffic to Newark, and Golden Gate traffic to Oakland all count at the entrance, so the share is a share of entrance traffic, not of ships bound up the river.

Distances follow route cells, so they run a few kilometers longer than channel miles; the Mississippi corridor puts Baton Rouge 356 km above Head of Passes, against 352 km in Appendix A.4. Appendix A.18 shows every corridor's profile, and Appendix A.19 maps each one.

### 1.10 Limits of the route data

- **Carriage, not use.** The filter models the SOLAS carriage rule. Smaller ships that carry an S-band radar by choice, such as many research ships under 100 m, aren't counted.
- **Ships without AIS.** Navy ships often turn AIS off, so military traffic is undercounted. Navy operating areas aren't modeled.
- **Terrestrial coverage.** The Coast Guard receivers are on shore, so coverage thins far offshore. This doesn't move the routes near land.
- **Sampled days.** A port served less than about once a month may not reach the ship threshold, although the lower threshold near deep-draft ports helps (Section 1.5).
- **Not for navigation.** MarineCadastre data are published for planning, not navigation. Charted fairways and racons fill some gaps.

## 2. EMC Analysis

 

 

 

## 3. Frequency-Dependent Zones

Each part of the 2900–3100 MHz band can have its own zone distance, drawn from the same Section 1 routes. In the example below, the widest zone, 100 km, applies only at 3030–3070 MHz. These distances are examples to show the method. The EMC analysis in Section 2 will set the actual distances.

**Table 7. Example zone distance for each frequency range**

| Frequency range (MHz) | Zone distance (km) | Zone file |
| --- | --- | --- |
| 2900–3000 | 25 | `shipping_zone_2024_2025_band_2900-3000MHz_25km` |
| 3000–3030 | 50 | `shipping_zone_2024_2025_band_3000-3030MHz_50km` |
| 3030–3070 | 100 | `shipping_zone_2024_2025_band_3030-3070MHz_100km` |
| 3070–3100 | 50 | `shipping_zone_2024_2025_band_3070-3100MHz_50km` |

Each zone file comes as a shapefile, a KML file, and a KMZ file, and covers both the ship water and the land.

&#91;image: Four lower-48 maps of example zones: 25 km at 2900-3000 MHz, 50 km at 3000-3030 MHz, 100 km at 3030-3070 MHz, 50 km at 3070-3100 MHz\]

**Figure 4. Example frequency-dependent zones drawn from the Section 1 routes.** Each panel shows the U.S. land within that range's distance of large-ship water (light blue). The distances are examples, not EMC results.

### 3.1 How a zone is drawn

A zone covers the water where large ships operate and the land within the zone distance of that water.

1. **Ship water.** Water within 25 km of a route cell counts as ship water.
2. **Distance inland.** Land distance is measured from the Census coastline where it faces ship water. On rivers that the coastline file doesn't cover, such as the Mississippi above New Orleans, distance is measured from the route cells themselves.
3. **Distance method.** Distances are great-circle distances on the same 1 km grid, using a spherical Earth with the mean radius of 6,371 km.
4. **Boundary.** The zone boundary is traced at the zone distance and simplified to about 0.5 km.

Because the frequency ranges share one set of routes, a narrower zone always sits inside a wider one. The 3000–3030 MHz and 3070–3100 MHz ranges use the same 50 km zone.

## 4. Hawaii

Large-ship routes around Hawaii link Honolulu and Kalaeloa with Kahului and Nawiliwili and circle the Big Island toward Hilo, and a 50 km zone would cover 95% of the state's land. Hawaii uses the same AIS sample, ship filter, and zone method as the lower 48, with one change: the route rule counts ship-days instead of distinct ships per year.

### 4.1 Route rule: ship-days

The lower-48 rule (a cell is a route cell when at least four distinct large ships cross it in one year) breaks Hawaii's inter-island lanes. A few dedicated ships carry neighbor-island cargo, so most lane cells see fewer than four different ships a year, and only Honolulu, Kalaeloa, and Nawiliwili connect.

Hawaii therefore uses a ship-days rule. For each cell, the analysis counts the distinct large ships in it on each sampled day, adds those counts over the 104 days, and keeps cells with at least 6 ship-days. The cutoff of 6 was set on the lower 48: it's the value whose route set best matches the lower-48 network (Jaccard index 0.80 for 2024–2025, the cells in both sets divided by the cells in either; 0.81 for 2023–2024). Table 8 compares the rules that were tested.

**Table 8. Route rules tested for Hawaii**

| Rule | Match to the lower-48 network (Jaccard index) | Hawaii route cells | Ports on one network with Honolulu (of 6, Honolulu included) |
| --- | --- | --- | --- |
| At least 4 distinct ships in one year (lower-48 rule) | 1.00 | 3,965 | 3 |
| At least 2 distinct ships in one year | not calibrated | 19,144 | 4 |
| At least 6 ship-days (Hawaii rule) | 0.80 | 7,310 | 4 |
| At least 3 transits in NOAA AIS Vessel Transit Counts 2024 (all vessels) | 0.38 | 27,144 | 5 |

Ship-days connects the same ports as a two-ship minimum with fewer than half the cells, because it adds the lanes that dedicated ships cross week after week rather than one-off tracks. NOAA's transit counts include ferries, fishing boats, and tour boats, so they match the lower-48 network poorly; the analysis uses them only as a cross-check. The lower-48 port-approach rule is off for Hawaii, because ship-days already keeps thin port approaches, and NOAA charts show no fairways or S-band racons in the Hawaii grid.

### 4.2 Routes and zones

The ship-days rule gives 7,310 route cells (Figure 5). Honolulu, Kalaeloa, Kahului, and Nawiliwili sit on the route network. Ships approach Hilo, but the nearest route cell is 5.0 km from the port, likely because reports thin out in the last few kilometers. Kawaihae is 25 km from the nearest route cell. Every Hawaii port lies inside even the 25 km zone.

&#91;image: Map of the main Hawaiian Islands. Gray dots show every cell a large ship crossed; blue route cells connect Honolulu and Kalaeloa with Kahului and Nawiliwili, circle the Big Island toward Hilo, and run northeast toward the mainland. Kawaihae is off the routes.\]

**Figure 5. Large-ship routes around the main Hawaiian Islands, 2024–2025.** Blue cells meet the ship-days rule; gray cells are every cell a large ship crossed.

The zones use the same shore-mode method and band distances as the lower 48 (Table 7). Because the islands are small, the zones cover most of the land (Figure 6):

- Within 25 km: 12,351 km² (70%)
- Within 50 km: 16,720 km² (95%)
- Within 100 km: 17,573 km² (all of the main islands)

&#91;image: Map of the main Hawaiian Islands with land shaded by zone: the 25 km zone covers 70% of the land, the 50 km zone 95%, and the 100 km zone all of it. The interior and south of the Big Island, northwest Kauai, and Niihau fall outside 25 km.\]

**Figure 6. Hawaii land within 25, 50, and 100 km of large-ship water.** The 25 km zone leaves out the interior and south of the Big Island, northwest Kauai, and Niihau; the 50 km zone leaves out only part of the southern Big Island and Niihau.

The MATLAB code (`init_shipping_zone_hawaii_rev1.m`) and the Python code (`python/ship_route_rules.py`) give the same 7,310 route cells. On the sampled day checked, Hawaii's large-ship reports passed every data-validity check (ship ID format, IMO check digits, impossible speeds, and shared IDs). Because Hawaii and the lower 48 use different route rules, their route-cell counts aren't directly comparable.

## 5. Alaska

Large-ship routes in Alaska run the Inside Passage, Cook Inlet to Anchorage, Prince William Sound to Valdez, and Unimak Pass by Dutch Harbor, and satellite data add the great-circle lanes along and south of the Aleutians. A 25 km zone would cover 12% of Alaska's land east of 180°, a 50 km zone 17%, and a 100 km zone 27%. Alaska uses the same ship filter and zone method as the lower 48, with four differences: older data, the ship-days route rule, satellite lanes added offshore, and a grid that stops at 180°.

### 5.1 Data and route rule

- **Years: 2018 and 2019.** MarineCadastre has filtered Alaska out of its daily files since 2021. The 2018–2020 files still hold Alaska, with IMO numbers and standard ship types, so the lower-48 filter applies unchanged. 2020 is left out because of pandemic schedules. The sample is the first 52 Wednesdays of each year.
- **Route rule: ship-days.** Alaska traffic is sparse: a median of 54 large ships a day, against about 1,800 in the lower 48. Alaska therefore uses the Hawaii rule (at least 6 ship-days over the 104 days). It gives 26,983 route cells from ship tracks; the lower-48 rule would give 19,142.
- **Charted lanes.** NOAA charts add 23,444 cells of fairways and routing measures, mostly the Bering Sea and Bering Strait routes.
- **Satellite lanes.** The Coast Guard receivers are on shore and reach about 40 nautical miles (74 km), so busy lanes farther out are missing. The satellite-based North Pacific and Arctic Marine Vessel Traffic Dataset ([Kapsar and others, 2022](https://doi.org/10.18739/A2XG9FC41), CC BY 4.0) fills them. It counts cargo and tanker operating days in 625 km² hexagons. The cutoff (272 operating days over 2018–2019) is the one whose busy hexagons best match the shore-receiver routes where those routes are complete, within 74 km of shore (Jaccard index 0.57). The 400 hexagons at or above it add 318,134 water cells of ship water, 290 of the hexagons beyond shore-receiver range.
- **Grid: east of 180°.** The grid covers 51–72° N and 180–129° W. Stopping at 180° keeps polygons and KML files from splitting at the date line; the western Aleutians are out of scope.

### 5.2 Routes and zones

The routes reach Anchorage (0.3 km) and Valdez (0.6 km), the two deep-draft ports, and Nikiski and Dutch Harbor (0.3 km each). Kivalina is 12 km from the nearest route cell. All five ports lie inside the 25 km zone (Figure 7).

&#91;image: Map of Alaska east of 180 degrees. Blue route cells follow the Inside Passage, Cook Inlet to Anchorage, Prince William Sound to Valdez, and Unimak Pass near Dutch Harbor; light blue charted lanes run through the Bering Sea and Bering Strait; purple satellite-AIS hexagons add a wide band of lanes along and south of the Aleutians and patches in Cook Inlet and the Bering Sea.\]

**Figure 7. Large-ship routes in Alaska east of 180°, 2018–2019.** Blue cells meet the ship-days rule; light blue cells are NOAA charted lanes; purple cells are the busiest satellite-AIS hexagons; gray cells are every cell a large ship crossed.

The zones cover the coasts where the routes run and leave the interior outside every zone (Figure 8):

- Within 25 km: 179,047 km² (12%)
- Within 50 km: 261,953 km² (17%)
- Within 100 km: 409,521 km² (27%)

&#91;image: Map of Alaska with land near the coast shaded by zone: 12% within 25 km, 17% within 50 km, and 27% within 100 km of large-ship water, concentrated in Southeast Alaska, Southcentral Alaska, the Alaska Peninsula, the Aleutians, and the Bering Sea coast.\]

**Figure 8. Alaska land within 25, 50, and 100 km of large-ship water, east of 180°.** Percentages are of the 1.53 million km² of land cells in the grid.

### 5.3 Limits of the Alaska data

- **Satellite lanes are coarse.** Each satellite hexagon is about 27 km across, so the added ship water is wider than a lane, which makes the zones near those lanes larger, not smaller. Kapsar has no length cut, so its cargo and tanker counts include some ships under 100 m.
- **Older years.** The routes are from 2018–2019, not 2024–2025 like the rest of the paper.
- **One gap day.** The file for February 7, 2018, holds only one large ship in Alaska; ship-days absorbs it.
- **Satellite cutoff.** The cutoff is the weakest choice in the Alaska method, so the zones were also built at half and double it. At half (136 operating days, 633 hexagons), the land in the 25, 50, and 100 km zones grows by 4%, 3%, and 2%. At double (544 operating days, 304 hexagons), it shrinks by 8%, 7%, and 6%. All five ports stay inside the 25 km zone at every cutoff.
- **Western Aleutians.** Islands west of 180° aren't analyzed.

The MATLAB code (`init_shipping_zone_alaska_rev1.m`) and the Python code (`python/ship_alaska_routes.py`) give the same 26,983 ship-track cells; `python/alaska_satellite_lanes.py` selects the satellite hexagons.

## 6. Puerto Rico and the U.S. Virgin Islands

Large-ship routes ring Puerto Rico and run through the Mona Passage to the west and the Anegada Passage to the east, and a 25 km zone would cover 96% of the land of Puerto Rico and the U.S. Virgin Islands. Everything here matches the lower 48: the 2024–2025 sample, the ship filter, the route rule (at least 4 distinct ships in one year, 2 within 50 km of a deep-draft port), the zone method, and the band distances. Traffic is dense enough for the lower-48 rule, at about 60 large ships a day.

### 6.1 Routes and zones

The routes hold 43,845 cells: 41,237 from ship tracks and 2,608 from the port-approach rule around San Juan, Guaynabo, Ponce, and Yabucoa, the four deep-draft Principal Ports. NOAA charts returned no fairways or S-band racons for this grid. Seven of the eight ports checked sit on the route network, within 0.8 km: the four deep-draft ports, plus Charlotte Amalie on St. Thomas and Limetree Bay and Frederiksted on St. Croix. Mayaguez, a small port on the west coast, is 30 km from the nearest route cell (Figure 9).

&#91;image: Map of Puerto Rico and the U.S. Virgin Islands. Blue route cells ring Puerto Rico, cross the Mona Passage to the west and the Anegada Passage to the east, and reach San Juan, Ponce, Guaynabo, Yabucoa, Charlotte Amalie, Limetree Bay, and Frederiksted; Mayaguez is off the routes.\]

**Figure 9. Large-ship routes around Puerto Rico and the U.S. Virgin Islands, 2024–2025.** Blue cells are route cells; gray cells are every cell a large ship crossed.

The islands are small, so the zones cover almost all of the land (Figure 10):

- Within 25 km: 9,583 km² (96%)
- Within 50 km: 9,970 km² (all but a few small cells)
- Within 100 km: 9,970 km²

&#91;image: Map of Puerto Rico and the U.S. Virgin Islands with land shaded by zone: 96% within 25 km and nearly all within 50 km of large-ship water.\]

**Figure 10. Land within 25, 50, and 100 km of large-ship water, Puerto Rico and the U.S. Virgin Islands.** Only the center of Puerto Rico's interior falls outside the 25 km zone.

The MATLAB code (`init_shipping_zone_prusvi_rev1.m`) gives 41,237 ship-track cells and the Python code (`python/ship_route_rules.py`) 41,236, the same one-cell boundary difference seen in the lower 48. The U.S. Virgin Islands harbors aren't Corps Principal Ports, so their positions are approximate.

## Appendix A. Where Large S-Band Ships Operate: Supporting Figures

These figures support Section 1. They show where ships that carry 2900–3100 MHz radars operate, how far from shore they run, which ports and fixed S-band sites they reach, and which ships the filter counts. All use the same 104 sampled AIS days in 2024 and 2025 and the same filter as Section 1. Each was computed twice, in MATLAB and in Python. The two agree to within one grid cell everywhere except two corridors: on the James River and the Calcasieu Ship Channel, the two least-cost paths follow slightly different channels (the path lengths differ by about 1 km), so the entrance and head counts there differ by up to 9%, and the continuation curves differ more near the entrance. The figures and tables report the Python values.

### A.1 Where the traffic concentrates

Large-ship traffic is concentrated in a small set of lanes. The busiest 6% of route cells carry half of all large-ship traffic, counted as distinct ships per cell. Of the 658,867 route cells, 503 saw 1,000 or more different large ships, and 344,850 saw fewer than 10. The darkest lanes are the port approaches and inland channels: Puget Sound, San Francisco Bay, Los Angeles and Long Beach, the Houston Ship Channel, the lower Mississippi, and the Chesapeake and Delaware approaches.

&#91;image: Map of the lower 48 states with each large-ship route cell colored by how many distinct ships used it; the darkest cells are the main coastal lanes and port approaches.\]

**Figure A-1. Distinct large ships per route cell, 2024–2025.**

### A.2 How far offshore the routes run

Most large-ship routes run close to shore. Half of all route cells are within 132 km of the coastline on the Pacific coast, 138 km on the Gulf, within 82 km on the Atlantic, and within 20 km on the Great Lakes. Ninety percent of Great Lakes route cells are within 49 km of shore. The Pacific curve has the longest tail because coastwise and transpacific lanes run far offshore, out to the edge of the analysis grid at 130° W.

&#91;image: Cumulative distribution of route-cell distance to the coastline for four coasts; the Great Lakes curve rises fastest, the Atlantic next, and the Pacific and Gulf curves extend hundreds of kilometers.\]

**Figure A-2. Share of route cells within a given distance of the Census coastline, by coast.**

### A.3 Ports and fixed S-band sites near the routes

The routes reach the places where S-band radars are used ashore and at the berth. All 24 named major ports are within 1.7 km of a route cell, and 71 of the 73 deep-draft ports (97%) are within 5 km. Racons (75 charted, 24 of them as S-band) sit a median of 0.6 km from a route, and 9 of the 10 Vessel Traffic Service areas are within 1 km; the tenth, Louisville on the Ohio River, serves towboats and is 393 km away. Inland river ports sit 48 to 700 km from the nearest route, which confirms that the filter keeps river barge traffic out.

&#91;image: Strip plot of distance to the nearest large-ship route for six kinds of site; ports, racons, and VTS areas cluster under 5 km, while inland river ports sit hundreds of kilometers away.\]

**Figure A-3. Distance from each site to the nearest large-ship route cell (log scale).**

### A.4 How far inland large ships go on the Mississippi

The Mississippi River is the one place where large S-band ships go far inland. About 2,100 different large ships used each 5 km reach of the river below New Orleans. Traffic thins above New Orleans (156 river km above Head of Passes), but 160 to 260 different large ships still used each reach near Baton Rouge, 352 river km upstream. The route ends about 5 km above Baton Rouge. River distance here is measured through the route cells; the New Orleans value agrees with the published river mile there (about mile 95).

&#91;image: Line chart of distinct large ships along the Mississippi from Head of Passes to Baton Rouge; traffic is highest below New Orleans, stays in the hundreds up to Baton Rouge, and ends just above it.\]

**Figure A-4. Distinct large ships by river distance above Head of Passes.**

Figures A-4b and A-4c put the Mississippi beside the 14 other rivers and ship channels from Section 1.9. Each line counts the distinct large ships seen at or beyond each point on any sampled day, starting 3 km in from the entrance so ships passing the entrance drop out. That count can only fall going upstream, so anchorage spikes and lane splits disappear and each drop marks ships stopping at a port. Distance is scaled so 1 is the head port. Savannah, Houston, the Mississippi, and the Hudson are highlighted; the other 11 are gray.

Figure A-4b divides each count by the ships that entered: 74% of the large ships that enter the Savannah reach Garden City, against 13% for Houston, 7% for the Mississippi, and 5% for the Hudson. These shares run lower than Table 6, whose denominator counts only ships seen at the entrance itself. A single-day sample often catches a ship at a berth or anchorage rather than crossing the entrance, so the entrance count misses many ships that the continuation count includes.

&#91;image: Fifteen falling step lines, one per river or ship channel, of the share of entering large ships seen at or beyond each point against distance scaled to the head port; four are highlighted: Savannah ends near 0.7, Houston near 0.13, the Mississippi near 0.07, and the Hudson near 0.05.\]

**Figure A-4b. Share of entering large ships still on each corridor, by scaled distance to the head port.**

Figure A-4c shows the same curves as ship counts. About 4,600 large ships enter the Mississippi and 3,900 the Houston Ship Channel, more than any other corridor, but only about 300 reach Baton Rouge and 490 reach Houston. The Baton Rouge count here (300) is higher than Table 6 (262) because it includes ships seen above Baton Rouge but not within 3 km of it.

&#91;image: Fifteen falling step lines, one per river or ship channel, of distinct large ships seen at or beyond each point against distance scaled to the head port; the Mississippi starts near 4,600 and the Houston Ship Channel near 3,900, and both end in the hundreds.\]

**Figure A-4c. Distinct large ships still on each corridor, by scaled distance to the head port.**

### A.5 Where tug-barges add to the routes

Ocean-going tug-barges add little beyond the large-ship lanes. Counting them adds 9,130 route cells, about 1% more than the 649,737 cells from the other large ships. The added cells are coastal: 4,121 on the Atlantic, 2,285 on the Gulf, 2,019 on the Great Lakes, and 705 on the Pacific. Most lie along the Gulf and Northeast shorelines and the Great Lakes shores, all within 25 km of the coastline by design (Section 1.5).

&#91;image: Map of large-ship routes in gray with the few cells that only tug-barges add shown in blue, mostly along the Northeast, Gulf, and Great Lakes coasts.\]

**Figure A-5. Route cells that only tug-barges put over the ship threshold.**

### A.6 Which route cells are the same in both years

The main lanes are the same in both years. 336,369 route cells pass the ship threshold in both 2024 and 2025, and they carry 85% of all large-ship traffic. The other 322,498 cells pass in only one year; they are the edges of the lanes and scattered offshore cells where a few ships pass. Using both years keeps those edge cells, so the routes cover any place large ships went in either year. Years held out of the sample agree: 81% of the cells that pass the threshold in 2023 alone, and 94% of those that pass in January to June 2026, are in the 2024–2025 network.

&#91;image: Map of route cells: cells that pass the ship threshold in both years form the main lanes in blue; cells that pass in only one year are scattered gray cells around them.\]

**Figure A-6. Route cells with 4 or more ships in both years or in only one year.**

### A.7 Which ships the filter keeps

The filter keeps the ships that SOLAS requires to carry a 3 GHz radar and drops the rest. On July 10, 2024, 22,414 ships reported on AIS in U.S. waters. The ship-type test kept 8,295, the 100 m length test kept 2,754, the IMO-number test kept 2,184, and 1,980 of those were inside the analysis grid: about 1 ship in 11 (Table 1 gives both days).

&#91;image: Horizontal bar chart of ships left after each filter step on July 10, 2024\]

**Figure A-7. Distinct ships left after each filter step, July 10, 2024.**

### A.8 Why 100 m

A 100 m length cutoff is the best single stand-in for 3,000 GT. At 100 m, 99.6% of the ships the test keeps are 3,000 GT or more, and the test keeps 98.1% of all ships of 3,000 GT or more. A shorter cutoff keeps more small ships that don't need an S-band radar; a longer one drops large ships that do, and above about 145 m it misses more than 1 in 10 of them. Figure 2 in Section 1.4 shows the same check ship by ship.

&#91;image: Line chart of the two accuracy measures against the length cutoff from 50 to 200 m, with 100 m marked\]

**Figure A-8. Length cutoff tested against registry gross tonnage, 4,129 cargo, tanker, and passenger ships.**

### A.9 Hexagon grid

At a 25 km scale, large-ship traffic forms a ring around the lower 48 states that is thickest at a few port complexes. The map groups the route cells into 7,678 equal-area hexagons and counts the different large ships in each. The busiest 5% of hexagons carry 42% of the traffic, and 140 hexagons saw 1,000 or more different large ships.

&#91;image: Hexagon map of the lower 48 states; hexagons along the coasts, Great Lakes, and lower Mississippi are shaded by the number of distinct large ships, darkest at the major port complexes.\]

**Figure A-9. Distinct large ships per 25 km hexagon, 2024–2025.**

### A.10 Spike map

The same hexagons drawn as spikes show where traffic peaks. The tallest spikes stand at Galveston Bay (the entrance shared by Houston, Texas City, and Galveston), the lower Mississippi, Los Angeles and Long Beach, and New York. The tallest single hexagon saw 3,206 different large ships. Hexagons with fewer than 10 ships are left off so the peaks read clearly.

&#91;image: Spike map of the lower 48 states with a vertical spike on each hexagon, sized by distinct large ships; the tallest spikes stand at Galveston Bay, the lower Mississippi, Los Angeles-Long Beach, and New York.\]

**Figure A-10. Spike map of large-ship traffic per 25 km hexagon.**

### A.11 Port close-ups

Inside the busiest port areas, large ships keep to a few narrow dredged channels. The six areas shown (New York and New Jersey, the Chesapeake and Delaware Bays, Houston and Galveston, the lower Mississippi, Los Angeles and Long Beach, and Puget Sound) hold 25% of the busiest route cells, those used by 200 or more different large ships.

&#91;image: Six close-up maps of port areas showing large-ship route cells shaded by ship count; traffic runs in narrow dredged channels in each.\]

**Figure A-11. Large-ship route cells in six port areas, 1 km cells.**

### A.12 Distance from shore, mapped

The nearest-shore routes are the port approaches, inland channels, and the Great Lakes. 11% of route cells are within 25 km of the coastline, 24% within 50 km, and 51% within 100 km. Figure A-2 gives the same distances as curves by coast.

&#91;image: Map of large-ship route cells colored by distance from shore: darkest within 25 km at ports and on the Great Lakes, lighter farther offshore.\]

**Figure A-12. Large-ship route cells by distance from the Census coastline.**

### A.13 Traffic along the coast

Near-shore traffic peaks at the major port complexes. Counting the different large ships within 50 km of shore in each half degree along the coast, the peaks are Houston and Galveston on the Gulf (4,031 ships), the Mississippi delta close behind (3,705), New York on the Atlantic (2,199), and Los Angeles and Long Beach on the Pacific (2,126). Long stretches between the ports, such as the Big Bend of Florida and the Oregon coast, see far fewer ships.

&#91;image: Three bar charts of near-shore large-ship traffic along the Pacific, Gulf, and Atlantic coasts; each has one or two clear peaks at the major port complexes.\]

**Figure A-13. Distinct large ships within 50 km of shore per half degree along each coast.**

### A.14 Ports by traffic

Fifteen deep-draft ports each saw 1,000 or more different large ships within 10 km. The busiest are Galveston (2,953), New Orleans (2,426), Plaquemines (2,193), Long Beach (1,898), Los Angeles (1,839), Houston (1,704), and New York and New Jersey (1,700). Ports that share an approach, such as those around Galveston Bay, share many of the same ships.

&#91;image: Bubble map of 73 deep-draft ports sized by the number of large ships nearby; the largest circles are on the Texas and Louisiana coast, at Los Angeles-Long Beach, and at New York.\]

**Figure A-14. Distinct large ships within 10 km of each deep-draft port.**

### A.15 Where each ship type goes

Tankers concentrate in the Gulf: 87% of the 4,438 large tankers sailed in Gulf waters, against 50% of the 10,485 large cargo ships. The 283 large passenger ships cluster at the cruise ports of south Florida, and the 88 military and law-enforcement ships cluster around San Diego, Hampton Roads, and Jacksonville. Types come from the AIS ship-type code with the same 100 m and IMO rules as the main filter; Table 4 gives the type counts at the busiest ports.

&#91;image: Four hexagon maps of where tankers, cargo ships, passenger ships, and military and law enforcement ships go; tankers concentrate on the Gulf coast, cargo ships on all three coasts.\]

**Figure A-15. Distinct ships of each type per 25 km hexagon, 2024 and 2025 together.**

### A.16 How far inland the routes reach

Away from the coasts, only the Great Lakes and a few deep rivers bring large-ship routes inland: the lower Mississippi to Baton Rouge, the Hudson to Albany, the Columbia to Portland and Vancouver, and the Sacramento and San Joaquin to Sacramento and Stockton. The map shades each point of land by its distance to the nearest route cell. It shows where the ships are, not the zones; Section 3 draws the zones.

&#91;image: Map of the lower 48 states shaded by distance to the nearest large-ship route: dark bands along the coasts, the Great Lakes, the Hudson, Columbia, Sacramento, and lower Mississippi rivers; light in the interior.\]

**Figure A-16. Distance from U.S. land to the nearest large-ship route cell.**

### A.17 Fixed S-band sites on the lanes

Fixed S-band sites sit on the large-ship lanes. Of the 24 racons charted as S-band, 18 are within 5 km of a route; many of them are offshore in the Gulf of Mexico, along the fairways. Nine of the 10 Vessel Traffic Service areas are within 1 km of a route; the tenth, Louisville, serves river towboats.

&#91;image: Map of large-ship hexagons in light blue with racons and VTS areas marked; the S-band racons and VTS areas sit on the busiest lanes, except VTS Louisville on the Ohio River.\]

**Figure A-17. Racons and Vessel Traffic Service areas over the large-ship hexagon grid.**

### A.18 Rivers and ship channels: reach and profiles

These two figures carry Section 1.9. Figure A-18 compares the large ships at each corridor's entrance with those at its head port. Figure A-19 shows how traffic steps down along each corridor as it passes its ports; each panel has its own scale.

&#91;image: Dot chart with one row per river or ship channel, showing distinct large ships at the entrance (gray) and at the head port (blue); the gap is largest on the James, Hudson, Sacramento, Mississippi, Delaware, and Houston corridors.\]

**Figure A-18. Distinct large ships within 3 km of the entrance and of the head port, by corridor.**

&#91;image: Fifteen small step charts, one per river or ship channel, each showing distinct large ships against distance from the entrance; every profile steps down past the ports along the way.\]

**Figure A-19. Distinct large ships in each reach of each corridor.**

### A.19 Corridor maps and profiles

Each figure pairs a map of the corridor's route cells, shaded by distinct large ships, with the profile of ships against distance from the entrance. Dashed lines mark the ports along the way. Gray cells on the maps are other large-ship routes outside the corridor.

&#91;image: Map of the Mobile Bay route cells shaded by distinct large ships, and a step chart of ships against distance from the entrance; 475 ships at the entrance and 495 at Mobile.\]

**Figure A-20. Mobile Bay.**

&#91;image: Map of the Savannah River route cells shaded by distinct large ships, and a step chart of ships against distance from the entrance; 785 ships at the entrance and 765 at Garden City.\]

**Figure A-21. Savannah River.**

&#91;image: Map of the Cape Fear River route cells shaded by distinct large ships, and a step chart of ships against distance from the entrance; 206 ships at the entrance and 179 at Wilmington NC.\]

**Figure A-22. Cape Fear River.**

&#91;image: Map of the Chesapeake Bay to Baltimore route cells shaded by distinct large ships, and a step chart of ships against distance from the entrance; 1,461 ships at the entrance and 829 at Baltimore.\]

**Figure A-23. Chesapeake Bay to Baltimore.**

&#91;image: Map of the Calcasieu Ship Channel route cells shaded by distinct large ships, and a step chart of ships against distance from the entrance; 409 ships at the entrance and 211 at Lake Charles.\]

**Figure A-24. Calcasieu Ship Channel.**

&#91;image: Map of the Columbia River route cells shaded by distinct large ships, and a step chart of ships against distance from the entrance; 580 ships at the entrance and 279 at Vancouver.\]

**Figure A-25. Columbia River.**

&#91;image: Map of the St. Johns River route cells shaded by distinct large ships, and a step chart of ships against distance from the entrance; 393 ships at the entrance and 157 at Jacksonville.\]

**Figure A-26. St. Johns River.**

&#91;image: Map of the San Joaquin River route cells shaded by distinct large ships, and a step chart of ships against distance from the entrance; 743 ships at the entrance and 164 at Stockton.\]

**Figure A-27. San Joaquin River to Stockton.**

&#91;image: Map of the Sabine-Neches Waterway route cells shaded by distinct large ships, and a step chart of ships against distance from the entrance; 1,032 ships at the entrance and 205 at Beaumont.\]

**Figure A-28. Sabine-Neches Waterway.**

&#91;image: Map of the Houston Ship Channel route cells shaded by distinct large ships, and a step chart of ships against distance from the entrance; 2,693 ships at the entrance and 491 at Houston.\]

**Figure A-29. Houston Ship Channel.**

&#91;image: Map of the Delaware River route cells shaded by distinct large ships, and a step chart of ships against distance from the entrance; 761 ships at the entrance and 123 at Trenton.\]

**Figure A-30. Delaware River.**

&#91;image: Map of the Mississippi River route cells shaded by distinct large ships, and a step chart of ships against distance from the entrance; 2,095 ships at the entrance and 262 at Baton Rouge.\]

**Figure A-31. Mississippi River to Baton Rouge.**

&#91;image: Map of the Sacramento River route cells shaded by distinct large ships, and a step chart of ships against distance from the entrance; 743 ships at the entrance and 91 at West Sacramento.\]

**Figure A-32. Sacramento River.**

&#91;image: Map of the Hudson River route cells shaded by distinct large ships, and a step chart of ships against distance from the entrance; 1,380 ships at the entrance and 69 at Albany.\]

**Figure A-33. Hudson River.**

&#91;image: Map of the James River route cells shaded by distinct large ships, and a step chart of ships against distance from the entrance; 975 ships at the entrance and 28 at Hopewell, where the large-ship routes end 22 km below Richmond.\]

**Figure A-34. James River.**

### A.20 How large-ship port visits split among the ports

Thirteen of the 73 deep-draft ports take half of all large-ship port visits, and Gulf ports take 48%. These ten figures show the same split in different forms. A port visit is one distinct large ship seen within 10 km of a deep-draft port over the 104 sampled days. Unlike Table 4, each 1 km cell counts toward its nearest port only, so neighbors such as Los Angeles and Long Beach split the water they share and the visits add to a total (39,688). A ship that calls at two ports counts once at each. Ports on a coastwise lane, such as Galveston at the Bolivar Roads entrance and Oxnard (Port Hueneme), also count ships passing within 10 km.

**Treemap.** Each rectangle is one port, sized by its share of visits and grouped by coast. Galveston (7.4%), New Orleans (6.1%), and Plaquemines (5.5%) are the largest.

&#91;image: Treemap of the 73 deep-draft ports grouped into Gulf, Atlantic, Pacific, and Great Lakes blocks, each rectangle sized by its share of large-ship port visits; the Gulf block covers about half the area, led by Galveston, New Orleans, and Plaquemines.\]

**Figure A-35. Share of large-ship port visits by port and coast (treemap).**

**Circle packing.** The same shares as circles, which makes the long tail of small ports easy to see: the 10 busiest take 43% of visits.

&#91;image: Packed circles, one per deep-draft port, sized by large-ship port visits and colored by coast; Galveston, New Orleans, and Plaquemines are the largest circles, and dozens of small circles ring them.\]

**Figure A-36. Large-ship port visits, one circle per port.**

**Ranked bars.** The 25 busiest ports with a running total; the total passes half at Savannah, the 13th port.

&#91;image: Horizontal bar chart of the 25 busiest deep-draft ports by share of large-ship port visits, colored by coast, with the running total beside each bar; the running total passes 50% at the 13th port.\]

**Figure A-37. The 25 busiest ports by share of visits, with the running total.**

**Concentration curve.** The cumulative share against the number of ports: 13 ports take half and 30 take four-fifths, far above an even split.

&#91;image: Concentration curve rising steeply from zero: the cumulative share of large-ship port visits passes 50% at the 13th port and 80% at the 30th, against a dashed line for an even split across 73 ports.\]

**Figure A-38. Cumulative share of large-ship port visits, busiest ports first.**

**Waffle.** One hundred squares grouped by port complex: eight complexes take 63%, led by the lower Mississippi (16%) and Houston-Galveston (13%).

&#91;image: Waffle chart of 100 squares, each 1% of large-ship port visits, colored by port complex; the lower Mississippi and Houston-Galveston fill 29 squares, and all other ports fill about a third.\]

**Figure A-39. Share of visits by port complex, each square 1%.**

**Marimekko.** Column width is a complex's share of visits and column height its ship-type mix. Tankers make up 71% of visits at Sabine-Neches and 57% at Houston-Galveston; cargo and container ships lead at every other complex.

&#91;image: Marimekko chart of the 12 busiest port complexes with column width set by share of port visits and column height split by ship type; tanker share is highest in the Gulf complexes and cargo share highest in the Atlantic and Pacific complexes.\]

**Figure A-40. Ship-type mix of the 12 busiest port complexes.**

**Sunburst.** Rings for coast, port complex, and port. A third of the Gulf's visits are on the lower Mississippi.

&#91;image: Sunburst chart with coasts in the inner ring, port complexes in the middle ring, and ports in the outer ring, each sized by share of large-ship port visits; the Gulf takes about half the circle.\]

**Figure A-41. Share of visits by coast, complex, and port.**

**Dorling map.** One circle per port at its location, nudged apart so none overlap. The Texas and Louisiana ports form the largest cluster.

&#91;image: Map of the lower 48 states with one non-overlapping circle per deep-draft port, sized by large-ship port visits and colored by coast; the largest circles crowd the Texas and Louisiana coast.\]

**Figure A-42. Large-ship port visits on a map.**

**Shares within each coast.** No port takes more than a sixth of any ocean coast's visits; New York-New Jersey leads the Atlantic with 16.5%.

&#91;image: Four 100% stacked horizontal bars, one per coast, each split into its five busiest ports and the rest; no port takes more than a sixth of any ocean coast's port visits.\]

**Figure A-43. How each coast's visits split among its ports.**

**2024 against 2025.** Shares barely moved. The largest shift among the top 15 is Baltimore, up 0.5 points in 2025, after the Key Bridge collapse closed the Fort McHenry channel to deep-draft ships for about 11 weeks in 2024.

&#91;image: Dumbbell chart of the 15 busiest deep-draft ports, each row joining its share of large-ship port visits in 2024 to its share in 2025; most pairs nearly touch, and Baltimore rises the most.\]

**Figure A-44. Share of visits in 2024 and 2025, the 15 busiest ports.**

### A.21 Data sources

- Ship positions: Bureau of Ocean Energy Management and NOAA Office for Coastal Management, [MarineCadastre.gov AIS data](https://marinecadastre.gov/ais), daily files for 2024 ([csv2024](https://noaaocm.blob.core.windows.net/ais/csv2/csv2024/)) and 2025 ([csv2025](https://noaaocm.blob.core.windows.net/ais/csv2/csv2025/)); 2023 and 2026 for the stability check.
- Shipping fairways and traffic separation schemes: NOAA Office of Coast Survey, [ENC Direct, Marine Transportation layer](https://encdirect.noaa.gov/arcgis/rest/services/NavigationChartData/MarineTransportation/FeatureServer/0).
- Racons: NOAA Office of Coast Survey, [ENC Direct](https://encdirect.noaa.gov/arcgis/rest/services/encdirect) general, coastal, and approach chart layers.
- States: U.S. Census Bureau, [cartographic boundary file, states, 1:500,000, 2023](https://www2.census.gov/geo/tiger/GENZ2023/shp/cb_2023_us_state_500k.zip).
- Coastline: U.S. Census Bureau, [TIGER/Line coastline, 2023](https://www2.census.gov/geo/tiger/TIGER2023/COASTLINE/tl_2023_us_coastline.zip).
- Ports: U.S. Army Corps of Engineers Principal Ports, as published in the [DOE NETL Energy Transition Atlas](https://arcgis.netl.doe.gov/server/rest/services/Hosted/Energy_Transition_Atlas_493d6/FeatureServer/16).
- Gross tonnage: [Wikidata](https://query.wikidata.org/) ship records (IMO number, gross tonnage, length).
- Key Bridge channel closure dates: U.S. Army Corps of Engineers, [Fort McHenry Federal Channel restored](https://www.army.mil/article/277129).
- Radar carriage: [33 CFR 164.35](https://www.ecfr.gov/current/title-33/chapter-I/subchapter-P/part-164/section-164.35); SOLAS Chapter V, Regulation 19.
- Code and figures: [matlab\_shipping\_gis](https://github.com/nicklasorte/matlab_shipping_gis) (MATLAB R2025b and Python).
