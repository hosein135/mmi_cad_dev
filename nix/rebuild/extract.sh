#!/usr/bin/env bash
# Unpack vendor/mmi_pd_040526.tar.gz into vendor/mmi (Windows path), flatten
# dirs, drop NTFS-unsafe leftovers, delete the tarball. Full tree including src/.
set -euo pipefail
REPO="${1:-}"
if [ -z "$REPO" ]; then
  REPO="$(cd "$(dirname "$0")/../.." && pwd)"
fi
cd "$REPO"

TAR=""
for p in vendor/mmi_pd_040526.tar.gz vendor/mmi_pd_040526.tar mmi_pd_040526.tar.gz; do
  if [ -f "$p" ]; then
    TAR="$p"
    break
  fi
done

DEST="${REPO}/vendor/mmi"
LAYOUT="${REPO}/nix/rebuild/layout.sh"
OLD_CACHE="${HOME}/.cache/mmi-cad/vendor"

enable_case_sensitive() {
  local linux="$1"
  mkdir -p "$linux"
  if command -v wslpath >/dev/null 2>&1 && command -v fsutil.exe >/dev/null 2>&1; then
    local win
    win="$(wslpath -w "$linux")"
    fsutil.exe file setCaseSensitiveInfo "$win" enable >/dev/null || \
      echo "extract: WARN could not enable NTFS case sensitivity on ${win}" >&2
  fi
}

# 32-bit helper named "export" collides with directory Export/ on NTFS.
strip_ntfs_clashes() {
  local root="$1"
  rm -f \
    "$root/src/max4.2.11/aux/irsim/src/utils/export" \
    "$root/src/max4.3.16/aux/irsim/src/utils/export"
}

copy_tree() {
  local from="$1" to="$2"
  rm -rf "$to"
  enable_case_sensitive "$to"
  tar -C "$from" -cf - . | tar -C "$to" -xf -
}

if [ -d "${DEST}/src/max4.3.16" ]; then
  if [ -n "$TAR" ]; then
    echo "extract: ${DEST} already complete — removing ${TAR}"
    rm -f "$TAR"
  fi
  exit 0
fi

# Prefer migrating the existing WSL cache onto the Windows tree.
if [ -d "${OLD_CACHE}/src/max4.3.16" ]; then
  echo "extract: moving WSL cache → ${DEST}"
  BIN_SAVE=""
  if [ -d "${DEST}/bin" ] && ls "${DEST}/bin/max" >/dev/null 2>&1; then
    BIN_SAVE=$(mktemp -d /tmp/mmi-bin.XXXXXX)
    cp -a "${DEST}/bin/." "$BIN_SAVE/"
  fi
  strip_ntfs_clashes "$OLD_CACHE"
  copy_tree "$OLD_CACHE" "$DEST"
  if [ -n "$BIN_SAVE" ]; then
    mkdir -p "${DEST}/bin"
    cp -a "$BIN_SAVE/." "${DEST}/bin/"
    rm -rf "$BIN_SAVE"
  fi
  rm -rf "$OLD_CACHE" "${HOME}/mmi-vendor"
  rmdir "${HOME}/.cache/mmi-cad" 2>/dev/null || true
  rm -f "${REPO}/vendor/SOURCE.txt"
  echo "extract: Windows tree ${DEST}"
  if [ -n "$TAR" ]; then
    rm -f "$TAR"
    echo "extract: removed ${TAR}"
  fi
  exit 0
fi

if [ -z "$TAR" ]; then
  echo "extract: need vendor/mmi_pd_040526.tar.gz (or ${DEST} with src/)" >&2
  exit 1
fi

TMP=$(mktemp -d /tmp/mmi-extract.XXXXXX)
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

echo "extract: unpacking ${TAR}"
case "$TAR" in
  *.tar.gz|*.tgz) tar -xzf "$TAR" -C "$TMP" ;;
  *) tar -xf "$TAR" -C "$TMP" ;;
esac

SRC="${TMP}/mmi_pd_040526"
if [ ! -d "$SRC" ]; then
  SRC=$(find "$TMP" -mindepth 1 -maxdepth 1 -type d | head -1)
fi
[ -d "$SRC/src" ] || {
  echo "extract: unexpected archive layout under $TMP" >&2
  ls -la "$TMP" >&2
  exit 1
}

echo "extract: flattening directories"
bash "$LAYOUT" "$SRC"
strip_ntfs_clashes "$SRC"

echo "extract: Windows tree → ${DEST}"
copy_tree "$SRC" "$DEST"

rm -f "$TAR" "${REPO}/vendor/SOURCE.txt"
echo "extract: removed ${TAR}"
echo "extract: ready at ${DEST}"
