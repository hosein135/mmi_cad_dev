#!/usr/bin/env bash
# Repo-local git: keep working tree as LF (Linux). Run once after clone if
# your global git has core.autocrlf=true.
set -euo pipefail
cd "$(dirname "$0")/.."
git config core.autocrlf false
git config core.eol lf
echo "Set core.autocrlf=false core.eol=lf for this repo."
