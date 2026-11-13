# Review: port ship counts compared with public port-call statistics (agent "totals")

## Summary

Table 4 (Section 1.8) ranks deep-draft ports by distinct large ships within 10 km of each Corps port reference point. Its numbers match the code output exactly. They don't match public port-call ranks. I compared the 15 ports with U.S. Army Corps of Engineers (USACE) Waterborne Commerce trip data for calendar 2023 and 2024. The comparison metric is inbound trips by self-propelled dry-cargo vessels and tankers with a draft of 18 ft or more, a proxy for ships of 100 m and longer. I checked it against a second public series, Bureau of Transportation Statistics (BTS) 2023 vessel calls, which also come from USACE data. The two public series agree with each other (Spearman rho = 0.97 across 39 ports). Within the paper's top 15, the Spearman rank correlation between paper ship counts and public calls is -0.09 (USACE trips) and -0.32 (BTS calls, 12 ports listed). The range is -0.22 to +0.06 across draft cutoffs of 12 to 25 ft and single years. Across all 73 deep-draft ports, the correlation is 0.66. So the method picks out busy port areas in broad terms, but its top-15 order isn't a port-traffic order. Fourteen of the 15 ports move more than three places. Three causes explain the moves. (1) Gateway ports count every ship that passes their 10 km circle on the way to another port: Galveston, Sabine Pass, San Francisco, and Plaquemines. The paper explains this only for Galveston. (2) Neighboring circles overlap and count the same ships twice: Los Angeles and Long Beach, San Francisco and Oakland, Sabine Pass and Port Arthur. (3) A single point misses the main terminals of large ports: Houston's container terminals and Corpus Christi's Ingleside and Harbor Island terminals are 19 to 32 km from the reference points. Container ports with frequent repeat calls (Houston, New York, Virginia, Savannah) rank higher by calls than by distinct ships, which is expected. MARAD's port-level "Vessel Calls" file is no longer current. The latest edition on the MARAD Data and Statistics page covers 2015, and the server refused automated download (HTTP 403). I didn't use it. None of these issues changes a route or a zone: the zones come from route cells, not from Table 4.

### Comparison table

Public metric A: USACE Waterborne Commerce Statistics Center, "Five Year Trips Report" for each port, calendar 2024 edition. The value is the mean of 2023 and 2024 inbound ("receipts") trips by self-propelled dry-cargo vessels and tankers with a draft of 18 ft or more, from <https://ndc.ops.usace.army.mil/wcsc/webpub/data/year/2024/region/{region}/location/{id}/report/fiveYearTripsReport.json> (portal: <https://ndc.ops.usace.army.mil/wcsc/webpub/>). Rank A is the rank among the paper's 73 deep-draft ports. For New York, the port-level trips report returns HTTP 404, so I used the waterway "New York Harbor, NY Lower Entrance Channels" (location 397), which every deep-draft ship entering the port uses.

Public metric B: BTS Port Performance "Port Data", 2023 vessel calls by container, dry bulk, and other freight vessels (barges excluded), <https://data.bts.gov/resource/5rpz-kgm9.csv?cargo_type=VESSEL%20CALLS>. Rank B is the rank among the 39 of the paper's 73 ports that BTS lists. BTS doesn't list Galveston, Sabine Pass, or San Francisco.

| Paper rank | Port | Paper ships (104 days) | A: USACE inbound deep-draft trips per year | Rank A (of 73) | Move | B: BTS 2023 calls (rank of 39) | Corps tonnage rank |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Galveston, TX | 2,953 | 842 | 23 | +22 | not listed | 46 |
| 2 | New Orleans, LA | 2,426 | 2,025 | 8 | +6 | 1,466 (14) | 5 |
| 3 | Plaquemines Port District, LA | 2,193 | 729 | 27 | +24 | 558 (29) | 12 |
| 4 | Port of Long Beach, CA | 1,898 | 1,952 | 9 | +5 | 1,772 (9) | 6 |
| 5 | Port of Los Angeles, CA | 1,839 | 1,586 | 14 | +9 | 1,496 (13) | 9 |
| 6 | Houston Port Authority, TX | 1,704 | 6,048 | 1 | -5 | 6,272 (1) | 1 |
| 7 | New York, NY & NJ | 1,700 | 3,988 | 2 | -5 | 3,684 (2) | 4 |
| 8 | South Louisiana, LA, Port of | 1,415 | 1,744 | 12 | +4 | 2,304 (5) | 2 |
| 9 | Sabine Pass Port Authority, TX | 1,327 | 12 | 73 | +64 | not listed | 73 |
| 10 | Port Arthur, TX | 1,209 | 822 | 24 | +14 | 887 (22) | 15 |
| 11 | San Francisco Port, CA | 1,112 | 244 | 48 | +37 | not listed | 107 |
| 12 | Port of Oakland, CA | 1,068 | 974 | 21 | +9 | 980 (21) | 36 |
| 13 | Baltimore, MD | 1,067 | 1,823 | 10 | -3 | 1,978 (8) | 18 |
| 14 | Virginia, VA, Port of | 1,063 | 2,386 | 4 | -10 | 2,450 (4) | 10 |
| 15 | Port of Savannah, GA | 1,024 | 2,266 | 5 | -10 | 2,290 (7) | 13 |

Spearman rank correlation with paper ship counts:

| Comparison | Top 15 | All ports |
| --- | --- | --- |
| A: USACE trips, 18 ft or more, mean of 2023 and 2024 | -0.09 | 0.66 (n = 73) |
| A at cutoffs of 12, 15, 20, 22, and 25 ft (2023 and 2024) | -0.14 to -0.09 | 0.64 to 0.69 |
| A, 2024 only / 2023 only (18 ft) | +0.06 / -0.22 | 0.66 / 0.66 |
| A, all drafts (includes ferries and small craft) | +0.20 | 0.51 |
| B: BTS 2023 calls | -0.32 (n = 12) | 0.50 (n = 39) |
| Corps tonnage rank (paper's own column) | +0.32 | 0.66 |
| Top 15 without Galveston, Sabine Pass, San Francisco, and Plaquemines | +0.04 (n = 11) | n/a |
| Paper's nearest-port counts (port_share.csv), its own top 15, against A | +0.13 | n/a |

Ports in the public top 15 (metric A) that aren't in the paper's top 15: Port Everglades (public rank 3, paper rank 29), Corpus Christi (6, 17), PortMiami (7, 42), Charleston (11, 23), Philadelphia (13, 24), and Beaumont (15, 34).

Why each port moves more than three places:

- **Galveston (1 to 23).** The Bolivar Roads entrance is about 6 km from the Galveston reference point. Every ship bound for Houston, Texas City, or Galveston passes inside the circle. The Port of Galveston itself has 842 deep-draft inbound trips a year. The paper explains this one.
- **New Orleans (2 to 8).** Every ship bound for South Louisiana, Baton Rouge, and the midstream anchorages passes the New Orleans circle on the river.
- **Plaquemines (3 to 27).** The Plaquemines Port District covers the river below New Orleans to the Gulf. Every ship on the lower Mississippi passes it, and the river anchorages lie inside it. Its own traffic is 729 inbound trips a year: 0.66 two-year trips per distinct sampled ship, against 1.7 at New Orleans and 2.5 at South Louisiana.
- **Long Beach (4 to 9) and Los Angeles (5 to 14).** The two reference points are 5.6 km apart, so each circle counts most of the other port's ships. The paper's own nearest-port counts (port_share.csv) are 1,475 for Long Beach and 969 for Los Angeles, against 1,898 and 1,839 in Table 4. Los Angeles drops more because it takes more of its count from Long Beach.
- **Houston (6 to 1).** Houston has 7.1 two-year inbound trips per distinct sampled ship, the highest in the table: tanker shuttles and weekly container services call again and again. The circle also misses Barbours Cut and Bayport, Port Houston's container terminals, about 30 km from the reference point (see totals-3).
- **New York (7 to 2), Virginia (14 to 4), and Savannah (15 to 5).** Liner container ports. Each has about 4.4 to 4.7 two-year inbound trips per distinct sampled ship, so calls rank them higher than distinct ships do.
- **South Louisiana (8 to 12).** A small move. The port runs about 87 km along the river, so one 10 km circle covers only part of it. Ships bound upriver to Baton Rouge pass the circle anyway.
- **Sabine Pass (9 to 73).** The Sabine Pass Port Authority has 12 deep-draft inbound trips a year, the fewest of the 73 ports. Its circle covers the Sabine Pass entrance channel and the Sabine Pass LNG terminal, about 6 km away on the Louisiana side, which USACE doesn't count in this port. Every ship bound for Port Arthur, Beaumont, or Orange also passes.
- **Port Arthur (10 to 24).** Its reference point is 8.0 km from Sabine Pass, so the two circles overlap and share the entrance-channel traffic. Ships bound for Beaumont pass it.
- **San Francisco (11 to 48).** The Port of San Francisco has 244 deep-draft inbound trips a year. Its circle reaches the Golden Gate (about 7 km) and the Bay Bridge, so every ship bound for Oakland, Richmond, Carquinez Strait, Stockton, or Sacramento passes.
- **Oakland (12 to 21).** Its reference point is 8.2 km from San Francisco's, so the circles overlap. The paper's nearest-port count is 618, against 1,068 in Table 4.
- **Corpus Christi (17, public 6), outside the top 15.** The reference point is in the inner harbor. The Ingleside and Harbor Island crude-export terminals are about 19 and 32 km away, outside the circle (see totals-3).
- **Port Everglades (29, public 3) and PortMiami (42, public 7), outside the top 15.** Many calls by a small set of ships on weekly Caribbean liner and ro-ro services. Unverified: some of these ships may be under 100 m, which the paper's 100 m filter drops but the 18 ft draft proxy keeps.

## Findings

| ID | Severity | Location | Finding | Evidence | Proposed fix |
| --- | --- | --- | --- | --- | --- |
| totals-1 | Number | Section 1.8, Table 4 title and the "Busiest ports first" paragraph; Appendix A.14 | Table 4 calls its list "the 15 busiest deep-draft ports", but its order doesn't match public port-traffic ranks. Spearman rho between paper ship counts and public deep-draft calls is -0.09 within the top 15 (BTS: -0.32). Fourteen of 15 ports move more than three places. Six ports in the public top 15 aren't in the table. The count measures large ships passing within 10 km of a point, which suits S-band radar exposure, but it isn't port traffic. | Comparison table above. USACE trips: <https://ndc.ops.usace.army.mil/wcsc/webpub/>. BTS calls: <https://data.bts.gov/resource/5rpz-kgm9.csv?cargo_type=VESSEL%20CALLS>. Paper counts: outputs/2024_2025/viz/geo_ports.csv. Method: python/ship_geo_products.py:158-185 (any cell within PORT_KM = 10 km, line 40). | Retitle Table 4 "Port areas with the most large ships within 10 km". Say in the text that the count includes ships passing to other ports and doesn't rank port calls. Optionally add a column with the USACE deep-draft call rank and state rho. |
| totals-2 | Number | Section 1.8, Table 4 rows 1, 3, 9, 11; "Galveston ranks first because..." paragraph | Four of the top 11 are gateway points whose own port traffic is small: Sabine Pass (public rank 73 of 73, 12 inbound deep-draft trips a year), San Francisco (48th, 244), Plaquemines (27th, 729), and Galveston (23rd, 842). The paper explains only Galveston. Readers will take Sabine Pass and San Francisco for major cargo ports. | USACE trip reports, locations 2397, 4335, 2255, 2417 (URL pattern in the comparison-table notes). Distances computed from geo_ports.csv coordinates: Sabine Pass to Sabine Pass LNG about 5.8 km; San Francisco to the Golden Gate about 7.1 km; Galveston to Bolivar Roads about 6.0 km. | Extend the Galveston sentence: "Sabine Pass, San Francisco, and Plaquemines rank high for the same reason: their circles cover the entrance channel or river that ships to Port Arthur and Beaumont, the other Bay Area ports, and the upriver Mississippi ports must use." Or report these as gateways in a separate row group. |
| totals-3 | Number | Section 1.8, Table 4 rows for Houston; Table 5 Corpus Christi (paper rank 17) | One 10 km circle around the Corps reference point misses the main deep-draft terminals of large multi-terminal ports. Houston's reference point (29.747 N, 95.294 W) is about 30 km from Barbours Cut and 31 km from Bayport, Port Houston's container terminals. Corpus Christi's reference point (27.813 N, 97.398 W) is about 19 km from Ingleside and 32 km from Harbor Island. Ships that use only those terminals aren't counted at Houston or Corpus Christi (they show up at Galveston instead). This understates Houston (public rank 1, paper rank 6) and Corpus Christi (public rank 6, paper rank 17). | Coordinates from geo_ports.csv. Terminal locations: <https://en.wikipedia.org/wiki/Barbours_Cut_Terminal>, <https://porthouston.com/container-terminals/>. Terminal coordinates are approximate (Ingleside and Harbor Island from general knowledge, Unverified to the kilometer). Distances by haversine formula. | Count ships within the USACE port statistical area polygons (dataset "Ports and Port Statistical Areas", <https://catalog-beta.data.gov/dataset/ports-and-port-statistical-areas>) instead of a 10 km circle. At minimum, add a note that the circle covers only part of Houston and Corpus Christi. |
| totals-4 | Number | Section 1.8, Table 4; Appendix A.20 | Table 4 and Appendix A.20 use two different counts for the same ports without a note in Table 4. Overlapping circles double count: Los Angeles 1,839 in Table 4 against 969 nearest-port; Long Beach 1,898 against 1,475; Oakland 1,068 against 618; Sabine Pass 1,327 against 1,101. The nearest-port count would change Table 4: Oakland drops out and Mobile (867) enters. The paper notes "the counts don't add" but not that this changes the ranking. | outputs/2024_2025/viz/geo_ports.csv against outputs/2024_2025/viz/port_share.csv (column "ships"). Reference points 5.6 km apart (Los Angeles and Long Beach), 8.2 km (San Francisco and Oakland), 8.0 km (Sabine Pass and Port Arthur). | Use the nearest-port count in Table 4 so it agrees with A.20, or add a footnote with both counts for the overlapping pairs. |
| totals-5 | Wording | Section 1.8, "The ranking differs from the Corps tonnage rank, which counts cargo tons, not ships." | The sentence implies a ship-based public measure would agree with the table. It doesn't: public ship-call ranks disagree as much as the tonnage rank does (rho -0.09 against +0.32 for tonnage within the top 15). Distinct ships and calls differ by a factor of about 7 at Houston and about 0.02 to 0.7 at the gateway ports. | Ratio of two-year USACE inbound deep-draft trips to distinct sampled ships: Houston 7.1, New York 4.7, Virginia 4.5, Savannah 4.4, Plaquemines 0.66, Galveston 0.57, San Francisco 0.44, Sabine Pass 0.02. | Replace with: "The ranking differs from both the Corps tonnage rank and port-call counts. It counts each ship once, however often it calls, and it counts ships that pass the port on the way to another." |
| totals-6 | Wording | Section 1.8, "Fifteen ports see 1,000 or more large ships" and "The routes reach every major U.S. port" | The section doesn't name the ports that rank high in public calls but low in the table: Port Everglades, PortMiami, Corpus Christi, Charleston, Philadelphia, and Beaumont. All are on the route network (Table 5), so coverage holds, but a reader comparing with port statistics will ask. | Comparison table above. Unverified: whether a share of Port Everglades and PortMiami calls are by ships under 100 m. | Add one sentence: "Ports with frequent liner calls by few ships, such as Port Everglades and PortMiami, rank lower here than in port-call statistics." |

## Checked and found correct

- Every number in Table 4 (ships, tankers, cargo, passenger, military and law enforcement, Corps tonnage rank) matches outputs/2024_2025/viz/geo_ports.csv.
- Fifteen ports have 1,000 or more distinct large ships in geo_ports.csv; Mobile (867) is 16th.
- The Galveston explanation holds: Bolivar Roads is about 6 km from the Galveston reference point, inside the 10 km circle.
- The code counts any route cell within 10 km of the port point, so passing ships count (python/ship_geo_products.py:158-185; PORT_KM = 10.0 at line 40). This matches the paper's description.
- The paper's ranking is moderately consistent with public data across all 73 ports (rho 0.66 against USACE deep-draft trips, 0.66 against the Corps tonnage rank), so the 73-port coverage check in Table 5 isn't affected.
- The two public series agree: USACE deep-draft trips and BTS 2023 calls have rho 0.97 over 39 ports; Houston is 6,048 and 6,272.
- MARAD "Vessel Calls" by port: the MARAD Data and Statistics page (<https://maritime.dot.gov/data-reports/data-statistics/data-statistics>) lists "Vessel Calls in U.S. Ports, Selected Terminals and Lightering Areas (2015)" as the latest port-level edition. It's too old for a 2024–2025 comparison, and the file returned HTTP 403 to automated download, so I didn't use it.

Scratch work: /tmp/agent_scratch/totals/calc.py and /tmp/agent_scratch/totals/dl/ (downloaded USACE and BTS data, rows.json).
