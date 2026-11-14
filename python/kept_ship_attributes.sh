#!/bin/bash
# Static fields for every kept ship (data/kept_mmsi_2024_2025.csv) on each day,
# streamed from MarineCadastre daily files (plan step C1).
# Usage: python/kept_ship_attributes.sh <out_dir> <mmsi_list.csv> <yyyy-mm-dd> [more days...]
set -u
out=$1; list=$2; shift 2
here=$(cd "$(dirname "$0")" && pwd)
zstd=${ZSTD:-/opt/homebrew/bin/zstd}
mkdir -p "$out"
for day in "$@"; do
  f="$out/attributes_${day}.csv"
  [ -s "$f" ] && { echo "$day skip (exists)"; continue; }
  url="https://noaaocm.blob.core.windows.net/ais/csv2/csv${day:0:4}/ais-${day}.csv.zst"
  t0=$(date +%s)
  if curl -sfL --retry 3 "$url" | "$zstd" -dc | /usr/bin/python3 "$here/ais_ship_attributes.py" "$list" > "$f.part"; then
    mv "$f.part" "$f"; echo "$day ok ships=$(($(wc -l < "$f")-1)) secs=$(( $(date +%s)-t0 ))"
  else
    echo "$day FAILED"; rm -f "$f.part"
  fi
done
