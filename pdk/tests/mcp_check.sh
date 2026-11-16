#!/bin/sh
# Parser checks for the mcp menu. No network and no MAX window.
set -eu
here=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
root=$(CDPATH= cd -- "$here/../.." && pwd)
python3 "$root/pdk/mcp_ask.py" --selftest
tclsh "$root/pdk/tests/mcp_selftest.tcl"
