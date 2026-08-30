#!/usr/bin/env bash
# Remove case-only duplicates that break Windows Git indexing on vendor/mmi.
set -euo pipefail
cd "$(dirname "$0")/.."

while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  if [[ -f "$path" ]]; then
    echo "remove: $path"
    git rm -f -- "$path" >/dev/null 2>&1 || rm -f -- "$path"
  fi
done < <(find vendor/mmi -name 'MAX_Man_ch2LayoutEda.gif' -type f | sort)

while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  if [[ -f "$path" ]]; then
    echo "remove: $path"
    git rm -f -- "$path" >/dev/null 2>&1 || rm -f -- "$path"
  fi
done < <(find vendor/mmi -path '*/irsim/*/MAKEFILE' -type f | sort)

echo "done"
