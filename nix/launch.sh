# Runs inside the mmi-cad FHS namespace (bubblewrap). Host launcher: run.sh
set -euo pipefail

info()  { printf '%s\n' "[mmi-cad] $*"; }
warn()  { printf '%s\n' "[mmi-cad] WARN: $*" >&2; }
error() { printf '%s\n' "[mmi-cad] ERROR: $*" >&2; }

MMI_CAD_ROOT="${MMI_CAD_ROOT:-${PWD:-.}}"
CAD_HOME="/mmi-home"
CAD="${CAD_HOME}/cad"
MMI_TOOLS="${MMI_TOOLS:-/mmi-vendor/mmi}"

mkdir -p "${CAD_HOME}" "${CAD}" /mmi-pdks 2>/dev/null || true

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
chmod -R u+w "${CAD}/mmi_local" 2>/dev/null || true

if [ -d /mmi-bundle ]; then
  cp -f /mmi-bundle/pdk_import.tcl "${CAD}/mmi_local/max/pdk/" 2>/dev/null || true
  cp -f /mmi-bundle/mag_import.tcl "${CAD}/mmi_local/max/pdk/" 2>/dev/null || true
  cp -f /mmi-bundle/mag2gds.sh "${CAD}/mmi_local/max/pdk/" 2>/dev/null || true
  chmod 755 "${CAD}/mmi_local/max/pdk/mag2gds.sh" 2>/dev/null || true
  if [ -d /mmi-bundle/samples ]; then
    cp -a /mmi-bundle/samples/. "${CAD}/mmi_local/max/pdk/samples/"
  fi
  if [ -f /mmi-bundle/app-defaults/Mmi ]; then
    cp -f /mmi-bundle/app-defaults/Mmi "${CAD}/mmi_pd/app-defaults/Mmi"
  fi
  if [ -f /mmi-bundle/Xresources ]; then
    cp -f /mmi-bundle/Xresources "${CAD_HOME}/.Xresources"
  fi
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
  if ! grep -q "${MARKER}" "${f}" 2>/dev/null; then
    printf '\n%s\nsource /mmi-bundle/maxrc\n' "${MARKER}" >> "${f}"
  fi
}
ensure_maxrc "${CAD_HOME}/.maxrc"
ensure_maxrc "${CAD}/mmi_local/max/.maxrc"

export MMI_LOCAL="${CAD}/mmi_local"
export MMI_PDK_DIR="/mmi-bundle"
export MMI_BROWSER="${MMI_BROWSER:-xdg-open}"
export PDK_ROOT="${PDK_ROOT:-/mmi-pdks}"
export PDK="${PDK:-sky130A}"
export MN_BIN_DIR="${MN_BIN_DIR:-bin.linux}"
export MALLOC_ARENA_MAX="${MALLOC_ARENA_MAX:-1}"
export PATH="/mmi-magic/bin:${MMI_TOOLS}/bin:${PATH}"
export QT_X11_NO_MITSHM=1
export LC_ALL=C
export LANG=C
export _XNO_XFT=1
export XAPPLRESDIR="${MMI_TOOLS}/app-defaults"
if [ -f /usr/share/X11/XKeysymDB ]; then
  export XKEYSYMDB=/usr/share/X11/XKeysymDB
fi

# XLFD bitmap fonts from the Nix store (no host font cache copy).
FONT_ROOT="${MMI_XFONT_ROOT:-${MMI_FONTS_SRC:-}}"
if [ -n "${FONT_ROOT}" ] && command -v wslpath >/dev/null 2>&1 && grep -qi microsoft /proc/version 2>/dev/null; then
  FONT_ROOT="$(wslpath -w "${MMI_FONTS_SRC}")"
fi

cmd="${1:-/bin/bash}"
need_display=1
case "${cmd}" in
  /bin/bash|bash|/bin/sh|sh|-bash) need_display=0 ;;
esac

if [ -z "${DISPLAY:-}" ]; then
  if [ "${need_display}" = "1" ]; then
    error "DISPLAY is not set. Start a graphical session (or VcXsrv on WSL) first."
    exit 1
  fi
  warn "DISPLAY is not set — GUI tools will not work."
fi

echo "=============================================="
echo "  Micro Magic CAD (Nix FHS, x86_64)"
echo "=============================================="
echo "  DISPLAY=${DISPLAY:-<unset>}"
echo "  XAUTHORITY=${XAUTHORITY:-<unset>}"
echo "  PDK_ROOT=${PDK_ROOT}"
echo "  MMI_TOOLS=${MMI_TOOLS}"
echo "  Magic: $(command -v magic 2>/dev/null || echo missing)"
echo "  Font root: ${FONT_ROOT:-<unset>}"

if [ -f "${CAD_HOME}/.Xresources" ]; then
  xrdb -merge "${CAD_HOME}/.Xresources" 2>/dev/null || true
fi
if [ -f "${MMI_TOOLS}/app-defaults/Mmi" ]; then
  xrdb -merge "${MMI_TOOLS}/app-defaults/Mmi" 2>/dev/null || true
fi

FP_LIST=""
if [ -n "${MMI_FONTS_SRC:-}" ] && [ -d "${MMI_FONTS_SRC}" ]; then
  for sub in 75dpi misc 100dpi Type1 cyrillic; do
    d="${MMI_FONTS_SRC}/${sub}"
    if [ -d "${d}" ] && [ -f "${d}/fonts.dir" ]; then
      if [ -z "${FP_LIST}" ]; then
        FP_LIST="${d}"
      else
        FP_LIST="${FP_LIST},${d}"
      fi
      echo "  + ${d}"
    fi
  done
fi

if [ -n "${FP_LIST}" ] && [ -n "${DISPLAY:-}" ]; then
  if xset fp= "${FP_LIST}" 2>/tmp/xset-fp.err; then
    echo "  Font path replaced with XLFD bitmap dirs"
  else
    echo "  WARN: xset fp= failed:"
    cat /tmp/xset-fp.err 2>/dev/null || true
    old_ifs="${IFS}"
    IFS=','
    for d in ${FP_LIST}; do
      xset +fp "${d}" 2>/dev/null || true
    done
    IFS="${old_ifs}"
  fi
  xset fp rehash 2>/dev/null || true
elif [ -n "${DISPLAY:-}" ]; then
  echo "  WARN: No bitmap font dirs found in ${MMI_FONTS_SRC:-<unset>}"
fi

if [ -n "${DISPLAY:-}" ]; then
  echo ""
  echo "--- Font Path ---"
  xset q 2>/dev/null | grep -A 20 "Font Path" | head -n 25 || true
  echo ""
  echo "--- XLFD fonts ---"
  MISSING=0
  for font in \
      "-adobe-helvetica-medium-r-normal--12-120-75-75-p-67-iso8859-1" \
      "-adobe-helvetica-medium-r-normal--14-140-75-75-p-78-iso8859-1" \
      "-misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1" \
      "fixed" "9x15"
  do
    if xlsfonts 2>/dev/null | grep -qF -e "${font}"; then
      echo "  [OK] ${font}"
    else
      echo "  [MISSING] ${font}"
      MISSING=1
    fi
  done
  if [ "${MISSING}" = "1" ]; then
    echo ""
    echo "  WARN: Some XLFD fonts missing. max/nst may still look wrong."
  fi
fi

echo ""
echo "=============================================="
echo "  Starting: $*"
echo "=============================================="
echo ""

if [ "$#" -eq 0 ]; then
  exec /bin/bash
fi
exec "$@"
