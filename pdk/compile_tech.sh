#!/usr/bin/env bash
# Build MAX $tech.tech from a .source (make_tech) and compile $tech.tech27.
#
# Tcl 8.0 exec treats any stderr as failure, so this script never writes
# to stderr: all diagnostics go to stdout.
#
# Usage: compile_tech.sh SOURCE TECH DEST_TECHDIR
exec 2>&1
set +e
export LC_ALL=C
export LANG=C

source_file="${1:-}"
tech="${2:-}"
dest="${3:-}"

if [ -z "$source_file" ] || [ -z "$tech" ] || [ -z "$dest" ]; then
  echo "usage: compile_tech.sh SOURCE TECH DEST_TECHDIR"
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

echo "compile_tech.sh start"
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
  cpp="$(find_bin cpp /usr/bin/cpp mmi_cpp)"
  m4="$(find_bin m4 /usr/bin/m4 mmi_m4)"
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

echo "running make_tech..."
make_bin="$(find_bin make_tech)"
wish_bin="$(find_bin mmi_tclsh mmi_wish)"
echo "  make_tech=$make_bin"
echo "  tcl=$wish_bin"

if [ -n "$wish_bin" ] && [ -n "$make_bin" ]; then
  "$wish_bin" -f "$make_bin" -- -r -file "$source_file" -tech "$tech"
  echo "make_tech (mmi_wish) exit $?"
elif [ -n "$make_bin" ]; then
  "$make_bin" -r -file "$source_file" -tech "$tech"
  echo "make_tech exit $?"
else
  echo "make_tech not found"
fi

echo "after make_tech:"
ls -la "$priv" 2>/dev/null || echo "  missing $priv"
ls -la "$dest" 2>/dev/null || echo "  missing $dest"

# make_tech writes ~/mmi_private/max/tech/<tech>/ ; also try DEST.
copy_tech "$priv" "$dest"
copy_tech "$dest" "$priv"

ok=0
if compile_dir "$priv"; then
  :
fi
if compile_dir "$dest"; then
  :
fi
if compile_dir "$loc"; then
  :
fi

copy_tech "$priv" "$dest"
copy_tech "$dest" "$priv"
copy_tech "$priv" "$loc"
copy_tech "$dest" "$loc"

echo "installed:"
ls -la "$priv" 2>/dev/null || true
ls -la "$loc" 2>/dev/null || true
ls -la "$dest" 2>/dev/null || true

if [ -s "$priv/${tech}.tech27" ] || [ -s "$loc/${tech}.tech27" ] || [ -s "$dest/${tech}.tech27" ]; then
  echo "compile_tech.sh ok"
  exit 0
fi
echo "compile_tech.sh failed: no ${tech}.tech27"
exit 1
