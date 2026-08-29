#!/usr/bin/env bash
# =============================================================================
# run.sh — Auto setup-or-start for Micro Magic CAD (x86_64 Linux / WSL2)
#
# Host bootstrap (no OS package manager): curl (static binary if missing) + Nix
# (official installer). The CAD itself runs in a Nix FHS env from flake.nix —
# 32-bit Motif binaries + Magic VLSI. No Docker.
#
# First run:  ensure curl + Nix, lock flake, then nix run .#mmi-cad
# Later runs: if the mmi_cad Nix env is already ready, skip setup and start CAD.
#
# Usage:
#   ./run.sh                # start CAD shell (auto setup if first time)
#   ./run.sh max            # start a tool
#   ./run.sh --force-setup  # re-run Nix prep even if ready
#   ./run.sh --force-install  # re-extract vendor tarball
#   ./run.sh --prep-only    # ensure env only, do not start CAD
#   ./run.sh --clean        # drop local prefix/fonts/ready marker
#   ./run.sh --help
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${GREEN}[run]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[run]${NC}  $*"; }
error() { echo -e "${RED}[run]${NC} $*" >&2; }
step()  { echo -e "${CYAN}[run]${NC}  $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"
READY_MARKER="${SCRIPT_DIR}/.mmi-nix-ready"
BOOTSTRAP_DIR="${SCRIPT_DIR}/.mmi-bootstrap"
BOOTSTRAP_BIN="${BOOTSTRAP_DIR}/bin"
CURL_STATIC_VERSION="8.20.0"
NIX_INSTALL_URL="https://nixos.org/nix/install"

FORCE_SETUP=false
PREP_ONLY=false
FORCE_INSTALL=false
FORCE_FONTS=false
CLEAN=false
CMD_ARGS=()

for arg in "$@"; do
    case "$arg" in
        --help|-h)
            sed -n '3,20p' "$0" | sed 's/^# //'
            exit 0 ;;
        --force-setup)    FORCE_SETUP=true ;;
        --prep-only)      PREP_ONLY=true ;;
        --force-install)  FORCE_INSTALL=true ;;
        --force-fonts)    FORCE_FONTS=true ;;
        --clean)          CLEAN=true ;;
        --build-only)     PREP_ONLY=true; warn "--build-only is --prep-only (no Docker image)." ;;
        --no-build)       warn "--no-build ignored (Nix builds the env as needed)." ;;
        --save-tar)
            error "--save-tar is gone: this project no longer builds a Docker image."
            error "Use the vendor tarball mmi_pd_040526.tar.gz plus Nix, not docker save."
            exit 1 ;;
        --force-load|--skip-load)
            warn "$arg ignored (no Docker image to load)." ;;
        *.tar|*.tar.gz|*.tgz)
            warn "Ignoring image archive $arg (Docker was removed). Put mmi_pd_040526.tar.gz in ${SCRIPT_DIR}." ;;
        *)                CMD_ARGS+=("$arg") ;;
    esac
done

[ ${#CMD_ARGS[@]} -eq 0 ] && CMD_ARGS=("/bin/bash")

source_nix_profile() {
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
}

enable_flakes() {
    export NIX_CONFIG="${NIX_CONFIG:-}
experimental-features = nix-command flakes
"
}

prepend_bootstrap_path() {
    if [ -d "${BOOTSTRAP_BIN}" ]; then
        case ":${PATH}:" in
            *":${BOOTSTRAP_BIN}:"*) ;;
            *) export PATH="${BOOTSTRAP_BIN}:${PATH}" ;;
        esac
    fi
}

nix_env_ready() {
    source_nix_profile || true
    enable_flakes
    prepend_bootstrap_path

    command -v nix >/dev/null 2>&1 || return 1
    command -v curl >/dev/null 2>&1 || return 1
    nix flake --help >/dev/null 2>&1 || return 1
    [ -f "${SCRIPT_DIR}/flake.nix" ] || return 1
    [ -f "${SCRIPT_DIR}/flake.lock" ] || return 1
    [ -f "${READY_MARKER}" ] || return 1
    nix flake metadata "${SCRIPT_DIR}" >/dev/null 2>&1 || return 1
    return 0
}

http_get() {
    local url="$1" dest="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --proto '=https' --tlsv1.2 -o "${dest}" "${url}"
    else
        error "Cannot download ${url}: curl is required (bootstrap)."
        return 1
    fi
}

extract_tar_xz() {
    local archive="$1" dest="$2"
    mkdir -p "${dest}"
    if tar -xJf "${archive}" -C "${dest}" 2>/dev/null; then
        return 0
    fi
    error "Cannot extract ${archive}: need tar with xz support (tar -xJf)."
    return 1
}

static_curl_asset() {
    local os arch
    os="$(uname -s)"
    arch="$(uname -m)"
    case "${os}" in
        Linux)
            case "${arch}" in
                x86_64|amd64)  echo "curl-linux-x86_64-musl-${CURL_STATIC_VERSION}.tar.xz" ;;
                aarch64|arm64) echo "curl-linux-aarch64-musl-${CURL_STATIC_VERSION}.tar.xz" ;;
                *)
                    error "Unsupported Linux arch for static curl: ${arch}"
                    return 1 ;;
            esac
            ;;
        Darwin)
            case "${arch}" in
                x86_64)        echo "curl-macos-x86_64-${CURL_STATIC_VERSION}.tar.xz" ;;
                arm64|aarch64) echo "curl-macos-arm64-${CURL_STATIC_VERSION}.tar.xz" ;;
                *)
                    error "Unsupported macOS arch for static curl: ${arch}"
                    return 1 ;;
            esac
            ;;
        *)
            error "Unsupported OS for static curl: ${os}"
            return 1
            ;;
    esac
}

ensure_curl() {
    prepend_bootstrap_path
    if command -v curl >/dev/null 2>&1; then
        info "curl: $(curl --version 2>/dev/null | head -1)"
        return 0
    fi

    step "curl not found — installing static binary (no OS package manager) ..."
    local asset url archive extract_dir found
    asset="$(static_curl_asset)" || exit 1
    url="https://github.com/stunnel/static-curl/releases/download/${CURL_STATIC_VERSION}/${asset}"
    mkdir -p "${BOOTSTRAP_BIN}" "${BOOTSTRAP_DIR}/tmp"
    archive="${BOOTSTRAP_DIR}/tmp/${asset}"
    extract_dir="${BOOTSTRAP_DIR}/tmp/curl-extract-$$"
    rm -rf "${extract_dir}"
    mkdir -p "${extract_dir}"

    http_get "${url}" "${archive}" || exit 1
    extract_tar_xz "${archive}" "${extract_dir}" || exit 1

    found="$(find "${extract_dir}" -type f -name curl 2>/dev/null | head -1 || true)"
    if [ -z "${found}" ]; then
        error "Static curl archive had no 'curl' binary: ${asset}"
        exit 1
    fi
    cp -f "${found}" "${BOOTSTRAP_BIN}/curl"
    chmod +x "${BOOTSTRAP_BIN}/curl"
    rm -rf "${extract_dir}" "${archive}"
    prepend_bootstrap_path

    if ! command -v curl >/dev/null 2>&1; then
        error "Static curl installed to ${BOOTSTRAP_BIN}/curl but not on PATH."
        exit 1
    fi
    info "curl installed (static): $(curl --version 2>/dev/null | head -1)"
}

ensure_nix() {
    source_nix_profile || true
    if command -v nix >/dev/null 2>&1; then
        info "Nix: $(nix --version 2>/dev/null || true)"
        return 0
    fi

    step "Nix not found — installing via official installer (no OS package manager) ..."
    ensure_curl
    local installer
    installer="${BOOTSTRAP_DIR}/tmp/nix-installer.sh"
    mkdir -p "${BOOTSTRAP_DIR}/tmp"
    http_get "${NIX_INSTALL_URL}" "${installer}" || exit 1
    chmod +x "${installer}"
    sh "${installer}" --daemon --yes
    source_nix_profile || true
    if ! command -v nix >/dev/null 2>&1; then
        error "Nix installed but not on PATH. Open a new terminal and re-run."
        exit 1
    fi
    info "Nix installed: $(nix --version)"
}

ensure_flakes() {
    enable_flakes
    if ! nix flake --help >/dev/null 2>&1; then
        error "This Nix build does not support flakes. Upgrade Nix, then re-run."
        exit 1
    fi
}

ensure_flake_lock() {
    if [ ! -f "${SCRIPT_DIR}/flake.nix" ]; then
        error "flake.nix missing in ${SCRIPT_DIR}"
        exit 1
    fi
    if [ ! -f "${SCRIPT_DIR}/flake.lock" ]; then
        step "Creating flake.lock (first time) ..."
        nix flake lock "${SCRIPT_DIR}"
    fi
}

# 32-bit Linux ELF CAD: native x86_64 Linux or WSL2 only. Not macOS, not ARM.
check_host_os() {
    local os arch
    os="$(uname -s)"
    arch="$(uname -m)"
    case "${os}" in
        Linux)
            if [ "${arch}" != "x86_64" ] && [ "${arch}" != "amd64" ]; then
                error "This CAD is 32-bit Linux ELF. Nix FHS needs x86_64 Linux, not ${arch}."
                error "ARM machines cannot run these binaries without an x86_64 Linux VM."
                exit 1
            fi
            if [ -z "${DISPLAY:-}" ] && ! grep -qi microsoft /proc/version 2>/dev/null; then
                warn "DISPLAY unset — start a graphical session for the CAD GUI."
            fi
            if grep -qi microsoft /proc/version 2>/dev/null; then
                if ! uname -r | grep -qiE 'microsoft-standard|WSL2|WSL2'; then
                    warn "WSL1 detected. This Nix FHS setup needs WSL2 (user namespaces / bubblewrap)."
                fi
            fi
            ;;
        Darwin)
            error "macOS cannot run Micro Magic's 32-bit Linux binaries."
            error "Docker was a Linux VM. Without Docker you need a real x86_64 Linux host or WSL2."
            exit 1
            ;;
        *)
            error "Unsupported OS: ${os}. Use x86_64 Linux or WSL2."
            exit 1
            ;;
    esac
}

detect_display() {
    local os wsl_ver="" host_ip local_ip
    os="$(uname -s)"
    case "${os}" in
        Linux)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                if uname -r | grep -qiE 'microsoft-standard|WSL2'; then
                    wsl_ver=2
                    host_ip="$(grep nameserver /etc/resolv.conf | awk '{print $2}' | head -1)"
                    [ -z "${host_ip}" ] && { error "Cannot determine Windows host IP from /etc/resolv.conf."; exit 1; }
                    export DISPLAY="${host_ip}:0.0"
                else
                    wsl_ver=1
                    export DISPLAY="${DISPLAY:-localhost:0.0}"
                fi
                warn "WSL${wsl_ver} detected. X server target: ${DISPLAY}"
                warn "Start VcXsrv/Xming on Windows with 'Disable access control' checked."
                if command -v wslpath >/dev/null 2>&1; then
                    export MMI_XFONT_ROOT="$(wslpath -w "${SCRIPT_DIR}/.mmi-xfonts")"
                    info "VcXsrv font path: ${MMI_XFONT_ROOT}"
                fi
            else
                if [ -z "${DISPLAY:-}" ]; then
                    error "DISPLAY not set. Start an X session first."
                    exit 1
                fi
                export MMI_XFONT_ROOT="${SCRIPT_DIR}/.mmi-xfonts"
                xhost +local: 2>/dev/null || true
                xhost +SI:localuser:"$(id -un)" 2>/dev/null || true
            fi
            ;;
        Darwin)
            error "macOS is not supported without a Linux VM."
            exit 1
            ;;
    esac
}

clean_local() {
    step "Removing local Nix CAD prefix / fonts / ready marker ..."
    rm -f "${READY_MARKER}"
    rm -rf "${SCRIPT_DIR}/.mmi-prefix" "${SCRIPT_DIR}/.mmi-xfonts" "${SCRIPT_DIR}/.mmi-bootstrap"
    info "Clean complete. Nix store packages are kept (run nix-collect-garbage to drop those)."
}

setup_first_time() {
    step "First-time (or incomplete) setup — preparing mmi_cad Nix environment ..."
    ensure_curl
    ensure_nix
    ensure_flakes
    ensure_flake_lock
    check_host_os
    nix flake metadata "${SCRIPT_DIR}" >/dev/null
    date -u +"%Y-%m-%dT%H:%M:%SZ" > "${READY_MARKER}"
    info "mmi_cad environment prepared → ${READY_MARKER}"
}

run_cad() {
    export MMI_CAD_ROOT="${SCRIPT_DIR}"
    [ "${FORCE_INSTALL}" = true ] && export MMI_FORCE_INSTALL=1
    [ "${FORCE_FONTS}" = true ] && export MMI_FORCE_FONTS=1

    if [ ! -f "${SCRIPT_DIR}/mmi_pd_040526.tar.gz" ] && [ ! -f "${SCRIPT_DIR}/mmi_pd_040526.tar" ]; then
        warn "Vendor tarball mmi_pd_040526.tar.gz is not in ${SCRIPT_DIR}"
        warn "The FHS env will still build; launching CAD needs that archive."
    fi

    step "Nix environment ready — starting CAD ..."
    mkdir -p "${SCRIPT_DIR}/pdks" "${SCRIPT_DIR}/workspace"
    info "PDK_ROOT (host)  → ${SCRIPT_DIR}/pdks"
    info "Workspace        → ${SCRIPT_DIR}/workspace"
    nix run "${SCRIPT_DIR}#mmi-cad" -- "${CMD_ARGS[@]}"
}

main() {
    if grep -q $'\r' "$0" 2>/dev/null; then
        error "$0 has Windows CRLF line endings. In WSL run:"
        error "  sed -i 's/\\\\r\$//' run.sh && chmod +x run.sh"
        exit 1
    fi

    if [ "${CLEAN}" = true ]; then
        clean_local
        FORCE_SETUP=true
    fi

    if [ "${FORCE_SETUP}" = true ]; then
        rm -f "${READY_MARKER}"
        setup_first_time
    elif nix_env_ready; then
        info "mmi_cad environment already ready — starting."
        source_nix_profile || true
        enable_flakes
        check_host_os
    else
        setup_first_time
    fi

    if [ "${PREP_ONLY}" = true ]; then
        step "Realising mmi-cad FHS env (prep-only) ..."
        nix build "${SCRIPT_DIR}#mmi-cad" --no-link
        info "Prep-only — done."
        exit 0
    fi

    detect_display
    run_cad
}

main
