#!/usr/bin/env bash
# Assemble $out/mmi: flattened 2004 data + newly built ELF 64-bit tools.
set -euo pipefail
ROOT="${1:?extracted tree}"
OUT="${2:?nix $out}"
LAYOUT="${LAYOUT_SH:-$(cd "$(dirname "$0")" && pwd)/layout.sh}"

export LC_ALL=C
export LANG=C
export TZ=UTC

max_bin="$ROOT/src/max4.3.16/o/linux/max"
sue_bin="$ROOT/src/sue4.4/bin.linux/sue.exe"
nst_bin="$ROOT/src/nst2.4/bin.linux/nst"

missing=0
for src in "$max_bin" "$sue_bin" "$nst_bin"; do
  name=$(basename "$src")
  if [ ! -x "$src" ]; then
    echo "install: missing $name ($src)" >&2
    missing=1
  elif ! file -L "$src" | grep -q 'ELF 64-bit'; then
    echo "install: $name is not ELF 64-bit" >&2
    file -L "$src" >&2 || true
    missing=1
  fi
done
if [ "$missing" != 0 ]; then
  echo "install: x86_64 tools failed to build (see log)." >&2
  exit 1
fi

mkdir -p "$OUT/mmi"
# Data/scripts/tech only — not source, not prebuilt bindir ELFs.
epoch="${SOURCE_DATE_EPOCH:-315532800}"
( cd "$ROOT" && tar --sort=name \
    --mtime="@${epoch}" \
    --owner=0 --group=0 --numeric-owner \
    --exclude='./src' \
    --exclude='./bin' \
    --exclude='./.x64-bin' \
    -cf - \
    . ) | ( cd "$OUT/mmi" && tar -xf - )

bash "$LAYOUT" "$OUT/mmi"

bindir="$OUT/mmi/bin"
mkdir -p "$bindir"

install_bin() {
  local src="$1" dest="$2"
  [ -e "$src" ] || return 0
  if [ -x "$src" ] && file -L "$src" | grep -q 'ELF 64-bit'; then
    install -Dm755 "$src" "$dest"
    file "$dest" || true
  elif [ -f "$src" ] && ! file -L "$src" | grep -q ELF; then
    install -Dm755 "$src" "$dest"
  fi
}

install_bin "$max_bin" "$bindir/max.bin"
install_bin "$sue_bin" "$bindir/sue.exe"
install_bin "$nst_bin" "$bindir/nst"

if [ -x "$bindir/max.bin" ]; then
  cat > "$bindir/max" << 'EOF'
#!/bin/sh
export MN_BIN_DIR="${MN_BIN_DIR:-bin.linux}"
exec "$(dirname "$0")/max.bin" "$@"
EOF
  chmod +x "$bindir/max"
fi

maxtcl_src="$ROOT/src/max4.3.16/maxtcl"
if [ -d "$maxtcl_src" ]; then
  mkdir -p "$OUT/mmi/max"
  cp -a "$maxtcl_src" "$OUT/mmi/max/"
  echo "install: maxtcl -> $OUT/mmi/max/maxtcl"
fi

fonts_src="$ROOT/src/utils/mmi_local/max/fonts"
if [ -d "$fonts_src" ]; then
  mkdir -p "$OUT/mmi/max/fonts"
  cp -a "$fonts_src"/. "$OUT/mmi/max/fonts/"
  if command -v mkfontdir >/dev/null 2>&1; then
    (cd "$OUT/mmi/max/fonts" && mkfontdir . 2>/dev/null || true)
    if [ -n "${SORT_FONT_INDEX_SH:-}" ] && [ -f "${SORT_FONT_INDEX_SH}" ]; then
      bash "${SORT_FONT_INDEX_SH}" "$OUT/mmi/max/fonts"
    fi
  fi
  echo "install: max fonts -> $OUT/mmi/max/fonts"
fi

for aux in ext2spice ext2sim gemini irsim anXhelper; do
  found=$(LC_ALL=C find "$ROOT/src/max4.3.16/o" -type f -name "$aux" | LC_ALL=C sort | head -1)
  if [ -z "$found" ]; then
    echo "install: missing maxaux binary $aux" >&2
    exit 1
  fi
  install_bin "$found" "$bindir/$aux"
  if [ ! -x "$bindir/$aux" ]; then
    echo "install: failed to install $aux" >&2
    exit 1
  fi
done

e2s=""
for cand in "$ROOT/src/edif2sue1.2.12/edif2sue.linux" "$ROOT/src/edif2sue1.2.12/edif2sue"; do
  if [ -x "$cand" ]; then
    e2s="$cand"
    break
  fi
done
if [ -z "$e2s" ]; then
  echo "install: missing edif2sue" >&2
  exit 1
fi
install_bin "$e2s" "$bindir/edif2sue"

install_bin "$ROOT/src/sue4.4/bin.linux/sue_tee" "$bindir/sue_tee"
if [ ! -x "$bindir/sue_tee" ]; then
  echo "install: missing sue_tee" >&2
  exit 1
fi

if [ -f "$OUT/mmi/max/tech/tech_target/make_tech" ]; then
  ln -sfn ../max/tech/tech_target/make_tech "$bindir/make_tech"
elif [ -f "$ROOT/src/max4.3.16/proto/tech/tech_target/make_tech" ]; then
  install -Dm755 "$ROOT/src/max4.3.16/proto/tech/tech_target/make_tech" "$bindir/make_tech"
else
  echo "install: missing make_tech" >&2
  exit 1
fi

# make_tech compiles .tech → .tech27 with mmi_cpp | mmi_m4 (old i486 ELFs).
# Wrap the FHS GNU tools (gcc's cpp + m4).
cat > "$bindir/mmi_cpp" << 'EOF'
#!/bin/bash
set -e
cpp_bin="$(command -v cpp || true)"
if [ -z "$cpp_bin" ]; then
  echo "mmi_cpp: cpp not on PATH (need gcc in the CAD environment)" >&2
  exit 1
fi
args=()
for a in "$@"; do
  if [ "$a" = "-traditional" ]; then
    args+=(-traditional-cpp)
  else
    args+=("$a")
  fi
done
exec "$cpp_bin" "${args[@]}"
EOF
chmod 755 "$bindir/mmi_cpp"
cat > "$bindir/mmi_m4" << 'EOF'
#!/bin/sh
m4_bin="$(command -v m4 || true)"
if [ -z "$m4_bin" ]; then
  echo "mmi_m4: m4 not on PATH (need GNU m4 in the CAD environment)" >&2
  exit 1
fi
exec "$m4_bin" "$@"
EOF
chmod 755 "$bindir/mmi_m4"

if [ -x "$ROOT/src/utils/bin.x86_64-linux/tclsh" ]; then
  install_bin "$ROOT/src/utils/bin.x86_64-linux/tclsh" "$bindir/mmi_tclsh"
  cp -f "$bindir/mmi_tclsh" "$bindir/mmi_tclsh.8.0"
  chmod +x "$bindir/mmi_tclsh.8.0"
fi
if [ -x "$ROOT/src/utils/bin.x86_64-linux/wish" ]; then
  install_bin "$ROOT/src/utils/bin.x86_64-linux/wish" "$bindir/mmi_wish"
  cp -f "$bindir/mmi_wish" "$bindir/mmi_wish.8.0"
  chmod +x "$bindir/mmi_wish.8.0"
fi

cat > "$bindir/sue" << 'EOF'
#!/bin/sh
exec "$(dirname "$0")/sue.exe" "$@"
EOF
chmod +x "$bindir/sue"

# Versioned trees some scripts still name: same 64-bit binaries.
for pair in "sue:sue.exe" "nst:nst" "max:max.bin" "edif2sue:edif2sue"; do
  prod="${pair%%:*}"
  name="${pair##*:}"
  if [ -d "$OUT/mmi/$prod" ] && [ -x "$bindir/$name" ]; then
    mkdir -p "$OUT/mmi/$prod/bin"
    cp -f "$bindir/$name" "$OUT/mmi/$prod/bin/$(basename "$name")"
    ln -sfn bin "$OUT/mmi/$prod/bin.linux"
  fi
done
if [ -x "$bindir/max" ] && [ -d "$OUT/mmi/max/bin" ]; then
  cp -f "$bindir/max" "$OUT/mmi/max/bin/max"
fi
if [ -x "$bindir/sue" ] && [ -d "$OUT/mmi/sue/bin" ]; then
  cp -f "$bindir/sue" "$OUT/mmi/sue/bin/sue"
fi

ln -sfn bin "$OUT/mmi/bin.linux"
ln -sfn bin "$OUT/mmi/bin.i486-linux"
printf 'linux\n' > "$OUT/BINDIR"
printf '64\n' > "$OUT/BITS"

echo "install: ELF 64-bit tools in $bindir"
ls -la "$bindir"
