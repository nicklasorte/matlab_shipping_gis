#!/bin/bash
# Pull AIS positions of the S-band research ships (data/sband_truth_ships.csv)
# from MarineCadastre daily files, streamed: download | zstd -d | MMSI filter.
# Usage: python/truth_ship_tracks.sh <out_dir> <mmsi,list> <yyyy-mm-dd> [more days...]
# Writes <out_dir>/tracks_<day>.csv (header plus matching rows) and a log line per day.
set -u
out=$1; mmsi=$2; shift 2
here=$(cd "$(dirname "$0")" && pwd)
zstd=${ZSTD:-/opt/homebrew/bin/zstd}
mkdir -p "$out"
for day in "$@"; do
  f="$out/tracks_${day}.csv"
  [ -s "$f" ] && { echo "$day skip (exists)"; continue; }
  y=${day:0:4}
  url="https://noaaocm.blob.core.windows.net/ais/csv2/csv${y}/ais-${day}.csv.zst"
  t0=$(date +%s)
  if curl -sfL --retry 3 "$url" | "$zstd" -dc | /usr/bin/python3 "$here/ais_mmsi_filter.py" "$mmsi" > "$f.part"; then
    mv "$f.part" "$f"; echo "$day ok rows=$(($(wc -l < "$f")-1)) secs=$(( $(date +%s)-t0 ))"
  else
    echo "$day FAILED"; rm -f "$f.part"
  fi
done
