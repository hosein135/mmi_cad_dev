#!/usr/bin/env bash
# Make vendor/mmi safe for Git on Windows: no AUX paths, no symlinks, no ':' names.
set -euo pipefail
ROOT="${1:?vendor/mmi path}"
cd "$ROOT"

rename_max_aux() {
  local max="$1"
  [ -d "$max/aux" ] || return 0
  rm -rf "$max/maxaux"
  mv "$max/aux" "$max/maxaux"
  echo "normalize: $max/aux -> maxaux"
  local mm="$max/make/Makefile.main"
  if [ -f "$mm" ]; then
    sed -i \
      -e 's|aux/ext/|maxaux/ext/|g' \
      -e 's|aux/irsim/|maxaux/irsim/|g' \
      -e 's/all: max aux/all: max maxaux/' \
      -e 's/^aux:/maxaux:/' \
      -e 's/^\.PHONY: aux$/.PHONY: maxaux/' \
      -e 's/cd aux;/cd maxaux;/' \
      "$mm"
  fi
}

rename_max_aux "src/max4.2.11"
rename_max_aux "src/max4.3.16"

fix_reserved_names() {
  find . -depth \( -name ':*' -o -name 'CON' -o -name 'PRN' -o -name 'NUL' \) -print0 2>/dev/null |
    while IFS= read -r -d '' p; do
      base=$(basename "$p")
      dir=$(dirname "$p")
      new="${base#:}"
      [ "$new" = "$base" ] && new="_${base}"
      if [ -e "$dir/$new" ]; then
        new="_${new}"
      fi
      mv "$p" "$dir/$new"
      echo "normalize: renamed $(basename "$p") -> $new"
    done
}

expand_symlinks() {
  local pass link tmp
  for pass in 1 2 3 4 5 6 7 8 9 10; do
    link=$(find . -depth -type l -print -quit 2>/dev/null || true)
    [ -n "$link" ] || break
    find . -depth -type l -print0 | while IFS= read -r -d '' l; do
      [ -L "$l" ] || continue
      tmp="${l}.norm.$$"
      if [ -d "$l" ]; then
        rm -rf "$tmp"
        mkdir -p "$tmp"
        cp -aL "$l/." "$tmp/"
        rm -f "$l"
        mv "$tmp" "$l"
      else
        cp -aL "$l" "$tmp"
        rm -f "$l"
        mv "$tmp" "$l"
      fi
    done
    echo "normalize: symlink pass $pass"
  done
}

fix_bin() {
  local b=bin
  [ -d "$b" ] || return 0
  for name in mmi_tclsh mmi_wish; do
    if [ -x "$b/$name" ] && [ ! -f "$b/${name}.8.0" ]; then
      cp -f "$b/$name" "$b/${name}.8.0"
      chmod +x "$b/${name}.8.0"
    fi
  done
  if [ ! -e bin.linux ] || [ -L bin.linux ]; then
    rm -f bin.linux
    printf '%s\n' bin > bin.linux
  fi
}

fix_reserved_names
expand_symlinks
fix_bin

echo "normalize: done under $ROOT"
remaining=$(find . -type l 2>/dev/null | wc -l)
echo "normalize: symlinks left: $remaining"
