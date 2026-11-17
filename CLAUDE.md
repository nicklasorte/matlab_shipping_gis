# CLAUDE.md

Instructions for Claude sessions (Claude Code or chat) working in this repo.
Read this first, then `docs/plans/next_steps_rev2.md` (current plan) and the
Status section of `docs/plans/next_steps_rev1.md` (phase 1 results).

## What this repo is

MATLAB (with Python twins) code that builds large-ship routes from public AIS
data and draws frequency-dependent zones around them for the 2.7 GHz study
(2900–3100 MHz, shipborne S-band radar). Regions: lower 48, Hawaii, Puerto Rico
and the U.S. Virgin Islands, and Alaska. The working paper is a Claude Doc; the
Word copy is `docs/2.7GHz_Routes_and_Zones_Sections_DRAFT.docx`.

## Start of every session

1. Read `docs/plans/next_steps_rev2.md` and the "Status" section of
   `docs/plans/next_steps_rev1.md`: open
   decisions (D1 to D6), done and open steps, what's running.
2. Check open review items in `docs/review/round4/findings_r4.md` (and earlier
   rounds under `docs/review/`) before changing method or text, so you don't
   reopen a closed item.
3. `git pull` first. If it hangs (it has on the Mac clone), download changed
   files at a commit hash from GitHub instead and check their content.

## End of every session

Update the status in `docs/plans/next_steps_rev2.md` (what changed,
latest commit, open decisions, anything still running), commit, and push.
That file is the handoff between sessions and between Claude Code and chat.

## Rules

- **Sources:** public and cleared material only. Don't use the GMF.
- **Repo stays public.** Don't commit coder answer keys, private data, or
  credentials. Photo-coding sheets live outside the repo.
- **MATLAB:** R2025b. Use built-in and toolbox functions first; verify syntax
  with `help` in a live session, not from memory. Lint with `checkcode` and run
  before committing.
- **Python and MATLAB versions of everything.** A new analysis gets both, and
  the two must agree (state the tolerance).
- **Names:** `_rev1` file suffix (`_rev2` for a new version), snake_case.
- **Fail loudly:** `error()` with an identifier; no silent skips.
- **Numbers in the paper** must trace to a committed output file or log. Commit
  run logs (for example `outputs/rerun_logs_20261114/`).
- **Writing:** Google developer documentation style; NTIA conventions; mark
  documents DRAFT//PRE-DECISIONAL.
- **Review:** AI agents do the technical review (blind, separate agents for
  numbers, method and code, style and Section 508, and an opposing reader);
  Nick does the human review. Policy calls (decisions D1 to D6) are Nick's.
- **Paper edits:** exact fixes and new sourced content go in as plain edits;
  rewording goes in as suggestions for Nick to accept.
- **Confirm before finalizing** any deliverable that leaves the repo.

## Git

- Commit trailer:

  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  ```

  plus a `Claude-Session:` line when the session provides one.
- Push: `git push -q origin HEAD:main && git push -q -f origin HEAD:claude/shipping-zone-rev1`
- Don't commit macOS `._*` files; tar on the Mac with `--owner=0 --group=0`.

## Running things

- **Tests:** `test_shipping_zone_rev1.m`, `test_water_clip_rev1.m` (MATLAB);
  `python3 -m pytest -q python/` and `python3 python/test_known_answer.py`.
- **Zone runs:** `init_shipping_zone_rev1.m` (lower 48),
  `init_shipping_zone_hawaii_rev1.m`, `init_shipping_zone_prusvi_rev1.m`,
  `init_shipping_zone_alaska_rev1.m` (`lane_suffix`: `''`, `'_x0.5'`, `'_x2'`,
  `'_nosat'`, `'_beyond'`). Land areas in the paper: lower 48 301,168 /
  638,688 / 1,261,529 km²; Hawaii 7,869 / 14,132 / 16,717; Puerto Rico and USVI
  7,211 / 9,278 / 9,278; Alaska 112,426 / 210,895 / 353,639 (25 / 50 / 100 km).
  A rerun that changes these needs a reason and a paper update.
- **AIS:** MarineCadastre daily `.csv.zst`, 104 Wednesdays (52 each in 2024
  and 2025; Alaska uses 2018–2019). Large AIS downloads and MATLAB runs happen
  on Nick's Mac (`~/github-runs/matlab_shipping_gis`).
- **Word copy:** export the doc as docx (pictures "fit"), then
  `python3 python/word_copy_rev1.py <export.docx> <previous.docx> <out.docx> ["<alt prefix>=<image>" ...]`.

## Where things are

| Path | What |
| --- | --- |
| `docs/plans/next_steps_rev2.md` | Current plan and decisions (the handoff) |
| `docs/plans/next_steps_rev1.md` | Phase 1 plan and results |
| `docs/review/` | Review rounds 1 to 4, findings, and dispositions |
| `docs/protocols/` | Photo-coding protocol for the S-band carriage rate |
| `data/` | Inputs: truth ships, radar models, kept-ship list, PSIX tonnage |
| `outputs/` | Zone files, checks, sensitivity runs, rerun logs |
| `python/` | Python twins, figures, tests |
| `docs/viz_python/`, `docs/viz_matlab/` | Paper figures |
