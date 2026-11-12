#!/bin/bash
# Tests that do not need MAX or a display.
set -euo pipefail
T=${TCLSH:-/nix/store/biz055ybc5x1vxar1dqlrjsw7w9axgc2-tcl-8.6.16/bin/tclsh}
if [ ! -x "$T" ]; then
  T=$(command -v tclsh)
fi
R=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
echo "== mag_exact =="
"$T" "$R/pdk/tests/mag_exact.tcl"
echo "== rule_audit =="
"$T" "$R/pdk/tests/rule_audit.tcl"
echo "== tcl80 =="
bash "$R/pdk/tests/tcl80_check.sh"
echo "== importer --list =="
"$T" "$R/pdk/importer/importer.tcl" --list
echo "== gen_sue_lib =="
pdk=""
for c in "$HOME/.ciel/sky130A" /mmi-pdks/sky130A "$R/data/pdks/sky130A"; do
  if [ -d "$c/libs.tech/xschem" ]; then pdk=$c; break; fi
done
if [ -z "$pdk" ]; then
  echo "no sky130A tree; SUE generation skipped"
  exit 0
fi
rm -rf /tmp/mmi-sue-parent
mkdir -p /tmp/mmi-sue-parent/sue/lib
"$T" "$R/pdk/sue/gen_sue_lib.tcl" "$pdk" /tmp/mmi-sue-parent/sue/lib/sky130A sky130A sky130A
echo "== sue -lib resolve =="
PDK_ROOT=/tmp/mmi-sue-parent "$T" << EOF
set SUE_LIB_NO_APPLY 1
source {$R/pdk/sue/sue_lib.tcl}
set env(PDK_ROOT) /tmp/mmi-sue-parent
set found [sue_lib_find sky130A]
if {\$found == ""} { puts "FAIL find"; exit 1 }
puts "found \$found"
set LIB sky130A
sue_lib_apply
if {![file isdirectory [lindex \$LIB 0]]} { puts "FAIL rewrite \$LIB"; exit 1 }
puts "rewritten \$LIB"
EOF
echo "== icon sanity =="
f=$(ls /tmp/mmi-sue-parent/sue/lib/sky130A/devices/*__nfet_01v8.sue 2>/dev/null | head -1 || true)
echo "file ${f:-missing}"
if [ -n "$f" ]; then sed -n '1,30p' "$f"; fi
"$T" << 'EOF'
set bad 0
foreach f [glob -nocomplain /tmp/mmi-sue-parent/sue/lib/sky130A/devices/*.sue] {
  set fh [open $f r]
  set t [read $fh]
  close $fh
  if {![info complete $t]} { puts "incomplete $f"; incr bad }
  if {[regexp {\nspiceprefix} $t]} { puts "multiline model $f"; incr bad }
}
if {$bad} { exit 1 }
puts "icons complete"
EOF
grep -n 'ln_min' /tmp/mmi-sue-parent/sue/lib/sky130A/spice_header.h
echo "== importer status =="
PDK_ROOT=/tmp/mmi-sue-parent "$T" "$R/pdk/importer/importer.tcl" --status sky130A
echo "all local tests passed"

