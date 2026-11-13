# Reviewer read-ahead: limits and questions

DRAFT//PRE-DECISIONAL

Working paper: *2.7 GHz large-ship routes and zones* (Sections 1, 3–6 and
Appendix A). November 2026.

## What the paper does

The paper maps where large ships (100 m or longer, the class that carries
S-band navigation radar) sail near the United States, and draws example
zones around those routes at 25, 50, and 100 km. It uses public AIS data
from MarineCadastre (NOAA and BOEM), with routes built from 104 weekly
sample days. The zone distances are placeholders until the EMC analysis
(Section 2) sets them.

| Area | Data years | Route rule | Route cells (0.01°) |
| --- | --- | --- | --- |
| Lower 48 | 2024–2025 | 4 or more distinct ships in one year | 675,763 |
| Hawaii | 2024–2025 | 6 or more ship-days | 7,310 |
| Alaska, east of 180° | 2018–2019 | 6 or more ship-days, plus satellite-AIS lanes | 26,983 AIS, plus charted and satellite lanes |
| Puerto Rico and the USVI | 2024–2025 | 4 or more distinct ships in one year | 43,845 |

## Limits we know about

Each of these could move a route or a zone. Tell us if any is stated too
weakly in the paper.

1. **Alaska uses older data.** MarineCadastre stopped publishing Alaska
   after 2020, so Alaska uses 2018–2019 while the rest uses 2024–2025.
2. **Shore receivers reach about 40 nautical miles.** Beyond that, the
   shore-based data misses ships. In Alaska we fill the gap with a public
   satellite-AIS dataset (Kapsar et al. 2022, CC BY 4.0), whose hexagons are
   about 27 km across. Its cutoff matches the shore-based routes only
   moderately (Jaccard index 0.57).
3. **Navy and other government ships often turn AIS off.** The routes show
   commercial traffic only.
4. **The route rules are analyst choices.** The lower-48 rule (four ships
   in a year) was set first; the Hawaii and Alaska rule (six ship-days) was
   calibrated to match it in the lower 48. Other reasonable rules give
   other edges.
5. **Weekly sampling.** One day a week, two years. Rare routes, such as
   seasonal or one-off voyages, may be missed or included by chance. 81% of
   2023 route cells and 94% of 2026 route cells fall inside the 2024–2025
   network; Hawaii is less stable (56–63%).
6. **AIS errors.** We checked four days in each 2024–2025 area and three
   Alaska days. Errors are rare in Hawaii and Puerto Rico. In the lower 48,
   position jumps and shared ship IDs rose in 2025 (14% of ships on
   2025-07-09), and on the worst day 915 route cells (0.14%) came only from
   flagged reports. Alaska showed a similar jump rate on one 2019 day. A
   rebuild without flagged reports is planned for the review.
7. **No charted lanes or radar beacons were returned for Puerto Rico**, and
   no radar beacons for Hawaii or Alaska. We haven't yet confirmed against
   the charts that none exist.
8. **Not analyzed:** the western Aleutians (west of 180°), Guam, the
   Northern Mariana Islands, and American Samoa.
9. **No maritime operator reviewed the routes.** They were checked against
   NOAA transit counts, NOAA charts, satellite AIS in Alaska, and the
   deep-draft ports, not against local knowledge.
10. **Zone distances are examples.** The 25, 50, and 100 km zones show the
   method, not a recommendation.

## Questions for reviewers

Answer the ones in your area; skip the rest. Comments in the working-paper
doc are best.

### Routes (any reviewer)

The routes haven't been reviewed by a maritime operator, so these questions
are open to everyone.

1. Do the route maps in Sections 3 through 6 match where large ships
   sail? Name any lane, anchorage, or port approach that is missing or
   shouldn't be there.
2. Are there areas where large ships routinely operate without AIS (for
   example, Navy operating areas) that the zones should account for?
3. Do the Alaska satellite lanes (Section 5) look right, especially the
   Bering Strait and the Gulf of Alaska great-circle routes?
4. Is a 100 m length cutoff a fair stand-in for "carries S-band radar"?

### RF engineering

5. Does a cell-based route network give the EMC analysis what it needs, or
   would it need ship density or time-at-location instead?
6. Are 25, 50, and 100 km the right range of distances to illustrate, given
   what you expect the EMC analysis to show?

### GIS and data

7. Are the distance method (geodesic distance to the nearest route cell on
   a 0.01° grid), the projections, and the land and coastline layers
   (Census 1:500,000 states, TIGER coastline) right for every area,
   including Alaska near 180°?
8. Is cutting the Alaska analysis at 180° acceptable, or should the
   western Aleutians be added?

### Style, Section 508, and data use

9. Can a non-specialist follow Sections 1 and 3 without the appendix?
10. Do the MarineCadastre terms and the CC BY 4.0 attribution for the
    satellite dataset meet NTIA's requirements? Is citing 2018–2019 data
    for Alaska acceptable?

## What we are not asking

- Whether the zones should be used, or how. That is a policy decision.
- The EMC analysis or the final zone distances.
