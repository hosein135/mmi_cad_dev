#!/usr/bin/env bash
# Build MAX $tech.tech27 from a .source table.
#
# Primary path: source_to_tech27.tcl (no make_tech/cpp/m4 — those hang under
# nested MAX / Xvnc). Optional make_tech is attempted briefly for richer DRC.
#
# Usage: compile_tech.sh SOURCE TECH DEST_TECHDIR [STATUS_FILE] [CANCEL_FILE] [LOG_FILE]
set +e
export LC_ALL=C
export LANG=C

source_file="${1:-}"
tech="${2:-}"
dest="${3:-}"
status_file="${4:-}"
cancel_file="${5:-}"
log_file="${6:-}"

if [ -n "$log_file" ]; then
  exec >>"$log_file" 2>&1
else
  exec 2>&1
fi

if [ -z "$source_file" ] || [ -z "$tech" ] || [ -z "$dest" ]; then
  echo "usage: compile_tech.sh SOURCE TECH DEST_TECHDIR [STATUS] [CANCEL] [LOG]"
  exit 1
fi

if [ -n "${MMI_TOOLS:-}" ]; then
  export PATH="${MMI_TOOLS}/bin:${PATH}"
  export MMI_TOOLS
else
  export PATH="/mmi-vendor/mmi/bin:${PATH}"
  export MMI_TOOLS=/mmi-vendor/mmi
fi

home="${HOME:-/mmi-home}"
local_root="${MMI_LOCAL:-$home/cad/mmi_local}"
priv="${home}/mmi_private/max/tech/${tech}"
loc="${local_root}/max/tech/${tech}"

st() {
  local pct="${1:-94}"
  local msg="${2:-Compiling MAX technology...}"
  local status="${3:-running}"
  echo "$msg"
  if [ -n "$status_file" ]; then
    {
      echo "STATUS=$status"
      echo "PCT=$pct"
      echo "MSG=$msg"
    } > "${status_file}.tmp"
    mv -f "${status_file}.tmp" "$status_file"
  fi
}

cancelled() {
  [ -n "$cancel_file" ] && [ -f "$cancel_file" ]
}

finish_fail() {
  st 94 "${1:-compile failed}" fail
  exit 1
}

finish_ok() {
  st 99 "Compiled ${tech}.tech27" ok
  echo "compile_tech.sh ok"
  exit 0
}

if cancelled; then
  finish_fail "Cancelled."
fi

st 94 "compile_tech.sh starting" running
echo "  source=$source_file"
echo "  tech=$tech"
echo "  dest=$dest"
echo "  PATH=$PATH"
echo "  HOME=$home"
echo "  MMI_TOOLS=$MMI_TOOLS"

mkdir -p "$dest" "$priv" "$loc" || true
# If priv is a symlink into dest, writing once covers both.
cp -f "$source_file" "$dest/${tech}.source" 2>/dev/null || true
cp -f "$source_file" "$priv/${tech}.source" 2>/dev/null || true
cp -f "$source_file" "$loc/${tech}.source" 2>/dev/null || true

find_bin() {
  local name
  for name in "$@"; do
    if [ -x "$name" ]; then
      echo "$name"
      return 0
    fi
    if command -v "$name" >/dev/null 2>&1; then
      command -v "$name"
      return 0
    fi
  done
  echo ""
  return 1
}

find_generator() {
  local f
  for f in \
    /mmi-pdk-live/source_to_tech27.tcl \
    "${local_root}/max/pdk/source_to_tech27.tcl" \
    "${MMI_PDK_DIR:-/mmi-bundle}/source_to_tech27.tcl" \
    /mmi-bundle/source_to_tech27.tcl \
    "$(dirname "$0")/source_to_tech27.tcl"
  do
    if [ -f "$f" ]; then
      echo "$f"
      return 0
    fi
  done
  echo ""
  return 1
}

copy_tech() {
  local from="$1"
  local to="$2"
  [ -d "$from" ] || return 0
  mkdir -p "$to" || return 0
  local ext
  for ext in tech tech27 tcl palette source; do
    if [ -f "$from/${tech}.${ext}" ]; then
      cp -f "$from/${tech}.${ext}" "$to/"
    fi
  done
  if [ -f "$from/drc_macros.i" ]; then
    cp -f "$from/drc_macros.i" "$to/"
  fi
}

have_tech27() {
  [ -s "$priv/${tech}.tech27" ] || [ -s "$loc/${tech}.tech27" ] || [ -s "$dest/${tech}.tech27" ]
}

# Always rebuild .tech27 from .source (fixes older broken generators).
st 95 "Generating ${tech}.tech27 from .source..."
gen="$(find_generator)"
tclsh="$(find_bin /usr/bin/tclsh tclsh /bin/tclsh mmi_tclsh)"
echo "  generator=$gen"
echo "  tclsh=$tclsh"

if [ -z "$gen" ]; then
  finish_fail "source_to_tech27.tcl not found"
fi
if [ -z "$tclsh" ]; then
  finish_fail "tclsh not found"
fi

if cancelled; then
  finish_fail "Cancelled."
fi

rm -f "$dest/${tech}.tech27" "$priv/${tech}.tech27" "$loc/${tech}.tech27" 2>/dev/null || true

# Prefer system tclsh: mmi_tclsh is Tcl 8.0 and shares MAX command names.
echo "running: $tclsh $gen $source_file $tech $dest"
if ! "$tclsh" "$gen" "$source_file" "$tech" "$dest"; then
  echo "source_to_tech27 exit $?"
  alt="$(find_bin tclsh /usr/bin/tclsh)"
  if [ -n "$alt" ] && [ "$alt" != "$tclsh" ]; then
    echo "retry with $alt"
    "$alt" "$gen" "$source_file" "$tech" "$dest"
    echo "retry exit $?"
  fi
fi
echo "after generator:"
ls -la "$dest" 2>/dev/null || true

if [ ! -s "$dest/${tech}.tech27" ]; then
  finish_fail "source_to_tech27.tcl did not write $dest/${tech}.tech27"
fi

# Sanity: reject known-bad patterns from older generators
if grep -q 'labels \*' "$dest/${tech}.tech27" 2>/dev/null; then
  finish_fail "generated tech27 still has invalid 'labels *'"
fi
if grep -qE '[[:space:]]width[[:space:]]+[^[:space:]]+[[:space:]]+-' "$dest/${tech}.tech27" 2>/dev/null; then
  finish_fail "generated tech27 still has invalid DRC width '-'"
fi
if grep -qE '[[:space:]]spacing[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+-' "$dest/${tech}.tech27" 2>/dev/null; then
  finish_fail "generated tech27 still has invalid DRC spacing '-'"
fi
if [ ! -s "$dest/${tech}.palette" ]; then
  finish_fail "generator did not write ${tech}.palette"
fi
if [ ! -s "$dest/${tech}.tcl" ]; then
  finish_fail "generator did not write ${tech}.tcl"
fi
if grep -qE '^set DRC_DATA\([^)]+\) [^{].* ' "$dest/${tech}.tcl" 2>/dev/null; then
  finish_fail "generated tcl has unbraced multi-word DRC_DATA set"
fi
if grep -q '^cifstyle ' "$dest/${tech}.tech27" 2>/dev/null; then
  # cifstyle must be inside drc, not a top-level section start
  if ! awk '/^drc$/{d=1} d&&/^cifstyle /{ok=1} END{exit !ok}' "$dest/${tech}.tech27"; then
    finish_fail "generated tech27 has top-level cifstyle (must be under drc)"
  fi
fi

copy_tech "$dest" "$priv"
copy_tech "$dest" "$loc"

echo "installed:"
ls -la "$priv" 2>/dev/null || true
ls -la "$loc" 2>/dev/null || true
ls -la "$dest" 2>/dev/null || true

if have_tech27; then
  finish_ok
fi
finish_fail "compile_tech.sh failed: no ${tech}.tech27"
