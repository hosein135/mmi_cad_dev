#!/bin/bash
# Tapeout-quality Mag → GDS using Magic VLSI (not the Tcl paint dumper).
# Usage: mag2gds.sh <design_dir> <top_cell> <gds_out> [family]
set -euo pipefail

DIR="${1:?design directory}"
TOP="${2:?top cell}"
OUT="${3:?output .gds}"
FAMILY="${4:-sky130A}"
PDK_ROOT="${PDK_ROOT:-/opt/pdks}"

DIR="$(cd "$DIR" && pwd)"
OUTDIR="$(dirname "$OUT")"
mkdir -p "$OUTDIR"
OUT="$(cd "$OUTDIR" && pwd)/$(basename "$OUT")"

magic_bin="$(command -v magic || true)"
if [ -z "$magic_bin" ] && [ -x /opt/magic/bin/magic ]; then
  magic_bin=/opt/magic/bin/magic
fi
if [ -z "$magic_bin" ]; then
  echo "ERROR: magic is not installed (expected /opt/magic/bin/magic)." >&2
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
  echo "Tapeout mag2gds needs an open_pdks-style PDK, for example:" >&2
  echo "  \$PDK_ROOT/sky130A/libs.tech/magic/sky130A.magicrc" >&2
  echo "Put that tree in the shared folder (host ./pdks → /opt/pdks)," >&2
  echo "or use the Tcl paint-dump converter instead." >&2
  exit 3
fi

export PDK_ROOT
export PDK="$pdk_name"
export PDKPATH="${PDK_ROOT}/${pdk_name}"
export MAGTYPE=mag

SCRIPT="$(mktemp /tmp/mag2gds_XXXXXX.tcl)"
cleanup() { rm -f "$SCRIPT"; }
trap cleanup EXIT

{
  echo "drc off"
  echo "crashbackups stop"
  echo "gds rescale false"
  echo "gds readonly false"
  echo "cif *hier write disable"
  echo "cif *array write disable"
  echo "addpath {$DIR}"
  # Every directory that contains .mag in the design (Tcl 8.x-safe walk via find)
  find "$DIR" -type d \( -name .git -o -name maglef -o -name max_import \) -prune -o \
      -type f -name '*.mag' -printf '%h\n' 2>/dev/null | sort -u | while read -r d; do
    echo "addpath {$d}"
  done
  # Shared PDK mag views (stdcells, primitives)
  if [ -d "$PDKPATH/libs.ref" ]; then
    find "$PDKPATH/libs.ref" -type d \( -name mag -o -name maglef \) 2>/dev/null | while read -r d; do
      echo "addpath {$d}"
    done
  fi
  echo "load $TOP -dereference"
  echo "select top cell"
  echo "expand"
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
