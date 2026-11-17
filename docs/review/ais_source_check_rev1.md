# What the lower-48 AIS data hold far offshore (plan step R7, review R4OPP-12)

DRAFT//PRE-DECISIONAL

Date: November 17, 2026.

## Question

The paper said the 2024-2025 AIS data come from Coast Guard shore receivers,
but route cells reach far beyond any shore receiver's range. Where do those
reports come from?

## What the metadata says

- NOAA InPort record 73064, "Nationwide Automatic Identification System 2024"
  ([full list](https://www.fisheries.noaa.gov/inport/item/73064/full-list),
  read November 17, 2026): "Records were received from all U.S. Coast Guard
  NAIS terrestrial receivers." The records are filtered to one-minute
  frequency and subset to vessels broadcasting within the Exclusive Economic
  Zone. The record doesn't mention satellite AIS. Alaska records are filtered
  out at the request of the Alaska Marine Data Exchange.
- The MarineCadastre repository
  ([ocm-marinecadastre/ais-vessel-traffic](https://github.com/ocm-marinecadastre/ais-vessel-traffic))
  says only that the data come from the Coast Guard Nationwide AIS.
- The Coast Guard
  ([NAIS transitions to sustainment](https://dcms.uscg.mil/Our-Organization/Assistant-Commandant-for-Acquisition-CG-9/Newsroom/Latest-Acquisition-News/Article/1664712/coast-guard-nais-transitions-to-sustainment))
  gives shore receiver ranges of up to 24 nautical miles two-way and 50
  nautical miles receive-only, and says the program's third increment combined
  permanent transceivers with satellite coverage, observing traffic up to
  2,000 nautical miles from the coast.

## What the data show

Distance from each lower-48 route cell to the Census coastline
(`outputs/2024_2025/viz/viz_offshore.csv`, 658,867 cells;
`outputs/2023_2024/viz/viz_offshore.csv`, 661,137 cells):

| Distance from the coastline | 2024-2025 | 2023-2024 |
| --- | ---: | ---: |
| More than 50 nautical miles | 52.0% | 52.4% |
| More than 200 nautical miles | 17.0% | 17.9% |

Beyond 200 nautical miles, by coast (2024-2025): Pacific 35.0%, Gulf 9.5%,
Atlantic 5.8%, Great Lakes 0%.

## Conclusion

Shore receivers can't explain reports hundreds of kilometers offshore. The
Coast Guard's description of satellite coverage in the Nationwide AIS likely
does, but the MarineCadastre metadata don't say so, and how complete the
offshore coverage is isn't documented. The share is stable across the two
periods, so it doesn't bias the comparison between years.

Paper edits (doc revision 525): Section 1.10 "Receiver coverage" states the
offshore shares and the Coast Guard description; the Section 1.2 data table
no longer calls the source terrestrial only.

Open: the 2018-2019 Alaska files appear to lack the long-range reports (the
reason the paper adds satellite hexagons there); confirming that from the
2018-2019 metadata is left for a later step.
