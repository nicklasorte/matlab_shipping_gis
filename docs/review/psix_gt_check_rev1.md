# Gross tonnage of U.S.-flag kept ships from Coast Guard PSIX (plan step C5)

DRAFT//PRE-DECISIONAL

Date: November 14, 2026. Script: `python/psix_gt_kept_ships.py`. Data:
`data/psix_gt_kept_ships.csv`, `data/psix_tonnage_rows.csv`.

## Method

The Coast Guard Port State Information Exchange (PSIX) publishes a public SOAP
web service (`https://cgmix.uscg.mil/xml/PSIXData.asmx`). For each U.S.-flag
kept ship (MMSI country codes 303, 338, 366 to 369) with a call sign, the script
looks up the PSIX vessel by call sign, then its tonnage rows. PSIX gives
Convention (Subpart B) tonnage as two rows whose unit labels don't follow the
measure, so gross tonnage is taken as the larger value and net as the smaller.

## Match

Of 789 U.S.-flag kept ships with a call sign: 552 matched by call sign and
name, 111 by call sign only, 17 ambiguous, and 109 not found. 474 have a PSIX
gross tonnage; the results below use the 391 matched by call sign and name.

## Results

| Kept ships (U.S. flag, call sign and name match) | Ships | 3,000 GT or more | Median GT |
| --- | ---: | ---: | ---: |
| Towing (AIS types 31, 32, 52) | 159 | 0 (0%) | 497 |
| All other kept types | 232 | 212 (91%) | 29,801 |
| Cargo group | 139 | 97% | 36,751 |
| Tanker group | 62 | 87% | 29,801 |
| Passenger group | 16 | 94% | 5,871 |

The towing result is new evidence for review R4OPP-1: the tug-barge rule adds
route cells from vessels whose own tonnage is far below the SOLAS 3 GHz size.
Section 1.5 now states it (doc revision 520). The cargo, tanker, and passenger
shares are close to the Wikidata check in Section 1.4 for the U.S.-flag subset,
an independent registry source.

## Limits

- U.S.-flag ships only (789 of 16,085 kept ships), and a fifth of them didn't
  match cleanly.
- The spot-check against PSIX web pages called for in the plan wasn't possible
  from this session (the PSIX pages are blocked); values come from the same
  PSIX database through the web service. Ten sample rows look plausible (for
  example Maersk Iowa 50,686 GT, Matson Anchorage 20,965 GT).
