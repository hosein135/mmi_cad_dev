#!/usr/bin/env bash
# Build MAX $tech.tech from a .source (make_tech) and compile $tech.tech27.
#
# Nested mmi_wish inside MAX deadlocks on Xvnc. make_tech's mmi_cpp|m4 pipe
# also hangs under Tcl 8.0. This script:
#   - uses tclsh only (never wish)
#   - stops make_tech once .tech is fully written
#   - compiles .tech27 with system cpp|m4
#   - writes STATUS= for the Import PDK progress dialog
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
else
  export PATH="/mmi-vendor/mmi/bin:${PATH}"
fi

home="${HOME:-/mmi-home}"
local_root="${MMI_LOCAL:-$home/cad/mmi_local}"
priv="${home}/mmi_private/max/tech/${tech}"
loc="${local_root}/max/tech/${tech}"
mtpid=""

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

cleanup() {
  if [ -n "${mtpid:-}" ]; then
    kill "$mtpid" 2>/dev/null
    sleep 0.2 2>/dev/null || sleep 1
    kill -9 "$mtpid" 2>/dev/null
    wait "$mtpid" 2>/dev/null
    mtpid=""
  fi
}
trap cleanup EXIT TERM INT

finish_fail() {
  st 94 "${1:-compile failed}" fail
  exit 1
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

mkdir -p "$dest" "$priv" "$loc" || true

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

ensure_drc_macros() {
  local dir="$1"
  if [ -f "$dir/drc_macros.i" ]; then
    return 0
  fi
  local cand
  for cand in \
    "${MMI_TOOLS:-/mmi-vendor/mmi}/max/tech/tech_target/drc_macros.i" \
    /mmi-vendor/mmi/max/tech/tech_target/drc_macros.i
  do
    if [ -f "$cand" ]; then
      cp -f "$cand" "$dir/drc_macros.i"
      echo "copied drc_macros.i from $cand"
      return 0
    fi
  done
  echo "drc_macros.i not found"
  return 1
}

tech_bytes() {
  local f sz
  for f in "$priv/${tech}.tech" "$dest/${tech}.tech" "$loc/${tech}.tech"; do
    if [ -f "$f" ]; then
      sz=$(wc -c < "$f" 2>/dev/null | tr -d ' ')
      echo "${sz:-0}"
      return 0
    fi
  done
  echo 0
}

compile_dir() {
  local dir="$1"
  local src="$dir/${tech}.tech"
  local dst="$dir/${tech}.tech27"
  local tmp="$dir/${tech}.tech27.tmp"
  if [ ! -f "$src" ]; then
    echo "no .tech in $dir"
    return 1
  fi
  ensure_drc_macros "$dir"
  echo "compiling $src ($(wc -c < "$src" | tr -d ' ') bytes)"

  local cpp m4 gccb trad sz
  cpp="$(find_bin cpp /usr/bin/cpp)"
  m4="$(find_bin m4 /usr/bin/m4)"
  gccb="$(find_bin gcc /usr/bin/gcc)"
  echo "  cpp=$cpp"
  echo "  m4=$m4"
  echo "  gcc=$gccb"
  if [ -z "$m4" ]; then
    echo "GNU m4 is not on PATH"
    return 1
  fi

  for trad in -traditional-cpp -traditional; do
    rm -f "$tmp"
    if [ -n "$cpp" ]; then
      echo "  $cpp -P $trad | $m4"
      "$cpp" -P $trad "$src" | "$m4" > "$tmp"
    elif [ -n "$gccb" ]; then
      echo "  $gccb -E -P $trad | $m4"
      "$gccb" -E -P $trad -x c "$src" | "$m4" > "$tmp"
    else
      echo "cpp/gcc not on PATH"
      return 1
    fi
    sz=$(wc -c < "$tmp" 2>/dev/null | tr -d ' ')
    echo "  output bytes=${sz:-0}"
    if [ "${sz:-0}" -gt 100 ]; then
      mv -f "$tmp" "$dst"
      echo "wrote $dst"
      return 0
    fi
    echo "  ---- head ----"
    head -c 400 "$tmp" 2>/dev/null || true
    echo
  done
  rm -f "$tmp"
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

# make_tech writes .tech then blocks forever on mmi_cpp|m4 under MAX.
# Stop it once .tech size is stable; we compile .tech27 ourselves.
run_make_tech_limited() {
  local sz last same i tclsh make_bin
  sz=$(tech_bytes)
  if [ "$sz" -gt 1000 ]; then
    echo "reusing existing .tech ($sz bytes)"
    return 0
  fi

  make_bin="$(find_bin make_tech)"
  # Never mmi_wish: nested Tk vs MAX freezes the Import PDK dialog.
  tclsh="$(find_bin mmi_tclsh /usr/bin/tclsh tclsh)"
  echo "  make_tech=$make_bin"
  echo "  tclsh=$tclsh"
  if [ -z "$make_bin" ]; then
    echo "make_tech not found"
    return 1
  fi

  st 94 "Running make_tech (writing .tech)..."
  if [ -n "$tclsh" ]; then
    "$tclsh" -f "$make_bin" -- -r -file "$source_file" -tech "$tech" &
  else
    echo "WARNING: no tclsh; skipping make_tech shebang (it would start wish and hang)"
    return 1
  fi
  mtpid=$!
  echo "make_tech pid $mtpid"

  last=0
  same=0
  i=0
  while [ "$i" -lt 90 ]; do
    i=$((i + 1))
    if cancelled; then
      echo "cancelled during make_tech"
      cleanup
      return 1
    fi
    if ! kill -0 "$mtpid" 2>/dev/null; then
      wait "$mtpid"
      echo "make_tech exited $?"
      mtpid=""
      return 0
    fi
    sz=$(tech_bytes)
    st 94 "make_tech writing .tech (${sz} bytes)..."
    if [ "$sz" -gt 1000 ]; then
      if [ "$sz" = "$last" ]; then
        same=$((same + 1))
      else
        same=0
        last=$sz
      fi
      if [ "$same" -ge 2 ]; then
        echo ".tech stable at $sz bytes; stopping make_tech before hung cpp|m4"
        cleanup
        return 0
      fi
    fi
    sleep 1
  done
  echo "make_tech timed out after 90s"
  cleanup
  return 0
}

run_make_tech_limited

if cancelled; then
  finish_fail "Cancelled."
fi

echo "after make_tech:"
ls -la "$priv" 2>/dev/null || echo "  missing $priv"
ls -la "$dest" 2>/dev/null || echo "  missing $dest"

copy_tech "$priv" "$dest"
copy_tech "$dest" "$priv"

st 96 "Compiling .tech27 (cpp | m4)..."
compile_dir "$priv" || true
compile_dir "$dest" || true
compile_dir "$loc" || true

copy_tech "$priv" "$dest"
copy_tech "$dest" "$priv"
copy_tech "$priv" "$loc"
copy_tech "$dest" "$loc"

echo "installed:"
ls -la "$priv" 2>/dev/null || true
ls -la "$loc" 2>/dev/null || true
ls -la "$dest" 2>/dev/null || true

if [ -s "$priv/${tech}.tech27" ] || [ -s "$loc/${tech}.tech27" ] || [ -s "$dest/${tech}.tech27" ]; then
  st 99 "Compiled ${tech}.tech27" ok
  echo "compile_tech.sh ok"
  exit 0
fi
finish_fail "compile_tech.sh failed: no ${tech}.tech27"
