# Photo-coding protocol: S-band antenna on kept ships

DRAFT//PRE-DECISIONAL

Date: November 13, 2026. Plan step A3 of `docs/plans/ship_data_sources_plan_rev1.md`.
Public photos only.

## Purpose

Estimate the share of kept AIS ships that carry an S-band (3 GHz) navigation
radar antenna, by ship type. The result is a carriage rate, not a use rate: a
photo shows an antenna, not whether it radiates.

## Sample

1. Take the kept ships from the 2024–2025 AIS set, one row per ship (IMO number).
2. Group them as cargo, tanker, passenger, and other.
3. Draw 100 cargo, 100 tanker, 50 passenger, and 50 other ships at random with
   `python/photo_sample_draw_rev1.py` and a recorded seed. If a group has fewer
   ships than the quota, take all of them.
4. The script also marks a random 20% of the sample for the second coder.
5. Add the research ships in `data/sband_truth_ships.csv` that have a known S-band
   radar as planted answers, mixed into each coder's sheet without a label. A
   coder who calls a planted ship "no S-band" is retrained.

## Finding a photo

- Search by IMO number or name in public ship-photo sites. View the photo to code
  it. Don't download or republish photos; record the page URL and the date the
  photo was taken.
- Prefer a photo from the same year as the AIS data. A photo older than 2018
  is coded but flagged, because radars are replaced.
- Prefer a side or three-quarter view of the bridge and mast. Skip a photo that
  doesn't show the mast tops.
- If no usable photo is found after three sites, code "no photo".

## Codes

| Code | Meaning |
| --- | --- |
| `S` | A rotating antenna 10 ft (3 m) or longer, about 3.7 m for most S-band units, with the long slotted bar of an S-band radiator |
| `X_only` | Only rotating antennas shorter than 8 ft (2.4 m) |
| `unclear` | Antenna length between 8 and 10 ft, or the length can't be judged |
| `no_radar` | The mast is clear and shows no rotating antenna |
| `no_photo` | No usable photo found |

Rules:

- Judge length against something of known size, such as the window height or a
  person on deck, or the deckhouse width.
- Most S-band antennas are 12 ft (3.7 m). Some S-band antennas are 8 or 9 ft, so
  that length is `unclear`, not `X_only`
  (`docs/review/sband_radar_models_rev1.md`).
- A ship with two rotating antennas gets `S` if either is S-band by these rules.
- A small, fast-turning dome or a closed radome is not coded `S`.
- Record the number of rotating antennas seen and a one-line note.

## Coding sheet

`python/photo_sample_draw_rev1.py` writes one sheet per coder with these columns:
`imo`, `mmsi`, `name`, `ship_group`, `second_coder`, `photo_url`, `photo_date`,
`antennas_seen`, `code`, `note`. The coder fills the last six.

## Checks

1. Both coders code the 20% overlap without seeing each other's sheets. Report
   Cohen's kappa on the five codes. Require kappa of at least 0.7, or recode
   after the coders discuss the rules and re-draw a fresh 20%.
2. Report the share of planted ships coded `S`.
3. Report the share of each group coded `no_photo`; a high share biases the rate.

## Estimate

1. Rate = ships coded `S` over ships with a photo that is not `unclear` or
   `no_photo`. Report it by group with a 95% Wilson interval.
2. Report a bound: the rate if every `unclear` is `S`, and if none is.
3. Weight each group by its share of the kept ships to get an overall rate.

## Limits

- A photo shows carriage, not use. Many ships run X-band in port.
- Photos skew toward ships near popular ports.
- The sample of 300 gives an interval about plus or minus 10 points for a group of
  100 at a 50% rate. It can't resolve small differences between groups.
