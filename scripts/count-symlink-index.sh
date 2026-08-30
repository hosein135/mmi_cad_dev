#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

count=$(git ls-files -s vendor/mmi | awk '$1 == "120000" {print $4}' | wc -l)
echo "symlink_index_entries: $count"
