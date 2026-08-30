#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

rm -f .git/index.lock

mapfile -t paths < <(git ls-files -s vendor/mmi | awk '$1 == "120000" {print $4}')
echo "symlink_index_entries: ${#paths[@]}"

n=0
for path in "${paths[@]}"; do
  [[ -z "$path" ]] && continue
  if [[ -f "$path" && ! -L "$path" ]]; then
    git rm --cached -f -- "$path" >/dev/null
    git add -- "$path"
    n=$((n + 1))
    if (( n % 100 == 0 )); then
      echo "refreshed: $n"
    fi
  fi
done

echo "refreshed_symlinks: $n"
remaining=$(git ls-files -s vendor/mmi | awk '$1 == "120000" {print $4}' | wc -l)
echo "remaining_symlink_index_entries: $remaining"
