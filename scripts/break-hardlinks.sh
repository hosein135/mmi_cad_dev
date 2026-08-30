#!/usr/bin/env bash
# Break hard links so Windows Git can mmap vendor/mmi files.
set -euo pipefail
ROOT="${1:-vendor/mmi}"
cd "$(dirname "$0")/.."
cd "$ROOT"

n=0
while IFS= read -r -d '' f; do
  tmp="${f}.dedup.$$"
  cp -f -- "$f" "$tmp"
  mv -f -- "$tmp" "$f"
  n=$((n + 1))
done < <(find . -type f -links +1 -print0)

echo "broke_hardlinks: $n"
