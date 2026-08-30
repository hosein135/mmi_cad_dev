#!/usr/bin/env bash
# Micro Magic CAD — Nix launcher (x86_64 Linux / WSL2).
set -euo pipefail

info()  { printf '%s\n' "[run] $*"; }
warn()  { printf '%s\n' "[run] $*" >&2; }
error() { printf '%s\n' "[run] ERROR: $*" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

CMD_ARGS=()
PREP_ONLY=false
CLEAN=false

for arg in "$@"; do
  case "$arg" in
    --help|-h)
      cat <<'EOF'
Micro Magic CAD — run via Nix flake.

  ./run.sh              CAD shell
  ./run.sh max          start MAX
  ./run.sh --prep-only  extract tarball (once), delete it, and build
  ./run.sh --clean      remove data/home (CAD overlay)
EOF
      exit 0
      ;;
    --prep-only) PREP_ONLY=true ;;
    --clean) CLEAN=true ;;
    *.tar|*.tar.gz|*.tgz)
      warn "Ignoring $arg — put the tarball in vendor/."
      ;;
    *) CMD_ARGS+=("$arg") ;;
  esac
done

[ ${#CMD_ARGS[@]} -eq 0 ] && CMD_ARGS=("/bin/bash")

source_nix() {
  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck source=/dev/null
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  elif [ -f "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]; then
    # shellcheck source=/dev/null
    . "${HOME}/.nix-profile/etc/profile.d/nix.sh"
  elif [ -f /etc/profile.d/nix.sh ]; then
    # shellcheck source=/dev/null
    . /etc/profile.d/nix.sh
  fi
  export NIX_CONFIG="${NIX_CONFIG:-}
experimental-features = nix-command flakes
"
}

check_host() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"
  case "${os}" in
    Linux)
      if [ "${arch}" != "x86_64" ] && [ "${arch}" != "amd64" ]; then
        error "Need x86_64 Linux (or WSL2), not ${arch}."
        exit 1
      fi
      if grep -qi microsoft /proc/version 2>/dev/null; then
        if ! uname -r | grep -qiE 'microsoft-standard|WSL2'; then
          warn "WSL1 detected — bubblewrap needs WSL2."
        fi
      fi
      ;;
    *)
      error "Unsupported OS: ${os}. Use x86_64 Linux or WSL2."
      exit 1
      ;;
  esac
}

detect_display() {
  if [ -n "${DISPLAY:-}" ]; then
    return 0
  fi
  if grep -qi microsoft /proc/version 2>/dev/null; then
    local host_ip
    host_ip="$(awk '/nameserver/ {print $2; exit}' /etc/resolv.conf)"
    [ -n "${host_ip}" ] || { error "Cannot determine Windows host IP from /etc/resolv.conf."; exit 1; }
    export DISPLAY="${host_ip}:0.0"
    warn "WSL: using DISPLAY=${DISPLAY} (start VcXsrv/Xming with access control disabled)."
    return 0
  fi
  error "DISPLAY is not set. Start an X session first."
  exit 1
}

if [ "${CLEAN}" = true ]; then
  info "Removing data/home (CAD overlay) ..."
  rm -rf "${SCRIPT_DIR}/data/home"/*
fi

source_nix
NIX_BIN=""
old_ifs="${IFS}"
IFS=':'
for dir in ${PATH}; do
  [ -n "${dir}" ] && [ "${dir}" != "." ] || continue
  if [ -x "${dir}/nix" ] && [ -f "${dir}/nix" ]; then
    NIX_BIN="${dir}/nix"
    break
  fi
done
IFS="${old_ifs}"
[ -n "${NIX_BIN}" ] || {
  error "Nix is not installed. Install from https://nixos.org/download.html"
  exit 1
}

check_host

info "Ensuring vendor tree (extract tarball if needed) ..."
bash "${SCRIPT_DIR}/nix/rebuild/extract.sh" "${SCRIPT_DIR}"

if [ ! -f "${SCRIPT_DIR}/flake.lock" ]; then
  info "Creating flake.lock ..."
  "${NIX_BIN}" flake lock "${SCRIPT_DIR}"
fi

if [ "${PREP_ONLY}" = true ]; then
  info "Building mmi-vendor (x86_64 rebuild) ..."
  "${NIX_BIN}" build "${SCRIPT_DIR}#mmi-vendor" --out-link "${SCRIPT_DIR}/vendor/result" --impure
  if [ -d "${SCRIPT_DIR}/vendor/result/mmi/bin" ]; then
    mkdir -p "${SCRIPT_DIR}/vendor/mmi/bin"
    cp -a "${SCRIPT_DIR}/vendor/result/mmi/bin/." "${SCRIPT_DIR}/vendor/mmi/bin/"
    info "x86_64 binaries copied to vendor/mmi/bin"
  fi
  info "Building mmi-cad wrapper ..."
  "${NIX_BIN}" build "${SCRIPT_DIR}#mmi-cad" --no-link --impure
  info "Done."
  exit 0
fi

detect_display

export MMI_CAD_ROOT="${SCRIPT_DIR}"
mkdir -p "${SCRIPT_DIR}/data/pdks" "${SCRIPT_DIR}/data/workspace" "${SCRIPT_DIR}/data/home"
info "PDK_ROOT (host)  → ${SCRIPT_DIR}/data/pdks"
info "Workspace        → ${SCRIPT_DIR}/data/workspace"
info "Starting CAD via nix run ..."
"${NIX_BIN}" run "${SCRIPT_DIR}#mmi-cad" --impure -- "${CMD_ARGS[@]}"
