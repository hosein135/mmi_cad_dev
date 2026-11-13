#!/usr/bin/env bash
# Download a Magic-compiled open_pdks tree into PDK_ROOT.
#
# Called by the importer application, never from Nix and never from a MAX menu.
# skywater-pdk / gf180mcu-pdk omit git submodules (no stdcells). open_pdks
# templates are not a compiled install. IHP is not a lone .magicrc.
#
# Source: FOSSi ciel-releases (same artifacts as `ciel enable`):
#   https://github.com/fossi-foundation/ciel-releases
#
# Usage: fetch_pdk.sh <sky130A|gf180mcu|sg13g2> [status_file] [cancel_file]
# Incomplete runs keep $PDK_ROOT/.fetch-<family>/ so the next importer install resumes.
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

remote_size() {
  curl -fsIL --retry 2 --connect-timeout 15 \
    -A "mmi-cad-pdk-fetch" "$1" 2>/dev/null \
    | awk 'BEGIN{IGNORECASE=1} /^content-length:/ {gsub(/\r/,""); n=$2} END{print n+0}'
}

download_one() {
  local url="$1" dest="$2" label="$3" pct_lo="$4" pct_hi="$5"
  check_cancel
  write_status running "$pct_lo" "Downloading $label"
  log "GET $url"
  mkdir -p "$(dirname "$dest")"
  rm -f "$dest" "${dest}.part" "${dest}.ok"
  local total
  total="$(remote_size "$url" || true)"
  case "$total" in
    ''|*[!0-9]*) total=0 ;;
  esac
  curl -fL --retry 3 --retry-delay 2 --connect-timeout 30 \
    -A "mmi-cad-pdk-fetch" -o "${dest}.part" "$url" &
  CURL_PID=$!
  local got=0 pct="$pct_lo" span=$((pct_hi - pct_lo))
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
    if [ "$total" -gt 0 ] && [ "$span" -gt 0 ]; then
      pct=$((pct_lo + got * span / total))
    else
      pct=$((pct_lo + got / 1048576))
    fi
    if [ "$pct" -ge "$pct_hi" ]; then pct=$((pct_hi - 1)); fi
    if [ "$pct" -lt "$pct_lo" ]; then pct="$pct_lo"; fi
    if [ "$total" -gt 0 ]; then
      write_status running "$pct" "Downloading $label ($((got / 1048576)) / $((total / 1048576)) MB)"
    else
      write_status running "$pct" "Downloading $label ($((got / 1048576)) MB)"
    fi
    sleep 0.4
  done
  set +e
  wait "$CURL_PID"
  local rc=$?
  CURL_PID=""
  set -e
  if [ "$rc" -ne 0 ] || [ ! -s "${dest}.part" ]; then
    rm -f "${dest}.part" "${dest}.ok"
    die "Download failed: $label ($url)"
  fi
  mv -f "${dest}.part" "$dest"
  : >"${dest}.ok"
  write_status running "$pct_hi" "Downloaded $label"
}

archive_ready() {
  local a="$1"
  [ -s "$a" ] || return 1
  [ -f "${a}.ok" ] || return 1
  zstd -t "$a" >/dev/null 2>&1
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

# registry.json is the pin. The case above is the fallback when it is absent.
REG=""
for cand in \
    "${BUNDLE}/importer/registry.json" \
    /mmi-pdk-live/importer/registry.json \
    "$(dirname "$0")/importer/registry.json"
do
  if [ -f "$cand" ]; then
    REG="$cand"
    break
  fi
done
# MMI_CIEL_TAG is an explicit pin from the importer Advanced dialog.
# registry.json wins only when that override is empty.
if [ -z "${MMI_CIEL_TAG:-}" ] && [ -n "$REG" ] && command -v python3 >/dev/null 2>&1; then
  parsed="$(python3 -c '
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
want = sys.argv[2]
for item in data.get("pdks", []):
    names = {item.get("family"), item.get("name"), item.get("dir"), item.get("max_tech")}
    if want in names:
        print(item["tag"])
        print(" ".join(item["assets"]))
        break
' "$REG" "$FAMILY" 2>/dev/null || true)"
  reg_tag="$(printf '%s\n' "$parsed" | sed -n '1p')"
  reg_assets="$(printf '%s\n' "$parsed" | sed -n '2p')"
  if [ -n "$reg_tag" ] && [ -n "$reg_assets" ]; then
    TAG="$reg_tag"
    ASSETS="$reg_assets"
    log "registry $REG tag=$TAG"
  fi
fi

if [ -n "${MMI_PDK_LIBS:-}" ]; then
  ASSETS="$ASSETS $MMI_PDK_LIBS"
fi

# A compiled tree the user already has. Link it; uninstall removes the link.
if [ -n "${MMI_PDK_LOCAL:-}" ]; then
  mkdir -p "$PDK_ROOT" || die "PDK_ROOT $PDK_ROOT is not writable"
  DEST="$PDK_ROOT/$VARIANT"
  if ! tree_ready "$MMI_PDK_LOCAL"; then
    die "MMI_PDK_LOCAL is not a compiled open_pdks tree: $MMI_PDK_LOCAL"
  fi
  if [ -L "$DEST" ] || [ ! -e "$DEST" ]; then
    rm -f "$DEST"
    ln -s "$MMI_PDK_LOCAL" "$DEST"
    log "Linked local tree $MMI_PDK_LOCAL -> $DEST"
  elif tree_ready "$DEST"; then
    log "Already installed: $DEST"
  else
    die "$DEST exists and is not a finished tree. Remove it or pick another PDK_ROOT."
  fi
  write_status ok 100 "Local tree $DEST" "$DEST"
  exit 0
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

# Incomplete DEST cannot be resumed in-place; keep download cache, drop the tree.
# Do not delete $PDK_ROOT/max (MAX tech files).
if [ -d "$DEST" ] && ! tree_ready "$DEST"; then
  log "Removing incomplete tree $DEST"
  rm -rf "$DEST"
fi

STAGE="$PDK_ROOT/.fetch-${FAMILY}"
DL="$STAGE/dl"
UNPACK="$STAGE/unpack"
CURL_PID=""

on_exit() {
  if [ -n "${CURL_PID:-}" ]; then
    kill "$CURL_PID" 2>/dev/null || true
    wait "$CURL_PID" 2>/dev/null || true
  fi
  # Keep $STAGE on failure/cancel so the next importer install can resume.
}
trap on_exit EXIT

mkdir -p "$DL"
rm -f "$DL"/*.part

# Fold leftover per-PID stage dirs from older fetch_pdk.sh into the stable cache.
for old in "$PDK_ROOT"/.fetch-"${FAMILY}".*; do
  [ -d "$old" ] || continue
  [ "$old" = "$STAGE" ] && continue
  log "Merging leftover fetch dir $old"
  if [ -d "$old/dl" ]; then
    for f in "$old/dl"/*.tar.zst "$old/dl"/*.tar.zst.ok; do
      [ -e "$f" ] || continue
      base="$(basename "$f")"
      if [ ! -e "$DL/$base" ]; then
        mv "$f" "$DL/$base" 2>/dev/null || cp -a "$f" "$DL/$base"
      fi
    done
  fi
  rm -rf "$old"
done

rm -rf "$UNPACK"
mkdir -p "$UNPACK"

write_status running 1 "Fetching compiled open_pdks ($TAG)"
log "PDK_ROOT=$PDK_ROOT tag=$TAG variant=$VARIANT stage=$STAGE"

set -- $ASSETS
N=$#
i=0
have=0
for asset in $ASSETS; do
  if archive_ready "$DL/${asset}.tar.zst"; then
    have=$((have + 1))
  fi
done
if [ "$have" -gt 0 ]; then
  log "Resuming: $have/$N assets already downloaded"
  write_status running 2 "Resuming download ($have/$N assets already fetched)"
fi

for asset in $ASSETS; do
  i=$((i + 1))
  check_cancel
  pct_lo=$((5 + (i - 1) * 70 / N))
  pct_hi=$((5 + i * 70 / N))
  archive="$DL/${asset}.tar.zst"
  if archive_ready "$archive"; then
    log "Resume: skip download $asset"
    write_status running "$pct_hi" "Already downloaded $asset"
  else
    rm -f "$archive" "${archive}.part" "${archive}.ok"
    download_one "${CIEL_BASE}/${TAG}/${asset}.tar.zst" "$archive" "$asset.tar.zst" "$pct_lo" "$pct_hi"
    archive_ready "$archive" || die "Downloaded archive is not valid zstd: $asset"
  fi
  write_status running "$pct_hi" "Unpacking $asset"
  extract_zst "$archive" "$UNPACK"
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
  echo "mmi-cad PDK (importer, not Nix)"
  echo "  family  $FAMILY"
  echo "  variant $VARIANT"
  echo "  ciel    $TAG"
  echo "  assets  $ASSETS"
  echo "  source  ${CIEL_BASE}/${TAG}/"
} >"$DEST/MMI_PDK_SOURCE"

rm -rf "$STAGE"
write_status ok 100 "Installed $DEST" "$DEST"
log "Ready: $DEST"
exit 0
