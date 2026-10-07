#!/bin/bash
# Open a Magic VLSI GUI on a .mag design (nixpkgs magic-vlsi).
# Used after Mag→MAX import so the original layout sits next to MAX.
# Usage: open_mag.sh <design_dir> <top_cell> [family]
set -uo pipefail

DIR="${1:?design directory}"
TOP="${2:?top cell}"
FAMILY="${3:-sky130A}"
PDK_ROOT="${PDK_ROOT:-/mmi-pdks}"

DIR="$(cd "$DIR" && pwd)"

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

export PDK_ROOT
export PDK="$pdk_name"
export PDKPATH="${PDK_ROOT}/${pdk_name}"
export MAGTYPE=mag

# Same font-instance strip as mag2gds.sh. Otherwise the compare window
# segfaults on caravel motto/copyright before the chip is drawn.
find "$DIR" -type f -name '*.mag' -print 2>/dev/null | while read -r f; do
  grep -q '^use font_' "$f" 2>/dev/null || continue
  grep -v '^use font_' "$f" > "$f.nofont" && mv -f "$f.nofont" "$f"
  echo "stripped PDK font instances from $f"
done || true

TECHFILE="$PDKPATH/libs.tech/magic/${pdk_name}.tech"
SCRIPT="$(mktemp /tmp/open_mag_XXXXXX.tcl)"

{
  echo "catch {"
  echo "  set _want [string tolower {$pdk_name}]"
  echo "  set _fam  [string tolower {$FAMILY}]"
  echo "  set _have [string tolower [tech name]]"
  echo "  if {\$_have != \$_want && \$_have != \$_fam && [file exists {$TECHFILE}]} {"
  echo "    tech load {$TECHFILE}"
  echo "  }"
  echo "}"
  echo "drc off"
  echo "addpath {$DIR}"
  find "$DIR" -type d \( -name .git -o -name maglef -o -name max_import \) -prune -o \
      -type f -name '*.mag' -print 2>/dev/null | while read -r f; do dirname "$f"; done \
      | sort -u | while read -r d; do
    echo "addpath {$d}"
  done
  if [ -d "$PDKPATH/libs.ref" ]; then
    find "$PDKPATH/libs.ref" -type d -name mag 2>/dev/null | sort | while read -r d; do
      echo "addpath {$d}"
    done
    find "$PDKPATH/libs.ref" -type d -name maglef 2>/dev/null | sort | while read -r d; do
      echo "addpath {$d}"
    done
  fi
  echo "load {$TOP} -force -dereference"
  echo "select top cell"
  echo "expand"
  echo "catch { view }"
} > "$SCRIPT"

echo "Magic GUI: $magic_bin"
echo "PDK:       $PDKPATH"
echo "RC:        ${RC:-none}"
echo "Top:       $TOP"
echo "Dir:       $DIR"

cd "$DIR"
# Interactive layout window (not -dnull). Magic's -g is graphics type (X11),
# not window geometry. Force X11 so the CAD Xvnc session does not need Cairo.
args=( -noconsole )
if [ -n "${DISPLAY:-}" ]; then
  args+=( -g X11 )
else
  echo "WARN: DISPLAY is unset; Magic GUI needs the CAD X display." >&2
fi
if [ -n "$RC" ]; then
  args+=( -rcfile "$RC" )
fi
args+=( "$SCRIPT" )

set +e
"$magic_bin" "${args[@]}"
rm -f "$SCRIPT"
exit 0
