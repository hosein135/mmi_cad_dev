#!/usr/bin/env bash
# Flatten a 2004 MMI tree: unversioned product dirs, one bin/, no foreign-arch ELFs.
# Does not touch src/utils/blt2.4g.i486-linux2.2 (that is BLT source, not a bindir).
set -euo pipefail
TREE="${1:?path to extracted MMI tree}"
cd "$TREE"

drop_arch_bindirs() {
  find . \( \
      -name 'bin.i486-linux' -o -name 'bin.i486-linux*' \
      -o -name 'bin.hppa' -o -name 'bin.hppa*' \
      -o -name 'bin.sparc-solaris2' -o -name 'bin.sparc*' \
      -o -name 'bin-opt.hppa*' -o -name 'bin-opt.i486*' -o -name 'bin-opt.sparc*' \
    \) -prune -print0 2>/dev/null | while IFS= read -r -d '' p; do
    echo "layout: drop $p"
    rm -rf "$p"
  done
}

# Keep Tcl/shell wrappers from the i486 bindir; skip ELF binaries (rebuilt later).
harvest_scripts_from_i486() {
  local src="./bin.i486-linux"
  [ -d "$src" ] || return 0
  mkdir -p ./bin
  local f base
  for f in "$src"/*; do
    [ -e "$f" ] || continue
    [ -L "$f" ] && continue
    base=$(basename "$f")
    if file -b "$f" 2>/dev/null | grep -q ELF; then
      continue
    fi
    cp -a "$f" "./bin/$base"
    echo "layout: keep script bin/$base"
  done
}

unversion() {
  local versioned="$1" canonical="$2"
  if [ -L "$canonical" ] && [ -d "$versioned" ]; then
    rm -f "$canonical"
    mv "$versioned" "$canonical"
    ln -sfn "$canonical" "$versioned"
    echo "layout: $versioned -> $canonical/"
  elif [ -d "$versioned" ] && [ ! -e "$canonical" ]; then
    mv "$versioned" "$canonical"
    ln -sfn "$canonical" "$versioned"
    echo "layout: $versioned -> $canonical/"
  elif [ -d "$versioned" ] && [ -d "$canonical" ] && [ ! -L "$canonical" ]; then
    rm -rf "$versioned"
    ln -sfn "$canonical" "$versioned"
  fi
}

harvest_scripts_from_i486
drop_arch_bindirs

unversion max4.2.11 max
unversion sue4.4 sue
unversion nst2.4 nst
unversion edif2sue1.2.12 edif2sue
unversion speedy3.4 speedy
unversion nl-0.34 nl
unversion mmidoc1.4 mmidoc

mkdir -p bin
if [ -d bin.linux ] && [ ! -L bin.linux ]; then
  cp -a bin.linux/. bin/ 2>/dev/null || true
  rm -rf bin.linux
fi
ln -sfn bin bin.linux
# Legacy Tcl still names bin.i486-linux on Linux.
ln -sfn bin bin.i486-linux

# Dangling aliases left after dropping i486 bindirs.
find . -xtype l -print0 2>/dev/null | while IFS= read -r -d '' l; do
  echo "layout: drop dangling $l"
  rm -f "$l"
done

# Stray shared objects / EXEs that are not x86_64 (do not scan every source file).
find . -type f \( -name '*.so' -o -name '*.so.*' -o -name '*.exe' \) -print0 2>/dev/null |
  while IFS= read -r -d '' f; do
    desc=$(file -b "$f" 2>/dev/null || true)
    case "$desc" in
      *ELF*x86-64*|*ELF*64-bit*) ;;
      *ELF*)
        echo "layout: drop ELF $f"
        rm -f "$f"
        ;;
    esac
  done

echo "layout: done under $TREE"
