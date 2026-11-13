#!/bin/bash
# Open a Magic VLSI GUI on a GDS file with the PDK technology loaded.
# Used after Mag→MAX import: MAX writes the converted layout to GDS, then
# this starts magic-vlsi on that file. The PDK .magicrc supplies cifinput,
# which is what Magic needs in order to map GDS layer numbers.
# Usage: open_gds.sh <gds_file> <top_cell> [family]
set -uo pipefail

GDS="${1:?gds file}"
TOP="${2:?top cell}"
FAMILY="${3:-sky130A}"
PDK_ROOT="${PDK_ROOT:-/mmi-pdks}"

if [ ! -f "$GDS" ]; then
  echo "ERROR: GDS not found: $GDS" >&2
  exit 1
fi
GDS="$(cd "$(dirname "$GDS")" && pwd)/$(basename "$GDS")"

magic_bin="$(command -v magic || true)"
if [ -z "$magic_bin" ] && [ -x /mmi-magic/bin/magic ]; then
  magic_bin=/mmi-magic/bin/magic
fi
if [ -z "$magic_bin" ] && [ -x /usr/bin/magic ]; then
  magic_bin=/usr/bin/magic
fi
if [ -z "$magic_bin" ]; then
  echo "ERROR: magic-vlsi is not installed (expected magic on PATH or /mmi-magic/bin/magic)." >&2
  exit 2
fi

pdk_name="$FAMILY"
case "$FAMILY" in
  sky130A|sky130*|skywater*) pdk_name=sky130A ;;
  gf180*|gf180mcu) pdk_name=gf180mcuD
    [ -d "$PDK_ROOT/gf180mcuD" ] || pdk_name=gf180mcu ;;
  sg13g2|ihp*) pdk_name=ihp-sg13g2
    [ -d "$PDK_ROOT/ihp-sg13g2" ] || pdk_name=sg13g2 ;;
esac

RC=""
for cand in \
    "$PDK_ROOT/$pdk_name/libs.tech/magic/${pdk_name}.magicrc" \
    "$PDK_ROOT/$pdk_name/libs.tech/magic/${FAMILY}.magicrc" \
    "$PDK_ROOT/$pdk_name/libs.tech/magic/current/${pdk_name}.magicrc" \
    "$PDK_ROOT/sky130A/libs.tech/magic/sky130A.magicrc" \
    "$PDK_ROOT/sky130A/libs.tech/magic/current/sky130A.magicrc" \
    "$PDK_ROOT/gf180mcuD/libs.tech/magic/gf180mcuD.magicrc" \
    "$PDK_ROOT/ihp-sg13g2/libs.tech/magic/ihp-sg13g2.magicrc"
do
  if [ -f "$cand" ]; then
    RC="$cand"
    break
  fi
done
if [ -z "$RC" ] && [ -d "$PDK_ROOT/$pdk_name/libs.tech/magic" ]; then
  RC="$(find "$PDK_ROOT/$pdk_name/libs.tech/magic" -name '*.magicrc' -print -quit 2>/dev/null || true)"
fi
if [ -z "$RC" ]; then
  echo "ERROR: No Magic .magicrc for $pdk_name under PDK_ROOT=$PDK_ROOT" >&2
  echo "Magic cannot read this GDS without the PDK cifinput section." >&2
  echo "  \$PDK_ROOT/$pdk_name/libs.tech/magic/$pdk_name.magicrc" >&2
  echo "Import the PDK with ./run.sh importer first." >&2
  exit 3
fi

export PDK_ROOT
export PDK="$pdk_name"
export PDKPATH="${PDK_ROOT}/${pdk_name}"
export MAGTYPE=mag

TECHFILE="$PDKPATH/libs.tech/magic/${pdk_name}.tech"
SCRIPT="$(mktemp /tmp/open_gds_XXXXXX.tcl)"

{
  echo "catch {"
  echo "  set _want [string tolower {$pdk_name}]"
  echo "  set _fam  [string tolower {$FAMILY}]"
  echo "  set _have [string tolower [tech name]]"
  echo "  if {\$_have != \$_want && \$_have != \$_fam && [file exists {$TECHFILE}]} {"
  echo "    tech load {$TECHFILE}"
  echo "  }"
  echo "  puts \"open_gds: tech [tech name]\""
  echo "}"
  echo "drc off"
  echo "catch {gds rescale false}"
  echo "catch {gds readonly true}"
  echo "if {[catch {gds read {$GDS}} _err]} {"
  echo "  puts stderr \"open_gds: gds read failed: \$_err\""
  echo "} else {"
  echo "  catch {load {$TOP}}"
  echo "  select top cell"
  echo "  expand"
  echo "  catch {view}"
  echo "}"
} > "$SCRIPT"

echo "Magic GUI: $magic_bin"
echo "PDK:       $PDKPATH"
echo "RC:        $RC"
echo "Top:       $TOP"
echo "GDS:       $GDS"

cd "$(dirname "$GDS")"
# Interactive layout window (not -dnull). -g is the graphics type.
# Force X11 so the CAD Xvnc session does not need Cairo.
args=( -noconsole )
if [ -n "${DISPLAY:-}" ]; then
  args+=( -g X11 )
else
  echo "WARN: DISPLAY is unset; Magic GUI needs the CAD X display." >&2
fi
args+=( -rcfile "$RC" )
args+=( "$SCRIPT" )

set +e
"$magic_bin" "${args[@]}"
rm -f "$SCRIPT"
exit 0
