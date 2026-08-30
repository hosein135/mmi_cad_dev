#!/usr/bin/env bash
# Optional: unpack vendor/mmi_pd_040526.tar.gz into vendor/mmi.
# Normal clones already have vendor/mmi in git — this is recovery only.
# Does not read ~/.cache (that was host-impure).
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
  tar -C "$from" --sort=name -cf - . | tar -C "$to" -xf -
}

if [ -d "${DEST}/src/max4.3.16" ]; then
  if [ -n "$TAR" ]; then
    echo "extract: ${DEST} already complete — removing ${TAR}"
    rm -f "$TAR"
  fi
  exit 0
fi

if [ -z "$TAR" ]; then
  echo "extract: vendor/mmi is missing and no mmi_pd_040526 tarball was found." >&2
  echo "extract: clone this repo with vendor/mmi, or place the tarball in vendor/." >&2
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
  SRC=$(find "$TMP" -mindepth 1 -maxdepth 1 -type d | LC_ALL=C sort | head -1)
fi
[ -d "$SRC/src" ] || {
  echo "extract: unexpected archive layout under $TMP" >&2
  ls -la "$TMP" >&2
  exit 1
}

echo "extract: flattening directories"
bash "$LAYOUT" "$SRC"
strip_ntfs_clashes "$SRC"

echo "extract: tree → ${DEST}"
copy_tree "$SRC" "$DEST"

rm -f "$TAR" "${REPO}/vendor/SOURCE.txt"
echo "extract: removed ${TAR}"
echo "extract: ready at ${DEST}"
