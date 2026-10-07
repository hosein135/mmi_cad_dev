#!/usr/bin/env bash
set -euo pipefail
tmp=$(mktemp)
{
  echo start
  echo hi | while read -r x; do echo "got $x"; done
  echo after_pipe
} > "$tmp"
echo "survived brace"
echo "----"
cat "$tmp"
echo "----"
rm -f "$tmp"
