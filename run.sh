#!/usr/bin/env bash
# =============================================================================
# run.sh — Build and run the Micro Magic CAD Docker container
#
# Usage:
#   ./run.sh              # build then launch interactive shell
#   ./run.sh mmiwolf      # build then launch a specific CAD tool
#   ./run.sh --build-only # build image only, do not start container
#   ./run.sh --save-tar   # build quietly, write mmi-cad-offline.tar here, exit
#   ./run.sh --no-build   # skip build, run existing image directly
#   ./run.sh --clean      # remove image/containers/build cache, then rebuild
#   ./run.sh --help       # show this help
#
# X11 GUI forwarding is handled for Linux, WSL2 (VcXsrv), and macOS (XQuartz).
# Motif apps (max/nst) need XLFD fonts on a path the host X server can read.
# run.sh extracts image fonts to .mmi-xfonts and bind-mounts that path.
# =============================================================================
set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
IMAGE_NAME="mmi-cad"
IMAGE_TAG="latest"
CONTAINER_NAME="mmi-cad-session"
BASE_IMAGE="ubuntu:20.04"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OFFLINE_TAR="${SCRIPT_DIR}/mmi-cad-offline.tar"

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
step()  { echo -e "${CYAN}[STEP]${NC}  $*"; }

# ── Argument parsing ──────────────────────────────────────────────────────────
BUILD_ONLY=false
SKIP_BUILD=false
CLEAN=false
SAVE_TAR=false
CMD_ARGS=()

for arg in "$@"; do
    case "$arg" in
        --help|-h)
            sed -n '3,16p' "$0" | sed 's/^# //'
            exit 0 ;;
        --build-only) BUILD_ONLY=true ;;
        --save-tar)   SAVE_TAR=true; BUILD_ONLY=true ;;
        --no-build)   SKIP_BUILD=true ;;
        --clean)      CLEAN=true ;;
        *)            CMD_ARGS+=("$arg") ;;
    esac
done

[ ${#CMD_ARGS[@]} -eq 0 ] && CMD_ARGS=("/bin/bash")

# ── Sanity checks ─────────────────────────────────────────────────────────────
# WSL1 cannot run dockerd. Use the Windows Docker engine (docker.exe or
# DOCKER_HOST=tcp://localhost:2375 after exposing the daemon on 2375).
DOCKER_IS_EXE=0
if ! command -v docker &>/dev/null; then
    if command -v docker.exe &>/dev/null; then
        docker() { docker.exe "$@"; }
        DOCKER_IS_EXE=1
        info "Using docker.exe (Windows Docker engine)."
    else
        error "Docker is not installed or not in PATH."
        error "On WSL1: install Docker Desktop on Windows, enable"
        error "  Settings → General → Expose daemon on tcp://localhost:2375"
        error "then in WSL:  sudo apt-get install -y docker.io"
        error "              echo 'export DOCKER_HOST=tcp://localhost:2375' >> ~/.bashrc"
        exit 1
    fi
fi
if [ ! -f "Dockerfile" ] && [ "$SKIP_BUILD" = false ]; then
    error "Dockerfile not found. Run this script from the directory containing it."
    exit 1
fi
# CRLF check (common when the tree was cloned on Windows)
if grep -q $'\r' "$0" 2>/dev/null; then
    error "$0 has Windows CRLF line endings. In WSL run:"
    error "  sed -i 's/\\r\$//' run.sh && chmod +x run.sh"
    exit 1
fi
if ! docker info >/dev/null 2>&1; then
    error "Cannot talk to the Docker daemon (docker info failed)."
    error "WSL1 cannot run dockerd. On Windows: start Docker Desktop and enable"
    error "  Settings → General → Expose daemon on tcp://localhost:2375 without TLS"
    error "In WSL:  export DOCKER_HOST=tcp://localhost:2375"
    exit 1
fi

# ── OS / X11 detection ────────────────────────────────────────────────────────
OS="$(uname -s)"
WSL_VER=""
DISPLAY_VAR=""
XAUTH_MOUNT=""
XSOCK_MOUNT=""
NETWORK_MODE=""
XAUTH_ENV=""
FONT_MOUNT=""
MMI_XFONT_ROOT=""

detect_display_linux() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        # WSL1 shares the Windows network stack (localhost works).
        # WSL2 is a VM; DISPLAY must be the Windows host IP (resolv.conf nameserver).
        if uname -r | grep -qiE 'microsoft-standard|WSL2'; then
            WSL_VER=2
            HOST_IP=$(grep nameserver /etc/resolv.conf | awk '{print $2}' | head -1)
            [ -z "$HOST_IP" ] && { error "Cannot determine Windows host IP from /etc/resolv.conf."; exit 1; }
            DISPLAY_VAR="${HOST_IP}:0.0"
        else
            WSL_VER=1
            # WSL1 shares Windows networking; VcXsrv on :0 is localhost.
            DISPLAY_VAR="${DISPLAY:-localhost:0.0}"
        fi
        warn "WSL${WSL_VER} detected. X server target: ${DISPLAY_VAR}"
        warn "Start VcXsrv/Xming on Windows with 'Disable access control' checked."
    else
        # Native Linux
        [ -z "${DISPLAY:-}" ] && { error "DISPLAY not set. Start an X session first."; exit 1; }
        DISPLAY_VAR="$DISPLAY"

        if [ -d /tmp/.X11-unix ]; then
            XSOCK_MOUNT="-v /tmp/.X11-unix:/tmp/.X11-unix"
        else
            warn "X11 socket /tmp/.X11-unix not found."
        fi

        # Allow local Docker clients (belt-and-suspenders with cookie below)
        xhost +local: 2>/dev/null || true
        xhost +local:docker 2>/dev/null || true
        xhost +SI:localuser:"$(id -un)" 2>/dev/null || true

        # Build a cookie file with FamilyWild (ffff) so hostname/container
        # mismatches do not break MIT-MAGIC-COOKIE auth.
        XAUTH_FILE="/tmp/.mmi-docker.xauth"
        rm -f "${XAUTH_FILE}"
        touch "${XAUTH_FILE}"
        chmod 666 "${XAUTH_FILE}"
        if command -v xauth >/dev/null 2>&1; then
            # Prefer extracting the cookie for the current display
            if xauth nlist "${DISPLAY}" 2>/dev/null | sed -e 's/^..../ffff/' | xauth -f "${XAUTH_FILE}" nmerge - 2>/dev/null; then
                info "Prepared Xauthority cookie → ${XAUTH_FILE}"
            elif [ -f "${HOME}/.Xauthority" ]; then
                xauth -f "${HOME}/.Xauthority" nlist 2>/dev/null | sed -e 's/^..../ffff/' | xauth -f "${XAUTH_FILE}" nmerge - 2>/dev/null || true
                info "Copied host .Xauthority (wildcard) → ${XAUTH_FILE}"
            else
                warn "Could not extract X cookie; relying on xhost +local:"
            fi
        else
            warn "xauth not installed on host; relying on xhost +local:"
            warn "Install with: sudo apt-get install -y xauth"
        fi

        XAUTH_MOUNT="-v ${XAUTH_FILE}:${XAUTH_FILE}:rw"
        XAUTH_ENV="${XAUTH_FILE}"

        # Host network: container shares host netns so unix :0 works
        NETWORK_MODE="--network host"
    fi
}

detect_display_macos() {
    if ! pgrep -x Xquartz &>/dev/null; then
        warn "XQuartz is not running."
        warn "Start XQuartz, enable Preferences → Security → 'Allow connections from network clients',"
        warn "then run:  xhost +localhost"
    fi
    LOCAL_IP=$(ifconfig en0 2>/dev/null | awk '/inet /{print $2}' | head -1)
    [ -z "$LOCAL_IP" ] && LOCAL_IP="host.docker.internal"
    DISPLAY_VAR="${LOCAL_IP}:0"
    info "macOS: targeting XQuartz at ${DISPLAY_VAR}"
    xhost +localhost 2>/dev/null || true
}

# Image-only modes do not need X11 (and must work headless).
if [ "$BUILD_ONLY" = true ] || [ "$SAVE_TAR" = true ]; then
    :
else
    case "$OS" in
        Linux)  detect_display_linux ;;
        Darwin) detect_display_macos ;;
        *)
            error "Unsupported OS: $OS. Set DISPLAY manually and adapt this script."
            exit 1 ;;
    esac
fi

# ── Clean previous build ──────────────────────────────────────────────────────
clean_previous() {
    step "Cleaning previous build artifacts ..."

    CONTAINERS=$(docker ps -a --filter "ancestor=${IMAGE_NAME}:${IMAGE_TAG}" --format '{{.ID}}' 2>/dev/null || true)
    if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER_NAME}$"; then
        CONTAINERS="$CONTAINERS $(docker ps -a --filter "name=^${CONTAINER_NAME}$" --format '{{.ID}}')"
    fi
    CONTAINERS=$(echo "$CONTAINERS" | xargs 2>/dev/null || true)
    if [ -n "$CONTAINERS" ]; then
        warn "Stopping and removing containers: $CONTAINERS"
        # shellcheck disable=SC2086
        docker rm -f $CONTAINERS 2>/dev/null && info "Containers removed." || true
    else
        info "No containers to remove."
    fi

    if docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" &>/dev/null; then
        warn "Removing image ${IMAGE_NAME}:${IMAGE_TAG} ..."
        docker rmi -f "${IMAGE_NAME}:${IMAGE_TAG}" 2>/dev/null && info "Image removed." || true
    else
        info "Image ${IMAGE_NAME}:${IMAGE_TAG} not found — skipping."
    fi

    if docker image inspect "${BASE_IMAGE}" &>/dev/null; then
        warn "Removing base image ${BASE_IMAGE} (forces clean re-pull) ..."
        docker rmi -f "${BASE_IMAGE}" 2>/dev/null && info "Base image removed." || true
    fi

    warn "Pruning dangling images ..."
    docker image prune -f 2>/dev/null && info "Dangling images pruned." || true

    warn "Pruning build cache ..."
    docker builder prune -f 2>/dev/null && info "Build cache cleared." || true

    FONT_CACHE="$(cd "$(dirname "$0")" && pwd)/.mmi-xfonts"
    if [ -d "$FONT_CACHE" ]; then
        warn "Removing Motif font cache ${FONT_CACHE} ..."
        rm -rf "$FONT_CACHE" && info "Font cache removed." || true
    fi

    info "Clean complete."
    echo ""
}

if [ "$CLEAN" = true ]; then
    clean_previous
    SKIP_BUILD=false
fi

# ── Build ─────────────────────────────────────────────────────────────────────
if [ "$SKIP_BUILD" = false ]; then
    step "Building image ${IMAGE_NAME}:${IMAGE_TAG} ..."
    BUILD_ARGS=(--tag "${IMAGE_NAME}:${IMAGE_TAG}" --file Dockerfile .)
    if [ "$SAVE_TAR" = true ]; then
        docker build -q "${BUILD_ARGS[@]}" >/dev/null \
            && info "Build complete." \
            || { error "Docker build failed."; exit 1; }
    else
        docker build "${BUILD_ARGS[@]}" \
            && info "Build complete." \
            || { error "Docker build failed."; exit 1; }
    fi
else
    info "Skipping build (--no-build). Using existing image ${IMAGE_NAME}:${IMAGE_TAG}."
    if ! docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" &>/dev/null; then
        error "Image ${IMAGE_NAME}:${IMAGE_TAG} not found. Run without --no-build first."
        exit 1
    fi
fi

if [ "$SAVE_TAR" = true ]; then
    step "Writing ${OFFLINE_TAR}"
    docker save -o "${OFFLINE_TAR}" "${IMAGE_NAME}:${IMAGE_TAG}" \
        || { error "docker save failed."; exit 1; }
    info "Wrote ${OFFLINE_TAR}"
    ls -lh "${OFFLINE_TAR}"
    exit 0
fi

$BUILD_ONLY && { info "Build-only mode — done."; exit 0; }

# ── Remove stale container ────────────────────────────────────────────────────
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    warn "Removing existing container '${CONTAINER_NAME}' ..."
    docker rm -f "${CONTAINER_NAME}" >/dev/null
fi

# ── Ensure Motif fonts are visible to the host X server ───────────────────────
# xset +fp tells the X *server* (on the host) to open a directory. Paths that
# only exist inside the container are invisible to it. Solution: copy fonts out
# of the image and bind-mount them at the *same absolute path* on host+container.
ensure_host_fonts() {
    FONT_CACHE_REL=".mmi-xfonts"
    FONT_CACHE="$(cd "$(dirname "$0")" && pwd)/${FONT_CACHE_REL}"

    if [ ! -f "${FONT_CACHE}/75dpi/fonts.dir" ]; then
        step "Extracting Motif X11 fonts from image → ${FONT_CACHE}"
        mkdir -p "${FONT_CACHE}"
        TMP_CTR="mmi-font-extract-$$"
        docker create --name "${TMP_CTR}" "${IMAGE_NAME}:${IMAGE_TAG}" >/dev/null
        CP_DEST="${FONT_CACHE}"
        if [ "${DOCKER_IS_EXE}" = 1 ] && command -v wslpath >/dev/null 2>&1; then
            CP_DEST="$(wslpath -w "${FONT_CACHE}")"
        fi
        docker cp "${TMP_CTR}:/usr/share/fonts/X11/." "${CP_DEST}/"
        docker rm -f "${TMP_CTR}" >/dev/null
        info "Fonts extracted."
    else
        info "Using cached Motif fonts at ${FONT_CACHE}"
    fi

    MMI_XFONT_ROOT="${FONT_CACHE}"
    FONT_MOUNT="-v ${FONT_CACHE}:${FONT_CACHE}:ro"

    # Windows Docker daemon cannot bind-mount a WSL path like /home/... or
    # /mnt/c/.... Convert the host side to a Windows path and put the fonts
    # at a stable Linux path inside the container. VcXsrv still needs the
    # Windows path (xset talks to the X server on Windows).
    if [ -n "${WSL_VER:-}" ] && command -v wslpath >/dev/null 2>&1; then
        WIN_FONT="$(wslpath -w "${FONT_CACHE}")"
        FONT_MOUNT="-v ${WIN_FONT}:/opt/mmi-xfonts:ro"
        MMI_XFONT_ROOT="${WIN_FONT}"
        info "WSL${WSL_VER}: font mount ${WIN_FONT} → /opt/mmi-xfonts"
        info "VcXsrv font path: ${WIN_FONT}"
    fi
}

ensure_host_fonts

# Shared PDK + design workspace (host folders, bind-mounted — Magic and MAX
# both use PDK_ROOT=/opt/pdks so the PDK is not duplicated in the image).
PDK_HOST="${SCRIPT_DIR}/pdks"
WORK_HOST="${SCRIPT_DIR}/workspace"
mkdir -p "${PDK_HOST}" "${WORK_HOST}"
PDK_MOUNT="-v ${PDK_HOST}:/opt/pdks"
WORK_MOUNT="-v ${WORK_HOST}:/home/caduser/work"
if command -v wslpath >/dev/null 2>&1; then
    WIN_PDK="$(wslpath -w "${PDK_HOST}")"
    WIN_WORK="$(wslpath -w "${WORK_HOST}")"
    PDK_MOUNT="-v ${WIN_PDK}:/opt/pdks"
    WORK_MOUNT="-v ${WIN_WORK}:/home/caduser/work"
    info "Shared PDK_ROOT: ${WIN_PDK} → /opt/pdks"
    info "Workspace:       ${WIN_WORK} → /home/caduser/work"
else
    info "Shared PDK_ROOT: ${PDK_HOST} → /opt/pdks"
    info "Workspace:       ${WORK_HOST} → /home/caduser/work"
fi

# ── Run ───────────────────────────────────────────────────────────────────────
step "Starting '${CONTAINER_NAME}' ..."
info "  OS        → ${OS}"
info "  DISPLAY   → ${DISPLAY_VAR}"
info "  X fonts   → ${MMI_XFONT_ROOT}"
info "  Command   → ${CMD_ARGS[*]}"
echo ""

IPC_FLAG="--ipc=host"
# Windows Docker (WSL1 → docker.exe / tcp:2375) often rejects --ipc=host.
if [ -n "${WSL_VER:-}" ]; then
    IPC_FLAG=""
fi

docker run \
    --rm \
    --interactive \
    --tty \
    --name "${CONTAINER_NAME}" \
    ${IPC_FLAG} \
    --env DISPLAY="${DISPLAY_VAR}" \
    --env QT_X11_NO_MITSHM=1 \
    --env MMI_XFONT_ROOT="${MMI_XFONT_ROOT}" \
    --env PDK_ROOT=/opt/pdks \
    --env PDK=sky130A \
    ${XAUTH_ENV:+--env XAUTHORITY=${XAUTH_ENV}} \
    ${XSOCK_MOUNT} \
    ${XAUTH_MOUNT} \
    ${FONT_MOUNT} \
    ${PDK_MOUNT} \
    ${WORK_MOUNT} \
    ${NETWORK_MODE} \
    "${IMAGE_NAME}:${IMAGE_TAG}" \
    "${CMD_ARGS[@]}"
