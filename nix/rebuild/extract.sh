#!/usr/bin/env bash
# Unpack vendor/mmi_pd_040526.tar.gz, flatten it, keep the Unix source tree on
# the Linux filesystem (NTFS cannot store irsim's file+directory named "export"),
# copy the runtime slice to vendor/mmi, then delete the tarball.
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

CACHE="${MMI_VENDOR_CACHE:-${HOME}/.cache/mmi-cad/vendor}"
DEST="${REPO}/vendor/mmi"
LAYOUT="${REPO}/nix/rebuild/layout.sh"
POINTER="${REPO}/vendor/SOURCE.txt"

if [ -d "${CACHE}/src/max4.3.16" ]; then
  if [ -n "$TAR" ]; then
    echo "extract: cache already at ${CACHE} — removing ${TAR}"
    rm -f "$TAR"
  fi
  if [ ! -d "${DEST}/lib" ]; then
    echo "extract: refreshing runtime tree at ${DEST}"
    rm -rf "$DEST"
    mkdir -p "$DEST"
    tar -C "$CACHE" -cf - --exclude='./src' . | tar -C "$DEST" -xf -
  fi
  printf '%s\n' "$CACHE" > "$POINTER"
  exit 0
fi

if [ -z "$TAR" ]; then
  echo "extract: need vendor/mmi_pd_040526.tar.gz (or a cached tree at ${CACHE})" >&2
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

echo "extract: Linux source cache → ${CACHE}"
mkdir -p "$(dirname "$CACHE")"
rm -rf "$CACHE"
mkdir -p "$CACHE"
tar -C "$SRC" -cf - . | tar -C "$CACHE" -xf -

echo "extract: runtime tree (no src/) → ${DEST}"
rm -rf "$DEST"
mkdir -p "$DEST"
tar -C "$CACHE" -cf - --exclude='./src' . | tar -C "$DEST" -xf -

printf '%s\n' "$CACHE" > "$POINTER"

rm -f "$TAR"
echo "extract: removed ${TAR}"
echo "extract: source ${CACHE}"
echo "extract: runtime ${DEST}"
