# Decision: clip zone water to U.S. waters? (R2MET-1)

DRAFT//PRE-DECISIONAL

Date: November 13, 2026. Data: `outputs/foreign_water_split_py.csv`,
`outputs/foreign_water_by_country_py.csv` (Python), and
`outputs/foreign_water_split_rev1.csv` (MATLAB, same method, cross-check).

## The question

Each zone file holds U.S. land and all water within the zone distance of a route
cell. Water isn't clipped to U.S. jurisdiction, so the files include water off
Mexico, the Bahamas, Cuba, Canada, Russia, the British Virgin Islands, and the
Dominican Republic. Should the published zone files keep that water?

## How much water is foreign

Method: sample each zone on a 0.02° grid. Water nearer U.S. land than foreign
land (an equidistance line) counts as U.S.-side; the rest is foreign-side. The
equidistance line is the rule the zone code already uses to drop charted lanes
nearer foreign land. Negotiated boundaries depart from it (the Great Lakes, the
Strait of Juan de Fuca, the Gulf of Maine, and the Gulf of Mexico), so these are
estimates. The Python land (cell centres) matches the paper's land areas to
within 0.2% in the lower 48 and 0.8% elsewhere, so the table uses the Python numbers.

**Cross-check.** The MATLAB version counts a grid cell when the polygon touches
it, so its areas run higher (lower-48 land +13%, small islands more). The
foreign share of water agrees with Python to within 0.6 percentage points in
every region and distance (lower 48: 37.0%, 39.7%, 42.4%; Puerto Rico and USVI:
20.2%, 20.4%; Alaska: 5.8%, 7.1%, 8.4%), and the foreign-water areas agree to
within 3% in the lower 48 and Puerto Rico and USVI and 8% in Alaska.

| Region | Zone | Land | U.S.-side water | Foreign-side water | Foreign share of water |
| --- | --- | ---: | ---: | ---: | ---: |
| Lower 48 | 25 km | 300,719 km² | 2,533,983 km² | 1,455,196 km² | 36% |
| Lower 48 | 50 km | 638,412 km² | 2,923,762 km² | 1,890,469 km² | 39% |
| Lower 48 | 100 km | 1,261,494 km² | 3,183,627 km² | 2,301,572 km² | 42% |
| Hawaii | 25 km | 7,926 km² | 87,648 km² | 0 | 0% |
| Hawaii | 100 km | 16,776 km² | 252,837 km² | 0 | 0% |
| Puerto Rico and USVI | 25 km | 7,174 km² | 117,636 km² | 29,236 km² | 20% |
| Puerto Rico and USVI | 50 and 100 km | 9,288 km² | 118,807 km² | 29,999 km² | 20% |
| Alaska | 25 km | 111,693 km² | 580,660 km² | 33,052 km² | 5% |
| Alaska | 50 km | 209,823 km² | 855,190 km² | 60,922 km² | 7% |
| Alaska | 100 km | 351,830 km² | 1,341,843 km² | 116,525 km² | 8% |

By nearest country, the lower-48 foreign water is about 70–74% Mexico (the
Pacific lanes off Baja California and the western Gulf), 10–12% Canada (mostly
the Great Lakes), 8–13% the Bahamas, and 6–7% Cuba. In Puerto Rico and USVI it
is the British Virgin Islands and the Dominican Republic (Mona Passage). In
Alaska it is Canada (Dixon Entrance and Hecate Strait) and Russia (Bering Sea).

The lower-48 zones also hold 1.4 to 2.2 million km² of water more than 200
nautical miles from U.S. land, much of it the same water off Mexico.

## What doesn't change

Land. Clipping the published water doesn't move any route cell, and routes in
foreign water stay zone sources, because a ship's radar radiates across the
boundary whatever its position. Every land area in the paper stays as it is.

## Options

1. **Keep foreign water (now).** Simplest; the paper discloses it (Section 3).
   The maps overstate the U.S. footprint, and a reader may take the water as a
   U.S. claim.
2. **Clip at the equidistance line.** Uses data already in the repo and the rule
   the code already applies to charted lanes. Removes the numbers above. It is an
   approximation, not the legal boundary.
3. **Clip to official U.S. maritime limits.** NOAA's U.S. Maritime Limits and
   Boundaries (public) give the EEZ and the negotiated boundaries; the Great
   Lakes need the International Boundary Commission line. Most defensible;
   needs a new input layer and a check of its license and currency.
4. **Clip to U.S. waters and 200 nautical miles.** Option 2 or 3 plus a cut at
   the EEZ's outer edge, which drops the far-offshore Pacific water.

In every option the routes stay unclipped as sources, so land doesn't change.

## For Nick

This is a policy call: whether the zones describe where ships operate, or where
the United States would apply a rule. The analysis can support any option. A
recommendation, if wanted: option 3 for published files, with the unclipped
files kept in the repo as the analysis record.

## Decision

Nick chose option 2 on November 13, 2026. See "Water clip" in `findings_r2.md`.

Round three added a 200 nautical mile cap: water more than 200 nautical miles from every coast now stays in the zones. With it, the clip removes 32% to 34% of lower-48 zone water (`outputs/foreign_water_clip_effect_rev1.csv`); the table above is the uncapped pre-clip estimate.
