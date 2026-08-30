#!/usr/bin/env bash
# Make mkfontdir / mkfontscale output byte-stable. Those tools follow readdir
# order, which is not deterministic across filesystems.
set -euo pipefail
export LC_ALL=C
dir="${1:?font directory}"
cd "$dir"

sort_index() {
  local f="$1"
  [ -f "$f" ] || return 0
  local rest n
  rest="$(tail -n +2 "$f" | LC_ALL=C sort -u || true)"
  if [ -z "$rest" ]; then
    printf '%s\n' "0" >"$f"
    return 0
  fi
  n="$(printf '%s\n' "$rest" | grep -c .)"
  {
    printf '%s\n' "$n"
    printf '%s\n' "$rest"
  } >"$f"
}

sort_index fonts.dir
sort_index fonts.scale
