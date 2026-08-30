#!/usr/bin/env bash
# Local git settings so vendor/mmi checkouts hash the same on Linux and Windows.
set -euo pipefail
cd "$(dirname "$0")/.."
git config core.autocrlf false
git config core.eol lf
git config core.symlinks false
echo "Set core.autocrlf=false core.eol=lf core.symlinks=false for this repo."
