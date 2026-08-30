#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

rm -f .git/index.lock

echo "Rebuilding index from HEAD..."
if [[ -f .git/index ]]; then
  cp -a .git/index ".git/index.bak.$(date +%s)"
fi

git read-tree HEAD

echo "Refreshing vendor/mmi symlink entries as regular files..."
n=0
while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  if [[ -f "$path" && ! -L "$path" ]]; then
    git add -- "$path"
    n=$((n + 1))
  fi
done < <(git ls-files -s vendor/mmi | awk '$1 == "120000" {print $4}')

echo "refreshed_symlinks: $n"

echo "Staging repo changes outside vendor/mmi..."
git add nix scripts vendor/README.md flake.nix run.sh pdk .gitignore 2>/dev/null || true
git add -u -- nix scripts vendor/README.md flake.nix run.sh pdk .gitignore 2>/dev/null || true

echo "done"
