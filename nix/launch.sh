# Runs inside the mmi-cad FHS namespace (bubblewrap). Host launcher: run.sh
# Nix Xvnc functions are prepended (mmi_start_nix_x).
set -euo pipefail

info()  { printf '%s\n' "[mmi-cad] $*"; }
warn()  { printf '%s\n' "[mmi-cad] WARN: $*" >&2; }
error() { printf '%s\n' "[mmi-cad] ERROR: $*" >&2; }

MMI_CAD_ROOT="${MMI_CAD_ROOT:-${PWD:-.}}"
CAD_HOME="/mmi-home"
CAD="${CAD_HOME}/cad"
MMI_TOOLS="${MMI_TOOLS:-/mmi-vendor/mmi}"
MMI_LOCAL="${MMI_LOCAL:-${CAD}/mmi_local}"

# Return 0 if $1 is a plausible X font directory path for this machine.
mmi_font_dir_ok() {
  local d="$1"
  [ -n "${d}" ] && [ -d "${d}" ] && [ -f "${d}/fonts.dir" ]
}

# Paths under these prefixes are visible to the client but often not to the X server.
mmi_path_needs_font_mirror() {
  case "$1" in
    /mmi-vendor/*|/mmi-home/*|/mmi-bundle/*|/mmi-magic/*|/mmi-pdks/*) return 0 ;;
  esac
  return 1
}

# Directory the X server should use for MAX Helvetica-Bold PCF fonts.
# Override anytime with MMI_MAX_FONTS_DIR (must contain fonts.dir).
mmi_resolve_max_font_dir() {
  local src cache

  if mmi_font_dir_ok "${MMI_MAX_FONTS_DIR:-}"; then
    printf '%s' "${MMI_MAX_FONTS_DIR}"
    return 0
  fi

  src="${MMI_TOOLS}/max/fonts"
  if mmi_font_dir_ok "${src}" && ! mmi_path_needs_font_mirror "${src}"; then
    printf '%s' "${src}"
    return 0
  fi

  if mmi_font_dir_ok "${MMI_LOCAL:-}/max/fonts" && ! mmi_path_needs_font_mirror "${MMI_LOCAL}/max/fonts"; then
    printf '%s' "${MMI_LOCAL}/max/fonts"
    return 0
  fi

  if mmi_font_dir_ok "${src}"; then
    cache="${MMI_FONT_CACHE:-${MMI_CAD_ROOT}/data/fonts/max}"
    mkdir -p "${cache}"
    if [ ! -f "${cache}/fonts.dir" ] || [ "${src}/fonts.dir" -nt "${cache}/fonts.dir" ]; then
      cp -a "${src}/." "${cache}/"
      command -v mkfontdir >/dev/null 2>&1 && (cd "${cache}" && mkfontdir . 2>/dev/null || true)
    fi
    if mmi_font_dir_ok "${cache}"; then
      printf '%s' "${cache}"
      return 0
    fi
  fi

  return 1
}

# Optional writable mirror of mmi_local max fonts (host path when CAD_HOME is a bind mount).
mmi_resolve_local_max_font_dir() {
  local d

  if [ -n "${MMI_CAD_ROOT:-}" ] && mmi_font_dir_ok "${MMI_CAD_ROOT}/data/home/cad/mmi_local/max/fonts"; then
    printf '%s' "${MMI_CAD_ROOT}/data/home/cad/mmi_local/max/fonts"
    return 0
  fi
  d="${MMI_LOCAL:-}/max/fonts"
  if mmi_font_dir_ok "${d}" && ! mmi_path_needs_font_mirror "${d}"; then
    printf '%s' "${d}"
    return 0
  fi
  return 1
}

mkdir -p "${CAD_HOME}" "${CAD}" /mmi-pdks 2>/dev/null || true

# PDKs are not fetched at launch. Import later from MAX (File menu).

if [ ! -e "${MMI_TOOLS}/bin/max" ] && [ ! -e "${MMI_TOOLS}/bin/sue.exe" ] && [ ! -e "${MMI_TOOLS}/bin/nst" ]; then
  error "x86_64 CAD tools not found at ${MMI_TOOLS}."
  error "Need vendor/mmi (extracted) or vendor/mmi_pd_040526.tar.gz, then: ./run.sh --prep-only"
  exit 1
fi

if [ -d "${MMI_TOOLS}/lib/tcl8.0" ]; then
  export TCL_LIBRARY="${MMI_TOOLS}/lib/tcl8.0"
fi
if [ -d "${MMI_TOOLS}/lib/tk8.0" ]; then
  export TK_LIBRARY="${MMI_TOOLS}/lib/tk8.0"
fi
if [ -d "${MMI_TOOLS}/lib" ]; then
  export LD_LIBRARY_PATH="${MMI_TOOLS}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
fi

# Keep Xauthority in the CAD home, not the host login dir.
REAL_HOME="${HOME:-}"
if [ -n "${XAUTHORITY:-}" ] && [ -f "${XAUTHORITY}" ]; then
  cp -f "${XAUTHORITY}" "${CAD_HOME}/.Xauthority" 2>/dev/null || true
  chmod 600 "${CAD_HOME}/.Xauthority" 2>/dev/null || true
  export XAUTHORITY="${CAD_HOME}/.Xauthority"
elif [ -n "${REAL_HOME}" ] && [ -f "${REAL_HOME}/.Xauthority" ]; then
  cp -f "${REAL_HOME}/.Xauthority" "${CAD_HOME}/.Xauthority" 2>/dev/null || true
  chmod 600 "${CAD_HOME}/.Xauthority" 2>/dev/null || true
  export XAUTHORITY="${CAD_HOME}/.Xauthority"
fi
export HOME="${CAD_HOME}"

# Writable local overlay (menus, tech, samples).
mkdir -p "${CAD}/mmi_local/max/pdk/samples" "${CAD}/mmi_pd/app-defaults"
if [ ! -d "${CAD}/mmi_local/max" ] && [ -d "${MMI_TOOLS}/mmi_local.sample" ]; then
  cp -a "${MMI_TOOLS}/mmi_local.sample" "${CAD}/mmi_local"
  chmod -R u+w "${CAD}/mmi_local"
fi
if [ -d "${MMI_TOOLS}/max/fonts" ] && [ ! -d "${CAD}/mmi_local/max/fonts" ]; then
  mkdir -p "${CAD}/mmi_local/max"
  cp -a "${MMI_TOOLS}/max/fonts" "${CAD}/mmi_local/max/"
  chmod -R u+w "${CAD}/mmi_local/max/fonts" 2>/dev/null || true
fi
chmod -R u+w "${CAD}/mmi_local" 2>/dev/null || true

# Overlay PDK Tcl from the Nix bundle, then the live checkout (wins).
# Never cp -a from the Nix store: that leaves 555 dirs and the next copy dies
# under set -e (Permission denied on samples/caravel_analog_por).
if [ -d /mmi-bundle ] || [ -d /mmi-pdk-live ]; then
  mkdir -p "${CAD}/mmi_local/max/pdk/samples" "${CAD}/mmi_pd/app-defaults"
  chmod -R u+w "${CAD}/mmi_local/max/pdk" 2>/dev/null || true
  for src in /mmi-bundle /mmi-pdk-live; do
    [ -d "${src}" ] || continue
    cp -f "${src}/pdk_import.tcl" "${CAD}/mmi_local/max/pdk/" 2>/dev/null || true
    cp -f "${src}/mag_import.tcl" "${CAD}/mmi_local/max/pdk/" 2>/dev/null || true
    cp -f "${src}/mag2gds.sh" "${CAD}/mmi_local/max/pdk/" 2>/dev/null || true
    cp -f "${src}/fetch_pdk.sh" "${CAD}/mmi_local/max/pdk/" 2>/dev/null || true
    cp -f "${src}/compile_tech.sh" "${CAD}/mmi_local/max/pdk/" 2>/dev/null || true
    cp -f "${src}/fetch_caravel_mag.sh" "${CAD}/mmi_local/max/pdk/" 2>/dev/null || true
    cp -f "${src}/source_to_tech27.tcl" "${CAD}/mmi_local/max/pdk/" 2>/dev/null || true
    cp -f "${src}/maxrc" "${CAD}/mmi_local/max/pdk/" 2>/dev/null || true
    chmod 755 "${CAD}/mmi_local/max/pdk/mag2gds.sh" 2>/dev/null || true
    chmod 755 "${CAD}/mmi_local/max/pdk/fetch_pdk.sh" 2>/dev/null || true
    chmod 755 "${CAD}/mmi_local/max/pdk/compile_tech.sh" 2>/dev/null || true
    chmod 755 "${CAD}/mmi_local/max/pdk/fetch_caravel_mag.sh" 2>/dev/null || true
    chmod 644 "${CAD}/mmi_local/max/pdk/source_to_tech27.tcl" 2>/dev/null || true
    if [ -f "${src}/app-defaults/Mmi" ]; then
      cp -f "${src}/app-defaults/Mmi" "${CAD}/mmi_pd/app-defaults/Mmi" 2>/dev/null || true
    fi
    if [ -f "${src}/Xresources" ]; then
      cp -f "${src}/Xresources" "${CAD_HOME}/.Xresources" 2>/dev/null || true
    fi
  done
  sample_src=""
  if [ -d /mmi-pdk-live/samples ]; then
    sample_src=/mmi-pdk-live/samples
  elif [ -d /mmi-bundle/samples ]; then
    sample_src=/mmi-bundle/samples
  fi
  if [ -n "${sample_src}" ]; then
    chmod -R u+w "${CAD}/mmi_local/max/pdk/samples" 2>/dev/null || true
    cp -rf --no-preserve=mode,ownership "${sample_src}/." \
      "${CAD}/mmi_local/max/pdk/samples/" 2>/dev/null \
      || cp -rf "${sample_src}/." "${CAD}/mmi_local/max/pdk/samples/" 2>/dev/null \
      || true
  fi
  chmod -R u+w "${CAD}/mmi_local" 2>/dev/null || true
fi
if [ -f "${MMI_TOOLS}/app-defaults/Mmi" ]; then
  cp -f "${MMI_TOOLS}/app-defaults/Mmi" "${CAD}/mmi_pd/app-defaults/Mmi" 2>/dev/null || true
fi
if [ -f "${CAD}/mmi_pd/app-defaults/Mmi" ]; then
  for app in Max max Nst nst; do
    cp -f "${CAD}/mmi_pd/app-defaults/Mmi" "${CAD}/mmi_pd/app-defaults/${app}"
  done
fi

MARKER="# mmi-pdk-nix"
ensure_maxrc() {
  local f="$1"
  mkdir -p "$(dirname "${f}")"
  if [ -e "${f}" ] && [ ! -w "${f}" ]; then
    chmod u+w "${f}" 2>/dev/null || rm -f "${f}"
  fi
  touch "${f}"
  chmod u+w "${f}" 2>/dev/null || true
  if [ -f /mmi-pdk-live/maxrc ]; then
    if ! grep -q 'source /mmi-pdk-live/maxrc' "${f}" 2>/dev/null; then
      printf '\n%s\nsource /mmi-pdk-live/maxrc\n' "${MARKER}" >> "${f}"
    fi
  elif ! grep -q "${MARKER}" "${f}" 2>/dev/null; then
    printf '\n%s\nsource /mmi-bundle/maxrc\n' "${MARKER}" >> "${f}"
  fi
}
ensure_maxrc "${CAD_HOME}/.maxrc"
ensure_maxrc "${CAD}/mmi_local/max/.maxrc"

export MMI_LOCAL
export MMI_PDK_DIR="/mmi-bundle"
export MMI_BROWSER="${MMI_BROWSER:-xdg-open}"
export PDK_ROOT="${PDK_ROOT:-/mmi-pdks}"
export PDK="${PDK:-sky130A}"
export MN_BIN_DIR="${MN_BIN_DIR:-bin.linux}"
if resolved="$(mmi_resolve_max_font_dir 2>/dev/null)"; then
  export MMI_MAX_FONTS_DIR="${resolved}"
fi
export PATH="/mmi-magic/bin:${MMI_TOOLS}/bin:${PATH}"
export QT_X11_NO_MITSHM=1
export LC_ALL=C
export LANG=C
export _XNO_XFT=1
export XAPPLRESDIR="${MMI_TOOLS}/app-defaults"
if [ -f /usr/share/X11/XKeysymDB ]; then
  export XKEYSYMDB=/usr/share/X11/XKeysymDB
fi

# Rebuild broken MAX tech27 left by older PDK converters (before max -tech).
mmi_repair_tech27() {
  local tech source dest sh
  for tech in sky130A gf180mcu sg13g2; do
    dest=""
    source=""
    for dest in \
      "/mmi-pdks/max/tech/${tech}" \
      "${CAD_HOME}/mmi_private/max/tech/${tech}" \
      "${CAD}/mmi_local/max/tech/${tech}"
    do
      if [ -f "${dest}/${tech}.source" ]; then
        source="${dest}/${tech}.source"
        break
      fi
    done
    [ -n "$source" ] || continue
    local need=0
    if [ ! -s "${dest}/${tech}.tech27" ]; then need=1; fi
    if [ ! -s "${dest}/${tech}.palette" ]; then need=1; fi
    if [ ! -s "${dest}/${tech}.tcl" ]; then need=1; fi
    if grep -qE 'labels[[:space:]]+\*' "${dest}/${tech}.tech27" 2>/dev/null; then need=1; fi
    if grep -qE '[[:space:]]width[[:space:]]+[^[:space:]]+[[:space:]]+-' "${dest}/${tech}.tech27" 2>/dev/null; then need=1; fi
    if grep -qE '[[:space:]]spacing[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+-' "${dest}/${tech}.tech27" 2>/dev/null; then need=1; fi
    if ! grep -qE '^drc[[:space:]]*$' "${dest}/${tech}.tech27" 2>/dev/null; then need=1; fi
    if ! grep -qE '^cifstyle[[:space:]]' "${dest}/${tech}.tech27" 2>/dev/null; then need=1; fi
    if grep -qE '^set DRC_DATA\([^)]+\) [^{].* ' "${dest}/${tech}.tcl" 2>/dev/null; then need=1; fi
    [ "$need" = "1" ] || continue
    sh=""
    for cand in /mmi-pdk-live/compile_tech.sh \
      "${CAD}/mmi_local/max/pdk/compile_tech.sh" \
      /mmi-bundle/compile_tech.sh
    do
      if [ -f "$cand" ]; then sh="$cand"; break; fi
    done
    [ -n "$sh" ] || continue
    info "Repairing broken ${tech} technology files..."
    bash "$sh" "$source" "$tech" "$dest" || true
  done
}
mmi_repair_tech27

cmd="${1:-/bin/bash}"

# Prefer the VM/desktop X server when DISPLAY already points at a local socket.
# MMI_USE_XVNC=1 forces TigerVNC + browser. MMI_USE_HOST_X=1 requires host DISPLAY.
export MMI_HOST_DISPLAY="${DISPLAY:-}"
if [ "${MMI_NO_X:-0}" = "1" ]; then
  info "MMI_NO_X=1 — not starting X"
elif [ "${MMI_USE_XVNC:-0}" = "1" ]; then
  mmi_start_nix_x
elif [ "${MMI_USE_HOST_X:-0}" = "1" ]; then
  if [ -z "${DISPLAY:-}" ]; then
    error "MMI_USE_HOST_X=1 but DISPLAY is not set."
    exit 1
  fi
  info "Using host X server DISPLAY=${DISPLAY}"
elif mmi_host_x_ok; then
  info "Using desktop DISPLAY=${DISPLAY}  (MMI_USE_XVNC=1 for browser/noVNC)"
else
  mmi_start_nix_x
fi

if [ -n "${DISPLAY:-}" ] && [ "${MMI_NO_X:-0}" != "1" ]; then
  if command -v xset >/dev/null 2>&1 && ! xset q >/dev/null 2>&1; then
    warn "Cannot connect to X DISPLAY=${DISPLAY} — GUI windows will not appear."
    warn "From a graphical session try:  echo \$DISPLAY"
    warn "Or force the browser desktop: MMI_USE_XVNC=1 ./run.sh $*"
  fi
fi

echo "=============================================="
echo "  Micro Magic CAD (x86_64)"
echo "=============================================="
echo "  DISPLAY=${DISPLAY:-<unset>}   MMI_TOOLS=${MMI_TOOLS}"
echo "  PDK_ROOT=${PDK_ROOT}   Magic: $(command -v magic 2>/dev/null || echo missing)"
if [ ! -d "${PDK_ROOT}/sky130A/libs.ref" ] && [ ! -d "${PDK_ROOT}/gf180mcuD/libs.ref" ] && [ ! -d "${PDK_ROOT}/ihp-sg13g2/libs.ref" ]; then
  echo "  PDKs: empty — start MAX, then File → Import PDK (not fetched by Nix)"
fi
if [ -n "${MMI_NOVNC_URL:-}" ]; then
  echo "  GUI is in the browser, not this terminal:"
  echo "  ${MMI_NOVNC_URL}"
elif [ -n "${DISPLAY:-}" ]; then
  echo "  GUI windows open on DISPLAY=${DISPLAY} (your desktop)"
fi
if [ -n "${MMI_MAX_FONTS_DIR:-}" ]; then
  echo "  MAX fonts: ${MMI_MAX_FONTS_DIR}"
fi

if [ -f "${CAD_HOME}/.Xresources" ]; then
  xrdb -merge "${CAD_HOME}/.Xresources" 2>/dev/null || true
fi
if [ -f "${MMI_TOOLS}/app-defaults/Mmi" ]; then
  xrdb -merge "${MMI_TOOLS}/app-defaults/Mmi" 2>/dev/null || true
fi

FP_LIST=""
mmi_fp_append() {
  local d="$1"
  mmi_font_dir_ok "${d}" || return 0
  case ",${FP_LIST}," in
    *,"${d}",*) return 0 ;;
  esac
  if [ -z "${FP_LIST}" ]; then
    FP_LIST="${d}"
  else
    FP_LIST="${FP_LIST},${d}"
  fi
}

# Classic MMI look: MAX Helvetica-Bold PCF, then 75dpi Adobe, then misc-fixed.
# Skip 100dpi / Type1 / server leftovers (they change size and weight).
mmi_fp_append "${MMI_MAX_FONTS_DIR:-}"
if local_fonts="$(mmi_resolve_local_max_font_dir 2>/dev/null)"; then
  mmi_fp_append "${local_fonts}"
fi
if [ -n "${MMI_FONTS_SRC:-}" ] && [ -d "${MMI_FONTS_SRC}" ]; then
  mmi_fp_append "${MMI_FONTS_SRC}/75dpi"
  mmi_fp_append "${MMI_FONTS_SRC}/misc"
fi

if [ -n "${FP_LIST}" ] && [ -n "${DISPLAY:-}" ]; then
  if xset fp= "${FP_LIST}" 2>/tmp/xset-fp.err; then
    echo "  Fonts: MAX PCF + 75dpi Helvetica + misc-fixed"
  else
    warn "xset fp= failed; trying one directory at a time"
    cat /tmp/xset-fp.err 2>/dev/null || true
    old_ifs="${IFS}"
    IFS=','
    built=""
    for d in ${FP_LIST}; do
      trial="${d}"
      [ -n "${built}" ] && trial="${built},${d}"
      if xset fp= "${trial}" 2>/dev/null; then
        built="${trial}"
      else
        warn "skip font dir ${d}"
      fi
    done
    IFS="${old_ifs}"
  fi
  xset fp rehash 2>/dev/null || true
elif [ -n "${DISPLAY:-}" ]; then
  warn "No bitmap font dirs found"
fi

if [ -n "${DISPLAY:-}" ]; then
  MISSING=0
  for font in \
      "-adobe-helvetica-medium-r-normal--12-120-75-75-p-67-iso8859-1" \
      "-adobe-helvetica-medium-r-normal--14-140-75-75-p-78-iso8859-1" \
      "-misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1" \
      "fixed" "9x15"
  do
    if ! xlsfonts -fn "${font}" 2>/dev/null | grep -q .; then
      MISSING=1
      warn "XLFD not found: ${font}"
    fi
  done
  if [ "${MISSING}" = "0" ]; then
    echo "  XLFD: helvetica 12/14, misc-fixed 14, fixed, 9x15  OK"
  fi
fi

echo ""
echo "=============================================="
echo "  Starting: $*"
echo "=============================================="
echo ""

if [ "$#" -eq 0 ]; then
  set -- /bin/bash
fi
if [ "${MMI_NIX_X:-0}" = "1" ]; then
  "$@"
  status=$?
  mmi_x_cleanup
  exit "${status}"
fi
exec "$@"
