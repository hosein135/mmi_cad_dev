#!/bin/bash
# Tapeout-quality Mag → GDS using Magic VLSI (not the Tcl paint dumper).
# Usage: mag2gds.sh <design_dir> <top_cell> <gds_out> [family]
set -euo pipefail

DIR="${1:?design directory}"
TOP="${2:?top cell}"
OUT="${3:?output .gds}"
FAMILY="${4:-sky130A}"
PDK_ROOT="${PDK_ROOT:-/mmi-pdks}"

DIR="$(cd "$DIR" && pwd)"
OUTDIR="$(dirname "$OUT")"
mkdir -p "$OUTDIR"
OUT="$(cd "$OUTDIR" && pwd)/$(basename "$OUT")"

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

# open_pdks layout: $PDK_ROOT/<pdk>/libs.tech/magic/<pdk>.magicrc
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
    "$PDK_ROOT/sky130A/libs.tech/magic/sky130A.magicrc" \
    "$PDK_ROOT/gf180mcuD/libs.tech/magic/gf180mcuD.magicrc" \
    "$PDK_ROOT/ihp-sg13g2/libs.tech/magic/ihp-sg13g2.magicrc"
do
  if [ -f "$cand" ]; then
    RC="$cand"
    break
  fi
done

if [ -z "$RC" ]; then
  echo "ERROR: No Magic .magicrc under PDK_ROOT=$PDK_ROOT" >&2
  echo "Tapeout mag2gds needs an open_pdks-style Magic rc:" >&2
  echo "  \$PDK_ROOT/sky130A/libs.tech/magic/sky130A.magicrc" >&2
  echo "Import a PDK from MAX first (File → Import PDK), or copy a .magicrc there." >&2
  exit 3
fi

export PDK_ROOT
export PDK="$pdk_name"
export PDKPATH="${PDK_ROOT}/${pdk_name}"
export MAGTYPE=mag

SCRIPT="$(mktemp /tmp/mag2gds_XXXXXX.tcl)"
cleanup() { rm -f "$SCRIPT"; }
trap cleanup EXIT

TECHFILE="$PDKPATH/libs.tech/magic/${pdk_name}.tech"

{
  echo "drc off"
  echo "crashbackups stop"
  # Some .magicrc files hard-code the build prefix: make sure the PDK tech is
  # really loaded (otherwise Magic silently keeps its built-in tech and every
  # cell loads empty).
  echo "catch {"
  echo "  set _want [string tolower {$pdk_name}]"
  echo "  set _fam  [string tolower {$FAMILY}]"
  echo "  set _have [string tolower [tech name]]"
  echo "  if {\$_have != \$_want && \$_have != \$_fam && [file exists {$TECHFILE}]} {"
  echo "    puts \"mag2gds: rc loaded tech '\$_have'; loading {$TECHFILE}\""
  echo "    tech load {$TECHFILE}"
  echo "  }"
  echo "  puts \"mag2gds: tech [tech name], lambda [tech lambda]\""
  echo "}"
  echo "gds rescale false"
  echo "gds readonly false"
  # Full-chip Caravel stays hierarchical. Flattening caravel_core plus the
  # example counter is hundreds of thousands of stdcells.
  if [ "${MAG2GDS_KEEP_HIER:-0}" = "1" ]; then
    echo "cif *hier write enable"
    echo "puts \"mag2gds: hierarchical GDS\""
  else
    echo "cif *hier write disable"
    echo "cif *array write disable"
  fi
  echo "addpath {$DIR}"
  # Every directory that contains .mag in the design. Skip maglef abstracts.
  find "$DIR" -type d \( -name .git -o -name maglef -o -name max_import \) -prune -o \
      -type f -name '*.mag' -print 2>/dev/null | while read -r f; do dirname "$f"; done \
      | sort -u | while read -r d; do
    echo "addpath {$d}"
  done
  # Shared PDK views: full mag first so maglef abstracts cannot shadow them.
  # MAGTYPE=mag also prefers mag/, but a direct maglef path still wins if first.
  if [ -d "$PDKPATH/libs.ref" ]; then
    find "$PDKPATH/libs.ref" -type d -name mag 2>/dev/null | sort | while read -r d; do
      echo "addpath {$d}"
    done
    find "$PDKPATH/libs.ref" -type d -name maglef 2>/dev/null | sort | while read -r d; do
      echo "addpath {$d}"
    done
  fi
  # -force: accept cells whose "tech" header differs from the loaded tech
  # (caravel .mag files carry "tech \$PDK"; PDK is exported above, but older
  # Magic builds do not expand it). Unknown options only print a notice.
  echo "load {$TOP} -force -dereference"
  echo "select top cell"
  if [ "${MAG2GDS_KEEP_HIER:-0}" != "1" ]; then
    echo "expand"
  fi
  echo "catch {puts \"mag2gds: top [cellname list window], bbox [box values]\"}"
  echo "gds write {$OUT}"
  echo "quit -noprompt"
} > "$SCRIPT"

echo "Magic: $magic_bin"
echo "PDK:   $PDKPATH"
echo "RC:    $RC"
echo "Top:   $TOP"
echo "GDS:   $OUT"

cd "$DIR"
"$magic_bin" -noconsole -dnull -rcfile "$RC" "$SCRIPT" </dev/null

if [ ! -s "$OUT" ]; then
  echo "ERROR: Magic did not write $OUT" >&2
  exit 4
fi
echo "Wrote $OUT ($(wc -c < "$OUT") bytes)"
