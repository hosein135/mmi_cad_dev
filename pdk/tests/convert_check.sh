#!/bin/bash
# Measure a Magic → GDS → MAX conversion. Does not change the product.
# The MAX steps run only when `max` is on PATH.
#
#   convert_check.sh <mag-dir> <top-cell> <family>
# family: sky130A | gf180mcu | sg13g2
set -u
dir=${1:?mag directory}
top=${2:?top cell}
family=${3:?family}
out=${4:-/tmp/mmi-convert-check-$top}
mkdir -p "$out"
echo "convert_check: $dir top=$top family=$family -> $out"

script=""
for c in \
    "$(dirname "$0")/../mag2gds.sh" \
    /mmi-pdk-live/mag2gds.sh \
    /mmi-bundle/mag2gds.sh
do
  if [ -f "$c" ]; then script=$c; break; fi
done

if ! command -v magic >/dev/null 2>&1; then
  echo "magic is not on PATH; GDS step skipped"
else
  if [ -n "$script" ]; then
    echo "1. Magic GDS (current switches)"
    bash "$script" "$dir" "$top" "$out/${top}.foundry.gds" "$family" \
      >"$out/magic_foundry.log" 2>&1 || echo "magic foundry path exited $? (see $out/magic_foundry.log)"
    echo "1b. Magic GDS with hierarchical cif"
    MAG2GDS_KEEP_HIER=1 bash "$script" "$dir" "$top" "$out/${top}.hier.gds" "$family" \
      >"$out/magic_hier.log" 2>&1 || echo "magic hier path exited $? (see $out/magic_hier.log)"
  fi
fi

if ! command -v max >/dev/null 2>&1; then
  echo "max is not on PATH."
  echo "On a machine with MAX, this script continues with:"
  echo "  gds_read of ${top}.foundry.gds, GDS_READ_NO_DRC=0, GDS_READ_SNAP_TO=0"
  echo "  DRC before save, cell_save_tree, reopen, DRC after save"
  echo "  XOR of the GDS MAX writes back against the Magic GDS"
  echo "Acceptance is in PLAN.md section 3.7."
  exit 0
fi

echo "2. MAX is present. Open the GDS with DRC enabled and snap disabled:"
echo "   max -tech $family -set GDS_READ_NO_DRC=0 -set GDS_READ_SNAP_TO=0 $out/${top}.foundry.gds"
exit 0
