#!/bin/sh
# Reject Tcl constructs MAX (8.0) and SUE (8.0) cannot parse,
# in the files those programs source.
set -e
root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
fail=0
scan() {
  f=$1
  hit=$(grep -nE 'dict |\{\*\}|[^a-z]lset |string repeat|file normalize|glob -directory' "$f" \
    | grep -vE '^[[:space:]]*[0-9]+:[[:space:]]*#' || true)
  if [ -n "$hit" ]; then
    echo "Tcl 8.0 incompatible construct in $f"
    printf '%s\n' "$hit"
    fail=1
  fi
}
scan "$root/pdk/pdk_common.tcl"
scan "$root/pdk/mag_import.tcl"
scan "$root/pdk/mag_exact.tcl"
scan "$root/pdk/image_layout.tcl"
scan "$root/pdk/maxrc"
scan "$root/pdk/sue/sue_lib.tcl"
if [ "$fail" != 0 ]; then
  exit 1
fi
echo "tcl 8.0 scan passed"
exit 0
