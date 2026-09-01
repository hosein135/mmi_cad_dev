#!/usr/bin/env bash
# Download a Magic-compiled open_pdks tree into PDK_ROOT.
#
# Called from MAX (File → Import PDK), never from Nix. GitHub archives of
# skywater-pdk / gf180mcu-pdk omit git submodules (no stdcells). open_pdks
# templates are not a compiled install. IHP is not a lone .magicrc.
#
# Source: FOSSi ciel-releases (same artifacts as `ciel enable`):
#   https://github.com/fossi-foundation/ciel-releases
#
# Usage: fetch_pdk.sh <sky130A|gf180mcu|sg13g2> [status_file] [cancel_file]
set -euo pipefail

FAMILY="${1:-}"
STATUS_FILE="${2:-}"
CANCEL_FILE="${3:-}"
PDK_ROOT="${PDK_ROOT:-/mmi-pdks}"
BUNDLE="${MMI_PDK_DIR:-/mmi-bundle}"
CIEL_BASE="https://github.com/fossi-foundation/ciel-releases/releases/download"
LOG="${MMI_PDK_FETCH_LOG:-}"

# Pinned ciel tags (open_pdks / IHP-Open-PDK commit). Override with MMI_CIEL_TAG.
SKY130_TAG="${MMI_CIEL_TAG:-sky130-e8daeda73ca8f5814dbc0b11d1d05802251a3750}"
GF180_TAG="${MMI_CIEL_TAG:-gf180mcu-0fe599b2afb6708d281543108caf8310912f54af}"
IHP_TAG="${MMI_CIEL_TAG:-ihp-sg13g2-ddb601a4a4473163e1ed6df416b885df18b4ac03}"

log() {
  local msg="$*"
  printf '%s\n' "$msg"
  if [ -n "$LOG" ]; then
    printf '%s\n' "$msg" >>"$LOG" || true
  fi
}

write_status() {
  local st="$1" pct="$2" msg="$3" dest="${4:-}"
  [ -n "$STATUS_FILE" ] || return 0
  local tmp="${STATUS_FILE}.tmp"
  {
    printf 'STATUS=%s\n' "$st"
    printf 'PCT=%s\n' "$pct"
    printf 'MSG=%s\n' "$msg"
    [ -n "$dest" ] && printf 'DEST=%s\n' "$dest"
  } >"$tmp"
  mv -f "$tmp" "$STATUS_FILE"
}

die() {
  local msg="$*"
  log "ERROR: $msg"
  write_status fail 0 "$msg"
  exit 1
}

check_cancel() {
  if [ -n "$CANCEL_FILE" ] && [ -f "$CANCEL_FILE" ]; then
    log "Cancelled."
    write_status cancelled 0 "Cancelled."
    exit 2
  fi
}

usage() {
  die "Usage: fetch_pdk.sh <sky130A|gf180mcu|sg13g2> [status_file] [cancel_file]"
}

need_bin() {
  command -v "$1" >/dev/null 2>&1 || die "Need '$1' in PATH (Nix FHS). PDKs are not part of the flake."
}

tree_ready() {
  local dir="$1"
  [ -d "$dir/libs.tech/magic" ] || return 1
  [ -d "$dir/libs.ref" ] || return 1
  local rc
  rc="$(find "$dir/libs.tech/magic" -maxdepth 1 -name '*.magicrc' -print -quit 2>/dev/null || true)"
  [ -n "$rc" ] || return 1
  local kid
  kid="$(find "$dir/libs.ref" -mindepth 1 -maxdepth 1 -type d -print -quit 2>/dev/null || true)"
  [ -n "$kid" ] || return 1
}

apply_fallback_magicrc() {
  local name="$1"
  local dest="$PDK_ROOT/$name/libs.tech/magic"
  mkdir -p "$dest"
  if [ -n "$(find "$dest" -maxdepth 1 -name '*.magicrc' -print -quit 2>/dev/null || true)" ]; then
    return 0
  fi
  local src="$BUNDLE/magic/${name}.magicrc"
  if [ -f "$src" ]; then
    log "Installing fallback Magic rc $src"
    cp -f "$src" "$dest/${name}.magicrc"
  fi
}

download_one() {
  local url="$1" dest="$2" label="$3" pct_lo="$4" pct_hi="$5"
  check_cancel
  write_status running "$pct_lo" "Downloading $label"
  log "GET $url"
  mkdir -p "$(dirname "$dest")"
  rm -f "$dest" "${dest}.part"
  curl -fL --retry 3 --retry-delay 2 --connect-timeout 30 \
    -A "mmi-cad-pdk-fetch" -o "${dest}.part" "$url" &
  CURL_PID=$!
  local got=0 pct="$pct_lo"
  while kill -0 "$CURL_PID" 2>/dev/null; do
    if [ -n "$CANCEL_FILE" ] && [ -f "$CANCEL_FILE" ]; then
      kill "$CURL_PID" 2>/dev/null || true
      wait "$CURL_PID" 2>/dev/null || true
      CURL_PID=""
      rm -f "${dest}.part"
      check_cancel
    fi
    if [ -f "${dest}.part" ]; then
      got="$(wc -c <"${dest}.part" 2>/dev/null | tr -d ' ' || echo 0)"
    fi
    pct=$((pct_lo + (got / (8 * 1048576))))
    if [ "$pct" -ge "$pct_hi" ]; then pct=$((pct_hi - 1)); fi
    if [ "$pct" -lt "$pct_lo" ]; then pct="$pct_lo"; fi
    write_status running "$pct" "Downloading $label ($((got / 1048576)) MB)"
    sleep 0.4
  done
  set +e
  wait "$CURL_PID"
  local rc=$?
  CURL_PID=""
  set -e
  if [ "$rc" -ne 0 ] || [ ! -s "${dest}.part" ]; then
    rm -f "${dest}.part"
    die "Download failed: $label ($url)"
  fi
  mv -f "${dest}.part" "$dest"
  write_status running "$pct_hi" "Downloaded $label"
}

extract_zst() {
  local archive="$1" dest="$2"
  check_cancel
  log "Unpack $archive → $dest"
  mkdir -p "$dest"
  if ! zstd -d -c "$archive" | tar -xf - -C "$dest"; then
    die "Unpack failed: $archive"
  fi
}

# --- family ---
VARIANT=""
TAG=""
ASSETS=""
case "$FAMILY" in
  sky130A|sky130|skywater)
    FAMILY=sky130A
    VARIANT=sky130A
    TAG="$SKY130_TAG"
    # Compiled Magic tech (common) + primitives + HD/HVL stdcells + IO.
    # Skip hs/lp/ls/ms/hdll (multi-GB). Extra names: MMI_PDK_LIBS="sky130_sram_macros"
    ASSETS="common sky130_fd_pr sky130_fd_io sky130_fd_sc_hd sky130_fd_sc_hvl"
    ;;
  gf180mcu|gf180mcuD|gf180)
    FAMILY=gf180mcu
    VARIANT=gf180mcuD
    TAG="$GF180_TAG"
    ASSETS="common gf180mcu_fd_pr gf180mcu_fd_io gf180mcu_fd_sc_mcu7t5v0"
    ;;
  sg13g2|ihp|ihp-sg13g2)
    FAMILY=sg13g2
    VARIANT=ihp-sg13g2
    TAG="$IHP_TAG"
    ASSETS="common sg13g2_pr sg13g2_io sg13g2_stdcell sg13g2_sram"
    ;;
  *)
    usage
    ;;
esac

if [ -n "${MMI_PDK_LIBS:-}" ]; then
  ASSETS="$ASSETS $MMI_PDK_LIBS"
fi

need_bin curl
need_bin tar
need_bin zstd
need_bin find
need_bin mv

mkdir -p "$PDK_ROOT" || die "PDK_ROOT $PDK_ROOT is not writable"

DEST="$PDK_ROOT/$VARIANT"
if tree_ready "$DEST"; then
  log "Already installed: $DEST"
  write_status ok 100 "Already installed: $DEST" "$DEST"
  exit 0
fi

# Skeleton leftover (Magic rc, no stdcells) — replace, keep max/tech.
if [ -d "$DEST" ] && ! tree_ready "$DEST"; then
  log "Replacing incomplete tree $DEST"
  rm -rf "$DEST"
fi

STAGE=""
CURL_PID=""

on_exit() {
  if [ -n "${CURL_PID:-}" ]; then
    kill "$CURL_PID" 2>/dev/null || true
    wait "$CURL_PID" 2>/dev/null || true
  fi
  if [ -n "${STAGE:-}" ]; then
    rm -rf "$STAGE"
  fi
}
trap on_exit EXIT

STAGE="$PDK_ROOT/.fetch-${FAMILY}.$$"
DL="$STAGE/dl"
UNPACK="$STAGE/unpack"
mkdir -p "$DL" "$UNPACK"

write_status running 1 "Fetching compiled open_pdks ($TAG)"
log "PDK_ROOT=$PDK_ROOT tag=$TAG variant=$VARIANT"

set -- $ASSETS
N=$#
i=0
for asset in $ASSETS; do
  i=$((i + 1))
  check_cancel
  pct_lo=$((5 + (i - 1) * 70 / N))
  pct_hi=$((5 + i * 70 / N))
  archive="$DL/${asset}.tar.zst"
  download_one "${CIEL_BASE}/${TAG}/${asset}.tar.zst" "$archive" "$asset.tar.zst" "$pct_lo" "$pct_hi"
  write_status running "$pct_hi" "Unpacking $asset"
  extract_zst "$archive" "$UNPACK"
  rm -f "$archive"
done

write_status running 88 "Installing into $PDK_ROOT"

found=0
for cand in "$UNPACK/$VARIANT" "$UNPACK"/*; do
  [ -d "$cand" ] || continue
  base="$(basename "$cand")"
  case "$base" in
    dl|unpack|.*) continue ;;
  esac
  if [ -d "$cand/libs.tech" ] || [ -d "$cand/libs.ref" ]; then
    found=1
    rm -rf "$PDK_ROOT/$base"
    mv "$cand" "$PDK_ROOT/$base"
    log "Installed $PDK_ROOT/$base"
  fi
done

[ "$found" -eq 1 ] || die "Archive had no open_pdks variant directory (expected $VARIANT)"

apply_fallback_magicrc "$VARIANT"
if [ "$VARIANT" = "gf180mcuD" ]; then
  apply_fallback_magicrc gf180mcuD
  for extra in gf180mcuA gf180mcuB gf180mcuC; do
    [ -d "$PDK_ROOT/$extra/libs.tech/magic" ] && apply_fallback_magicrc "$extra"
  done
fi
if [ "$VARIANT" = "sky130A" ]; then
  [ -d "$PDK_ROOT/sky130B/libs.tech/magic" ] && apply_fallback_magicrc sky130B
fi

tree_ready "$DEST" || die "Install incomplete: $DEST (need libs.tech/magic/*.magicrc and libs.ref/*)"

{
  echo "mmi-cad PDK (user Import PDK, not Nix)"
  echo "  family  $FAMILY"
  echo "  variant $VARIANT"
  echo "  ciel    $TAG"
  echo "  assets  $ASSETS"
  echo "  source  ${CIEL_BASE}/${TAG}/"
} >"$DEST/MMI_PDK_SOURCE"

write_status ok 100 "Installed $DEST" "$DEST"
log "Ready: $DEST"
exit 0
