#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

rm -f .git/index.lock

mapfile -t paths < <(git ls-files -s vendor/mmi | awk '$1 == "120000" {print $4}')
echo "symlink_index_entries: ${#paths[@]}"

n=0
for path in "${paths[@]}"; do
  [[ -z "$path" ]] && continue
  if [[ -e "$path" || -d "$path" ]]; then
    git rm --cached -f -- "$path" >/dev/null
    git add -- "$path"
    n=$((n + 1))
    echo "fixed: $path"
  else
    echo "skip_missing: $path"
  fi
done

echo "fixed_entries: $n"
remaining=$(git ls-files -s vendor/mmi | awk '$1 == "120000" {print $4}' | wc -l)
echo "remaining_symlink_index_entries: $remaining"
