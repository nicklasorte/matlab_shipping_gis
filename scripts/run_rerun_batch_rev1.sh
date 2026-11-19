#!/usr/bin/env bash
# Rerun batch (review round 5: R5MET-1, R5MET-3, R5NUM2-4). Run on the Mac, from the repo root:
#   git fetch origin && git checkout --detach <commit>     # the commit named in the plan
#   nohup bash scripts/run_rerun_batch_rev1.sh > /tmp/rerun_batch.out 2>&1 &
# Refuses to start if tracked files differ from HEAD. Every log starts with a COMMIT line.
set -u
cd "$(dirname "$0")/.."
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "ERROR shipgis:dirty tracked files differ from HEAD; commit or stash first" >&2; exit 1
fi
COMMIT=$(git rev-parse HEAD)
DAY=$(date +%Y%m%d)
LOGDIR=outputs/rerun_logs_${DAY}
mkdir -p "$LOGDIR"
STATUS=$LOGDIR/status.log
say() { echo "$(date +%H:%M:%S) $*" >> "$STATUS"; }
run() {  # run <log name> <matlab code>
  local name=$1; shift
  say "START $name"
  { echo "COMMIT $COMMIT"; matlab -batch "$*" 2>&1; } > "$LOGDIR/$name.log"
  say "END $name (exit $?)"
}
say "COMMIT $COMMIT"
run lower48        "init_shipping_zone_rev1"
for v in no_tug both_years no_great_lakes great_lakes_only underway no_lakers lakers_only no_st_lawrence; do
  run "$v" "decision_variant='$v'; init_shipping_zone_rev1"
done
run hawaii "init_shipping_zone_hawaii_rev1"
run prusvi "init_shipping_zone_prusvi_rev1"
run alaska_d2 "lane_suffix=''; init_shipping_zone_alaska_rev1"
for s in _all400 _nosat _x0.5 _x2; do
  run "alaska${s}" "lane_suffix='$s'; init_shipping_zone_alaska_rev1"
done
say "ALLDONE (zone runs). Still to run by hand: foreign-water split, stress outputs, GT check, sites check."
