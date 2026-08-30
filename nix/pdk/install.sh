#!/usr/bin/env bash
# Assemble a pinned PDK tree: Magic tech files + source checkouts for MAX import.
# No network. Inputs are flake-locked store paths.
set -euo pipefail

: "${out:?}"
: "${OPEN_PDKS:?}"
: "${SKYWATER_PDK:?}"
: "${GF180MCU_PDK:?}"
: "${MAGICRC_SKY:?}"
: "${MAGICRC_GF:?}"
: "${MAGICRC_IHP:?}"

export LC_ALL=C
export TZ=UTC

preproc() {
  local src="$1" dest="$2"
  shift 2
  python3 "${OPEN_PDKS}/common/preproc.py" "$@" "${src}" > "${dest}.pre"
  mv "${dest}.pre" "${dest}"
}

install_magic_tech() {
  local family="$1" techname="$2" srcdir="$3"
  shift 3
  local dest="${out}/${techname}/libs.tech/magic"
  mkdir -p "${dest}"
  local f
  for f in "${srcdir}"/*; do
    [ -f "$f" ] || continue
    local base
    base="$(basename "$f")"
    local outf="${dest}/${base}"
    case "$base" in
      *.magicrc|*.tech|*.tcl|*-BindKeys)
        if [ -f "${OPEN_PDKS}/common/preproc.py" ]; then
          preproc "$f" "$outf" "$@" || cp -f "$f" "$outf"
        else
          cp -f "$f" "$outf"
        fi
        sed -i \
          -e "s/TECHNAME/${techname}/g" \
          -e "s|STAGING_PATH|/mmi-pdks|g" \
          -e "s|MAGIC_CURRENT|libs.tech/magic|g" \
          "$outf"
        ;;
      *)
        cp -f "$f" "$outf"
        ;;
    esac
  done
  if [ -f "${dest}/${family}.tech" ] && [ ! -f "${dest}/${techname}.tech" ]; then
    cp -f "${dest}/${family}.tech" "${dest}/${techname}.tech"
  fi
  if [ -f "${dest}/${family}.tcl" ] && [ ! -f "${dest}/${techname}.tcl" ]; then
    cp -f "${dest}/${family}.tcl" "${dest}/${techname}.tcl"
  fi
}

mkdir -p "${out}/src" "${out}/sky130A/libs.tech/magic" \
  "${out}/gf180mcuD/libs.tech/magic"

cp -a "${SKYWATER_PDK}" "${out}/src/skywater-pdk"
cp -a "${GF180MCU_PDK}" "${out}/src/gf180mcu-pdk"

# IHP git checkout is multi-GB (git-lfs). Default closure ships Magic rc only.
if [ -n "${IHP_OPEN_PDK:-}" ] && [ -d "${IHP_OPEN_PDK}" ]; then
  if [ -d "${IHP_OPEN_PDK}/ihp-sg13g2" ]; then
    cp -a "${IHP_OPEN_PDK}/ihp-sg13g2" "${out}/ihp-sg13g2"
  else
    mkdir -p "${out}/src/ihp-open-pdk"
    cp -a "${IHP_OPEN_PDK}/." "${out}/src/ihp-open-pdk/"
  fi
fi

if [ -d "${OPEN_PDKS}/sky130/magic" ]; then
  install_magic_tech sky130 sky130A "${OPEN_PDKS}/sky130/magic" -DMETAL5
fi
if [ -d "${OPEN_PDKS}/gf180mcu/magic" ]; then
  install_magic_tech gf180mcu gf180mcuD "${OPEN_PDKS}/gf180mcu/magic"
fi

# Controlled Magic startup files (stable, no m4/TECHNAME leftovers).
install -Dm644 "${MAGICRC_SKY}" "${out}/sky130A/libs.tech/magic/sky130A.magicrc"
install -Dm644 "${MAGICRC_GF}" "${out}/gf180mcuD/libs.tech/magic/gf180mcuD.magicrc"

mkdir -p "${out}/ihp-sg13g2/libs.tech/magic"
install -Dm644 "${MAGICRC_IHP}" "${out}/ihp-sg13g2/libs.tech/magic/ihp-sg13g2.magicrc"

{
  echo "mmi-pdks: flake-locked sources"
  echo "  src/skywater-pdk"
  echo "  src/gf180mcu-pdk"
  echo "  ihp-sg13g2/libs.tech/magic (Nix magicrc; full IHP tree optional)"
  echo "  sky130A/libs.tech/magic (open_pdks + Nix magicrc)"
  echo "  gf180mcuD/libs.tech/magic"
  echo "  ihp-sg13g2"
} > "${out}/SOURCES"

test -f "${out}/sky130A/libs.tech/magic/sky130A.magicrc"
test -d "${out}/src/skywater-pdk"
test -d "${out}/src/gf180mcu-pdk"
test -f "${out}/ihp-sg13g2/libs.tech/magic/ihp-sg13g2.magicrc"
