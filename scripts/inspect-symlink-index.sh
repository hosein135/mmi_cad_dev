#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  if [[ -L "$path" ]]; then
    echo "symlink: $path -> $(readlink "$path")"
  elif [[ -d "$path" ]]; then
    echo "directory: $path"
  elif [[ -f "$path" ]]; then
    echo "file: $path"
  else
    echo "missing: $path"
  fi
done < <(git ls-files -s vendor/mmi | awk '$1 == "120000" {print $4}')
