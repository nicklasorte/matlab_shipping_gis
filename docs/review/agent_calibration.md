# Agent calibration: planted errors

DRAFT//PRE-DECISIONAL

Date: November 12, 2026

## What was done

Before trusting the stage 3 agents, we measured what they catch. A copy of
the paper and the code (`/tmp/paper_repo_b`, not committed) got 20 planted
errors of known kinds. Three agents reviewed the copy with the same briefs as
the real review, without being told that errors were planted: the method
reviewer, the numbers checker (ledger), and the style and Section 508
reviewer. The answer key was kept where the agents couldn't read it.

## Results

| # | Kind | Planted error | Method | Ledger | Style |
| --- | --- | --- | --- | --- | --- |
| 1 | Number | Table 3 total changed (675,763 to 675,673) | Yes | Yes | Yes |
| 2 | Number | Hawaii 25 km share changed (70% to 80%) | Yes | Yes | Yes |
| 3 | Number | Alaska 25 km area transposed (179,047 to 197,047) | Yes | Yes | Yes |
| 4 | Number | Alaska satellite Jaccard index (0.57 to 0.75) | Yes | Yes | Yes |
| 5 | Number | First of two mentions changed (1,347,288 to 1,374,288) | Yes | Yes | Yes |
| 6 | Number | Port count contradicts its other mention (69 to 71 of 73) | Yes | Yes | Yes |
| 7 | Citation | DOI digits swapped | Yes | Yes | No |
| 8 | Cross-reference | Points to a figure that doesn't exist | Yes | Yes | Yes |
| 9 | Cross-reference | Points to the wrong figure | Yes | Yes | Yes |
| 10 | Caption | Figure 7 years contradict the data | Yes | Yes | Yes |
| 11 | Unit | km for an area | Yes | Yes | Yes |
| 12 | Consistency | Length cutoff contradicts Section 1.4 (90 m) | Yes | Yes | Yes |
| 13 | Code | Length cutoff in the init script (90 m) | Yes | Yes | Out of brief |
| 14 | Code | Route rule in the init script (5 ships) | Yes | Yes | Out of brief |
| 15 | Code | Tug-barge distance in the init script (35 km) | Yes | Yes | Out of brief |
| 16 | Code | Zone distance in the init script (150 km) | Yes | Yes | Out of brief |
| 17 | Code | Half-cell latitude shift in the Python grid index | Yes | Yes | Out of brief |
| 18 | Projection | Hawaii land test set to the Alaska projection | No | No | Out of brief |
| 19 | Section 508 | Alt text removed from Figure 2 | No | Yes | Yes |
| 20 | Marking | DRAFT//PRE-DECISIONAL removed | No | No | Yes |
| | | **Caught** | **17 of 20** | **18 of 20** | **13 of 13 in brief, 14 of 20 overall** |

Caught by at least one agent: 19 of 20 (95%).

| Kind | Caught by at least one agent |
| --- | --- |
| Numbers (6) | 6 (100%) |
| Citation, cross-reference, caption, unit, consistency (6) | 6 (100%) |
| Code constants and grid index (5) | 5 (100%) |
| Section 508 and marking (2) | 2 (100%) |
| Projection in a check script (1) | 0 (0%) |

## What this means for Nick's review

- **Numbers, references, captions, and code-paper mismatches:** the agents
  caught every planted error, usually two or three agents each, so the stage 3
  findings in these kinds can be trusted as a first pass.
- **Projections and coordinate systems in helper scripts:** no agent caught
  the planted swap. It sat in a data-check script, not in the zone code, and
  no brief asked agents to check every projection string. **Check the
  projections yourself**, or rely on the GIS reviewer's projection check (its
  brief does ask), which ran on the real repo only.
- **Each agent misses things outside its brief.** The method reviewer missed
  the alt text and the marking; the style reviewer missed the DOI. Keep the
  overlapping roles.
- **Bonus:** the agents on the planted copy also reported real errors that
  exist in the unaltered paper (for example, the Mississippi route end in
  Section 1.7, and figures and tables not cited before they appear). Those are
  counted in the real review, not here.

## Limits

One run, 20 errors, three agents. The catch rates are an estimate, not a
guarantee. Errors of a kind not planted here (for example, a wrong method that
the paper describes accurately) aren't measured.
