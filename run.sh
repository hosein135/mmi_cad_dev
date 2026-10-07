#!/usr/bin/env bash
# Micro Magic CAD — Nix launcher for x86_64 Linux (bare metal, VM, or WSL2).
set -euo pipefail

info()  { printf '%s\n' "[run] $*"; }
warn()  { printf '%s\n' "[run] $*" >&2; }
error() { printf '%s\n' "[run] ERROR: $*" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"
MMI_ORIG_ARGS=("$@")

# shellcheck source=nix/host-linux.sh
. "${SCRIPT_DIR}/nix/host-linux.sh"

# sudo looks like "Nix is not installed" because root does not see the
# desktop user's profile. Switch back before checks or installs.
if [ "${1:-}" != "--help" ] && [ "${1:-}" != "-h" ]; then
  mmi_rerun_as_desktop_user "$@" || exit 1
fi

CMD_ARGS=()
PREP_ONLY=false
CLEAN=false

for arg in "$@"; do
  case "$arg" in
    --help|-h)
      cat <<'EOF'
Micro Magic CAD — run via Nix flake (pure eval, NixOS 25.05).

  ./run.sh              CAD shell (host X if DISPLAY is set, else Nix Xvnc)
  ./run.sh max          start MAX
  ./run.sh --prep-only  build vendor + wrapper into the Nix store
  ./run.sh --clean      remove data/home (CAD overlay)

Needs x86_64 Linux: bare metal, a VM with a GUI desktop, or WSL2
(not WSL1, not Windows-native). Run as your desktop user. sudo is
accepted and continues as that user. Missing git and curl are installed
with that distro's package manager. Nix 2.28+ (NixOS 25.05) is
installed or upgraded automatically when the current one cannot be used.
First install keeps ~1 GiB in the Nix store and needs ~6 GiB free.

On a graphical VM, windows open on your desktop. If CAD starts its own
X server, open the printed http://127.0.0.1:6080 URL.
Force VNC: MMI_USE_XVNC=1 ./run.sh max
Force host X: MMI_USE_HOST_X=1 DISPLAY=:0 ./run.sh max
EOF
      exit 0
      ;;
    --prep-only) PREP_ONLY=true ;;
    --clean) CLEAN=true ;;
    *.tar|*.tar.gz|*.tgz)
      warn "Ignoring $arg — vendor sources are in git (vendor/mmi)."
      ;;
    *) CMD_ARGS+=("$arg") ;;
  esac
done

[ ${#CMD_ARGS[@]} -eq 0 ] && CMD_ARGS=("/bin/bash")

# Preflight before Nix, vendor checks, or any store writes.
mmi_check_linux_host || exit 1
mmi_check_free_space || exit 1
mmi_ensure_git_and_curl || exit 1

if [ "${CLEAN}" = true ]; then
  info "Removing data/home (CAD overlay) ..."
  rm -rf "${SCRIPT_DIR}/data/home"/*
fi

mmi_source_nix
NIX_BIN=""
if ! NIX_BIN="$(mmi_find_nix)"; then
  mmi_install_nix || exit 1
  mmi_source_nix
  if ! NIX_BIN="$(mmi_find_nix)"; then
    error "Nix install finished, but the nix command is still missing."
    exit 1
  fi
fi
mmi_check_existing_nix || exit 1

if [ ! -d "${SCRIPT_DIR}/vendor/mmi/src/max4.3.16" ]; then
  error "vendor/mmi/src/max4.3.16 is missing. CAD sources must be in git."
  error "If you have vendor/mmi_pd_040526.tar.gz, run: bash nix/rebuild/extract.sh"
  exit 1
fi

if [ ! -f "${SCRIPT_DIR}/flake.lock" ]; then
  error "flake.lock is missing. This repository must ship a lock file for reproducibility."
  exit 1
fi

mmi_ensure_flake_git_files || exit 1
mmi_warn_if_git_dirty

if [ "${PREP_ONLY}" = true ]; then
  info "Building mmi-vendor (pure flake eval, nixpkgs 25.05) ..."
  "${NIX_BIN}" build --accept-flake-config "${SCRIPT_DIR}#mmi-vendor" --out-link "${SCRIPT_DIR}/vendor/result"
  info "Building mmi-cad wrapper ..."
  "${NIX_BIN}" build --accept-flake-config "${SCRIPT_DIR}#mmi-cad" --no-link
  info "Done. Binaries stay in the Nix store (not copied into git)."
  exit 0
fi

export MMI_CAD_ROOT="${SCRIPT_DIR}"
mkdir -p "${SCRIPT_DIR}/data/pdks" "${SCRIPT_DIR}/data/workspace" "${SCRIPT_DIR}/data/home"
info "PDK_ROOT (host)  → ${SCRIPT_DIR}/data/pdks  (empty until you import a PDK in MAX)"
info "Workspace        → ${SCRIPT_DIR}/data/workspace"
info "Starting CAD via nix run (Nix Xvnc) ..."
"${NIX_BIN}" run --accept-flake-config "${SCRIPT_DIR}#mmi-cad" -- "${CMD_ARGS[@]}"
