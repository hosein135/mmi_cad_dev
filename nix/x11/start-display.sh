# Nix-provided X server (TigerVNC Xvnc) + noVNC.
# CAD tools always talk to this X server, never to VcXsrv / host X.
# Prepended onto launch.sh by flake.nix (helpers info/warn/error come from launch.sh).

mmi_x_cleanup() {
  if [ -n "${MMI_NOVNC_PID:-}" ]; then
    kill "${MMI_NOVNC_PID}" 2>/dev/null || true
  fi
  if [ -n "${MMI_XVNC_PID:-}" ]; then
    kill "${MMI_XVNC_PID}" 2>/dev/null || true
  fi
}

mmi_open_url() {
  local url="$1"
  # Native Linux / VM first; WSL helpers only as fallback.
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" >/dev/null 2>&1 || true
    return 0
  fi
  if command -v gio >/dev/null 2>&1; then
    gio open "$url" >/dev/null 2>&1 || true
    return 0
  fi
  if command -v sensible-browser >/dev/null 2>&1; then
    sensible-browser "$url" >/dev/null 2>&1 || true
    return 0
  fi
  if command -v wslview >/dev/null 2>&1; then
    wslview "$url" >/dev/null 2>&1 || true
    return 0
  fi
  if command -v explorer.exe >/dev/null 2>&1; then
    explorer.exe "$url" >/dev/null 2>&1 || true
    return 0
  fi
}

mmi_font_path() {
  local fp="" d
  for d in \
      "${MMI_TOOLS:-/mmi-vendor/mmi}/max/fonts" \
      "${MMI_FONTS_SRC:-}/75dpi" \
      "${MMI_FONTS_SRC:-}/misc" \
      /mmi-xfonts/75dpi \
      /mmi-xfonts/misc
  do
    [ -n "$d" ] && [ -d "$d" ] && [ -f "$d/fonts.dir" ] || continue
    case ",${fp}," in
      *,"${d}",*) continue ;;
    esac
    if [ -z "$fp" ]; then
      fp="$d"
    else
      fp="${fp},${d}"
    fi
  done
  printf '%s' "$fp"
}

mmi_start_nix_x() {
  local xvnc log i sock
  xvnc="$(command -v Xvnc || true)"
  if [ -z "$xvnc" ]; then
    error "Nix Xvnc is not in the FHS environment (tigervnc)."
    return 1
  fi

  MMI_X_NUM="${MMI_X_NUM:-99}"
  MMI_VNC_PORT="${MMI_VNC_PORT:-5901}"
  MMI_NOVNC_PORT="${MMI_NOVNC_PORT:-6080}"
  MMI_VNC_GEOMETRY="${MMI_VNC_GEOMETRY:-1920x1080}"
  log="${CAD_HOME:-/mmi-home}/.mmi-xvnc.log"
  mkdir -p "${CAD_HOME:-/mmi-home}" /tmp/.X11-unix
  chmod 1777 /tmp/.X11-unix 2>/dev/null || true

  export XAUTHORITY="${XAUTHORITY:-${CAD_HOME:-/mmi-home}/.Xauthority}"
  : > "${XAUTHORITY}"
  chmod 600 "${XAUTHORITY}" 2>/dev/null || true

  if [ -n "${MMI_XKB_ROOT:-}" ]; then
    export XKB_CONFIG_ROOT="${MMI_XKB_ROOT}"
  elif [ -d /usr/share/X11/xkb ]; then
    export XKB_CONFIG_ROOT=/usr/share/X11/xkb
  fi

  sock="/tmp/.X11-unix/X${MMI_X_NUM}"
  rm -f "${sock}" "/tmp/.X${MMI_X_NUM}-lock"

  local fp
  fp="$(mmi_font_path)"
  local args=(
    ":${MMI_X_NUM}"
    -geometry "${MMI_VNC_GEOMETRY}"
    -depth 24
    -rfbport "${MMI_VNC_PORT}"
    -localhost
    -SecurityTypes None
    -AlwaysShared
    -auth "${XAUTHORITY}"
    -pn
  )
  if [ -n "$fp" ]; then
    args+=(-fp "$fp")
  fi
  if [ -n "${MMI_XKB_ROOT:-}" ] && [ -d "${MMI_XKB_ROOT}" ]; then
    args+=(-xkbdir "${MMI_XKB_ROOT}")
  fi

  info "Starting Nix Xvnc :${MMI_X_NUM} (VNC 127.0.0.1:${MMI_VNC_PORT})"
  "$xvnc" "${args[@]}" >"${log}" 2>&1 &
  MMI_XVNC_PID=$!

  for i in $(seq 1 80); do
    if [ -S "${sock}" ]; then
      break
    fi
    if ! kill -0 "${MMI_XVNC_PID}" 2>/dev/null; then
      error "Xvnc exited. Log: ${log}"
      cat "${log}" >&2 || true
      return 1
    fi
    sleep 0.1
  done
  if [ ! -S "${sock}" ]; then
    error "Xvnc did not create ${sock}. Log: ${log}"
    cat "${log}" >&2 || true
    return 1
  fi

  export DISPLAY=":${MMI_X_NUM}"
  export MMI_NIX_X=1

  if command -v xsetroot >/dev/null 2>&1; then
    xsetroot -solid '#2a2a2a' 2>/dev/null || true
  fi

  local web=""
  if command -v novnc >/dev/null 2>&1; then
    web="$(command -v novnc)"
  elif [ -x /usr/bin/novnc ]; then
    web=/usr/bin/novnc
  fi
  if [ -n "$web" ]; then
    "$web" --listen "127.0.0.1:${MMI_NOVNC_PORT}" \
      --vnc "127.0.0.1:${MMI_VNC_PORT}" >"${CAD_HOME:-/mmi-home}/.mmi-novnc.log" 2>&1 &
    MMI_NOVNC_PID=$!
    MMI_NOVNC_URL="http://127.0.0.1:${MMI_NOVNC_PORT}/vnc.html?autoconnect=1&resize=remote"
    info "noVNC: ${MMI_NOVNC_URL}"
    if [ "${MMI_OPEN_BROWSER:-1}" != "0" ]; then
      mmi_open_url "${MMI_NOVNC_URL}"
    fi
  else
    warn "novnc not found — connect a VNC client to 127.0.0.1:${MMI_VNC_PORT}"
  fi

  trap mmi_x_cleanup EXIT INT TERM
}
