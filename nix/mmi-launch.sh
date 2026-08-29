# Runs inside the mmi-cad FHS namespace (bubblewrap). Host launcher: run.sh
set -euo pipefail

info()  { printf '%s\n' "[mmi-cad] $*"; }
warn()  { printf '%s\n' "[mmi-cad] WARN: $*" >&2; }
error() { printf '%s\n' "[mmi-cad] ERROR: $*" >&2; }

MMI_CAD_ROOT="${MMI_CAD_ROOT:-${PWD:-.}}"
MMI_TARBALL_NAME="${MMI_TARBALL_NAME:-mmi_pd_040526.tar.gz}"
MMI_DIR_NAME="${MMI_DIR_NAME:-mmi_pd_040526}"
CAD_HOME="/mmi-home"
CAD="${CAD_HOME}/cad"

mkdir -p "${CAD_HOME}" "${CAD}" /mmi-pdks 2>/dev/null || true

# Keep a copy of the real login home for Xauthority, then use the CAD prefix as HOME
# so MAX picks up .maxrc without writing into the user's actual homedir.
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

install_vendor() {
  local tarball="" name
  for name in \
      "${MMI_CAD_ROOT}/${MMI_TARBALL_NAME}" \
      "${MMI_CAD_ROOT}/mmi_pd_040526.tar.gz" \
      "${MMI_CAD_ROOT}/mmi_pd_040526.tar"
  do
    if [ -f "${name}" ]; then
      tarball="${name}"
      break
    fi
  done
  if [ -z "${tarball}" ]; then
    error "Vendor tarball not found."
    error "Place ${MMI_TARBALL_NAME} in ${MMI_CAD_ROOT} and re-run."
    exit 1
  fi

  info "Installing Micro Magic CAD from $(basename "${tarball}") ..."
  mkdir -p "${CAD}"
  rm -rf "${CAD:?}/${MMI_DIR_NAME}" "${CAD}/mmi_pd" "${CAD}/mmi_local"
  case "${tarball}" in
    *.gz|*.tgz) tar -xzf "${tarball}" -C "${CAD}" ;;
    *)          tar -xf "${tarball}" -C "${CAD}" ;;
  esac

  if [ ! -d "${CAD}/${MMI_DIR_NAME}" ]; then
    local found
    found="$(find "${CAD}" -mindepth 1 -maxdepth 1 -type d -name 'mmi_pd*' | head -n 1 || true)"
    if [ -n "${found}" ]; then
      MMI_DIR_NAME="$(basename "${found}")"
    else
      error "Tarball did not contain ${MMI_DIR_NAME}/"
      exit 1
    fi
  fi

  ln -sfn "${MMI_DIR_NAME}" "${CAD}/mmi_pd"
  if [ -d "${CAD}/mmi_pd/bin.i486-linux" ]; then
    ln -sfn bin.i486-linux "${CAD}/mmi_pd/bin"
  elif [ -d "${CAD}/mmi_pd/bin.linux" ]; then
    ln -sfn bin.linux "${CAD}/mmi_pd/bin"
  fi
  if [ -d "${CAD}/mmi_pd/mmi_local.sample" ]; then
    cp -a "${CAD}/mmi_pd/mmi_local.sample" "${CAD}/mmi_local"
  else
    mkdir -p "${CAD}/mmi_local"
  fi
  info "Vendor tools installed under ${CAD}/mmi_pd"
}

if [ "${MMI_FORCE_INSTALL:-0}" = "1" ] || [ ! -e "${CAD}/mmi_pd/bin/max" ]; then
  install_vendor
fi

# Overlay MAX PDK menus from the Nix-provided tree (always refresh).
mkdir -p "${CAD}/mmi_local/max/pdk/samples" "${CAD}/mmi_pd/app-defaults"
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
if [ -f "${CAD}/mmi_pd/app-defaults/Mmi" ]; then
  for app in Max max Nst nst; do
    cp -f "${CAD}/mmi_pd/app-defaults/Mmi" "${CAD}/mmi_pd/app-defaults/${app}"
  done
fi

MARKER="# mmi-pdk-nix"
ensure_maxrc() {
  local f="$1"
  mkdir -p "$(dirname "${f}")"
  touch "${f}"
  if ! grep -q "${MARKER}" "${f}" 2>/dev/null; then
    printf '\n%s\nsource /mmi-bundle/maxrc\n' "${MARKER}" >> "${f}"
  fi
}
ensure_maxrc "${CAD_HOME}/.maxrc"
ensure_maxrc "${CAD}/mmi_local/max/.maxrc"

export MMI_TOOLS="${CAD}/mmi_pd"
export MMI_LOCAL="${CAD}/mmi_local"
export MMI_PDK_DIR="/mmi-bundle"
export MMI_BROWSER="${MMI_BROWSER:-xdg-open}"
export PDK_ROOT="${PDK_ROOT:-/mmi-pdks}"
export PDK="${PDK:-sky130A}"
export PATH="/mmi-magic/bin:${MMI_TOOLS}/bin:${PATH}"
export QT_X11_NO_MITSHM=1
export LC_ALL=C
export LANG=C
export _XNO_XFT=1
export XAPPLRESDIR="${MMI_TOOLS}/app-defaults"
if [ -f /usr/share/X11/XKeysymDB ]; then
  export XKEYSYMDB=/usr/share/X11/XKeysymDB
fi

# Materialize XLFD bitmap fonts where the host X server can read them.
FONT_CACHE="${MMI_CAD_ROOT}/.mmi-xfonts"
if [ -n "${MMI_FONTS_SRC:-}" ] && [ -d "${MMI_FONTS_SRC}" ]; then
  if [ "${MMI_FORCE_FONTS:-0}" = "1" ] || [ ! -f "${FONT_CACHE}/75dpi/fonts.dir" ]; then
    info "Installing Motif XLFD fonts → ${FONT_CACHE}"
    mkdir -p "${FONT_CACHE}"
    cp -a "${MMI_FONTS_SRC}/." "${FONT_CACHE}/"
  fi
fi
FONT_ROOT="${MMI_XFONT_ROOT:-${FONT_CACHE}}"

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
echo "  Micro Magic CAD (Nix FHS, no Docker)"
echo "=============================================="
echo "  DISPLAY=${DISPLAY:-<unset>}"
echo "  XAUTHORITY=${XAUTHORITY:-<unset>}"
echo "  PDK_ROOT=${PDK_ROOT}"
echo "  MMI_TOOLS=${MMI_TOOLS}"
echo "  Magic: $(command -v magic 2>/dev/null || echo missing)"
echo "  Font root: ${FONT_ROOT}"

if [ -f "${CAD_HOME}/.Xresources" ]; then
  xrdb -merge "${CAD_HOME}/.Xresources" 2>/dev/null || true
fi
if [ -f "${MMI_TOOLS}/app-defaults/Mmi" ]; then
  xrdb -merge "${MMI_TOOLS}/app-defaults/Mmi" 2>/dev/null || true
fi

FP_LIST=""
for sub in 75dpi misc 100dpi Type1 cyrillic; do
  d="${FONT_ROOT}/${sub}"
  if [ -d "${d}" ] && [ -f "${d}/fonts.dir" ]; then
    if [ -z "${FP_LIST}" ]; then
      FP_LIST="${d}"
    else
      FP_LIST="${FP_LIST},${d}"
    fi
    echo "  + ${d}"
  fi
done

if [ -n "${FP_LIST}" ] && [ -n "${DISPLAY:-}" ]; then
  if xset fp= "${FP_LIST}" 2>/tmp/xset-fp.err; then
    echo "  Font path replaced with Motif bitmap dirs"
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
  echo "  WARN: No bitmap font dirs found under ${FONT_ROOT}"
fi

if [ -n "${DISPLAY:-}" ]; then
  echo ""
  echo "--- Font Path ---"
  xset q 2>/dev/null | grep -A 20 "Font Path" | head -n 25 || true
  echo ""
  echo "--- Motif-critical fonts ---"
  MISSING=0
  for font in \
      "-adobe-helvetica-medium-r-normal--12-120-75-75-p-67-iso8859-1" \
      "-adobe-helvetica-medium-r-normal--14-140-75-75-p-78-iso8859-1" \
      "-misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1" \
      "fixed" "9x15"
  do
    if xlsfonts 2>/dev/null | grep -qF "${font}"; then
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
